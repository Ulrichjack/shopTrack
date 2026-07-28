import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  String? _detectedCode;
  bool _handlingDetection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      autoStart: true,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_safeStart());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_controller.stop());
    }
  }

  Future<void> _safeStart() async {
    try {
      if (!_controller.value.isRunning) {
        await _controller.start();
      }
    } on MobileScannerException catch (error) {
      if (error.errorCode !=
          MobileScannerErrorCode.controllerAlreadyInitialized) {
        rethrow;
      }
    }
  }

  Future<void> _retry() async {
    try {
      await _controller.stop();
    } catch (_) {
      // Le contrôleur peut ne pas être initialisé après un refus de permission.
    }
    await _safeStart();
    if (mounted) setState(() {});
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingDetection || _detectedCode != null) return;
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;

    if (code == null) return;
    _handlingDetection = true;
    await _controller.stop();
    await HapticFeedback.mediumImpact();

    if (mounted) {
      setState(() {
        _detectedCode = code;
        _handlingDetection = false;
      });
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _detectedCode = null;
      _handlingDetection = false;
    });
    await _safeStart();
  }

  Future<void> _enterCodeManually() async {
    final textController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Saisir le code'),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'QR ou code-barres',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, textController.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    textController.dispose();

    if (code != null && code.isNotEmpty && mounted) {
      Navigator.of(context).pop(code);
    }
  }

  String _errorMessage(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'La permission caméra est refusée. Autorisez la caméra dans les paramètres du téléphone, puis appuyez sur Réessayer.',
      MobileScannerErrorCode.unsupported =>
        'Le scanner n’est pas compatible avec cet appareil.',
      MobileScannerErrorCode.controllerUninitialized =>
        'La caméra ne s’est pas initialisée correctement.',
      MobileScannerErrorCode.controllerAlreadyInitialized =>
        'La caméra est déjà utilisée. Fermez les autres applications caméra puis réessayez.',
      MobileScannerErrorCode.controllerDisposed =>
        'Le scanner a été fermé de façon inattendue.',
      MobileScannerErrorCode.genericError =>
        error.errorDetails?.message ??
            'La caméra est indisponible. Vérifiez la permission et réessayez.',
    };
  }

  Widget _buildError(
    BuildContext context,
    MobileScannerException error,
    Widget? child,
  ) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage(error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
              TextButton(
                onPressed: _enterCodeManually,
                child: const Text('Saisir le code manuellement'),
              ),
              Text(
                'Erreur technique : ${error.errorCode.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Saisie manuelle',
            onPressed: _enterCodeManually,
            icon: const Icon(Icons.keyboard),
          ),
          IconButton(
            tooltip: 'Changer de caméra',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
          IconButton(
            tooltip: 'Flash',
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            errorBuilder: _buildError,
            placeholderBuilder: (_, __) => const ColoredBox(
              color: Colors.black,
              child: Center(child: CircularProgressIndicator()),
            ),
            onDetect: _onDetect,
          ),
          Center(
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _detectedCode != null
                        ? AppColors.primary
                        : Colors.white70,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          if (_detectedCode == null)
            const Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Text(
                'Placez le code dans le cadre',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          if (_detectedCode != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Code détecté',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _detectedCode!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _scanAgain,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reprendre'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pop(_detectedCode),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Valider'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
