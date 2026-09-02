import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

/// Ce qu'une feuille de montant renvoie : la somme, et par quel moyen.
///
/// Le moyen voyage avec la somme parce que les deux se décident dans le même
/// geste. Les séparer obligeait l'appelant à lire une variable modifiée par
/// une closure — le genre d'attelage qui finit par renvoyer le mode d'avant.
typedef SaisieMontant = ({int montant, String mode});

/// Demander un montant par le bas de l'écran, avec ou sans moyen de paiement.
///
/// Même forme que [showChoiceSheet] — et pour la même raison. La feuille
/// possède son champ et son contrôleur, et les libère elle-même dans
/// `dispose()`.
///
/// C'est ce détail qui a fait l'écran rouge du 31/08. Le contrôleur était créé
/// par l'appelant, puis `dispose()` juste après l'`await` — sauf que la feuille
/// est encore à l'écran pendant son animation de fermeture, avec un `TextField`
/// branché dessus. Un contrôleur libéré sous un champ vivant, et Flutter
/// s'arrête sur `_dependents.isEmpty`.
///
/// **Le contrôleur appartient au `State` qui l'utilise, et personne d'autre ne
/// le libère.** Cette feuille existe pour que la règle n'ait plus à être
/// réapprise à chaque écran : passe par elle plutôt que d'en réécrire une.
///
/// [valider] rend `null` si le montant est acceptable, sinon le message à
/// afficher sous le champ. C'est là que se posent les plafonds — l'écran ne
/// doit jamais laisser partir un montant que le serveur refusera.
Future<SaisieMontant?> showMontantSheet({
  required BuildContext context,
  required String titre,
  int? valeurInitiale,
  required String? Function(int montant) valider,
  String? aide,
  bool avecModePaiement = false,
}) {
  return showModalBottomSheet<SaisieMontant>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      // Le clavier recouvrirait le champ sans ce décalage.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _CorpsMontant(
        titre: titre,
        valeurInitiale: valeurInitiale,
        valider: valider,
        aide: aide,
        avecModePaiement: avecModePaiement,
      ),
    ),
  );
}

class _CorpsMontant extends StatefulWidget {
  const _CorpsMontant({
    required this.titre,
    required this.valeurInitiale,
    required this.valider,
    required this.aide,
    required this.avecModePaiement,
  });

  final String titre;
  final int? valeurInitiale;
  final String? Function(int montant) valider;
  final String? aide;
  final bool avecModePaiement;

  @override
  State<_CorpsMontant> createState() => _CorpsMontantState();
}

class _CorpsMontantState extends State<_CorpsMontant> {
  late final TextEditingController _controleur = TextEditingController(
    text: widget.valeurInitiale?.toString() ?? '',
  );
  String? _erreur;
  String _mode = 'especes';

  // Trois moyens, pas quatre.
  //
  // « Autre » a été retiré le 01/09 sur la demande de la cliente : dans cette
  // boutique on paie en espèces, par Orange Money ou par MTN, et rien d'autre.
  // Un quatrième choix vague aurait surtout servi à ranger là ce qu'on ne sait
  // pas nommer — et personne n'aurait su, six mois plus tard, où était cet
  // argent ni comment le rapatrier.
  //
  // La contrainte serveur accepte toujours `autre` : les lignes anciennes
  // restent lisibles, on cesse seulement d'en créer.
  static const _modes = {
    'especes': 'Espèces',
    'orange_money': 'Orange Money',
    'mtn_momo': 'MTN MoMo',
  };

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _valider() {
    final montant = int.tryParse(_controleur.text.trim());
    if (montant == null || montant <= 0) {
      setState(() => _erreur = 'Entre un montant.');
      return;
    }
    final probleme = widget.valider(montant);
    if (probleme != null) {
      setState(() => _erreur = probleme);
      return;
    }
    Navigator.of(context).pop((montant: montant, mode: _mode));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.titre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controleur,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Montant (FCFA)',
              helperText: widget.aide,
              helperMaxLines: 2,
              errorText: _erreur,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _valider(),
          ),
          if (widget.avecModePaiement) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'COMMENT ?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes.entries.map((entree) {
                final actif = entree.key == _mode;
                return ChoiceChip(
                  selected: actif,
                  onSelected: (_) => setState(() => _mode = entree.key),
                  label: Text(entree.value),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: actif ? Colors.white : AppColors.textPrimary,
                    fontWeight: actif ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            // Compter du Mobile Money comme des espèces créerait un manquant du
            // même montant à la clôture — et l'application accuserait quelqu'un.
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Seules les espèces entrent dans le tiroir.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _valider,
              child: const Text(
                'Valider',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
