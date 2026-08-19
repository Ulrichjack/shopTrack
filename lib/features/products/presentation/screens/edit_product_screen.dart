import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../core/providers/shop_settings_provider.dart';
import '../providers/product_provider.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final ProductEntity product;

  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _buyPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _minQuantityController;
  late TextEditingController _barcodeController;
  late TextEditingController _unitController;

  File? _newImageFile;

  @override
  void initState() {
    super.initState();
    // On pré-remplit les champs avec les données actuelles du produit
    _nameController = TextEditingController(text: widget.product.name);
    _buyPriceController = TextEditingController(text: widget.product.buyPrice.toInt().toString());
    _sellPriceController = TextEditingController(text: widget.product.sellPrice.toInt().toString());
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _minQuantityController = TextEditingController(text: widget.product.minQuantity.toString());
    _barcodeController = TextEditingController(text: widget.product.barcode ?? '');
    _unitController = TextEditingController(text: widget.product.unit ?? '');
  }

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
        _newImageFile = File(photo.path);
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

  InputDecoration _buildInputDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 2)),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(productProvider).isLoading;
    final settings = ref.watch(shopSettingsProvider).value;
    final isPeriodic = settings?.saleCaptureMode == 'periodic';
    // Modifier la quantité à la main court-circuiterait le module qui la
    // gère (arrivage en cycles, comptage en inventaire) : le chiffre saisi
    // serait écrasé au prochain mouvement, sans que personne comprenne.
    final stockGereParModule =
        isPeriodic || settings?.unitMode == 'hierarchical';
    // Voir `add_product_screen` : le scan ne sert qu'à la vente au fil de l'eau.
    final venteAuScan = !stockGereParModule;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Modifier le produit'), elevation: 0),
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
                  decoration: _buildInputDecoration('Ex: Casque P47', prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Colors.grey)),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Obligatoire' : null,
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
                    ),
                  ),
                  // Mêmes raccourcis qu'à la création : c'est souvent ici
                  // qu'on vient corriger une unité mal tapée, autant proposer
                  // celles qui existent déjà plutôt que d'en créer une de plus.
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
                                  onPressed: () => _unitController.text = unit,
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],

                // Masqué en cycles et en inventaire, comme à la création : on
                // n'y scanne rien, on saisit un arrivage ou un comptage.
                //
                // Le contrôleur garde la valeur d'origine du produit : cacher
                // le champ ne l'efface pas. Une boutique qui reviendrait au
                // mode simple retrouverait ses codes-barres intacts.
                if (venteAuScan) ...[
                  _buildFieldLabel("Code-barres"),
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
                ],

                _buildFieldLabel("Photo de l'article"),
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: _newImageFile != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_newImageFile!, fit: BoxFit.cover))
                        : (widget.product.photoUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(widget.product.photoUrl!, fit: BoxFit.cover))
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.grey.shade400, size: 40),
                        const SizedBox(height: 8),
                        Text('Changer la photo', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    )),
                  ),
                ),
                const SizedBox(height: 40),

                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await ref.read(productProvider.notifier).updateProduct(
                          id: widget.product.id,
                          name: _nameController.text.trim(),
                          buyPrice: double.parse(_buyPriceController.text),
                          sellPrice: double.parse(_sellPriceController.text),
                          // Le stock reste celui géré par le module : on ne
                          // le réécrit pas depuis cet écran.
                          quantity: stockGereParModule
                              ? widget.product.quantity
                              : int.parse(_quantityController.text),
                          minQuantity: int.parse(_minQuantityController.text),
                          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
                          unit: _unitController.text.trim().isEmpty
                              ? null
                              : _unitController.text.trim(),
                          existingPhotoUrl: widget.product.photoUrl,
                          newImageFile: _newImageFile,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Produit modifié avec succès !'), backgroundColor: AppColors.primary),
                          );
                          context.pop();                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
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
                  label: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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