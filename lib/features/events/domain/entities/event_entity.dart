import 'package:flutter/material.dart';

class EventEntity {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String organizer;
  final int maxParticipants;
  final List<String> registeredStudentIds;
  final String colorType;
  final IconData icon;
  final bool isOnline;

  const EventEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.organizer,
    required this.maxParticipants,
    this.registeredStudentIds = const [],
    this.colorType = 'blue',
    this.icon = Icons.event_rounded,
    this.isOnline = false,
  });

  bool isRegistered(String studentId) {
    if (studentId.isEmpty) return false;
    return registeredStudentIds.contains(studentId);
  }

  int get currentParticipants => registeredStudentIds.length;
  int get spotsRemaining => (maxParticipants - currentParticipants).clamp(0, maxParticipants);
  bool get isFull => currentParticipants >= maxParticipants;

  EventEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? organizer,
    int? maxParticipants,
    List<String>? registeredStudentIds,
    String? colorType,
    IconData? icon,
    bool? isOnline,
  }) {
    return EventEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      organizer: organizer ?? this.organizer,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registeredStudentIds: registeredStudentIds ?? this.registeredStudentIds,
      colorType: colorType ?? this.colorType,
      icon: icon ?? this.icon,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
