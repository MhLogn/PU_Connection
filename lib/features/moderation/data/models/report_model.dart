import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/entities/report_target_type.dart';

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.id,
    required super.reporterId,
    super.reporterName,
    required super.targetId,
    required super.targetType,
    super.targetAuthorId,
    super.targetAuthorName,
    required super.reason,
    super.details,
    super.status,
    super.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? created;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated);
    }

    final reasonStr = map['reason'] as String? ?? 'other';
    final reason = ReportReason.values.firstWhere(
      (r) => r.name == reasonStr,
      orElse: () => ReportReason.other,
    );

    final targetTypeStr = map['targetType'] as String? ?? 'post';
    final targetType = ReportTargetType.values.firstWhere(
      (t) => t.name == targetTypeStr,
      orElse: () => ReportTargetType.post,
    );

    return ReportModel(
      id: id,
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      targetId: map['targetId'] as String? ?? '',
      targetType: targetType,
      targetAuthorId: map['targetAuthorId'] as String? ?? '',
      targetAuthorName: map['targetAuthorName'] as String? ?? '',
      reason: reason,
      details: map['details'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: created,
    );
  }

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReportModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'targetId': targetId,
      'targetType': targetType.name,
      'targetAuthorId': targetAuthorId,
      'targetAuthorName': targetAuthorName,
      'reason': reason.name,
      'details': details,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
