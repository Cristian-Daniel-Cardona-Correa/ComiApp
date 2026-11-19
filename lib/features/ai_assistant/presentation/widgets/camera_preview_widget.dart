import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Visor de cámara real para el Asistente Chef Gemini Live.
/// Permite capturar fotos reales de los alimentos usando la cámara del dispositivo,
/// visualizarlas dentro del modal y transmitirlas como frame visual al modelo Gemini.
class CameraPreviewWidget extends StatefulWidget {
  final VoidCallback onCloseCamera;
  final ValueChanged<List<int>>? onFrameCaptured;
  final ValueChanged<String>? onPhotoSaved;
  final String? initialImagePath;

  const CameraPreviewWidget({
    super.key,
    required this.onCloseCamera,
    this.onFrameCaptured,
    this.onPhotoSaved,
    this.initialImagePath,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  final _picker = ImagePicker();
  String? _capturedImagePath;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _capturedImagePath = widget.initialImagePath;
  }

  @override
  void didUpdateWidget(covariant CameraPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImagePath != oldWidget.initialImagePath &&
        widget.initialImagePath != null) {
      _capturedImagePath = widget.initialImagePath;
    }
  }

  Future<void> _takePhoto() async {
    setState(() => _isCapturing = true);
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        setState(() {
          _capturedImagePath = photo.path;
        });

        widget.onPhotoSaved?.call(photo.path);

        if (widget.onFrameCaptured != null) {
          final bytes = await photo.readAsBytes();
          widget.onFrameCaptured!(bytes);
        }
      }
    } catch (e) {
      debugPrint('Error al capturar foto de cámara: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo acceder a la cámara: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineDark, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen real capturada o visor inicial
          if (_capturedImagePath != null)
            Image.file(
              File(_capturedImagePath!),
              fit: BoxFit.cover,
            )
          else
            Container(
              color: const Color(0xFF142421),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      size: 42,
                      color: AppColors.mintSoft,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cámara para Gemini Live',
                      style: AppTypography.titleMedium
                          .copyWith(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Apunta a tu sartén o ingredientes para que el chef te dé retroalimentación visual en vivo.',
                        style: AppTypography.bodySmall
                            .copyWith(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isCapturing ? null : _takePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(
                        _isCapturing ? 'Abriendo cámara...' : 'Capturar con la cámara',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Botón de re-captura si ya tomó foto
          if (_capturedImagePath != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _takePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Tomar otra', style: TextStyle(fontSize: 12)),
              ),
            ),

          // Badge LIVE
          Positioned(
            top: 8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _capturedImagePath != null
                    ? AppColors.primaryTeal
                    : AppColors.errorCoral,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _capturedImagePath != null ? 'FOTO ENVIADA AL CHEF' : 'CÁMARA REAL DISPONIBLE',
                    style: AppTypography.badge
                        .copyWith(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // Botón Cerrar Visor
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black54,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                onPressed: widget.onCloseCamera,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
