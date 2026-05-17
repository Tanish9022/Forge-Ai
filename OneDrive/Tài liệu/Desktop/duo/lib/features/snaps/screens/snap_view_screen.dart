import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/snaps/snaps_models.dart';
import '../../../core/snaps/snaps_service.dart';
import '../../../core/theme/app_colors.dart';

class SnapViewScreen extends ConsumerStatefulWidget {
  const SnapViewScreen({super.key, required this.snap});
  final Snap snap;

  @override
  ConsumerState<SnapViewScreen> createState() => _SnapViewScreenState();
}

class _SnapViewScreenState extends ConsumerState<SnapViewScreen> {
  File? _imageFile;
  bool _isLoading = true;
  bool _isError = false;
  
  Timer? _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.snap.duration ?? 10;
    _loadSnap();
  }

  Future<void> _loadSnap() async {
    try {
      final file = await ref.read(snapsServiceProvider).downloadAndDecryptSnap(widget.snap.storageRef);
      await ref.read(snapsServiceProvider).markSnapViewed(widget.snap.id);
      
      if (mounted) {
        setState(() {
          _imageFile = file;
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 1) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          context.pop();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_imageFile != null && _imageFile!.existsSync()) {
      _imageFile!.deleteSync(); // Clean up decrypted file when done
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.rose500)),
      );
    }

    if (_isError || _imageFile == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text('Failed to load snap', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _imageFile!,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
                    onPressed: () async {
                      await ref.read(snapsServiceProvider).toggleSaveSnap(widget.snap.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Snap saved')),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_timeLeft',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
