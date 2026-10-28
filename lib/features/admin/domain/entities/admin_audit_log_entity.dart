import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AdminAuditLogEntity extends Equatable {
  final String id;
  final String adminId;
  final String adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final String details;
  final DateTime timestamp;

  const AdminAuditLogEntity({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.details = '',
    required this.timestamp,
  });

  factory AdminAuditLogEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime ts = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      ts = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      ts = DateTime.tryParse(data['timestamp']) ?? ts;
    }

    return AdminAuditLogEntity(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      action: data['action'] ?? '',
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      details: data['details'] ?? '',
      timestamp: ts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminEmail': adminEmail,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    adminId,
    adminEmail,
    action,
    targetType,
    targetId,
    details,
    timestamp,
  ];
}
