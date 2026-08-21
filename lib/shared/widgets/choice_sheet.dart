import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Choisir dans une liste : une recherche et des lignes, ouvertes par le bas.
///
/// Remplace `DropdownButton`, qui devient inutilisable passé une dizaine
/// d'entrées — il faut faire défiler à l'aveugle une liste qui déborde de
/// l'écran, sans pouvoir chercher. Ici on tape les premières lettres.
///
/// Renvoie l'élément choisi, ou `null` si la feuille est fermée sans choisir.
Future<T?> showChoiceSheet<T>({
  required BuildContext context,
  required String titre,
  required List<T> elements,
  required String Function(T) libelle,
  String Function(T)? sousLibelle,
  T? selection,
  String indice = 'Rechercher',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      // Le clavier remonte la feuille, sinon il recouvre la liste filtrée.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _ChoiceSheetBody<T>(
          titre: titre,
          elements: elements,
          libelle: libelle,
          sousLibelle: sousLibelle,
          selection: selection,
          indice: indice,
        ),
      ),
    ),
  );
}

class _ChoiceSheetBody<T> extends StatefulWidget {
  const _ChoiceSheetBody({
    required this.titre,
    required this.elements,
    required this.libelle,
    required this.indice,
    this.sousLibelle,
    this.selection,
  });

  final String titre;
  final List<T> elements;
  final String Function(T) libelle;
  final String Function(T)? sousLibelle;
  final T? selection;
  final String indice;

  @override
  State<_ChoiceSheetBody<T>> createState() => _ChoiceSheetBodyState<T>();
}

class _ChoiceSheetBodyState<T> extends State<_ChoiceSheetBody<T>> {
  final _controleur = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibles = widget.elements
        .where(
          (e) =>
              _recherche.isEmpty ||
              widget.libelle(e).toLowerCase().contains(_recherche),
        )
        .toList();

    // La recherche ne s'affiche que si elle sert : sous une dizaine d'entrées,
    // un champ de plus n'est que du bruit et vole une ligne à la liste.
    final avecRecherche = widget.elements.length > 8;

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.titre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        if (avecRecherche)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _controleur,
              autofocus: true,
              onChanged: (v) =>
                  setState(() => _recherche = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: widget.indice,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _recherche.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controleur.clear();
                          setState(() => _recherche = '');
                        },
                      ),
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: visibles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Rien ne correspond à cette recherche.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: visibles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final element = visibles[i];
                    final choisi = element == widget.selection;
                    return ListTile(
                      title: Text(
                        widget.libelle(element),
                        style: TextStyle(
                          fontWeight: choisi
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: widget.sousLibelle == null
                          ? null
                          : Text(widget.sousLibelle!(element)),
                      trailing: choisi
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(element),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
