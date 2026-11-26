import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_theme.dart';

/// Réglages d'activation des modules d'une boutique, côté web.
///
/// Mêmes valeurs par défaut que `ShopSettings` sur Android : absence de ligne
/// `shop_settings` = comportement actuel de l'app, mode simple.
class WebShopSettings {
  const WebShopSettings({
    this.unitMode = 'simple',
    this.saleCaptureMode = 'realtime',
    this.multiPointEnabled = false,
    this.commandesEnabled = false,
  });

  final String unitMode;
  final String saleCaptureMode;
  final bool multiPointEnabled;
  final bool commandesEnabled;

  bool get venteParUnites => unitMode == 'hierarchical';
  bool get inventairePeriodique => saleCaptureMode == 'periodic';

  WebShopSettings avec({
    bool? venteParUnites,
    bool? inventairePeriodique,
    bool? commandes,
  }) => WebShopSettings(
    unitMode: venteParUnites == null
        ? unitMode
        : (venteParUnites ? 'hierarchical' : 'simple'),
    saleCaptureMode: inventairePeriodique == null
        ? saleCaptureMode
        : (inventairePeriodique ? 'periodic' : 'realtime'),
    multiPointEnabled: multiPointEnabled,
    commandesEnabled: commandes ?? commandesEnabled,
  );
}

/// Inventaire périodique et commandes avec acompte s'excluent, dans les deux
/// sens. Un acompte en espèces écrit une ligne de caisse ; en périodique il
/// n'y a pas de caisse calculée, et cette ligne n'aurait aucun écran où
/// apparaître. L'argent serait encaissé et invisible — pire que de ne pas
/// pouvoir l'encaisser.
bool combinaisonImpossible(WebShopSettings reglages) =>
    reglages.inventairePeriodique && reglages.commandesEnabled;

/// Lit **les quatre** réglages.
///
/// Les quatre, et pas seulement ceux dont l'écran se sert : l'enregistrement
/// est un upsert, et une colonne absente du message reprend sa valeur par
/// défaut côté serveur. Lire trois colonnes puis en réécrire quatre revient à
/// remettre la quatrième à zéro — silencieusement, et sur une boutique qui
/// n'avait rien demandé. Le provider Android porte le même avertissement.
Future<WebShopSettings> chargerReglagesWeb(
  SupabaseClient client,
  String shopId,
) async {
  final ligne = await client
      .from('shop_settings')
      .select('unit_mode, sale_capture_mode, multi_point_enabled, commandes_enabled')
      .eq('shop_id', shopId)
      .maybeSingle();
  if (ligne == null) return const WebShopSettings();
  return WebShopSettings(
    unitMode: (ligne['unit_mode'] as String?) ?? 'simple',
    saleCaptureMode: (ligne['sale_capture_mode'] as String?) ?? 'realtime',
    multiPointEnabled: (ligne['multi_point_enabled'] as bool?) ?? false,
    commandesEnabled: (ligne['commandes_enabled'] as bool?) ?? false,
  );
}

/// Écrit **les quatre** réglages ensemble. Voir `chargerReglagesWeb`.
///
/// La combinaison impossible est refusée ici, pas seulement dans l'interface :
/// un interrupteur grisé ne protège rien, c'est l'écriture qui doit tenir.
Future<void> enregistrerReglagesWeb(
  SupabaseClient client, {
  required String shopId,
  required WebShopSettings reglages,
}) async {
  if (combinaisonImpossible(reglages)) {
    throw ArgumentError(
      'Inventaire périodique et commandes avec acompte ne peuvent pas être '
      'actifs en même temps.',
    );
  }
  await client.from('shop_settings').upsert({
    'shop_id': shopId,
    'unit_mode': reglages.unitMode,
    'sale_capture_mode': reglages.saleCaptureMode,
    'multi_point_enabled': reglages.multiPointEnabled,
    'commandes_enabled': reglages.commandesEnabled,
  }, onConflict: 'shop_id');
}

/// Formulaire des réglages, réservé au propriétaire.
///
/// Renvoie `true` à la fermeture si un réglage a changé, pour que l'appelant
/// recharge la boutique : changer de mode change les onglets.
class WebShopSettingsForm extends StatefulWidget {
  const WebShopSettingsForm({
    super.key,
    required this.shopId,
    required this.nomBoutique,
  });

  final String shopId;
  final String nomBoutique;

  @override
  State<WebShopSettingsForm> createState() => _WebShopSettingsFormState();
}

