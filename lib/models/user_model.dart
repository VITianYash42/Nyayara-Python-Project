import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role; // user, hr, admin
  final bool anonymousFlag;
  final List<TrustedContact> trustedContacts;
  final String? organizationId;
  final String? department;
  final DateTime createdAt;
  final String? profilePicUrl;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'user',
    this.anonymousFlag = false,
    this.trustedContacts = const [],
    this.organizationId,
    this.department,
    required this.createdAt,
    this.profilePicUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'user',
      anonymousFlag: data['anonymousFlag'] ?? false,
      trustedContacts: (data['trustedContacts'] as List<dynamic>? ?? [])
          .map((e) => TrustedContact.fromMap(e as Map<String, dynamic>))
          .toList(),
      organizationId: data['organizationId'],
      department: data['department'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profilePicUrl: data['profilePicUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'anonymousFlag': anonymousFlag,
      'trustedContacts': trustedContacts.map((e) => e.toMap()).toList(),
      'organizationId': organizationId,
      'department': department,
      'createdAt': Timestamp.fromDate(createdAt),
      'profilePicUrl': profilePicUrl,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? anonymousFlag,
    List<TrustedContact>? trustedContacts,
    String? organizationId,
    String? department,
    String? profilePicUrl,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      anonymousFlag: anonymousFlag ?? this.anonymousFlag,
      trustedContacts: trustedContacts ?? this.trustedContacts,
      organizationId: organizationId ?? this.organizationId,
      department: department ?? this.department,
      createdAt: createdAt,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    );
  }
}

class TrustedContact {
  final String name;
  final String phone;
  final String email;
  final String relation;

  TrustedContact({
    required this.name,
    required this.phone,
    this.email = '',
    this.relation = 'Friend',
  });

  factory TrustedContact.fromMap(Map<String, dynamic> map) {
    return TrustedContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      relation: map['relation'] ?? 'Friend',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'relation': relation,
    };
  }
}
