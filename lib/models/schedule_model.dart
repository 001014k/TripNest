import 'package:flutter/material.dart';

class ScheduleModel {
  final String id;
  final String userId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final int colorValue;
  final List<String>? collaboratorIds; // 친구 협업 용

  ScheduleModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.placeId,
    this.latitude,
    this.longitude,
    required this.colorValue,
    this.collaboratorIds,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> j) => ScheduleModel(
    id: j['id'],
    userId: j['user_id'],
    title: j['title'],
    startTime: DateTime.parse(j['start_time']),
    endTime: DateTime.parse(j['end_time']),
    placeId: j['place_id'],
    latitude: j['latitude'],
    longitude: j['longitude'],
    colorValue: j['color_value'],
    collaboratorIds: (j['collaborator_ids'] as List?)?.map((e) => e as String).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'place_id': placeId,
    'latitude': latitude,
    'longitude': longitude,
    'color_value': colorValue,
    'collaborator_ids': collaboratorIds,
  };

  // 여기서 Color 타입 getter 추가
  Color get color => Color(colorValue);
}
