import 'package:flutter/material.dart';
import '../../domain/entities/habit_entity.dart';

class HabitModel {
  final int id;
  String name;
  final Color color;
  Map<String, HabitEntryModel> data; // O como se llame tu clase interna de entradas

  HabitModel({required this.id, required this.name, required this.color, required this.data});

  // --- COPIÁ ESTE MÉTODO ADENTRO DE TU MODELO ---
  HabitEntity toEntity() {
    return HabitEntity(
      id: id,
      name: name,
      color: color,
      // Mapeamos el mapa interno de entradas a entidades de dominio
      data: data.map((key, value) => MapEntry(key, value.toEntity())),
    );
  }
}

class HabitEntryModel {
  final DateTime date;
  bool done;
  String time;

  HabitEntryModel({required this.date, this.done = false, this.time = "--:--"});

  // Si tenés una entidad equivalente en el dominio (ej: HabitEntryEntity)
  HabitEntryEntity toEntity() {
    return HabitEntryEntity(date: date, done: done, time: time);
  }
}