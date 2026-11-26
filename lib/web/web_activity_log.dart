import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_cameroun_time.dart';
import 'web_theme.dart';

/// Historique d'audit du web : qui a fait quoi dans cette boutique.
///
/// L'écran Android lit la base locale Drift ; le web lit le serveur. Deux
/// différences en découlent, assumées :
///
/// - ne figure ici que ce qui a été synchronisé. Un geste fait hors ligne sur
///   un téléphone apparaît après sa remontée, pas avant ;
/// - chaque requête porte le `shop_id` actif. L'écran Android, lui, lit ses
///   tables locales **sans filtre de boutique** : sur un téléphone qui en
///   gère plusieurs, son journal les mélange.

/// Libellé d'un type de mouvement de caisse. Mêmes termes que l'Android : ce
/// journal sert à retrouver un geste, et deux vocabulaires pour le même geste
/// obligeraient à traduire de tête.
String libelleMouvementCaisse(String? type) => switch (type) {
  'morning_balance' => 'Initialisation de la caisse',
  'incoming' => 'Entrée de caisse',
  'withdrawal' => 'Sortie de caisse',
  'adjustment_in' => 'Ajustement positif de caisse',
  'adjustment_out' => 'Ajustement négatif de caisse',
  _ => 'Mouvement de caisse',
};

const _typesEntrants = {'morning_balance', 'incoming', 'adjustment_in'};

bool mouvementEntrant(String? type) => _typesEntrants.contains(type);

class WebActivityEntry {
  const WebActivityEntry({
    required this.date,
    required this.titre,
    required this.detail,
    required this.icone,
    this.auteur,
  });

  final DateTime date;
  final String titre;
  final String detail;
  final IconData icone;

  /// Déjà nommé (« la patronne »), ou nul quand la table ne porte pas d'auteur.
  final String? auteur;
}

/// Nom affichable d'un compte, à partir des rôles de la boutique.
///
/// Le rôle répond à la question qu'on se pose devant ce journal — « qui ? » —
/// et un identifiant technique n'y répond pas. Le repli ne sert que pour un
/// compte retiré de la boutique depuis.
String nommerAuteurWeb(String? userId, Map<String, String> roles) {
  if (userId == null) return 'auteur inconnu';
  final role = roles[userId];
  if (role == 'owner') return 'la patronne';
  if (role != null) return 'la vendeuse';
  return userId.length <= 8
      ? 'utilisateur $userId'
      : 'utilisateur ${userId.substring(0, 8)}';
}

int _entier(Object? valeur) => (valeur as num?)?.round() ?? 0;

String _fcfa(int montant) =>
    '${NumberFormat.decimalPattern('fr_FR').format(montant)} FCFA';

/// Construit les lignes du journal à partir des quatre sources déjà lues.
///
/// Séparé de la lecture réseau pour être testable : c'est la fusion et le tri
/// qui peuvent se tromper, pas la requête.
List<WebActivityEntry> fusionnerJournalAudit({
  required List<Map<String, dynamic>> ventes,
  required List<Map<String, dynamic>> mouvementsCaisse,
  required List<Map<String, dynamic>> mouvementsStock,
  required List<Map<String, dynamic>> clotures,
  required Map<String, String> roles,
  Map<String, String> nomsProduits = const {},
}) {
  final lignes = <WebActivityEntry>[];

  for (final vente in ventes) {
    final date = DateTime.tryParse('${vente['created_at']}');
    if (date == null) continue;
    lignes.add(
      WebActivityEntry(
        date: date,
        titre: 'Vente enregistrée',
        detail: _fcfa(_entier(vente['total_amount'])),
        auteur: nommerAuteurWeb(vente['user_id'] as String?, roles),
        icone: Icons.point_of_sale,
      ),
    );
  }

  for (final mouvement in mouvementsCaisse) {
    final date = DateTime.tryParse('${mouvement['created_at']}');
    if (date == null) continue;
    final type = mouvement['type'] as String?;
    final note = mouvement['note'] as String?;
    final signe = mouvementEntrant(type) ? '+' : '-';
    lignes.add(
      WebActivityEntry(
        date: date,
        titre: libelleMouvementCaisse(type),
        detail:
            '$signe${_fcfa(_entier(mouvement['amount']))}'
            '${note == null || note.isEmpty ? '' : ' — $note'}',
        auteur: nommerAuteurWeb(mouvement['user_id'] as String?, roles),
        icone: Icons.account_balance_wallet_outlined,
      ),
    );
  }

  for (final mouvement in mouvementsStock) {
    final date = DateTime.tryParse('${mouvement['created_at']}');
    if (date == null) continue;
    final produit = nomsProduits[mouvement['product_id'] as String?];
    final note = mouvement['note'] as String?;
    final nature = mouvement['type'] == 'recharge'
        ? 'Réapprovisionnement'
        : 'Correction de stock';
    lignes.add(
      WebActivityEntry(
        date: date,
        titre: 'Mouvement de stock',
        detail:
            '$nature : ${_entier(mouvement['quantity'])}'
            '${produit == null ? '' : ' — $produit'}'
            '${note == null || note.isEmpty ? '' : ' — $note'}',
        // `stock_movements` ne porte pas de colonne d'auteur côté serveur.
        // Afficher l'identifiant de la boutique à sa place, comme le fait
        // l'écran Android, invente un auteur : mieux vaut ne rien promettre.
        auteur: null,
        icone: Icons.inventory_2_outlined,
      ),
    );
  }

  for (final cloture in clotures) {
    // `closed_at` est l'instant du geste ; `closing_date` est la journée
    // concernée. Pour un journal chronologique c'est l'instant qui compte —
    // une journée rouverte puis reclôturée se range au moment de la reclôture.
    final date =
        DateTime.tryParse('${cloture['closed_at']}') ??
        DateTime.tryParse('${cloture['closing_date']}');
    if (date == null) continue;
    final note = cloture['note'] as String?;
    final ecart = cloture['cash_gap'];
    lignes.add(
      WebActivityEntry(
        date: date,
        titre: 'Clôture de caisse',
        detail:
            (ecart == null
                ? 'Sans comptage du tiroir'
                : 'Écart : ${_fcfa(_entier(ecart))}') +
            (note == null || note.isEmpty ? '' : ' — $note'),
        auteur: nommerAuteurWeb(cloture['user_id'] as String?, roles),
        icone: Icons.lock_clock_outlined,
      ),
    );
  }

  lignes.sort((a, b) => b.date.compareTo(a.date));
  return lignes;
}

