import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/snaps/snaps_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SnapCameraScreen extends ConsumerStatefulWidget {
  const SnapCameraScreen({super.key});

  @override
  ConsumerState<SnapCameraScreen> createState() => _SnapCameraScreenState();
}

class _SnapCameraScreenState extends ConsumerState<SnapCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isSending = false;

  int _selectedDuration = 10; // 10 seconds by default

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Prefer front camera for snaps
        final frontCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
        
        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takeSnap() async {
    if (_controller == null || !_controller!.value.isInitialized || _isSending) return;

    setState(() => _isSending = true);

    try {
      final xFile = await _controller!.takePicture();
      final file = File(xFile.path);

      await ref.read(snapsServiceProvider).createSnap(
            file: file,
            duration: _selectedDuration,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Snap sent!')),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('Error sending snap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send snap: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.rose500)),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Camera unavailable', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => context.pop(),
                    ),
                    DropdownButton<int>(
                      value: _selectedDuration,
                      dropdownColor: AppColors.gray900,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.timer, color: Colors.white),
                      items: [3, 5, 10].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('${value}s'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDuration = val);
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: _isSending
                      ? const CircularProgressIndicator(color: AppColors.rose500)
                      : GestureDetector(
                          onTap: _takeSnap,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
