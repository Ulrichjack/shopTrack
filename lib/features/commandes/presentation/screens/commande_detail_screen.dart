import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/providers/app_mode_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/montant_sheet.dart';
import '../providers/commandes_provider.dart';
import 'commande_edition_sheet.dart';

/// Un dossier, son argent et son histoire.
///
/// L'écran ne propose JAMAIS un geste que le serveur refuserait : pas
/// d'encaissement avant le prix, pas de paiement au-delà du solde, pas de
/// remboursement au-delà de ce qui est entré. Un refus ne coûte pas seulement
/// un message — il bloque la file cinq essais durant et fait apparaître un
/// bandeau que personne ne sait quoi faire (voir docs/PIEGES_CONNUS.md #30).
class CommandeDetailScreen extends ConsumerWidget {
  const CommandeDetailScreen({super.key, required this.dossierId});

  final String dossierId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dossiersAsync = ref.watch(dossiersCommandesProvider);
    final estPatron = ref.watch(appModeProvider).value ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Commande'),
        actions: [
          // Corriger une date ou une description ne devrait jamais obliger à
          // recréer la commande : elle emporterait ses acomptes avec elle.
          dossiersAsync.maybeWhen(
            data: (dossiers) {
              final d = dossiers
                  .where((x) => x.dossier.id == dossierId)
                  .firstOrNull;
              // Rien ne se corrige sur une commande close : la retoucher des
              // semaines plus tard changerait un bilan déjà consulté.
              if (d == null || d.estAnnulee || d.estLivree) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Corriger',
                onPressed: () =>
                    _corriger(context, ref, d.dossier, d.client?.nom ?? ''),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: dossiersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(humanSyncError(e), textAlign: TextAlign.center),
          ),
        ),
        data: (dossiers) {
          final dossier = dossiers
              .where((d) => d.dossier.id == dossierId)
              .firstOrNull;
          if (dossier == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Cette commande n’existe plus.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _EnTete(dossier: dossier),
              const SizedBox(height: 14),
              _Argent(dossier: dossier),
              // Livrée sans coût : impossible à rater, et le bouton est dans
              // le bandeau. Le geste existait déjà, mais quatrième dans une
              // pile de boutons — on ferme la feuille au moment de livrer, et
              // on ne retrouve plus par où la rouvrir.
              //
              // Un bandeau plutôt qu'une obligation : elle ne connaît pas
              // toujours son coût le jour de la livraison. Bloquer la livraison
              // sur un chiffre qu'elle ira chercher demain lui ferait mentir
              // sur la date, et la date décide du bilan.
              if (estPatron &&
                  dossier.estLivree &&
                  dossier.dossier.coutMatiere == null) ...[
                const SizedBox(height: 12),
                _CoutManquant(dossier: dossier),
              ],
              const SizedBox(height: 14),
              _Actions(dossier: dossier, estPatron: estPatron),
              const SizedBox(height: 20),
              _Historique(paiements: dossier.paiements),
            ],
          );
        },
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.dossier});

  final DossierAvecSolde dossier;

  static const _libelles = {
    'gateau': 'Gâteau',
    'objet_decoratif': 'Objet décoratif',
    'formation': 'Formation',
    'decoration_evenementielle': 'Décoration événementielle',
  };

  @override
  Widget build(BuildContext context) {
    final d = dossier.dossier;
    final format = DateFormat('EEEE d MMMM y', 'fr');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dossier.client?.nom ?? 'Client',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            if (dossier.client?.telephone != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    dossier.client!.telephone!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Text(
              _libelles[d.categorie] ?? d.categorie,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(d.description, style: const TextStyle(height: 1.4)),
            if (d.datePrevue != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'À livrer le ${format.format(d.datePrevue!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Argent extends ConsumerWidget {
  const _Argent({required this.dossier});

  final DossierAvecSolde dossier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solde = dossier.solde;
    final estPatron = ref.watch(appModeProvider).value ?? false;

    if (solde == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.pending_actions, color: AppColors.warningDark),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Le prix n’est pas encore fixé. Aucun acompte ne peut être '
                'encaissé avant.',
                style: TextStyle(color: AppColors.warningDark, height: 1.3),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Ligne(
              'Prix convenu',
              dossier.dossier.montantAccepte!,
              gras: false,
            ),
            const SizedBox(height: 8),
            _Ligne('Déjà encaissé', dossier.netEncaisse, gras: false),
            if (dossier.totalRembourse > 0) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'dont ${CurrencyFormatter.format(dossier.totalRembourse.toDouble())} remboursés',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
            // Le bénéfice, seulement pour la patronne et seulement s'il est
            // connu. Zéro à la place de « on ne sait pas » ferait croire à une
            // commande blanche — et c'est le genre de chiffre qu'on recopie
            // dans un bilan sans se méfier.
            if (estPatron && dossier.benefice != null) ...[
              const Divider(height: 24),
              _Ligne(
                'Ça m\'a coûté',
                dossier.dossier.coutMatiere!,
                gras: false,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'J\'ai gagné',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    CurrencyFormatter.format(dossier.benefice!.toDouble()),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: dossier.benefice! >= 0
                          ? AppColors.primary
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            // Sur une commande ANNULÉE, le sens s'inverse.
            //
            // L'écran annonçait « RESTE À PAYER 170 000 F » sur une commande
            // annulée dont la cliente avait versé 110 000 et reçu 100 000. Elle
            // ne doit rien : c'est la BOUTIQUE qui lui doit les 10 000 gardés.
            // Réclamer 170 000 F à quelqu'un qu'on doit rembourser, c'est le
            // genre d'erreur qui coûte une cliente.
            if (dossier.estAnnulee)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dossier.netEncaisse > 0 ? 'À RENDRE' : 'ANNULÉE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    dossier.netEncaisse > 0
                        ? CurrencyFormatter.format(
                            dossier.netEncaisse.toDouble(),
                          )
                        : 'Rien à rendre',
                    style: TextStyle(
                      fontSize: dossier.netEncaisse > 0 ? 22 : 15,
                      fontWeight: FontWeight.bold,
                      color: dossier.netEncaisse > 0
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    solde <= 0 ? 'SOLDÉE' : 'RESTE À PAYER',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    solde <= 0
                        ? 'Rien à encaisser'
                        : CurrencyFormatter.format(solde.toDouble()),
                    style: TextStyle(
                      fontSize: solde <= 0 ? 15 : 22,
                      fontWeight: FontWeight.bold,
                      color: solde <= 0 ? AppColors.primary : AppColors.error,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// « Cette commande est livrée mais tu n'as pas dit ce qu'elle t'a coûté. »
class _CoutManquant extends ConsumerWidget {
  const _CoutManquant({required this.dossier});

  final DossierAvecSolde dossier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(commandesNotifierProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate_outlined,
                color: AppColors.warningDark,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Livrée, mais tu n\'as pas dit ce qu\'elle t\'a coûté.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warningDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 34),
            child: Text(
              'Tant que c\'est vide, le bénéfice du mois est plus beau que le '
              'vrai.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.warningDark,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warningDark,
              ),
              onPressed: () => _saisirPuisExecuter(
                context: context,
                titre: 'Ce que ça m\'a coûté',
                aide:
                    'Ingrédients, matière, ce que tu as payé à quelqu\'un. '
                    'N\'y mets pas ce que tu vas resservir.',
                valider: (montant) =>
                    dossier.dossier.montantAccepte != null &&
                        montant > dossier.dossier.montantAccepte!
                    ? 'Plus que le prix de vente : tu perdrais de l\'argent.'
                    : null,
                action: (saisie) => notifier.enregistrerCout(
                  dossierId: dossier.dossier.id,
                  cout: saisie.montant,
                ),
                succes: 'Coût enregistré.',
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Dire combien ça a coûté',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne(this.libelle, this.montant, {required this.gras});

  final String libelle;
  final int montant;
  final bool gras;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(libelle, style: TextStyle(color: Colors.grey.shade700)),
        Text(
          CurrencyFormatter.format(montant.toDouble()),
          style: TextStyle(
            fontWeight: gras ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.dossier, required this.estPatron});

  final DossierAvecSolde dossier;
  final bool estPatron;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solde = dossier.solde;
    // Lu ici, jamais dans la feuille : un `ref.watch` dans un
    // `showModalBottomSheet` casse l'écran (assertion `_dependents.isEmpty`).
    final notifier = ref.read(commandesNotifierProvider);
    final actions = <Widget>[];

    // Fixer le prix n'est PAS réservé à la patronne — sauf pour une décoration.
    //
    // Elle n'est jamais à la boutique : une cliente qui commande un gâteau et
    // demande son prix repartirait sans réponse. Ce qui remplace
    // l'interdiction, c'est la trace (`created_by`, écrit par le serveur).
    //
    // L'exception vient de la cliente, et le métier l'explique : un gâteau et
    // une formation ont un tarif connu d'avance, une décoration se chiffre au
    // cas par cas — la salle, le nombre d'invités, ce qu'il faut louer. C'est
    // un devis, pas un prix.
    final prixReserveAuPatron =
        dossier.dossier.categorie == 'decoration_evenementielle';
    // Une commande livrée est FIGÉE.
    //
    // Après la livraison, corriger le prix ne corrige plus rien : il ferait
    // apparaître une dette ou l'effacerait sur une affaire déjà close, des
    // semaines plus tard, sans que personne ne s'en aperçoive. Le bilan du
    // mois passé changerait tout seul.
    //
    // Avant la livraison, en revanche, le prix doit rester modifiable : la
    // cliente ajoute un étage à son gâteau ou trente invités à sa décoration,
    // et le devis suit. C'est la livraison qui ferme, pas le paiement.
    final figee = dossier.estLivree || dossier.estAnnulee;
    if (!figee && (estPatron || !prixReserveAuPatron)) {
      actions.add(
        _Bouton(
          icone: solde == null ? Icons.sell_outlined : Icons.edit_outlined,
          libelle: solde == null ? 'Fixer le prix' : 'Corriger le prix',
          principal: solde == null,
          onPressed: () => _saisirPuisExecuter(
            context: context,
            titre: solde == null ? 'Prix convenu' : 'Corriger le prix',
            valeurInitiale: dossier.dossier.montantAccepte,
            // Baisser le prix sous ce qui est déjà encaissé rendrait le solde
            // négatif et ferait mentir tous les totaux : le plancher est
            // l'argent réellement reçu.
            aide: dossier.netEncaisse > 0
                ? 'Au moins ${CurrencyFormatter.format(dossier.netEncaisse.toDouble())}, déjà encaissés.'
                : null,
            valider: (montant) => montant < dossier.netEncaisse
                ? 'Au moins ${CurrencyFormatter.format(dossier.netEncaisse.toDouble())}.'
                : null,
            action: (saisie) => notifier.fixerMontant(
              dossierId: dossier.dossier.id,
              montant: saisie.montant,
            ),
            succes: 'Prix enregistré.',
          ),
        ),
      );
    }

    // Pas d'encaissement avant le prix : le serveur le refuse, et l'écran ne
    // doit pas proposer un bouton qui finit en opération bloquée.
    // Encaisser reste ouvert même après livraison : la cliente peut emporter sa
    // commande en devant encore de l'argent. Refuser d'enregistrer une entrée
    // ferait un surplus inexpliqué au comptage du soir.
    if (solde != null && solde > 0 && !dossier.estAnnulee) {
      actions.add(
        _Bouton(
          icone: Icons.payments_outlined,
          libelle: 'Encaisser un paiement',
          principal: true,
          onPressed: () => _saisirPuisExecuter(
            context: context,
            titre: 'Encaisser',
            avecModePaiement: true,
            aide: 'Au maximum ${CurrencyFormatter.format(solde.toDouble())}.',
            valider: (montant) => montant > solde
                ? 'Pas plus de ${CurrencyFormatter.format(solde.toDouble())}.'
                : null,
            action: (saisie) => notifier.enregistrerPaiement(
              dossierId: dossier.dossier.id,
              montant: saisie.montant,
              modePaiement: saisie.mode,
            ),
            succes: 'Paiement enregistré.',
          ),
        ),
      );
    }

    // Rendre l'argent : ouvert au vendeur, mais pas après la livraison.
    //
    // Avant livraison, le bouton est nécessaire — une commande annulée, la
    // cliente devant le comptoir : sans lui la vendeuse rend les billets sans
    // les enregistrer, et le soir la caisse annonce un manquant à son nom.
    //
    // Après livraison, la cliente est formelle : « il n'y a pas de
    // remboursement quand on a déjà livré ». Le bouton disparaît donc, sauf
    // pour la patronne — une exception rarissime doit rester rare, pas devenir
    // impossible.
    if (dossier.netEncaisse > 0 && (estPatron || !dossier.estLivree)) {
      actions.add(
        _Bouton(
          icone: Icons.undo,
          libelle: 'Rembourser',
          principal: false,
          onPressed: () => _saisirPuisExecuter(
            context: context,
            titre: 'Rembourser',
            avecModePaiement: true,
            aide:
                'Au maximum ${CurrencyFormatter.format(dossier.netEncaisse.toDouble())}, '
                'la somme réellement reçue.',
            valider: (montant) => montant > dossier.netEncaisse
                ? 'Pas plus de ${CurrencyFormatter.format(dossier.netEncaisse.toDouble())}.'
                : null,
            action: (saisie) => notifier.enregistrerPaiement(
              dossierId: dossier.dossier.id,
              montant: saisie.montant,
              modePaiement: saisie.mode,
              typeMouvement: 'remboursement',
            ),
            succes: 'Remboursement enregistré.',
          ),
        ),
      );
    }

    if (solde != null && !figee) {
      actions.add(
        _Bouton(
          icone: Icons.check_circle_outline,
          libelle: 'Marquer comme livrée',
          principal: false,
          onPressed: () =>
              _livrer(context, notifier, dossier, estPatron: estPatron),
        ),
      );
    }

    // Le coût appartient à la patronne, et c'est cohérent avec tout le reste :
    // l'application cache déjà les prix d'achat et les marges à la vendeuse.
    // Le lui faire saisir lui montrerait ce que la patronne gagne par gâteau.
    //
    // Et ça ne contredit pas « la patronne n'est jamais là » : une cliente ne
    // reste pas debout à attendre un coût de revient. C'est la règle du
    // module — ce qui bloque une cliente au comptoir appartient à la vendeuse,
    // ce qui peut attendre appartient à la patronne.
    if (estPatron && solde != null && !dossier.estAnnulee) {
      actions.add(
        _Bouton(
          icone: Icons.calculate_outlined,
          libelle: dossier.dossier.coutMatiere == null
              ? 'Ce que ça m\'a coûté'
              : 'Corriger le coût',
          principal: false,
          onPressed: () => _saisirPuisExecuter(
            context: context,
            titre: 'Ce que ça m\'a coûté',
            valeurInitiale: dossier.dossier.coutMatiere,
            aide:
                'Ingrédients, matière, ce que tu as payé à quelqu\'un. '
                'N\'y mets pas ce que tu vas resservir.',
            valider: (montant) =>
                dossier.dossier.montantAccepte != null &&
                    montant > dossier.dossier.montantAccepte!
                ? 'Plus que le prix de vente : tu perdrais de l\'argent. '
                      'Vérifie.'
                : null,
            action: (saisie) => notifier.enregistrerCout(
              dossierId: dossier.dossier.id,
              cout: saisie.montant,
            ),
            succes: 'Coût enregistré.',
          ),
        ),
      );
    }

    // Annuler appartient à la patronne, et c'est la seule chose qu'on lui
    // réserve vraiment ici : une commande annulée disparaît du travail de la
    // semaine, et cette décision-là n'appartient pas à qui tient le comptoir.
    //
    // ANNULER, jamais SUPPRIMER : une commande effacée emporterait ses acomptes
    // avec elle — l'argent serait entré en caisse et plus rien ne dirait
    // pourquoi. Même règle qu'un produit déjà vendu, qu'on archive.
    if (estPatron &&
        dossier.dossier.statut != 'annulee' &&
        !dossier.estLivree) {
      actions.add(
        _Bouton(
          icone: Icons.cancel_outlined,
          libelle: 'Annuler la commande',
          principal: false,
          onPressed: () => _annuler(context, notifier, dossier.dossier.id),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final action in actions) ...[action, const SizedBox(height: 10)],
      ],
    );
  }
}

/// Livrer, puis demander ce que ça a coûté — dans le même geste.
///
/// C'est le seul moment où elle le sait : la commande vient d'être faite, les
/// achats sont frais. Le demander plus tard, c'est ne jamais l'obtenir.
///
/// La livraison est enregistrée D'ABORD, et le coût est facultatif : si elle
/// ferme la feuille, la commande est quand même livrée. Lier les deux ferait
/// qu'une hésitation sur un chiffre bloquerait une livraison réelle.
Future<void> _livrer(
  BuildContext context,
  CommandesNotifier notifier,
  DossierAvecSolde dossier, {
  required bool estPatron,
}) async {
  await _executer(
    context,
    () => notifier.changerStatut(
      dossierId: dossier.dossier.id,
      statut: 'terminee',
    ),
    'Commande marquée comme livrée.',
  );
  if (!estPatron || !context.mounted) return;
  if (dossier.dossier.coutMatiere != null) return;

  final saisie = await showMontantSheet(
    context: context,
    titre: 'Ce que ça t\'a coûté',
    aide:
        'Ingrédients, matière, ce que tu as payé à quelqu\'un. N\'y mets pas '
        'ce que tu vas resservir. Tu peux passer et le mettre plus tard.',
    valider: (montant) =>
        dossier.dossier.montantAccepte != null &&
            montant > dossier.dossier.montantAccepte!
        ? 'Plus que le prix de vente : tu perdrais de l\'argent. Vérifie.'
        : null,
  );
  if (saisie == null || !context.mounted) return;
  await _executer(
    context,
    () => notifier.enregistrerCout(
      dossierId: dossier.dossier.id,
      cout: saisie.montant,
    ),
    'Coût enregistré.',
  );
}

Future<void> _corriger(
  BuildContext context,
  WidgetRef ref,
  LocalDossiersCommande dossier,
  String nomClient,
) async {
  final correction = await showCorrectionSheet(
    context: context,
    dossier: dossier,
    nomClient: nomClient,
  );
  if (correction == null || !context.mounted) return;
  await _executer(
    context,
    () => ref
        .read(commandesNotifierProvider)
        .modifierDossier(
          dossierId: dossier.id,
          description: correction.description,
          categorie: correction.categorie,
          nomClient: correction.nomClient,
          datePrevue: correction.datePrevue,
        ),
    'Commande corrigée.',
  );
}

Future<void> _annuler(
  BuildContext context,
  CommandesNotifier notifier,
  String dossierId,
) async {
  final motif = await showMotifAnnulationSheet(context);
  if (motif == null || !context.mounted) return;
  await _executer(
    context,
    () => notifier.annulerDossier(dossierId: dossierId, motif: motif),
    'Commande annulée.',
  );
}

/// Ouvre la feuille, puis exécute — un seul chemin pour les trois montants.
///
/// Le contexte n'est utilisé qu'après un `mounted` : entre l'ouverture de la
/// feuille et la réponse, l'utilisateur a pu quitter l'écran.
Future<void> _saisirPuisExecuter({
  required BuildContext context,
  required String titre,
  int? valeurInitiale,
  required String? Function(int montant) valider,
  String? aide,
  bool avecModePaiement = false,
  required Future<void> Function(SaisieMontant saisie) action,
  required String succes,
}) async {
  final saisie = await showMontantSheet(
    context: context,
    titre: titre,
    valeurInitiale: valeurInitiale,
    valider: valider,
    aide: aide,
    avecModePaiement: avecModePaiement,
  );
  if (saisie == null || !context.mounted) return;
  await _executer(context, () => action(saisie), succes);
}

/// Exécute une action et rend compte, succès comme échec.
Future<void> _executer(
  BuildContext context,
  Future<void> Function() action,
  String succes,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(
      SnackBar(content: Text(succes), backgroundColor: AppColors.primary),
    );
  } catch (erreur) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(humanSyncError(erreur)),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

/// Demander un montant, à la manière de `showChoiceSheet` : la feuille possède
/// son champ et son contrôleur, et les libère elle-même.
///
/// C'est le détail qui a fait l'écran rouge du 31/08. Le contrôleur était créé
/// ici puis `dispose()` juste après l'`await` — sauf que la feuille est encore
/// à l'écran pendant son animation de fermeture, avec un `TextField` branché
/// dessus. Un contrôleur libéré sous un champ vivant, et Flutter s'arrête sur
/// `_dependents.isEmpty`.
///
/// La règle, valable pour toute feuille du projet : **le contrôleur appartient
/// au `State` qui l'utilise**, et personne d'autre ne le libère.
class _Bouton extends StatelessWidget {
  const _Bouton({
    required this.icone,
    required this.libelle,
    required this.principal,
    required this.onPressed,
  });

  final IconData icone;
  final String libelle;
  final bool principal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: principal
          ? FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: onPressed,
              icon: Icon(icone),
              label: Text(
                libelle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icone),
              label: Text(libelle),
            ),
    );
  }
}

class _Historique extends StatelessWidget {
  const _Historique({required this.paiements});

  final List<LocalPaiementsCommande> paiements;

  static const _modes = {
    'especes': 'Espèces',
    'mtn_momo': 'MTN MoMo',
    'orange_money': 'Orange Money',
    'autre': 'Autre',
  };

  @override
  Widget build(BuildContext context) {
    if (paiements.isEmpty) {
      return Text(
        'Aucun versement pour le moment.',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    final tries = [...paiements]
      ..sort((a, b) => b.effectueAt.compareTo(a.effectueAt));
    final format = DateFormat('dd/MM/yyyy à HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VERSEMENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        for (final p in tries)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: Icon(
                p.typeMouvement == 'remboursement'
                    ? Icons.undo
                    : Icons.arrow_downward,
                color: p.typeMouvement == 'remboursement'
                    ? AppColors.error
                    : AppColors.primary,
              ),
              // « Encaissé » / « Remboursé » écrits en toutes lettres : une
              // pastille verte ou rouge se lit vite, mais se lit AUSSI de
              // travers — et il s'agit d'argent rendu ou reçu.
              title: Text(
                '${p.typeMouvement == 'remboursement' ? 'Remboursé' : 'Encaissé'} '
                '${CurrencyFormatter.format(p.montant.toDouble())}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: p.typeMouvement == 'remboursement'
                      ? AppColors.error
                      : AppColors.primaryDark,
                ),
              ),
              subtitle: Text(
                '${_modes[p.modePaiement] ?? p.modePaiement} · '
                '${format.format(p.effectueAt)}'
                '${p.note == null ? '' : '\n${p.note}'}',
              ),
              isThreeLine: p.note != null,
            ),
          ),
      ],
    );
  }
}
