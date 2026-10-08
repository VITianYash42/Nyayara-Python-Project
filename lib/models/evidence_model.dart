import 'package:cloud_firestore/cloud_firestore.dart';

class EvidenceModel {
  final String evidenceId;
  final String complaintId;
  final String userId;
  final String fileURL;
  final String fileName;
  final String type; // image, video, audio, document
  final int fileSize; // bytes
  final DateTime timestamp;
  final String strengthScore; // Weak, Moderate, Strong, Very Strong
  final int strengthPercent; // 0-100
  final String aiAnalysis;
  final String? thumbnailUrl;

  EvidenceModel({
    required this.evidenceId,
    required this.complaintId,
    required this.userId,
    required this.fileURL,
    required this.fileName,
    required this.type,
    this.fileSize = 0,
    required this.timestamp,
    this.strengthScore = 'Moderate',
    this.strengthPercent = 60,
    this.aiAnalysis = '',
    this.thumbnailUrl,
  });

  factory EvidenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EvidenceModel(
      evidenceId: doc.id,
      complaintId: data['complaintId'] ?? '',
      userId: data['userId'] ?? '',
      fileURL: data['fileURL'] ?? '',
      fileName: data['fileName'] ?? '',
      type: data['type'] ?? 'document',
      fileSize: data['fileSize'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      strengthScore: data['strengthScore'] ?? 'Moderate',
      strengthPercent: data['strengthPercent'] ?? 60,
      aiAnalysis: data['aiAnalysis'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'userId': userId,
      'fileURL': fileURL,
      'fileName': fileName,
      'type': type,
      'fileSize': fileSize,
      'timestamp': Timestamp.fromDate(timestamp),
      'strengthScore': strengthScore,
      'strengthPercent': strengthPercent,
      'aiAnalysis': aiAnalysis,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get typeIcon {
    switch (type) {
      case 'image': return '🖼️';
      case 'video': return '🎥';
      case 'audio': return '🎵';
      default: return '📄';
    }
  }
}

class SosAlert {
  final String alertId;
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final List<String> notifiedContacts;
  final bool resolved;

  SosAlert({
    required this.alertId,
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.notifiedContacts = const [],
    this.resolved = false,
  });

  factory SosAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SosAlert(
      alertId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notifiedContacts: List<String>.from(data['notifiedContacts'] ?? []),
      resolved: data['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'notifiedContacts': notifiedContacts,
      'resolved': resolved,
    };
  }
}
