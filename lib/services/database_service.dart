import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import '../models/evidence_model.dart';
import '../core/app_constants.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────── COMPLAINTS ────────────────────────────────────

  /// Submit a new complaint and run escalation check
  Future<String> submitComplaint(ComplaintModel complaint) async {
    final docRef = await _db
        .collection(AppConstants.colComplaints)
        .add(complaint.toMap());
    await _checkAndEscalate(complaint.harasserName, complaint.department, docRef.id);
    return docRef.id;
  }

  /// Stream complaints for a specific user
  Stream<List<ComplaintModel>> userComplaintsStream(String userId) {
    return _db
        .collection(AppConstants.colComplaints)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ComplaintModel.fromFirestore).toList());
  }

  /// Stream all complaints for HR Dashboard
  Stream<List<ComplaintModel>> allComplaintsStream({String? orgId}) {
    Query query = _db.collection(AppConstants.colComplaints);
    if (orgId != null) query = query.where('organizationId', isEqualTo: orgId);
    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ComplaintModel.fromFirestore).toList());
  }

  /// Get all past complaints for a user (one-time fetch)
  Future<List<ComplaintModel>> getUserComplaints(String userId) async {
    final snap = await _db
        .collection(AppConstants.colComplaints)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map(ComplaintModel.fromFirestore).toList();
  }

  /// Update complaint status (HR action)
  Future<void> updateComplaintStatus(String complaintId, String status) async {
    await _db
        .collection(AppConstants.colComplaints)
        .doc(complaintId)
        .update({'status': status, 'lastUpdated': FieldValue.serverTimestamp()});
  }

  /// Escalation: if same offender reported ≥3 times → flag High Risk
  /// Does NOT auto-file FIR — only flags for HR to review
  Future<void> _checkAndEscalate(
      String harasserName, String department, String newComplaintId) async {
    if (harasserName.isEmpty) return;
    final snaps = await _db
        .collection(AppConstants.colComplaints)
        .where('harasserName', isEqualTo: harasserName)
        .where('department', isEqualTo: department)
        .get();

    final count = snaps.docs.length;
    if (count >= 3) {
      final batch = _db.batch();
      // Mark all complaints for this offender as escalated
      for (final doc in snaps.docs) {
        batch.update(doc.reference, {
          'escalated': true,
          'offenderReportCount': count,
          'severityScore': AppConstants.severityHigh,
        });
      }
      // Mark new complaint too
      batch.update(
          _db.collection(AppConstants.colComplaints).doc(newComplaintId), {
        'escalated': true,
        'offenderReportCount': count + 1,
        'severityScore': AppConstants.severityHigh,
      });
      await batch.commit();

      // Write escalation notification for HR dashboard
      await _db.collection('notifications').add({
        'type': 'escalation',
        'harasserName': harasserName,
        'department': department,
        'complaintCount': count + 1,
        'message':
            '⚠️ High Risk: $harasserName from $department has ${count + 1} complaints. Consider FIR.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
  }

  // ─────────────────── EVIDENCE ──────────────────────────────────────

  /// Save evidence metadata after upload
  Future<String> saveEvidence(EvidenceModel evidence) async {
    final docRef =
        await _db.collection(AppConstants.colEvidence).add(evidence.toMap());
    // Link evidence ID to its complaint
    if (evidence.complaintId.isNotEmpty) {
      await _db
          .collection(AppConstants.colComplaints)
          .doc(evidence.complaintId)
          .update({
        'evidenceIds': FieldValue.arrayUnion([docRef.id]),
      }).catchError((_) {}); // Ignore if complaint doc doesn't exist yet
    }
    return docRef.id;
  }

  /// Stream evidence filtered by complaintId (real data only)
  Stream<List<EvidenceModel>> evidenceStream(String complaintId) {
    return _db
        .collection(AppConstants.colEvidence)
        .where('complaintId', isEqualTo: complaintId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(EvidenceModel.fromFirestore).toList());
  }

  /// Stream ALL evidence for a user (Evidence Vault view)
  Stream<List<EvidenceModel>> userEvidenceStream(String userId) {
    return _db
        .collection(AppConstants.colEvidence)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(EvidenceModel.fromFirestore).toList());
  }

  /// Get all evidence for a user (one-time fetch)
  Future<List<EvidenceModel>> getUserEvidence(String userId) async {
    final snap = await _db
        .collection(AppConstants.colEvidence)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map(EvidenceModel.fromFirestore).toList();
  }

  // ─────────────────── AI CHAT HISTORY ──────────────────────────────

  /// Save an AI chat session for signed-in users
  Future<void> saveChatSession(String userId, List<Map<String, dynamic>> messages) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('chatHistory')
        .add({
      'messages': messages,
      'timestamp': FieldValue.serverTimestamp(),
      'messageCount': messages.length,
    });
  }

  /// Get last N chat sessions for a user
  Future<List<Map<String, dynamic>>> getChatHistory(String userId,
      {int limit = 5}) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('chatHistory')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'messages': data['messages'] ?? [],
        'timestamp': data['timestamp'],
        'messageCount': data['messageCount'] ?? 0,
      };
    }).toList();
  }

  /// Delete a specific chat session
  Future<void> deleteChatSession(String userId, String sessionId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('chatHistory')
        .doc(sessionId)
        .delete();
  }

  // ─────────────────── TRUSTED CONTACTS ─────────────────────────────

  /// Save/update trusted contacts in subcollection
  Future<void> saveTrustedContact(String userId, Map<String, dynamic> contact) async {
    final contactId = contact['id'] as String?;
    if (contactId != null && contactId.isNotEmpty) {
      await _db
          .collection('users')
          .doc(userId)
          .collection('trustedContacts')
          .doc(contactId)
          .set(contact);
    } else {
      await _db
          .collection('users')
          .doc(userId)
          .collection('trustedContacts')
          .add(contact);
    }
  }

  /// Delete a trusted contact
  Future<void> deleteTrustedContact(String userId, String contactId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('trustedContacts')
        .doc(contactId)
        .delete();
  }

  /// Stream trusted contacts for a user
  Stream<List<Map<String, dynamic>>> trustedContactsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('trustedContacts')
        .snapshots()
        .map((s) => s.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // ─────────────────── SOS ──────────────────────────────────────────

  Future<String> logSosAlert(SosAlert alert) async {
    final docRef = await _db
        .collection(AppConstants.colSosAlerts)
        .add(alert.toMap());
    return docRef.id;
  }

  // ─────────────────── HR ANALYTICS ─────────────────────────────────

  Future<Map<String, int>> getDepartmentComplaintCount({String? orgId}) async {
    final query = orgId != null
        ? _db.collection(AppConstants.colComplaints).where('organizationId', isEqualTo: orgId)
        : _db.collection(AppConstants.colComplaints);

    final snaps = await query.get();
    final Map<String, int> deptCount = {};
    for (final doc in snaps.docs) {
      final dept = (doc.data() as Map<String, dynamic>)['department'] ?? 'Unknown';
      deptCount[dept] = (deptCount[dept] ?? 0) + 1;
    }
    return deptCount;
  }

  Future<Map<String, int>> getRepeatOffenders({String? orgId}) async {
    final snaps = await _db.collection(AppConstants.colComplaints).get();
    final Map<String, int> offenderCount = {};
    for (final doc in snaps.docs) {
      final name = (doc.data() as Map<String, dynamic>)['harasserName'] ?? '';
      if (name.isNotEmpty) {
        offenderCount[name] = (offenderCount[name] ?? 0) + 1;
      }
    }
    return offenderCount;
  }

  /// Stream escalation notifications for HR
  Stream<List<Map<String, dynamic>>> escalationNotificationsStream() {
    return _db
        .collection('notifications')
        .where('type', isEqualTo: 'escalation')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'read': true});
  }
}
