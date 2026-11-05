import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_espacio/features/habits/data/models/habit.dart';

class HabitLocalDataSource {
  static const storageKey = 'habits_v1';

  /// Descarta la copia en memoria para volver a leer lo guardado.
  static void reiniciarCache() {
    _inMemoryDb.clear();
    _carga = null;
  }

  // Copia en memoria de los hábitos guardados en shared_preferences.
  static final List<HabitModel> _inMemoryDb = [];
  static Future<void>? _carga;

  // Se guarda la misma carga para que pedidos simultáneos no dupliquen los hábitos.
  Future<void> _load() => _carga ??= _cargar();

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) {
      _inMemoryDb.addAll(_generateInitialMockData());
      await _save();
    } else {
      for (final item in jsonDecode(raw) as List) {
        final e = item as Map<String, dynamic>;
        _inMemoryDb.add(
          HabitModel(
            id: e['id'],
            name: e['name'],
            color: Color(e['color']),
            data: (e['data'] as Map<String, dynamic>).map((k, v) {
              final d = v as Map<String, dynamic>;
              return MapEntry(
                k,
                HabitEntryModel(
                  date: DateTime.parse(d['date']),
                  done: d['done'],
                  time: d['time'],
                ),
              );
            }),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(
        _inMemoryDb
            .map(
              (e) => {
                'id': e.id,
                'name': e.name,
                'color': e.color.toARGB32(),
                'data': e.data.map(
                  (k, v) => MapEntry(k, {
                    'date': v.date.toIso8601String(),
                    'done': v.done,
                    'time': v.time,
                  }),
                ),
              },
            )
            .toList(),
      ),
    );
  }

  Future<List<HabitModel>> fetchHabits() async {
    await _load();
    return List.from(_inMemoryDb);
  }

  Future<List<HabitModel>> addHabit(String name, Color color) async {
    await _load();
    final newHabit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      color: color,
      data: {},
    );
    _inMemoryDb.add(newHabit);
    await _save();
    return List.from(_inMemoryDb);
  }

  Future<List<HabitModel>> deleteHabit(int id) async {
    await _load();
    _inMemoryDb.removeWhere((h) => h.id == id);
    await _save();
    return List.from(_inMemoryDb);
  }

  Future<List<HabitModel>> updateHabits(List<HabitModel> updatedList) async {
    await _load();
    _inMemoryDb.clear();
    _inMemoryDb.addAll(updatedList);
    await _save();
    return List.from(_inMemoryDb);
  }

  // Hábitos de ejemplo para una instalación nueva.
  static List<HabitModel> _generateInitialMockData() {
    final now = DateTime.now();
    return [
      HabitModel(
        id: 1,
        name: "Tomar 2L de agua",
        color: const Color(0xFF4ADE80),
        data: _generateEntriesForMonth(now.year, now.month, 0.7, [8, 9, 10]),
      ),
      HabitModel(
        id: 2,
        name: "Programar en Flutter",
        color: const Color(0xFFFBBF24),
        data: _generateEntriesForMonth(now.year, now.month, 0.5, [
          14,
          15,
          16,
          17,
        ]),
      ),
      HabitModel(
        id: 3,
        name: "Hacer ejercicio",
        color: Colors.blueAccent,
        data: _generateEntriesForMonth(now.year, now.month, 0.4, [7, 19]),
      ),
    ];
  }

  static Map<String, HabitEntryModel> _generateEntriesForMonth(
    int year,
    int month,
    double probability,
    List<int> allowedHours,
  ) {
    Map<String, HabitEntryModel> generated = {};
    int days = DateTime(year, month + 1, 0).day;
    final rand = Random();

    for (int d = 1; d <= days; d++) {
      if (d > DateTime.now().day) break; // No rellenar el futuro
      if (rand.nextDouble() < probability) {
        final date = DateTime(year, month, d);
        final hour = allowedHours[rand.nextInt(allowedHours.length)]
            .toString()
            .padLeft(2, '0');
        final min = rand.nextBool() ? "00" : "30";
        generated["$year-$month-$d"] = HabitEntryModel(
          date: date,
          done: true,
          time: "$hour:$min",
        );
      }
    }
    return generated;
  }
}
