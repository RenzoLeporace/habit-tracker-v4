import 'package:flutter/material.dart';

class HabitEntity {
  final int id;
  String name;
  final Color color;
  Map<String, HabitEntryEntity> data;

  HabitEntity({
    required this.id,
    required this.name,
    required this.color,
    required this.data,
  });
}

class HabitEntryEntity {
  final DateTime date;
  bool done;
  String time;

  HabitEntryEntity({
    required this.date,
    this.done = false,
    this.time = "--:--",
  });
}