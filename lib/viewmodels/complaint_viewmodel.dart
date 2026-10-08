import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../models/evidence_model.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../core/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum ComplaintStatus { idle, loading, success, error }

class ComplaintViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  ComplaintStatus _status = ComplaintStatus.idle;
  String? _errorMessage;
  AIAnalysisResult? _latestAnalysis;
  String? _generatedFIR;
  String? _generatedHREmail;
  bool _isAnalyzing = false;
  bool _emailSent = false;

  ComplaintStatus get status => _status;
  String? get errorMessage => _errorMessage;
  AIAnalysisResult? get latestAnalysis => _latestAnalysis;
  String? get generatedFIR => _generatedFIR;
  String? get generatedHREmail => _generatedHREmail;
  bool get isAnalyzing => _isAnalyzing;
  bool get emailSent => _emailSent;

  Stream<List<ComplaintModel>> userComplaintStream(String userId) =>
      _db.userComplaintsStream(userId);

  Stream<List<ComplaintModel>> allComplaintsStream({String? orgId}) =>
      _db.allComplaintsStream(orgId: orgId);

  // ── AI: Analyze Incident ───────────────────────────────────────────
  Future<void> analyzeIncident(String description) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _latestAnalysis = await AIService.analyzeIncident(description);
    } catch (e) {
      _errorMessage = 'AI analysis failed. Please try again.';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // ── AI: Generate FIR Draft ─────────────────────────────────────────
  Future<void> generateFIR({
    required String complainantName,
    required String incidentDate,
    required String incidentLocation,
    required String description,
    required String caseType,
  }) async {
    _isAnalyzing = true;
    notifyListeners();
    try {
      _generatedFIR = await AIService.generateFIRDraft(
        complainantName: complainantName,
        incidentDate: incidentDate,
        incidentLocation: incidentLocation,
        description: description,
        caseType: caseType,
      );
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // ── AI: Generate HR Complaint Email ───────────────────────────────
  Future<void> generateHREmail({
    required String complainantName,
    required bool isAnonymous,
    required String harasserName,
    required String department,
    required String incidentDate,
    required String description,
  }) async {
    _isAnalyzing = true;
    notifyListeners();
    try {
      _generatedHREmail = await AIService.generateHRComplaintEmail(
        complainantName: complainantName,
        isAnonymous: isAnonymous,
        harasserName: harasserName,
        department: department,
        incidentDate: incidentDate,
        description: description,
      );
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // ── Submit Complaint with Optional Email Notification ─────────────
  Future<String?> submitComplaintWithEmail({
    required ComplaintModel complaint,
    String? hrEmail,
  }) async {
    _status = ComplaintStatus.loading;
    _emailSent = false;
    notifyListeners();

    try {
      // 1. Save to Firestore
      final id = await _db.submitComplaint(complaint);

      // 2. Generate email content if HR email provided
      if (hrEmail != null && hrEmail.isNotEmpty) {
        final emailContent = await AIService.generateHRComplaintEmail(
          complainantName: complaint.anonymous ? 'Anonymous' : (complaint.userName ?? 'Complainant'),
          isAnonymous: complaint.anonymous,
          harasserName: complaint.harasserName,
          department: complaint.department,
          incidentDate: complaint.timestamp.toString().substring(0, 10),
          description: complaint.description,
        );

        // 3. Try to send email via Cloud Function
        try {
          await _sendEmailViaCloudFunction(
            hrEmail: hrEmail,
            emailContent: emailContent,
            complainantId: id,
          );
          _emailSent = true;
          // Log email status in Firestore
          await _db.updateComplaintStatus(id, complaint.status);
        } catch (emailError) {
          // Email failed, but complaint was saved — not critical
          _emailSent = false;
        }
      }

      _status = ComplaintStatus.success;
      notifyListeners();
      return id;
    } catch (e) {
      _errorMessage = 'Failed to submit complaint: $e';
      _status = ComplaintStatus.error;
      notifyListeners();
      return null;
    }
  }

  /// Legacy submit without email
  Future<String?> submitComplaint(ComplaintModel complaint) async {
    return submitComplaintWithEmail(complaint: complaint);
  }

  Future<void> _sendEmailViaCloudFunction({
    required String hrEmail,
    required String emailContent,
    required String complainantId,
  }) async {
    // Using EmailJS (Client Side) because Cloud Functions requires Blaze plan
    final url = Uri.parse(AppConstants.emailJsUrl);
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost', // Sometimes needed for EmailJS
      },
      body: jsonEncode({
        'service_id': AppConstants.emailJsServiceId,
        'template_id': AppConstants.emailJsTemplateId,
        'user_id': AppConstants.emailJsPublicKey,
        'template_params': {
          'to_email': hrEmail,
          'subject': 'Formal POSH Complaint - Reference: $complainantId',
          'message': emailContent,
          'complainant_id': complainantId,
        }
      }),
    );

    debugPrint("EmailJS Status: ${response.statusCode}");
    debugPrint("EmailJS Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('EmailJS Failed: ${response.body}');
    }
  }

  // ── Update Status (HR) ─────────────────────────────────────────────
  Future<void> updateComplaintStatus(String complaintId, String status) async {
    await _db.updateComplaintStatus(complaintId, status);
    notifyListeners();
  }

  // ── Analytics (HR) ────────────────────────────────────────────────
  Future<Map<String, int>> getDepartmentStats({String? orgId}) async =>
      await _db.getDepartmentComplaintCount(orgId: orgId);

  Future<Map<String, int>> getRepeatOffenders({String? orgId}) async =>
      await _db.getRepeatOffenders(orgId: orgId);

  Stream<List<Map<String, dynamic>>> get escalationStream =>
      _db.escalationNotificationsStream();

  void reset() {
    _status = ComplaintStatus.idle;
    _errorMessage = null;
    _latestAnalysis = null;
    _generatedFIR = null;
    _generatedHREmail = null;
    _emailSent = false;
    notifyListeners();
  }
}
