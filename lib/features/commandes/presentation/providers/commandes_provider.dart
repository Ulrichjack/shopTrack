import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/sync/sync_service.dart';

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
              montantAccepte: null,
              datePrevue: datePrevue,
              statut: 'demande',
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
          'statut': 'demande',
        }),
      );
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(dossiersCommandesProvider);
    return dossierId;
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
    });

    await ref.read(syncServiceProvider).processQueue();
    ref.invalidate(dossiersCommandesProvider);
  }
}

final commandesNotifierProvider = Provider(CommandesNotifier.new);
