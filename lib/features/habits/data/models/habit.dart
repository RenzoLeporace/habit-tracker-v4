import 'package:flutter/material.dart';
import 'package:mi_espacio/features/habits/domain/entities/habit_entity.dart';

class HabitModel {
  final int id;
  String name;
  final Color color;
  Map<String, HabitEntryModel> data;

  HabitModel({
    required this.id,
    required this.name,
    required this.color,
    required this.data,
  });

  HabitEntity toEntity() {
    return HabitEntity(
      id: id,
      name: name,
      color: color,
      // Convierte cada registro diario a su entidad de dominio.
      data: data.map((key, value) => MapEntry(key, value.toEntity())),
    );
  }
}

class HabitEntryModel {
  final DateTime date;
  bool done;
  String time;

  HabitEntryModel({required this.date, this.done = false, this.time = "--:--"});

  HabitEntryEntity toEntity() {
    return HabitEntryEntity(date: date, done: done, time: time);
  }
}
