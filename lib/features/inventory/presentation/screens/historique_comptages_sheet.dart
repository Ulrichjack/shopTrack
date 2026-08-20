import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/inventory_count_provider.dart';

/// Les repères posés, du plus récent au plus ancien.
///
/// Une période d'inventaire va d'un comptage au suivant — mais rien nulle part
/// ne montrait ces repères. Le commerçant ne pouvait ni savoir quand il avait
/// compté la dernière fois, ni voir à quel rythme il compte. Cette liste
/// répond aux deux d'un coup d'œil.
Future<void> showHistoriqueComptagesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _HistoriqueComptages(),
  );
}

class _HistoriqueComptages extends ConsumerWidget {
  const _HistoriqueComptages();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toursAsync = ref.watch(historiqueComptagesProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mes comptages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: toursAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Erreur : $e', textAlign: TextAlign.center),
                  ),
                ),
                data: (tours) {
                  if (tours.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun comptage pour le moment.\n'
                          'Le premier posera ton point de départ.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: tours.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tour = tours[index];
                      // Le plus récent est en tête : c'est celui qu'on vient
                      // vérifier.
                      final estDernier = index == 0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: estDernier
                              ? AppColors.primaryLight
                              : Colors.grey.shade200,
                          child: Icon(
                            Icons.flag_outlined,
                            color: estDernier
                                ? AppColors.primaryDark
                                : Colors.grey.shade600,
                          ),
                        ),
                        title: Text(
                          DateFormat('dd/MM/yyyy').format(tour.date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${tour.produitsComptes} produit(s) compté(s)'
                          // L'écart avec le tour précédent : c'est lui qui
                          // révèle le rythme réel, pas la date seule.
                          '${tour.joursDepuisPrecedent == null ? ' · premier repère' : ' · ${tour.joursDepuisPrecedent} jour(s) après le précédent'}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
