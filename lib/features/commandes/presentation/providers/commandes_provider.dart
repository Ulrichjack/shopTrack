import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

/// Module C — commandes avec acompte.
///
/// Gâteau d'événement, objet décoratif sur mesure, formation, décoration :
/// quatre métiers, un seul geste. Un client commande, verse une avance,
/// récupère plus tard.

/// Un dossier et son argent, calculés ensemble.
///
/// Le solde ne se stocke JAMAIS, il se recalcule.
///
/// C'est la règle qui protège ce module du piège qu'on a mis une journée à
/// retirer de l'inventaire : un devis de 150 000 F n'est pas une recette de
/// 150 000 F. Si la cliente verse 40 000 F, seuls 40 000 F sont entrés en
/// caisse — et un solde figé dans une colonne aurait fini par mentir dès le
/// premier remboursement.
class DossierAvecSolde {
  const DossierAvecSolde({
    required this.dossier,
    required this.client,
    required this.paiements,
  });

  final LocalDossiersCommande dossier;

  /// Nul si le client n'est pas encore redescendu du serveur. Le dossier reste
  /// affichable : mieux vaut une ligne sans nom qu'une ligne absente.
  final LocalClient? client;

  final List<LocalPaiementsCommande> paiements;

  int get totalPaye => paiements
      .where((p) => p.typeMouvement == 'paiement')
      .fold(0, (somme, p) => somme + p.montant);

  int get totalRembourse => paiements
      .where((p) => p.typeMouvement == 'remboursement')
      .fold(0, (somme, p) => somme + p.montant);

  /// Ce qui est réellement resté dans la caisse pour ce dossier.
  int get netEncaisse => totalPaye - totalRembourse;

  /// Ce que la cliente doit encore. Nul tant que le prix n'est pas fixé — et
  /// ce nul est un état normal, pas une donnée manquante : la vendeuse
  /// enregistre la demande, la propriétaire fixe le montant à distance.
  int? get solde => dossier.montantAccepte == null
      ? null
      : dossier.montantAccepte! - netEncaisse;

  bool get estSolde => solde != null && solde! <= 0;

  /// Livrée : la marchandise est partie, le dossier est fini.
  ///
  /// À ne pas confondre avec [estSolde], qui ne parle que d'argent. Un gâteau
  /// payé d'avance pour le 15 septembre est soldé et reste entièrement à faire ;
  /// une cliente qui emporte sa commande en devant encore 20 000 F est livrée
  /// sans être soldée. Ranger la liste sur l'argent masquait le travail.
  bool get estLivree => dossier.statut == 'terminee';

  /// Ce que la commande a rapporté. Nul tant qu'on ignore ce qu'elle a coûté.
  ///
  /// Nul et zéro ne veulent pas dire la même chose : zéro serait « elle n'a
  /// rien gagné », nul est « on ne sait pas ». Afficher zéro à la place de rien
  /// ferait croire à une commande blanche, et c'est le genre de chiffre qu'on
  /// recopie dans un bilan sans se méfier.
  int? get benefice {
    final prix = dossier.montantAccepte;
    final cout = dossier.coutMatiere;
    if (prix == null || cout == null) return null;
    return prix - cout;
  }

  /// La date promise est passée et rien n'est livré.
  ///
  /// Comparé au JOUR, pas à l'instant : une commande promise pour aujourd'hui
  /// n'est pas en retard à 8 h du matin. Sans ce détail, tout ce qui est dû
  /// dans la journée s'afficherait en rouge dès l'ouverture de la boutique, et
  /// l'alerte deviendrait un décor qu'on ne lit plus.
  bool get estEnRetard {
    final promis = dossier.datePrevue;
    if (promis == null || estLivree || estAnnulee) return false;
    final aujourdhui = DateTime.now();
    final jour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
    return DateTime(promis.year, promis.month, promis.day).isBefore(jour);
  }

  /// Annulée : ni à livrer, ni livrée. Elle reste dans la liste, barrée, avec
  /// son motif — jamais supprimée, sinon ses acomptes disparaîtraient avec.
  bool get estAnnulee => dossier.statut == 'annulee';

