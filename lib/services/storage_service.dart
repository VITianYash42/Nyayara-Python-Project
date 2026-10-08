import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Upload evidence file & return download URL
  Future<Map<String, String>> uploadEvidence({
    required File file,
    required String userId,
    required String complaintId,
    required String fileType, // image, video, audio, document
  }) async {
    final ext = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$ext';
    final path = '${AppConstants.storageEvidence}/$userId/$complaintId/$fileName';

    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: _getContentType(fileType, ext),
        customMetadata: {
          'userId': userId,
          'complaintId': complaintId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return {
      'url': downloadUrl,
      'fileName': fileName,
      'path': path,
    };
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture({
    required File file,
    required String userId,
  }) async {
    final ext = file.path.split('.').last;
    final path = '${AppConstants.storageProfilePics}/$userId/profile.$ext';
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Delete a file by its storage path
  Future<void> deleteFile(String storagePath) async {
    await _storage.ref().child(storagePath).delete();
  }

  /// Get upload progress stream
  UploadTask uploadWithProgress({
    required File file,
    required String userId,
    required String complaintId,
    required String fileType,
  }) {
    final ext = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$ext';
    final path = '${AppConstants.storageEvidence}/$userId/$complaintId/$fileName';
    final ref = _storage.ref().child(path);
    return ref.putFile(file, SettableMetadata(contentType: _getContentType(fileType, ext)));
  }

  String _getContentType(String fileType, String ext) {
    switch (fileType) {
      case 'image': return 'image/$ext';
      case 'video': return 'video/$ext';
      case 'audio': return 'audio/$ext';
      default: return 'application/octet-stream';
    }
  }
}