class _WebShopSettingsFormState extends State<WebShopSettingsForm> {
  final _client = Supabase.instance.client;
  WebShopSettings? _reglages;
  bool _charge = true;
  bool _enregistre = false;
  bool _modifie = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final reglages = await chargerReglagesWeb(_client, widget.shopId);
      if (mounted) {
        setState(() {
          _reglages = reglages;
          _charge = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _charge = false;
          _erreur = 'Réglages non lus. Vérifie ta connexion Internet.';
        });
      }
    }
  }

  Future<void> _appliquer(WebShopSettings demande) async {
    if (_enregistre) return;
    setState(() {
      _enregistre = true;
      _erreur = null;
    });
    try {
      await enregistrerReglagesWeb(
        _client,
        shopId: widget.shopId,
        reglages: demande,
      );
      if (mounted) {
        setState(() {
          _reglages = demande;
          _modifie = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erreur = e is ArgumentError
            ? '${e.message}'
            : 'Réglage non enregistré. Il reste tel qu\'il était.');
      }
    } finally {
      if (mounted) setState(() => _enregistre = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reglages = _reglages;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Réglages de la boutique',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(_modifie),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.nomBoutique} — les réglages ci-dessous ne touchent qu\'elle.',
            style: const TextStyle(color: WebPalette.muted),
          ),
          const SizedBox(height: 18),
          if (_charge) const LinearProgressIndicator(),
          if (_erreur != null) ...[
            Text(_erreur!, style: const TextStyle(color: WebPalette.danger)),
            const SizedBox(height: 12),
          ],
          if (reglages != null)
            WebShopSettingsBody(
              reglages: reglages,
              enCoursEnregistrement: _enregistre,
              onChanged: _appliquer,
            ),
        ],
      ),
    );
  }
}

/// Les trois interrupteurs, sans la lecture réseau ni l'état de chargement.
///
/// Séparé de l'écran pour être rendable dans un test : l'affichage
/// conditionnel — « vente par unités » cachée quand elle est inactive, les
/// deux modes qui se grisent l'un l'autre — est la partie qui peut se tromper,
/// et elle n'avait aucun moyen d'être vérifiée tant qu'elle vivait derrière un
/// appel à Supabase.
class WebShopSettingsBody extends StatelessWidget {
  const WebShopSettingsBody({
    super.key,
    required this.reglages,
    required this.onChanged,
    this.enCoursEnregistrement = false,
  });

  final WebShopSettings reglages;
  final ValueChanged<WebShopSettings> onChanged;
  final bool enCoursEnregistrement;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Affiché seulement si déjà actif, comme sur Android : le module est
      // masqué pour les nouvelles boutiques. On peut donc l'éteindre depuis le
      // web, pas l'allumer.
      if (reglages.venteParUnites)
        _interrupteur(
          titre: 'Vente par unités',
          detail:
              'Vendre au plateau, au carton, au casier… avec suivi du coût '
              'réel de chaque arrivage.',
          valeur: true,
          onChanged: (actif) => onChanged(reglages.avec(venteParUnites: actif)),
        ),
      _interrupteur(
        titre: 'Inventaire périodique',
        detail: reglages.commandesEnabled
            ? 'Indisponible : les commandes avec acompte sont activées, et '
                  'elles ont besoin d\'une caisse que ce mode ne tient pas.'
            : 'Ne plus saisir chaque vente : noter la recette du jour, compter '
                  'le stock de temps en temps, et laisser l\'app déduire ce qui '
                  'a été vendu.',
        valeur: reglages.inventairePeriodique,
        onChanged: reglages.commandesEnabled
            ? null
            : (actif) => onChanged(reglages.avec(inventairePeriodique: actif)),
      ),
      _interrupteur(
        titre: 'Commandes avec acompte',
        detail: reglages.inventairePeriodique
            ? 'Indisponible en inventaire périodique : un acompte entre dans le '
                  'tiroir, et ce mode ne tient pas de caisse — l\'argent '
                  'encaissé n\'apparaîtrait nulle part.'
            : 'Prendre une commande, encaisser une avance, suivre ce qui reste '
                  'dû : gâteaux, objets sur mesure, formations, décoration.',
        valeur: reglages.commandesEnabled,
        onChanged: reglages.inventairePeriodique
            ? null
            : (actif) => onChanged(reglages.avec(commandes: actif)),
      ),
      const SizedBox(height: 14),
      const Text(
        'Un changement de mode s\'applique aussi au téléphone après sa '
        'prochaine synchronisation. Les ventes et recettes déjà enregistrées '
        'restent dans l\'historique.',
        style: TextStyle(color: WebPalette.muted, fontSize: 13),
      ),
    ],
  );

  Widget _interrupteur({
    required String titre,
    required String detail,
    required bool valeur,
    required ValueChanged<bool>? onChanged,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: SwitchListTile(
      value: valeur,
      onChanged: enCoursEnregistrement ? null : onChanged,
      title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(detail),
      isThreeLine: true,
    ),
  );
}