  /// Les espèces seules touchent le tiroir.
  ///
  /// Un acompte de 40 000 F payé par Mobile Money compté comme espèces
  /// produirait un manquant de 40 000 F à chaque clôture — et l'application
  /// accuserait quelqu'un.
  int get encaisseEnEspeces => paiements
      .where((p) => p.modePaiement == 'especes')
      .fold(
        0,
        (somme, p) =>
            somme + (p.typeMouvement == 'paiement' ? p.montant : -p.montant),
      );
}

/// Tous les dossiers de la boutique active, du plus récent au plus ancien.
final dossiersCommandesProvider = FutureProvider<List<DossierAvecSolde>>((
  ref,
) async {
  final shopId = await watchShopId(ref);
  final db = ref.watch(localDbProvider);

  final dossiers =
      await (db.select(db.localDossiersCommandes)
            ..where((row) => row.shopId.equals(shopId))
            ..orderBy([(row) => drift.OrderingTerm.desc(row.createdAt)]))
          .get();

  final clients = await (db.select(
    db.localClients,
  )..where((row) => row.shopId.equals(shopId))).get();
  final paiements = await (db.select(
    db.localPaiementsCommandes,
  )..where((row) => row.shopId.equals(shopId))).get();

  final parClient = {for (final c in clients) c.id: c};
  final parDossier = <String, List<LocalPaiementsCommande>>{};
  for (final p in paiements) {
    parDossier.putIfAbsent(p.dossierId, () => []).add(p);
  }

  return dossiers
      .map(
        (d) => DossierAvecSolde(
          dossier: d,
          client: parClient[d.clientId],
          paiements: parDossier[d.id] ?? const [],
        ),
      )
      .toList();
});

/// Le nom de la ligne de caisse qui fait entrer dans le tiroir l'argent reçu
/// autrement qu'en espèces.
///
/// Volontairement pas « Retrait Mobile Money » : le mode « Autre » existe aussi
/// (virement, chèque, dépôt d'un proche). Un libellé qui parlerait de Mobile
/// Money mentirait dans le journal de caisse une fois sur dix.
///
/// Une seule constante, parce que deux endroits la lisent : celui qui écrit le
/// retrait, et celui qui calcule ce qui reste sur le compte. Deux chaînes
/// recopiées auraient fini par diverger, et le solde n'aurait plus jamais
/// baissé.
const categorieRetraitMobileMoney = 'Entrée depuis un compte';

/// Ce qui a été encaissé sans passer par le tiroir, et qui l'attend encore.
///
/// Un compte mobile est un SECOND TIROIR, pas de l'argent perdu. Il se remplit
/// quand une cliente paie par Orange Money, MTN ou autrement, et il se vide
/// quand la vendeuse va retirer — à ce moment-là, et à ce moment-là seulement,
/// les billets entrent dans la caisse physique.
///
/// C'est pour ça qu'on ne l'ajoute jamais à la caisse au moment du paiement :
/// l'argent n'est pas encore dans le tiroir. L'y mettre d'avance ferait
/// apparaître un manquant à chaque comptage du soir.
typedef ArgentHorsCaisse = ({int total, Map<String, int> parMode});

final soldeMobileMoneyProvider = FutureProvider<ArgentHorsCaisse>((ref) async {
  final shopId = await watchShopId(ref);
  final db = ref.watch(localDbProvider);

  final paiements = await (db.select(
    db.localPaiementsCommandes,
  )..where((row) => row.shopId.equals(shopId))).get();

  // Le détail par moyen, parce que « 30 000 F hors caisse » ne dit pas où
  // aller les chercher : Orange Money se retire chez un agent, un virement
  // s'attend à la banque.
  final parMode = <String, int>{};
  for (final p in paiements.where((p) => p.modePaiement != 'especes')) {
    final signe = p.typeMouvement == 'paiement' ? p.montant : -p.montant;
    parMode[p.modePaiement] = (parMode[p.modePaiement] ?? 0) + signe;
  }
  parMode.removeWhere((_, montant) => montant <= 0);
  final recu = parMode.values.fold<int>(0, (somme, m) => somme + m);

  final mouvements =
      await (db.select(db.localCashMovements)..where(
            (row) =>
                row.shopId.equals(shopId) &
                row.category.equals(categorieRetraitMobileMoney),
          ))
          .get();
  final retire = mouvements.fold<double>(0, (somme, m) => somme + m.amount);

  return (total: recu - retire.round(), parMode: parMode);
});

class CommandesNotifier {
  CommandesNotifier(this.ref);

