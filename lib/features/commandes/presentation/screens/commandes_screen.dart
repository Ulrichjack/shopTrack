import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/montant_sheet.dart';
import '../providers/commandes_provider.dart';
import '../../../../shared/widgets/bouton_reglages.dart';

/// Les commandes en cours, la plus urgente en premier.
class CommandesScreen extends ConsumerWidget {
  const CommandesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dossiersAsync = ref.watch(dossiersCommandesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: const [BoutonReglages()],
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
          if (dossiers.isEmpty) return const _Vide();

          // Une commande finit quand elle est LIVRÉE, pas quand elle est payée.
          //
          // Le gâteau du 15 septembre peut être payé en entier aujourd'hui : il
          // reste à faire. L'inverse existe aussi — la cliente emporte sa
          // commande et doit encore 20 000 F. Ranger les commandes selon
          // l'argent répondait à « qui me doit quoi » et masquait « qu'est-ce
          // que je dois livrer », qui est le travail de la semaine.
          final enCours = dossiers
              .where((d) => !d.estLivree && !d.estAnnulee)
              .toList();
          // Les retards remontent en tête, puis les dates les plus proches.
          // Une liste rangée par date de commande enterrait le gâteau de
          // demain sous six demandes prises la semaine dernière.
          enCours.sort((a, b) {
            if (a.estEnRetard != b.estEnRetard) return a.estEnRetard ? -1 : 1;
            final da = a.dossier.datePrevue;
            final db = b.dossier.datePrevue;
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });
          final enRetard = enCours.where((d) => d.estEnRetard).toList();
          final livrees = dossiers.where((d) => d.estLivree).toList();
          final annulees = dossiers.where((d) => d.estAnnulee).toList();

          // Ce qui reste à faire, tout en haut — pour TOUT LE MONDE.
          //
          // Ce bandeau était réservé à la patronne, ce qui était absurde :
          // c'est la vendeuse qui est au comptoir, et c'est elle qui verra la
          // cliente revenir. Lui cacher qu'une commande attend son prix, c'est
          // lui cacher son propre travail.
          //
          // Une demande sans prix noyée dans la liste attendrait que le client
          // rappelle. En tête, avec son nombre, elle se voit en une seconde.
          final sansPrix = enCours
              .where((d) => d.dossier.montantAccepte == null)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              // Le retard passe AVANT le devis : une cliente qui attend sa
              // commande depuis trois jours est un problème plus urgent qu'un
              // prix à fixer.
              if (enRetard.isNotEmpty) ...[
                _BandeauRetard(dossiers: enRetard),
                const SizedBox(height: 12),
              ],
              if (sansPrix.isNotEmpty) ...[
                _ADevisier(nombre: sansPrix.length),
                const SizedBox(height: 16),
              ],
              // TOUTES les commandes, pas seulement celles à livrer.
              //
              // Le total ne prenait que `enCours` : une commande livrée dont la
              // cliente devait encore 150 000 F sortait du compte, et l'écran
              // annonçait « reste à encaisser : 0 » avec 150 000 F dehors.
              // Livrer n'efface pas une dette — c'est même là que la dette
              // devient gênante, la marchandise est partie.
              _Total(dossiers: dossiers.where((d) => !d.estAnnulee).toList()),
              const SizedBox(height: 12),
              const _CompteMobileMoney(),
              const SizedBox(height: 16),
              // Deux sections nommées plutôt qu'une liste nue suivie d'un
              // titre : sans en-tête sur la première, on ne sait pas ce qu'on
              // regarde tant qu'on n'a pas fait défiler jusqu'au second titre.
              if (enCours.isNotEmpty) ...[
                const _TitreSection('À LIVRER'),
                const SizedBox(height: 10),
                for (final d in enCours) ...[
                  _LigneDossier(dossier: d),
                  const SizedBox(height: 10),
                ],
              ],
              if (livrees.isNotEmpty) ...[
                const SizedBox(height: 12),
                _TitreSection(
                  livrees.where((d) => d.dossier.coutMatiere == null).isEmpty
                      ? 'LIVRÉES'
                      : 'LIVRÉES — '
                            '${livrees.where((d) => d.dossier.coutMatiere == null).length} '
                            'sans coût',
                ),
                const SizedBox(height: 10),
                for (final d in livrees) ...[
                  _LigneDossier(dossier: d),
                  const SizedBox(height: 10),
                ],
              ],
              // Gardées et visibles, pas effacées : une commande annulée peut
              // porter un acompte encore dû à la cliente.
              if (annulees.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _TitreSection('ANNULÉES'),
                const SizedBox(height: 10),
                for (final d in annulees) ...[
                  _LigneDossier(dossier: d),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/commande-nouvelle'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle commande',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Ce qu'il reste à encaisser, en haut et en gros.
///
/// C'est la seule question que se pose la propriétaire en ouvrant cet écran :
/// combien d'argent l'attend encore. Le total des commandes, lui, ne veut rien
/// dire — il mélange ce qui est déjà payé et ce qui ne l'est pas.
class _Total extends StatelessWidget {
  const _Total({required this.dossiers});

  final List<DossierAvecSolde> dossiers;

  @override
  Widget build(BuildContext context) {
    // Seuls les soldes POSITIFS : une commande soldée vaut zéro et n'a rien à
    // retrancher au total.
    final reste = dossiers
        .where((d) => (d.solde ?? 0) > 0)
        .fold<int>(0, (somme, d) => somme + d.solde!);
    final nombreDebiteurs = dossiers.where((d) => (d.solde ?? 0) > 0).length;
    final encaisse = dossiers.fold<int>(0, (somme, d) => somme + d.netEncaisse);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RESTE À ENCAISSER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(reste.toDouble()),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              nombreDebiteurs == 0
                  ? 'Tout est encaissé · '
                        '${CurrencyFormatter.format(encaisse.toDouble())} reçus'
                  : '$nombreDebiteurs cliente(s) doivent encore · '
                        '${CurrencyFormatter.format(encaisse.toDouble())} déjà reçus',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'argent qui dort sur le téléphone, et le bouton pour le rapatrier.
///
/// Le Mobile Money est un second tiroir. Il se remplit quand une cliente paie
/// par Orange Money, et il se vide quand la vendeuse va retirer chez l'agent —
/// c'est à CE moment que les billets entrent dans la caisse, pas avant.
///
/// Compter le Mobile Money dans la caisse dès l'encaissement ferait apparaître
/// un manquant du même montant à chaque comptage du soir, sur le nom de celle
/// qui compte. Ici l'argent est visible, nommé, et rapatriable en deux gestes.
class _CompteMobileMoney extends ConsumerWidget {
  const _CompteMobileMoney();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hors = ref.watch(soldeMobileMoneyProvider).value;
    final solde = hors?.total ?? 0;
    if (hors == null || solde <= 0) return const SizedBox.shrink();

    // Lu avant d'ouvrir la feuille, jamais dedans (piège #33 et son voisin).
    final notifier = ref.read(commandesNotifierProvider);

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.warning,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _retirer(context, notifier, solde),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.phone_android, color: AppColors.warningDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PAS ENCORE DANS LA CAISSE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(solde.toDouble()),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Le détail par moyen : « 30 000 F hors caisse » ne dit pas
                    // où aller les chercher. Orange Money se retire chez un
                    // agent, un virement s'attend à la banque.
                    Text(
                      hors.parMode.entries
                          .map(
                            (e) =>
                                '${_libellesModes[e.key] ?? e.key} '
                                '${CurrencyFormatter.format(e.value.toDouble())}',
                          )
                          .join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warningDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Touche quand tu l\'as retiré et mis dans le tiroir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warningDark,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.warningDark),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _retirer(
    BuildContext context,
    CommandesNotifier notifier,
    int solde,
  ) async {
    final saisie = await showMontantSheet(
      context: context,
      titre: 'Rentré en caisse',
      valeurInitiale: solde,
      aide:
          'Ce que tu viens de mettre dans le tiroir. Au maximum '
          '${CurrencyFormatter.format(solde.toDouble())}.',
      valider: (montant) => montant > solde
          ? 'Pas plus de ${CurrencyFormatter.format(solde.toDouble())}.'
          : null,
    );
    if (saisie == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await notifier.transfererMobileMoney(montant: saisie.montant);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Enregistré. La caisse a été augmentée.'),
          backgroundColor: AppColors.primary,
        ),
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
}

const _libellesModes = {
  'mtn_momo': 'MTN MoMo',
  'orange_money': 'Orange Money',
  'autre': 'Autre',
};

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// « 2 commandes sont en retard », avec les noms.
///
/// Le nombre seul ferait ouvrir la liste pour savoir qui ; les noms permettent
/// d'appeler la cliente sans toucher à rien d'autre.
class _BandeauRetard extends StatelessWidget {
  const _BandeauRetard({required this.dossiers});

  final List<DossierAvecSolde> dossiers;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dossiers.length == 1
                      ? 'Une commande est en retard.'
                      : '${dossiers.length} commandes sont en retard.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final d in dossiers.take(3))
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: Text(
                '${d.client?.nom ?? 'Client'} · promise le '
                '${format.format(d.dossier.datePrevue!)}',
                style: const TextStyle(fontSize: 12.5, height: 1.3),
              ),
            ),
          if (dossiers.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: Text(
                'et ${dossiers.length - 3} autre(s)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
        ],
      ),
    );
  }
}

class _ADevisier extends StatelessWidget {
  const _ADevisier({required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nombre == 1
                  ? 'Une demande attend son prix.'
                  : '$nombre demandes attendent leur prix.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneDossier extends StatelessWidget {
  const _LigneDossier({required this.dossier});

  final DossierAvecSolde dossier;

  static const _libelles = {
    'gateau': 'Gâteau',
    'objet_decoratif': 'Objet décoratif',
    'formation': 'Formation',
    'decoration_evenementielle': 'Décoration',
  };

  @override
  Widget build(BuildContext context) {
    final d = dossier.dossier;
    final solde = dossier.solde;
    final format = DateFormat('dd/MM');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push('/commande-detail', extra: d.id),
        title: Text(
          dossier.client?.nom ?? 'Client',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: dossier.estAnnulee ? TextDecoration.lineThrough : null,
            color: dossier.estAnnulee ? Colors.grey.shade600 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${_libelles[d.categorie] ?? d.categorie} · ${d.description}'),
            if (d.datePrevue != null && !dossier.estAnnulee)
              Text(
                'Pour le ${format.format(d.datePrevue!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (dossier.estAnnulee && d.motifAnnulation != null)
              Text(
                'Annulée — ${d.motifAnnulation}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // « Prix à fixer » plutôt qu'un zéro : un montant nul se lirait
            // comme une commande gratuite, alors que c'est une demande qui
            // attend la propriétaire.
            if (solde == null)
              Text(
                'Prix à fixer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              )
            else if (solde <= 0)
              const Icon(Icons.check_circle, color: AppColors.primary)
            else
              Text(
                CurrencyFormatter.format(solde.toDouble()),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            if (solde != null && solde > 0 && dossier.netEncaisse > 0)
              Text(
                'sur ${CurrencyFormatter.format(d.montantAccepte!.toDouble())}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande pour le moment.\n\n'
              'Enregistre une demande quand un client commande un gâteau, '
              'un objet sur mesure, une formation ou une décoration.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
