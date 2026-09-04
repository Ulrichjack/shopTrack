import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/providers/app_mode_provider.dart';
import '../providers/commandes_provider.dart';

/// Enregistrer une commande : qui, quoi, pour quand.
///
/// Le prix n'est demandé qu'à la propriétaire. La vendeuse, elle, note la
/// demande et rien de plus — c'est le partage voulu par la cliente, et le
/// serveur le fait respecter de son côté (une insertion par un membre exige
/// `montant_accepte is null`).
class CommandeNouvelleScreen extends ConsumerStatefulWidget {
  const CommandeNouvelleScreen({super.key});

  @override
  ConsumerState<CommandeNouvelleScreen> createState() =>
      _CommandeNouvelleScreenState();
}

class _CommandeNouvelleScreenState
    extends ConsumerState<CommandeNouvelleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _montantController = TextEditingController();

  String _categorie = 'gateau';
  DateTime? _datePrevue;
  bool _enCours = false;

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _descriptionController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final aujourdhui = DateTime.now();
    final choisie = await showDatePicker(
      context: context,
      initialDate: _datePrevue ?? aujourdhui,
      firstDate: DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day),
      lastDate: DateTime(aujourdhui.year + 2),
      helpText: 'Pour quel jour ?',
    );
    if (choisie == null) return;
    setState(() => _datePrevue = choisie);
  }

  Future<void> _enregistrer({required bool estPatron}) async {
    if (!_formKey.currentState!.validate()) return;

    // La condition qui GARDE le montant doit être exactement celle qui AFFICHE
    // le champ. Elles avaient divergé : le champ apparaissait à la vendeuse
    // pour un gâteau, elle tapait 150 000, et la valeur était jetée en
    // silence — la commande naissait « à deviser » sans un mot d'explication.
    //
    // Un champ qu'on montre est un champ qu'on utilise. S'il ne sert pas, il
    // ne s'affiche pas.
    final montantBrut = _montantController.text.trim();
    final montant = estPatron && montantBrut.isNotEmpty
        ? int.tryParse(montantBrut)
        : null;

    setState(() => _enCours = true);
    try {
      final dossierId = await ref
          .read(commandesNotifierProvider)
          .creerDemande(
            nomClient: _nomController.text,
            telephone: _telephoneController.text,
            categorie: _categorie,
            description: _descriptionController.text,
            datePrevue: _datePrevue,
            montantAccepte: montant,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            montant == null
                ? 'Demande enregistrée. Le prix reste à fixer.'
                : 'Commande enregistrée.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      // On enchaîne sur la fiche plutôt que de revenir à la liste.
      //
      // Le geste réel est d'un seul tenant : la cliente commande ET verse son
      // avance dans la même conversation. Revenir à la liste obligeait à
      // retrouver la ligne qu'on venait de créer pour y entrer — trois gestes
      // pour une chose qui n'en est qu'une.
      context.pushReplacement('/commande-detail', extra: dossierId);
    } catch (erreur) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanSyncError(erreur)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estPatron = ref.watch(appModeProvider).value ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nouvelle commande')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            // Le formulaire défile et réserve le bas : le clavier mange la
            // moitié de l'écran sur un petit téléphone, et le bouton
            // « Enregistrer » se retrouvait dessous.
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              const _Titre('LE CLIENT'),
              TextFormField(
                controller: _nomController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom du client *',
                  hintText: 'Mme Ngo Bikoi',
                  border: OutlineInputBorder(),
                ),
                validator: (valeur) => (valeur ?? '').trim().isEmpty
                    ? 'Sans le nom, tu ne sauras pas à qui rendre la commande.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '6XX XX XX XX',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              const _Titre('LA COMMANDE'),
              _ChoixCategorie(
                valeur: _categorie,
                onChanged: (v) => setState(() => _categorie = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ce que le client demande *',
                  hintText:
                      'Gâteau 3 étages, vanille, décor doré, pour 60 personnes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (valeur) => (valeur ?? '').trim().isEmpty
                    ? 'Écris ce qui est commandé, même en une ligne.'
                    : null,
              ),
              const SizedBox(height: 12),
              _ChoixDate(
                date: _datePrevue,
                onChoisir: _choisirDate,
                onEffacer: () => setState(() => _datePrevue = null),
              ),

              // Le prix à la création n'est ouvert QU'À LA PATRONNE, et ce
              // n'est pas un choix d'écran : la règle vient du serveur. La
              // politique d'insertion d'un membre exige
              // `montant_accepte is null` — une vendeuse qui enverrait un prix
              // ici verrait sa commande refusée des heures plus tard.
              //
              // Elle n'est pas bloquée pour autant : enregistrer ouvre
              // maintenant la fiche, où « Fixer le prix » est le premier
              // bouton. Deux gestes qui s'enchaînent au lieu d'un formulaire
              // qui ment.
              if (estPatron) ...[
                const SizedBox(height: 24),
                const _Titre('LE PRIX'),
                TextFormField(
                  controller: _montantController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _categorie == 'decoration_evenementielle'
                        ? 'Montant du devis (FCFA)'
                        : 'Prix convenu (FCFA)',
                    helperText:
                        'Laisse vide si le prix n\'est pas encore fixé.',
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: _enCours
                      ? null
                      : () => _enregistrer(estPatron: estPatron),
                  child: _enCours
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ChoixCategorie extends StatelessWidget {
  const _ChoixCategorie({required this.valeur, required this.onChanged});

  final String valeur;
  final ValueChanged<String> onChanged;

  static const _choix = {
    'gateau': ('Gâteau', Icons.cake_outlined),
    'objet_decoratif': ('Objet décoratif', Icons.chair_outlined),
    'formation': ('Formation', Icons.school_outlined),
    'decoration_evenementielle': ('Décoration', Icons.celebration_outlined),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _choix.entries.map((entree) {
        final (libelle, icone) = entree.value;
        final actif = entree.key == valeur;
        return ChoiceChip(
          selected: actif,
          onSelected: (_) => onChanged(entree.key),
          avatar: Icon(
            icone,
            size: 18,
            color: actif ? Colors.white : Colors.grey.shade700,
          ),
          label: Text(libelle),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: actif ? Colors.white : AppColors.textPrimary,
            fontWeight: actif ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

class _ChoixDate extends StatelessWidget {
  const _ChoixDate({
    required this.date,
    required this.onChoisir,
    required this.onEffacer,
  });

  final DateTime? date;
  final VoidCallback onChoisir;
  final VoidCallback onEffacer;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('EEEE d MMMM y', 'fr');
    return InkWell(
      onTap: onChoisir,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'À livrer le',
          border: const OutlineInputBorder(),
          suffixIcon: date == null
              ? const Icon(Icons.calendar_today_outlined)
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onEffacer,
                  tooltip: 'Retirer la date',
                ),
        ),
        child: Text(
          date == null ? 'Pas de date fixée' : format.format(date!),
          style: TextStyle(
            color: date == null ? Colors.grey.shade600 : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