  final Ref ref;

  /// Enregistre une demande. Le montant reste NUL à ce stade.
  ///
  /// C'est le partage décidé avec la cliente : la vendeuse note ce que le
  /// client veut, la propriétaire fixe le prix depuis chez elle. Un dossier
  /// sans montant n'est donc pas incomplet, c'est une demande en attente de
  /// devis.
  Future<String> creerDemande({
    required String nomClient,
    String? telephone,
    required String categorie,
    required String description,
    DateTime? datePrevue,
    Map<String, dynamic> details = const {},
    int? montantAccepte,
  }) async {
    if (nomClient.trim().isEmpty) {
      throw ArgumentError('Le nom du client est obligatoire.');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError('Décris ce que le client demande.');
    }

    final shopId = await requireShopId(ref);
    final db = ref.read(localDbProvider);
    final maintenant = DateTime.now();

    // Le prix décide du statut, et c'est le serveur qui l'exige : une contrainte
    // interdit un dossier avancé sans montant, et interdit à un membre (la
    // vendeuse) d'en poser un. La propriétaire qui prend la commande elle-même
    // connaît son prix — la faire repasser par un second écran n'ajouterait
    // rien.
    final statut = montantAccepte == null ? 'demande' : 'confirmee';

    // Le client d'abord : le dossier le référence, et une clé composite
    // (client, boutique) côté serveur interdit qu'un dossier pointe vers le
    // client d'une autre boutique.
    final clientId = const Uuid().v4();
    final dossierId = const Uuid().v4();

    await db.transaction(() async {
      await db
          .into(db.localClients)
          .insert(
            LocalClient(
              id: clientId,
              shopId: shopId,
              nom: nomClient.trim(),
              telephone: telephone?.trim().isEmpty ?? true
                  ? null
                  : telephone!.trim(),
              createdAt: maintenant,
            ),
          );
      await db.addToQueue(
        'ADD_CLIENT',
        jsonEncode({
          'id': clientId,
          'shop_id': shopId,
          'nom': nomClient.trim(),
          'telephone': telephone?.trim().isEmpty ?? true
              ? null
              : telephone!.trim(),
        }),
      );

      await db
          .into(db.localDossiersCommandes)
          .insert(
            LocalDossiersCommande(
              id: dossierId,
              shopId: shopId,
              clientId: clientId,
              categorie: categorie,
              description: description.trim(),
              details: jsonEncode(details),
              montantAccepte: montantAccepte,
              datePrevue: datePrevue,
              statut: statut,
              createdAt: maintenant,
            ),
          );
      await db.addToQueue(
        'ADD_DOSSIER_COMMANDE',
        jsonEncode({
          'id': dossierId,
          'shop_id': shopId,
          'client_id': clientId,
          'categorie': categorie,
          'description': description.trim(),
          'details': details,
          'date_prevue': datePrevue?.toUtc().toIso8601String(),
          'montant_accepte': montantAccepte,
          'statut': statut,
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(dossiersCommandesProvider);
    return dossierId;
  }

  /// Fixe (ou corrige) le prix d'un dossier. Réservé à la propriétaire.
  ///
  /// Le serveur le fait respecter tout seul : la politique d'insertion du
  /// membre exige `montant_accepte is null`, et seule la propriétaire a le
  /// droit de mise à jour. L'écran cache le bouton, la base refuse le geste —
  /// les deux, parce que cacher n'est pas interdire.
  Future<void> fixerMontant({
    required String dossierId,
    required int montant,
  }) async {
    if (montant < 0) {
      throw ArgumentError('Un prix ne peut pas être négatif.');
    }

    final db = ref.read(localDbProvider);

    // Un dossier qui reçoit son prix quitte l'état « demande » : c'est ce que
    // la contrainte serveur attend, et c'est aussi ce que la propriétaire vient
    // de décider en tapant le montant.
    await db.transaction(() async {
      await (db.update(
        db.localDossiersCommandes,
      )..where((row) => row.id.equals(dossierId))).write(
        LocalDossiersCommandesCompanion(
          montantAccepte: drift.Value(montant),
          statut: const drift.Value('confirmee'),
        ),
      );
      await db.addToQueue(
        'UPDATE_DOSSIER_COMMANDE',
        jsonEncode({
          'id': dossierId,
          'montant_accepte': montant,
          'statut': 'confirmee',
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(dossiersCommandesProvider);
  }

  /// Corrige ce qui a été noté : la description, la date, la catégorie.
  ///
  /// Une cliente qui repousse son mariage de deux semaines, un nom mal
  /// entendu au téléphone, une catégorie choisie trop vite. Sans ce geste, la
  /// seule issue était de recréer la commande — en perdant ses acomptes.
  ///
  /// Ouvert au vendeur : c'est lui qui prend l'appel où la cliente change sa
  /// date. Le prix, lui, ne passe pas par ici — il a sa propre règle.
  Future<void> modifierDossier({
    required String dossierId,
    required String description,
    required String categorie,
    String? nomClient,
    DateTime? datePrevue,
  }) async {
    if (description.trim().isEmpty) {
      throw ArgumentError('Décris ce que le client demande.');
    }

    final db = ref.read(localDbProvider);
    final dossier = await (db.select(
      db.localDossiersCommandes,
    )..where((row) => row.id.equals(dossierId))).getSingleOrNull();

    await db.transaction(() async {
      // Le nom vit sur le CLIENT, pas sur le dossier : le corriger répare
      // aussi le journal de caisse et le bilan, qui le lisent au même endroit.
      final nom = nomClient?.trim();
      if (dossier != null && nom != null && nom.isNotEmpty) {
        await (db.update(db.localClients)
              ..where((row) => row.id.equals(dossier.clientId)))
            .write(LocalClientsCompanion(nom: drift.Value(nom)));
        await db.addToQueue(
          'UPDATE_CLIENT',
          jsonEncode({'id': dossier.clientId, 'nom': nom}),
        );
      }
      await (db.update(
        db.localDossiersCommandes,
      )..where((row) => row.id.equals(dossierId))).write(
        LocalDossiersCommandesCompanion(
          description: drift.Value(description.trim()),
          categorie: drift.Value(categorie),
          datePrevue: drift.Value(datePrevue),
        ),
      );
      await db.addToQueue(
        'UPDATE_DOSSIER_COMMANDE',
        jsonEncode({
          'id': dossierId,
          'description': description.trim(),
          'categorie': categorie,
          'date_prevue': datePrevue?.toUtc().toIso8601String(),
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(dossiersCommandesProvider);
  }

  /// Annule une commande. Réservé à la patronne, avec un motif obligatoire.
  ///
  /// ANNULER, PAS SUPPRIMER. Une commande effacée emporterait ses acomptes
  /// avec elle : l'argent serait entré dans la caisse et plus rien ne dirait
  /// pourquoi. C'est la même règle que pour un produit déjà vendu — on archive,
  /// on ne supprime pas.
  ///
  /// Les acomptes déjà encaissés restent donc à rembourser, visibles, et c'est
  /// exactement ce qu'on veut : une annulation ne fait pas disparaître une
  /// dette envers la cliente.
  Future<void> annulerDossier({
    required String dossierId,
    required String motif,
  }) async {
    if (motif.trim().isEmpty) {
      throw ArgumentError('Dis pourquoi la commande est annulée.');
    }

    final db = ref.read(localDbProvider);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('cached_user_id');
    if (userId == null) {
      throw StateError(
        'Connecte-toi avant d\'annuler : une annulation doit porter un nom.',
      );
    }
    final maintenant = DateTime.now();

    await db.transaction(() async {
      await (db.update(
        db.localDossiersCommandes,
      )..where((row) => row.id.equals(dossierId))).write(
        LocalDossiersCommandesCompanion(
          statut: const drift.Value('annulee'),
          motifAnnulation: drift.Value(motif.trim()),
          annuleAt: drift.Value(maintenant),
        ),
      );
      await db.addToQueue(
        'UPDATE_DOSSIER_COMMANDE',
        jsonEncode({
          'id': dossierId,
          'statut': 'annulee',
          'motif_annulation': motif.trim(),
          'annule_at': maintenant.toUtc().toIso8601String(),
          'annule_par': userId,
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(dossiersCommandesProvider);
  }

  /// Enregistre ce que la commande a coûté. Réservé à la propriétaire.
  ///
  /// Un seul nombre, saisi à la livraison — pas une recette ligne par ligne.
  /// La version riche a été écartée pour une raison qui n'est pas technique :
  /// neuf ingrédients par gâteau, c'est trois minutes de saisie, et le risque
  /// n'est pas qu'elle refuse mais qu'elle s'arrête au bout de quinze jours.
  /// Un historique de coûts à moitié rempli ment plus qu'il n'informe.
  ///
  /// Le serveur le fait respecter par un déclencheur : RLS filtre des lignes,
  /// pas des colonnes, et cette colonne-là n'appartient qu'à la patronne.
  Future<void> enregistrerCout({
    required String dossierId,
    required int cout,
  }) async {
    if (cout < 0) {
      throw ArgumentError('Un coût ne peut pas être négatif.');
    }

    final db = ref.read(localDbProvider);

    await db.transaction(() async {
      await (db.update(
        db.localDossiersCommandes,
      )..where((row) => row.id.equals(dossierId))).write(
        LocalDossiersCommandesCompanion(coutMatiere: drift.Value(cout)),
      );
      await db.addToQueue(
        'UPDATE_DOSSIER_COMMANDE',
        jsonEncode({'id': dossierId, 'cout_matiere': cout}),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(dossiersCommandesProvider);
  }

  /// Fait avancer un dossier (prête, terminée...).
  Future<void> changerStatut({
    required String dossierId,
    required String statut,
  }) async {
    final db = ref.read(localDbProvider);
    // Livrer DATE la livraison. Sans ça, le bilan ne saurait pas dans quel mois
    // faire tomber le bénéfice — `datePrevue` ne peut pas servir, c'est une
    // intention souvent vide et parfois fausse de deux jours.
    final livreeAt = statut == 'terminee' ? DateTime.now() : null;

    await db.transaction(() async {
      await (db.update(
        db.localDossiersCommandes,
      )..where((row) => row.id.equals(dossierId))).write(
        LocalDossiersCommandesCompanion(
          statut: drift.Value(statut),
          livreeAt: livreeAt == null
              ? const drift.Value.absent()
              : drift.Value(livreeAt),
        ),
      );
      await db.addToQueue(
        'UPDATE_DOSSIER_COMMANDE',
        jsonEncode({
          'id': dossierId,
          'statut': statut,
          if (livreeAt != null) 'livree_at': livreeAt.toUtc().toIso8601String(),
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(dossiersCommandesProvider);
  }

  /// Fait passer l'argent du compte Mobile Money au tiroir.
  ///
  /// Le geste réel : la vendeuse va chez l'agent, retire les billets, et les
  /// pose dans la caisse. L'application ne fait que le constater — c'est
  /// pourquoi la caisse monte ICI et pas au moment du paiement de la cliente.
  ///
  /// Une entrée, pas une vente : cet argent était déjà gagné, il change
  /// seulement de poche. Le bénéfice ne bouge pas.
  Future<void> transfererMobileMoney({required int montant}) async {
    if (montant <= 0) {
      throw ArgumentError('Le montant doit être supérieur à zéro.');
    }

    final shopId = await requireShopId(ref);
    final db = ref.read(localDbProvider);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('cached_user_id') ?? 'offline_user';
    final maintenant = DateTime.now();
    final id = const Uuid().v4();

    await db.transaction(() async {
      await db
          .into(db.localCashMovements)
          .insert(
            LocalCashMovement(
              id: id,
              shopId: shopId,
              userId: userId,
              amount: montant.toDouble(),
              type: 'incoming',
              category: categorieRetraitMobileMoney,
              note: 'Retiré du compte Mobile Money',
              createdAt: maintenant,
            ),
          );
      await db.addToQueue(
        'ADD_CASH_MOVEMENT',
        jsonEncode({
          'id': id,
          'shop_id': shopId,
          'user_id': userId,
          'amount': montant.toDouble(),
          'type': 'incoming',
          'category': categorieRetraitMobileMoney,
          'note': 'Retiré du compte Mobile Money',
          'created_at': maintenant.toUtc().toIso8601String(),
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(soldeMobileMoneyProvider);
    ref.invalidate(dashboardProvider);
  }

  /// Enregistre un paiement ou un remboursement.
  ///
  /// Un remboursement est une LIGNE DE PLUS, jamais une suppression : la
  /// vendeuse ne peut pas effacer un acompte qu'elle a encaissé, et l'histoire
  /// de l'argent reste lisible.
  Future<void> enregistrerPaiement({
    required String dossierId,
    required int montant,
    String modePaiement = 'especes',
    String typeMouvement = 'paiement',
    String? note,
  }) async {
    if (montant <= 0) {
      throw ArgumentError('Le montant doit être supérieur à zéro.');
    }

    final shopId = await requireShopId(ref);
    final db = ref.read(localDbProvider);
    final maintenant = DateTime.now();
    final id = const Uuid().v4();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('cached_user_id') ?? 'offline_user';

    // Le NOM de la cliente dans la note, pas l'identifiant du dossier.
    //
    // Le journal de caisse affichait « Commande 1af8bf08-9818-48d6… » : une
    // ligne illisible, qu'on ne peut rapprocher de rien sans rouvrir l'app et
    // chercher. « Acompte Mme Ngo Bikoi » se comprend six mois plus tard, et
    // sur un relevé imprimé.
    final dossier = await (db.select(
      db.localDossiersCommandes,
    )..where((row) => row.id.equals(dossierId))).getSingleOrNull();
    final client = dossier == null
        ? null
        : await (db.select(
            db.localClients,
          )..where((row) => row.id.equals(dossier.clientId))).getSingleOrNull();
    final libelle = client?.nom ?? 'commande';

    await db.transaction(() async {
      await db
          .into(db.localPaiementsCommandes)
          .insert(
            LocalPaiementsCommande(
              id: id,
              shopId: shopId,
              dossierId: dossierId,
              typeMouvement: typeMouvement,
              montant: montant,
              modePaiement: modePaiement,
              note: note?.trim().isEmpty ?? true ? null : note!.trim(),
              effectueAt: maintenant,
              createdAt: maintenant,
            ),
          );
      await db.addToQueue(
        'ADD_PAIEMENT_COMMANDE',
        jsonEncode({
          'id': id,
          'shop_id': shopId,
          'dossier_id': dossierId,
          'type_mouvement': typeMouvement,
          'montant': montant,
          'mode_paiement': modePaiement,
          'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
          'effectue_at': maintenant.toUtc().toIso8601String(),
        }),
      );

      // L'acompte en espèces est DANS le tiroir : il doit exister aussi en
      // mouvement de caisse.
      //
      // Sans cette ligne, la vendeuse encaisse 40 000 F, les pose dans le
      // tiroir, et le soir la clôture annonce 40 000 F de surplus qu'elle ne
      // sait pas expliquer — tous les soirs. C'est le même défaut que le
      // Mobile Money compté comme espèces, dans l'autre sens.
      //
      // `incoming` et non une vente : un acompte n'est pas une recette, c'est
      // de l'argent avancé. Il remplit la caisse sans toucher le bénéfice.
      if (modePaiement == 'especes') {
        final mouvementId = const Uuid().v4();
        final estRemboursement = typeMouvement == 'remboursement';
        final categorie = estRemboursement
            ? 'Remboursement commande'
            : 'Acompte commande';
        final typeCaisse = estRemboursement ? 'withdrawal' : 'incoming';
        final note = estRemboursement
            ? 'Remboursé à $libelle'
            : 'Acompte $libelle';

        await db
            .into(db.localCashMovements)
            .insert(
              LocalCashMovement(
                id: mouvementId,
                shopId: shopId,
                userId: userId,
                amount: montant.toDouble(),
                type: typeCaisse,
                category: categorie,
                note: note,
                createdAt: maintenant,
              ),
            );
        await db.addToQueue(
          'ADD_CASH_MOVEMENT',
          jsonEncode({
            'id': mouvementId,
            'shop_id': shopId,
            'user_id': userId,
            'amount': montant.toDouble(),
            'type': typeCaisse,
            'category': categorie,
            'note': note,
            'created_at': maintenant.toUtc().toIso8601String(),
          }),
        );
      }
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(dossiersCommandesProvider);
    ref.invalidate(soldeMobileMoneyProvider);

    // La caisse vient peut-être de changer : sans cette relance, l'accueil
    // continue d'afficher le solde d'avant l'acompte, et le commerçant voit un
    // écart qui n'existe pas. Invalidé même hors espèces — c'est une ligne, pas
    // un coût, et raisonner « seulement si » est exactement ce qui laisse
    // passer le cas oublié.
    ref.invalidate(dashboardProvider);
  }
}

final commandesNotifierProvider = Provider(CommandesNotifier.new);
