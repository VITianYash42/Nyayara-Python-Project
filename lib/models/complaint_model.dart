import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId;
  final String userId;
  final String? userName; // null if anonymous
  final String harasserName;
  final String department;
  final String description;
  final String caseType;
  final String severityScore; // Low, Medium, High, Critical
  final int severityPercent; // 0-100
  final String status;
  final DateTime timestamp;
  final bool anonymous;
  final String? hrEmail;
  final String? organizationId;
  final List<String> evidenceIds;
  final String firDraft;
  final String hrComplaintDraft;
  final List<String> legalSections;
  final String aiAnalysis;
  final String nextBestAction;
  final bool escalated;
  final int offenderReportCount;

  ComplaintModel({
    required this.complaintId,
    required this.userId,
    this.userName,
    required this.harasserName,
    required this.department,
    required this.description,
    required this.caseType,
    this.severityScore = 'Medium',
    this.severityPercent = 50,
    this.status = 'Pending Review',
    required this.timestamp,
    this.anonymous = false,
    this.hrEmail,
    this.organizationId,
    this.evidenceIds = const [],
    this.firDraft = '',
    this.hrComplaintDraft = '',
    this.legalSections = const [],
    this.aiAnalysis = '',
    this.nextBestAction = '',
    this.escalated = false,
    this.offenderReportCount = 1,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      complaintId: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'],
      harasserName: data['harasserName'] ?? '',
      department: data['department'] ?? '',
      description: data['description'] ?? '',
      caseType: data['caseType'] ?? 'Workplace Harassment',
      severityScore: data['severityScore'] ?? 'Medium',
      severityPercent: data['severityPercent'] ?? 50,
      status: data['status'] ?? 'Pending Review',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      anonymous: data['anonymous'] ?? false,
      hrEmail: data['hrEmail'],
      organizationId: data['organizationId'],
      evidenceIds: List<String>.from(data['evidenceIds'] ?? []),
      firDraft: data['firDraft'] ?? '',
      hrComplaintDraft: data['hrComplaintDraft'] ?? '',
      legalSections: List<String>.from(data['legalSections'] ?? []),
      aiAnalysis: data['aiAnalysis'] ?? '',
      nextBestAction: data['nextBestAction'] ?? '',
      escalated: data['escalated'] ?? false,
      offenderReportCount: data['offenderReportCount'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': anonymous ? null : userName,
      'harasserName': harasserName,
      'department': department,
      'description': description,
      'caseType': caseType,
      'severityScore': severityScore,
      'severityPercent': severityPercent,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'anonymous': anonymous,
      'hrEmail': hrEmail,
      'organizationId': organizationId,
      'evidenceIds': evidenceIds,
      'firDraft': firDraft,
      'hrComplaintDraft': hrComplaintDraft,
      'legalSections': legalSections,
      'aiAnalysis': aiAnalysis,
      'nextBestAction': nextBestAction,
      'escalated': escalated,
      'offenderReportCount': offenderReportCount,
    };
  }

  ComplaintModel copyWith({
    String? status,
    String? severityScore,
    int? severityPercent,
    bool? escalated,
    int? offenderReportCount,
    String? firDraft,
    String? hrComplaintDraft,
    String? aiAnalysis,
    String? nextBestAction,
    List<String>? legalSections,
    List<String>? evidenceIds,
  }) {
    return ComplaintModel(
      complaintId: complaintId,
      userId: userId,
      userName: userName,
      harasserName: harasserName,
      department: department,
      description: description,
      caseType: caseType,
      severityScore: severityScore ?? this.severityScore,
      severityPercent: severityPercent ?? this.severityPercent,
      status: status ?? this.status,
      timestamp: timestamp,
      anonymous: anonymous,
      hrEmail: hrEmail,
      organizationId: organizationId,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      firDraft: firDraft ?? this.firDraft,
      hrComplaintDraft: hrComplaintDraft ?? this.hrComplaintDraft,
      legalSections: legalSections ?? this.legalSections,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      nextBestAction: nextBestAction ?? this.nextBestAction,
      escalated: escalated ?? this.escalated,
      offenderReportCount: offenderReportCount ?? this.offenderReportCount,
    );
  }
}
