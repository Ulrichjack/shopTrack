import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_theme.dart';

/// Accès limité au propriétaire par la navigation et par les règles serveur.
class WebEmployeesPage extends StatefulWidget {
  const WebEmployeesPage({super.key, required this.shopId});
  final String shopId;

  @override
  State<WebEmployeesPage> createState() => _WebEmployeesPageState();
}

class _WebEmployeesPageState extends State<WebEmployeesPage> {
  List<Map<String, dynamic>> _membres = [];
  bool _charge = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void didUpdateWidget(covariant WebEmployeesPage ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.shopId != widget.shopId) _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _charge = true;
      _erreur = null;
    });
    try {
      final membres = await Supabase.instance.client
          .from('shop_members')
          .select('user_id,role')
          .eq('shop_id', widget.shopId)
          .order('role');
      if (mounted) setState(() => _membres = membres);
    } catch (_) {
      if (mounted) setState(() => _erreur = 'Employés indisponibles. Réessaie.');
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _ajouter() async {
    final numero = TextEditingController();
    final motDePasse = TextEditingController();
    String? erreur;
    bool enCours = false;
    final resultat = await showDialog<String>(
      context: context,
      builder: (dialogue) => StatefulBuilder(
        builder: (context, changer) => AlertDialog(
          title: const Text('Nouveau vendeur'),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Un compte par vendeur. Le mot de passe est provisoire.'),
              const SizedBox(height: 14),
              TextField(
                controller: numero,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Numéro'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motDePasse,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe provisoire',
                  helperText: '6 caractères minimum',
                ),
              ),
              if (erreur != null) ...[
                const SizedBox(height: 10),
                Text(erreur!, style: const TextStyle(color: WebPalette.danger)),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: enCours ? null : () => Navigator.pop(dialogue),
              child: const Text('Annuler')),
            FilledButton(
              onPressed: enCours ? null : () async {
                final n = numero.text.trim();
                final m = motDePasse.text.trim();
                if (n.isEmpty || m.length < 6) {
                  changer(() => erreur = 'Numéro et mot de passe de 6 caractères requis.');
                  return;
                }
                changer(() {
                  enCours = true;
                  erreur = null;
                });
                try {
                  final reponse = await Supabase.instance.client.functions.invoke(
                    'creer-vendeur', body: {
                      'telephone': n, 'motDePasse': m, 'shopId': widget.shopId,
                    });
                  final corps = reponse.data;
                  if (corps is! Map || corps['rattache'] != true) {
                    throw StateError(corps is Map && corps['erreur'] != null
                        ? '${corps['erreur']}' : 'Création non confirmée.');
                  }
                  if (dialogue.mounted) Navigator.pop(dialogue,
                      corps['compteExistant'] == true
                          ? 'Compte existant rattaché à la boutique.'
                          : 'Vendeur créé. Il devra changer son mot de passe.');
                } catch (e) {
                  if (dialogue.mounted) changer(() => erreur = e is StateError
                      ? e.message : 'Création non confirmée. Vérifie Internet.');
                } finally {
                  if (dialogue.mounted) changer(() => enCours = false);
                }
              },
              child: Text(enCours ? 'Création…' : 'Créer'),
            ),
          ],
        ),
      ),
    );
    numero.dispose();
    motDePasse.dispose();
    if (resultat != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultat)));
      await _charger();
    }
  }

  Future<void> _retirer(String userId) async {
    final confirme = await showDialog<bool>(context: context,
      builder: (dialogue) => AlertDialog(
        title: const Text('Retirer cet employé ?'),
        content: const Text('Il perdra l’accès à cette boutique. Son historique reste conservé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogue, false),
              child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialogue, true),
              child: const Text('Retirer')),
        ],
      ));
    if (confirme != true) return;
    try {
      await Supabase.instance.client.from('shop_members').delete()
          .eq('shop_id', widget.shopId).eq('user_id', userId);
      await _charger();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Retrait non confirmé. Actualise la liste.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 25, 20, 35),
    children: [
      const Text('ACCÈS À LA BOUTIQUE', style: TextStyle(
        color: WebPalette.pine, fontSize: 11,
        letterSpacing: 1.5, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Employés', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      const Text('Chaque vendeur a son compte et ne voit que les boutiques autorisées.'),
      const SizedBox(height: 20),
      Wrap(spacing: 10, children: [
        FilledButton.icon(onPressed: _ajouter,
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Ajouter un vendeur')),
        IconButton(onPressed: _charger, tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh)),
      ]),
      if (_charge) const LinearProgressIndicator(),
      if (_erreur != null) Text(_erreur!,
          style: const TextStyle(color: WebPalette.danger)),
      const SizedBox(height: 18),
      for (final membre in _membres)
        Card(child: ListTile(
          leading: Icon(membre['role'] == 'owner'
              ? Icons.admin_panel_settings_outlined : Icons.person_outline),
          title: Text(membre['role'] == 'owner' ? 'Propriétaire' : 'Vendeur'),
          subtitle: Text(membre['user_id'] ==
              Supabase.instance.client.auth.currentUser?.id
              ? 'Toi' : 'Compte ${('${membre['user_id']}').substring(0, 8)}'),
          trailing: membre['role'] == 'owner' ? null : IconButton(
            tooltip: 'Retirer', icon: const Icon(Icons.person_remove_outlined),
            onPressed: () => _retirer(membre['user_id'] as String),
          ),
        )),
    ],
  );
}
