import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_theme.dart';

/// Dossier et historique des versements confirmés par Supabase.
class WebOrderDetail extends StatefulWidget {
  const WebOrderDetail({
    super.key,
    required this.shopId,
    required this.dossier,
    required this.nomClient,
    required this.estPatron,
  });

  final String shopId;
  final Map<String, dynamic> dossier;
  final String nomClient;
  final bool estPatron;

  @override
  State<WebOrderDetail> createState() => _WebOrderDetailState();
}

class _WebOrderDetailState extends State<WebOrderDetail> {
  late final Future<List<Map<String, dynamic>>> _paiements = Supabase
      .instance
      .client
      .from('paiements_commandes')
      .select('id,type_mouvement,montant,mode_paiement,effectue_at')
      .eq('shop_id', widget.shopId)
      .eq('dossier_id', widget.dossier['id'] as String)
      .order('effectue_at', ascending: false);

  String _montant(num? valeur) =>
      '${NumberFormat.decimalPattern('fr_FR').format(valeur?.round() ?? 0)} FCFA';

  @override
  Widget build(BuildContext context) {
    final dossier = widget.dossier;
    final statut = dossier['statut'] as String? ?? 'demande';
    final prix = dossier['montant_accepte'] as num?;
    final solde = dossier['solde'] as num?;
    final netEncaisse = dossier['montant_net_encaisse'] as num? ?? 0;
    final peutFixerPrix =
        widget.estPatron && statut != 'terminee' && statut != 'annulee';
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        18,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DOSSIER DE COMMANDE',
                  style: TextStyle(
                    color: WebPalette.pine,
                    fontSize: 11,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.nomClient,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            '$statut · ${dossier['categorie']}',
            style: const TextStyle(
              color: WebPalette.pine,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WebPalette.soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dossier['description'] as String? ?? 'Aucune description',
            ),
          ),
          if (dossier['date_prevue'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Prévue le ${DateFormat('dd/MM/yyyy').format(DateTime.parse(dossier['date_prevue'] as String).toLocal())}',
            ),
          ],
          const SizedBox(height: 20),
          _ligne('Prix convenu', prix == null ? 'À fixer' : _montant(prix)),
          _ligne(
            'Encaissé net',
            _montant(dossier['montant_net_encaisse'] as num?),
          ),
          if (statut == 'annulee')
            _ligne('À rembourser', _montant(netEncaisse > 0 ? netEncaisse : 0))
          else if (solde != null && solde < 0)
            _ligne('Trop-perçu', _montant(-solde))
          else
            _ligne(
              'Reste à payer',
              solde == null ? 'Après fixation du prix' : _montant(solde),
            ),
          const Divider(height: 30),
          const Text(
            'Historique des paiements',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _paiements,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return const Text('Historique indisponible. Vérifie Internet.');
              }
              final lignes = snapshot.data ?? const <Map<String, dynamic>>[];
              if (lignes.isEmpty) {
                return const Text('Aucun versement enregistré.');
              }
              return Column(
                children: [
                  for (final ligne in lignes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        ligne['type_mouvement'] == 'remboursement'
                            ? 'Remboursement'
                            : 'Paiement',
                      ),
                      subtitle: Text(
                        '${ligne['mode_paiement']} · ${DateFormat('dd/MM/yyyy').format(DateTime.parse(ligne['effectue_at'] as String).toLocal())}',
                      ),
                      trailing: Text(_montant(ligne['montant'] as num?)),
                    ),
                ],
              );
            },
          ),
          if (peutFixerPrix) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Fixer ou corriger le prix'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ligne(String libelle, String valeur) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(libelle, style: const TextStyle(color: WebPalette.muted)),
        ),
        Text(valeur, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
