import 'package:equatable/equatable.dart';
import 'report_reason.dart';
import 'report_target_type.dart';

class ReportEntity extends Equatable {
  final String id;
  final String reporterId;
  final String reporterName;
  final String targetId;
  final ReportTargetType targetType;
  final String targetAuthorId;
  final String targetAuthorName;
  final ReportReason reason;
  final String details;
  final String status; // 'pending' | 'reviewed' | 'dismissed'
  final DateTime? createdAt;

  const ReportEntity({
    required this.id,
    required this.reporterId,
    this.reporterName = '',
    required this.targetId,
    required this.targetType,
    this.targetAuthorId = '',
    this.targetAuthorName = '',
    required this.reason,
    this.details = '',
    this.status = 'pending',
    this.createdAt,
  });

  ReportEntity copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? targetId,
    ReportTargetType? targetType,
    String? targetAuthorId,
    String? targetAuthorName,
    ReportReason? reason,
    String? details,
    String? status,
    DateTime? createdAt,
  }) {
    return ReportEntity(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      targetAuthorId: targetAuthorId ?? this.targetAuthorId,
      targetAuthorName: targetAuthorName ?? this.targetAuthorName,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reporterId,
        reporterName,
        targetId,
        targetType,
        targetAuthorId,
        targetAuthorName,
        reason,
        details,
        status,
        createdAt,
      ];
}