/// Lit le journal depuis le serveur de test, pour la boutique active.
Future<List<WebActivityEntry>> chargerJournalAuditWeb(
  SupabaseClient client, {
  required String shopId,
  int limite = 150,
}) async {
  final membres = await client
      .from('shop_members')
      .select('user_id, role')
      .eq('shop_id', shopId);
  final roles = <String, String>{
    for (final membre in membres)
      membre['user_id'] as String: (membre['role'] as String?) ?? 'seller',
  };

  final ventes = await client
      .from('sales')
      .select('id,total_amount,user_id,created_at')
      .eq('shop_id', shopId)
      .order('created_at', ascending: false)
      .limit(limite);
  final caisse = await client
      .from('cash_movements')
      .select('id,type,amount,note,user_id,created_at')
      .eq('shop_id', shopId)
      .order('created_at', ascending: false)
      .limit(limite);
  final stock = await client
      .from('stock_movements')
      .select('id,product_id,quantity,type,note,created_at')
      .eq('shop_id', shopId)
      .order('created_at', ascending: false)
      .limit(limite);
  final clotures = await client
      .from('daily_closings')
      .select('id,closing_date,closed_at,cash_gap,note,user_id')
      .eq('shop_id', shopId)
      .eq('is_closed', true)
      .order('closing_date', ascending: false)
      .limit(limite);

  final identifiants = {
    for (final ligne in stock)
      if (ligne['product_id'] != null) ligne['product_id'] as String,
  };
  var noms = <String, String>{};
  if (identifiants.isNotEmpty) {
    final produits = await client
        .from('products')
        .select('id,name')
        .eq('shop_id', shopId)
        .inFilter('id', identifiants.toList());
    noms = {
      for (final produit in produits)
        produit['id'] as String: produit['name'] as String,
    };
  }

  final lignes = fusionnerJournalAudit(
    ventes: ventes,
    mouvementsCaisse: caisse,
    mouvementsStock: stock,
    clotures: clotures,
    roles: roles,
    nomsProduits: noms,
  );
  return lignes.length <= limite ? lignes : lignes.sublist(0, limite);
}

/// Écran du journal, réservé au propriétaire.
class WebActivityLogPage extends StatefulWidget {
  const WebActivityLogPage({super.key, required this.shopId});

  final String shopId;

  @override
  State<WebActivityLogPage> createState() => _WebActivityLogPageState();
}

class _WebActivityLogPageState extends State<WebActivityLogPage> {
  final _client = Supabase.instance.client;
  List<WebActivityEntry>? _lignes;
  bool _charge = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    try {
      final lignes = await chargerJournalAuditWeb(
        _client,
        shopId: widget.shopId,
      );
      if (mounted) {
        setState(() {
          _lignes = lignes;
          _charge = false;
        });
      }
    } catch (_) {
      // Pas de liste vide en cas de panne : un écran vide se lit « il n'y a
      // rien », pas « ça n'a pas pu être lu ». La leçon est consignée dans
      // `employees_provider.dart`.
      if (mounted) {
        setState(() {
          _charge = false;
          _erreur = 'Historique non lu. Vérifie ta connexion Internet.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lignes = _lignes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique d’audit',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ventes, caisse, stock et clôtures synchronisés avec le '
                      'serveur de test.',
                      style: TextStyle(color: WebPalette.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _charge ? null : _charger,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        if (_charge) const LinearProgressIndicator(),
        if (_erreur != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _erreur!,
              style: const TextStyle(color: WebPalette.danger),
            ),
          ),
        if (lignes != null && lignes.isEmpty && _erreur == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Aucune activité synchronisée pour cette boutique.'),
          ),
        if (lignes != null && lignes.isNotEmpty)
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: lignes.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ligne = lignes[index];
                final quand = DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(heureCameroun(ligne.date));
                return ListTile(
                  leading: CircleAvatar(child: Icon(ligne.icone, size: 20)),
                  title: Text(ligne.titre),
                  subtitle: Text(
                    '${ligne.detail}\n$quand'
                    '${ligne.auteur == null ? '' : ' • par ${ligne.auteur}'}',
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
      ],
    );
  }
}
