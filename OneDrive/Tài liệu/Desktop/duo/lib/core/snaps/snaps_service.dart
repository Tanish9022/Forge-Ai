import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../api/api_client.dart';
import '../config/api_config.dart';
import '../crypto/crypto_service.dart';
import 'snaps_models.dart';

final snapsServiceProvider = Provider<SnapsService>((ref) {
  return SnapsService(
    ref.watch(apiClientProvider),
    ref.watch(cryptoServiceProvider),
  );
});

class SnapsService {
  SnapsService(this._dio, this._crypto);

  final Dio _dio;
  final CryptoService _crypto;

  Future<List<Snap>> getSnaps() async {
    final feed = await getSnapFeed();
    return feed.snaps;
  }

  Future<SnapFeed> getSnapFeed() async {
    final response = await _dio.get<Map<String, dynamic>>('/snaps');
    final items = response.data!['snaps'] as List<dynamic>;
    final streak = response.data!['streak'] as Map<String, dynamic>?;
    return SnapFeed(
      snaps: items.map((item) => Snap.fromJson(item as Map<String, dynamic>)).toList(),
      streakCount: streak?['count'] as int? ?? 0,
    );
  }

  Future<void> createSnap({required File file, required int? duration}) async {
    // Read and encrypt file
    final bytes = await file.readAsBytes();
    final encryptedMap = await _crypto.encryptBytes(bytes);
    final encryptedBase64 = encryptedMap['encryptedContent']!;
    final ivBase64 = encryptedMap['iv']!;

    // We store the IV along with the encrypted content in the file to simplify server storage for MVP.
    // The format could be: ivBase64 + ':' + encryptedBase64
    final fileContent = '$ivBase64:$encryptedBase64';
    
    // Create a temporary file to upload
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'snap_upload.enc'));
    await tempFile.writeAsString(fileContent);

    // Upload to media endpoint
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(tempFile.path, filename: 'snap.enc'),
    });

    final uploadRes = await _dio.post<Map<String, dynamic>>(
      '/media/upload',
      data: formData,
    );

    final storageRef = uploadRes.data!['url'] as String;

    // Create snap record
    await _dio.post<Map<String, dynamic>>(
      '/snaps',
      data: {
        'storageRef': storageRef,
        'duration': duration,
      },
    );
    
    // Cleanup
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
  
  Future<File> downloadAndDecryptSnap(String storageRef) async {
    final base = Uri.parse(ApiConfig.baseUrl);
    final origin = '${base.scheme}://${base.authority}';
    final url = storageRef.startsWith('http')
        ? storageRef
        : storageRef.startsWith('/api/')
            ? '$origin$storageRef'
            : '${ApiConfig.baseUrl}$storageRef';

    final response = await _dio.get<String>(
      url,
    );
    
    final fileContent = response.data!;
    final parts = fileContent.split(':');
    if (parts.length != 2) throw Exception('Invalid snap format');
    
    final ivBase64 = parts[0];
    final encryptedBase64 = parts[1];
    
    final decryptedBytes = await _crypto.decryptBytes(encryptedBase64, ivBase64);
    
    final tempDir = await getTemporaryDirectory();
    // Use a unique name
    final tempFile = File(p.join(tempDir.path, 'decrypted_snap_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await tempFile.writeAsBytes(decryptedBytes);
    
    return tempFile;
  }

  Future<void> markSnapViewed(String snapId) async {
    await _dio.post<Map<String, dynamic>>('/snaps/$snapId/view');
  }

  Future<void> toggleSaveSnap(String snapId) async {
    await _dio.patch<Map<String, dynamic>>('/snaps/$snapId/save');
  }

  Future<void> deleteSnapForBoth(String snapId) async {
    await _dio.delete<Map<String, dynamic>>('/snaps/$snapId');
  }
}
