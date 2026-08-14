// lib/features/products/presentation/screens/add_product_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/shop_settings_provider.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController(text: '2');
  final _barcodeController = TextEditingController();
  final _unitController = TextEditingController();

  File? _imageFile;

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  Future<void> _scanBarcode() async {
    final String? scannedCode = await context.push<String>('/scanner');
    if (scannedCode != null) {
      setState(() {
        _barcodeController.text = scannedCode;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  // Helper pour les titres au-dessus des champs
  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // 👇 LE SECRET DU BEAU DESIGN EST ICI 👇
  // Helper pour styliser tous les champs de la même façon (Style WhatsApp/Moderne)
  InputDecoration _buildInputDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefixIcon,
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // Bordure normale (grise)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      // Bordure quand on clique dessus (verte)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      // Bordure en cas d'erreur (rouge)
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(productProvider).isLoading;
    // L'unité ne sert qu'en inventaire périodique (afficher « 12 sacs »).
    // Le mode simple n'en a pas besoin : un champ de plus à remplir pour
    // rien découragerait les boutiques qui n'utilisent aucun module.
    final settings = ref.watch(shopSettingsProvider).value;
    final isPeriodic = settings?.saleCaptureMode == 'periodic';
    // La quantité de départ n'a pas de sens dans les modules : en cycles
    // c'est l'arrivage qui alimente le stock, en inventaire c'est le
    // comptage. Un champ qu'on remplit pour rien induit en erreur.
    final stockGereParModule =
        isPeriodic || settings?.unitMode == 'hierarchical';

    return Scaffold(
      backgroundColor: AppColors.background, // Fond gris très clair
      appBar: AppBar(
        title: const Text('Nouveau produit'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                _buildFieldLabel("Nom de l'article"),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                    'Ex: Casque P47',
                    prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Le nom est obligatoire' : null,
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Prix achat (F)"),
                          TextFormField(
                            controller: _buyPriceController,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('Ex: 25000'),
                            validator: (value) => value == null || value.isEmpty ? 'Obligatoire' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Prix vente (F)"),
                          TextFormField(
                            controller: _sellPriceController,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('Ex: 50000'),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Obligatoire';
                              final sell = double.tryParse(value);
                              final buy = double.tryParse(_buyPriceController.text);
                              if (buy != null && sell != null && sell < buy) return 'Vente < Achat !';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    if (!stockGereParModule) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel("Quantité en stock"),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration('Ex: 3'),
                              validator: (value) => value == null || value.isEmpty ? 'Obligatoire' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Alerte stock bas"),
                          TextFormField(
                            controller: _minQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('Ex: 2'),
                            validator: (value) => value == null || value.isEmpty ? 'Obligatoire' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (isPeriodic) ...[
                  _buildFieldLabel("Unité (sac, bouteille, casier…)"),
                  TextFormField(
                    controller: _unitController,
                    decoration: _buildInputDecoration(
                      'Ex: sac — comment tu comptes ce produit',
                      prefixIcon: const Icon(
                        Icons.straighten,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // Réutiliser une unité déjà employée évite de la retaper et
                  // évite surtout les doublons (« carton » / « Carton »), qui
                  // rendraient l'affichage incohérent d'un produit à l'autre.
                  Builder(
                    builder: (context) {
                      final units = ref.watch(knownUnitsProvider);
                      if (units.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: units
                              .map(
                                (unit) => ActionChip(
                                  label: Text(unit),
                                  onPressed: () =>
                                      _unitController.text = unit,
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],

                _buildFieldLabel("Code-barres (Optionnel)"),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: _buildInputDecoration('Aucun code scanné'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: const Text('Scanner', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),

                _buildFieldLabel("Photo de l'article"),
                GestureDetector(
                  onTap: _imageFile == null ? _takePhoto : null,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: _imageFile != null
                        ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _imageFile = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.grey.shade400, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Prendre une photo du produit',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final String? code = _barcodeController.text.trim().isEmpty
                            ? null
                            : _barcodeController.text.trim();

                        await ref.read(productProvider.notifier).addProduct(
                          name: _nameController.text.trim(),
                          buyPrice: double.parse(_buyPriceController.text),
                          sellPrice: double.parse(_sellPriceController.text),
                          quantity: stockGereParModule
                              ? 0
                              : int.parse(_quantityController.text),
                          minQuantity: int.parse(_minQuantityController.text),
                          barcode: code,
                          unit: _unitController.text.trim().isEmpty
                              ? null
                              : _unitController.text.trim(),
                          imageFile: _imageFile,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Produit enregistré avec succès !'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          context.pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Enregistrer le produit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}