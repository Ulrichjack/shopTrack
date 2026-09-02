import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';

/// Ce qu'une correction de commande renvoie.
typedef CorrectionCommande = ({
  String nomClient,
  String description,
  String categorie,
  DateTime? datePrevue,
});

/// Corriger ce qui a été noté : la description, la catégorie, la date.
///
/// Même forme que les autres feuilles du projet — elle possède ses contrôleurs
/// et les libère dans son `dispose()`. Voir `montant_sheet.dart` et le piège
/// #33 pour ce qui arrive quand l'appelant s'en charge.
Future<CorrectionCommande?> showCorrectionSheet({
  required BuildContext context,
  required LocalDossiersCommande dossier,
  required String nomClient,
}) {
  return showModalBottomSheet<CorrectionCommande>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _CorpsCorrection(dossier: dossier, nomClient: nomClient),
    ),
  );
}

class _CorpsCorrection extends StatefulWidget {
  const _CorpsCorrection({required this.dossier, required this.nomClient});

  final LocalDossiersCommande dossier;
  final String nomClient;

  @override
  State<_CorpsCorrection> createState() => _CorpsCorrectionState();
}

class _CorpsCorrectionState extends State<_CorpsCorrection> {
  // Un nom mal entendu au téléphone est l'erreur la plus courante, et la plus
  // gênante : c'est ce qu'on lit dans la liste, dans le journal de caisse et
  // dans le bilan. Sans ce champ il fallait recréer la commande — en perdant
  // ses acomptes.
  late final TextEditingController _nom = TextEditingController(
    text: widget.nomClient,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.dossier.description,
  );
  late String _categorie = widget.dossier.categorie;
  late DateTime? _datePrevue = widget.dossier.datePrevue;
  String? _erreur;

  static const _choix = {
    'gateau': 'Gâteau',
    'objet_decoratif': 'Objet décoratif',
    'formation': 'Formation',
    'decoration_evenementielle': 'Décoration',
  };

  @override
  void dispose() {
    _nom.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final aujourdhui = DateTime.now();
    final choisie = await showDatePicker(
      context: context,
      initialDate: _datePrevue ?? aujourdhui,
      // Une date passée reste choisissable : une commande notée en retard
      // existe, et l'interdire obligerait à mentir sur le jour réel.
      firstDate: DateTime(aujourdhui.year - 1),
      lastDate: DateTime(aujourdhui.year + 2),
      helpText: 'Pour quel jour ?',
    );
    if (choisie == null) return;
    setState(() => _datePrevue = choisie);
  }

  void _valider() {
    if (_nom.text.trim().isEmpty) {
      setState(() => _erreur = 'Le nom du client est obligatoire.');
      return;
    }
    if (_description.text.trim().isEmpty) {
      setState(() => _erreur = 'Décris ce que le client demande.');
      return;
    }
    Navigator.of(context).pop((
      nomClient: _nom.text,
      description: _description.text,
      categorie: _categorie,
      datePrevue: _datePrevue,
    ));
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
              const Expanded(
                child: Text(
                  'Corriger la commande',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            controller: _nom,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nom du client',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _choix.entries.map((entree) {
              final actif = entree.key == _categorie;
              return ChoiceChip(
                selected: actif,
                onSelected: (_) => setState(() => _categorie = entree.key),
                label: Text(entree.value),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: actif ? Colors.white : AppColors.textPrimary,
                  fontWeight: actif ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _description,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Ce que le client demande',
              errorText: _erreur,
              errorMaxLines: 2,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _choisirDate,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'À livrer le',
                border: const OutlineInputBorder(),
                suffixIcon: _datePrevue == null
                    ? const Icon(Icons.calendar_today_outlined)
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Retirer la date',
                        onPressed: () => setState(() => _datePrevue = null),
                      ),
              ),
              child: Text(
                _datePrevue == null
                    ? 'Pas de date fixée'
                    : '${_datePrevue!.day.toString().padLeft(2, '0')}/'
                          '${_datePrevue!.month.toString().padLeft(2, '0')}/'
                          '${_datePrevue!.year}',
                style: TextStyle(
                  color: _datePrevue == null
                      ? Colors.grey.shade600
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _valider,
              child: const Text(
                'Enregistrer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Demander pourquoi une commande est annulée.
///
/// Le motif est obligatoire : une commande annulée sans raison ressemble, six
/// mois plus tard, à une commande escamotée. C'est la trace qui rend
/// l'annulation acceptable.
Future<String?> showMotifAnnulationSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const _CorpsMotif(),
    ),
  );
}

class _CorpsMotif extends StatefulWidget {
  const _CorpsMotif();

  @override
  State<_CorpsMotif> createState() => _CorpsMotifState();
}

class _CorpsMotifState extends State<_CorpsMotif> {
  final _controleur = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _valider() {
    if (_controleur.text.trim().isEmpty) {
      setState(() => _erreur = 'Dis pourquoi la commande est annulée.');
      return;
    }
    Navigator.of(context).pop(_controleur.text.trim());
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
          const SizedBox(height: 12),
          const Text(
            'Annuler la commande',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'La commande reste dans la liste, barrée, avec sa raison. Les '
            'acomptes déjà encaissés restent à rembourser.',
            style: TextStyle(fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controleur,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Pourquoi ?',
              hintText: 'La cliente a reporté son mariage',
              errorText: _erreur,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _valider(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: _valider,
              child: const Text(
                'Annuler la commande',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
