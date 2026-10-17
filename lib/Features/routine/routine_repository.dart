import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
int minuteOf(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

class Activity {
  final String id, name, start, end, category;
  final DateTime date;
  Activity({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.category,
    required this.date,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start': start,
    'end': end,
    'category': category,
    'date': date.toIso8601String(),
  };
  factory Activity.fromJson(Map<String, dynamic> e) => Activity(
    id: e['id'],
    name: e['name'],
    start: e['start'],
    end: e['end'],
    category: e['category'],
    date: DateTime.parse(e['date']),
  );
}

class WeeklyTask {
  final String id, text;
  final DateTime date;
  final bool done;
  WeeklyTask({
    required this.id,
    required this.text,
    required this.date,
    this.done = false,
  });
  WeeklyTask copy({DateTime? date, bool? done}) => WeeklyTask(
    id: id,
    text: text,
    date: date ?? this.date,
    done: done ?? this.done,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'date': date.toIso8601String(),
    'done': done,
  };
  factory WeeklyTask.fromJson(Map<String, dynamic> e) => WeeklyTask(
    id: e['id'],
    text: e['text'],
    date: DateTime.parse(e['date']),
    done: e['done'],
  );
}

abstract class RoutineRepository {
  Future<List<Activity>> activities();
  Future<List<WeeklyTask>> tasks();
  Future<void> saveActivity(Activity activity);
  Future<void> deleteActivity(String id);
  Future<void> saveTask(WeeklyTask task);
  Future<void> deleteTask(String id);
}

class LocalRoutineRepository implements RoutineRepository {
  static const key = 'routine_v1';
  final _activities = <Activity>[];
  final _tasks = <WeeklyTask>[];
  bool _loaded = false;
  Future<void> _load() async {
    if (_loaded) return;
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _activities.addAll(
        (data['activities'] as List).map((e) => Activity.fromJson(e)),
      );
      _tasks.addAll((data['tasks'] as List).map((e) => WeeklyTask.fromJson(e)));
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode({
        'activities': _activities.map((e) => e.toJson()).toList(),
        'tasks': _tasks.map((e) => e.toJson()).toList(),
      }),
    );
  }

  @override
  Future<List<Activity>> activities() async {
    await _load();
    return List.unmodifiable(_activities);
  }

  @override
  Future<List<WeeklyTask>> tasks() async {
    await _load();
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    await _load();
    _activities.removeWhere((e) => e.id == activity.id);
    _activities.add(activity);
    await _persist();
  }

  @override
  Future<void> deleteActivity(String id) async {
    await _load();
    _activities.removeWhere((e) => e.id == id);
    await _persist();
  }

  @override
  Future<void> saveTask(WeeklyTask task) async {
    await _load();
    _tasks.removeWhere((e) => e.id == task.id);
    _tasks.add(task);
    await _persist();
  }

  @override
  Future<void> deleteTask(String id) async {
    await _load();
    _tasks.removeWhere((e) => e.id == id);
    await _persist();
  }
}

class RoutineController extends ChangeNotifier {
  final RoutineRepository repository;
  RoutineController(this.repository);
  List<Activity> activities = [];
  List<WeeklyTask> tasks = [];
  DateTime selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  int weekOffset = 0;
  Future<void> load() async {
    activities = await repository.activities();
    tasks = await repository.tasks();
    notifyListeners();
  }

  void changeDay(int amount) {
    selectedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day + amount,
    );
    notifyListeners();
  }

  void changeWeek(int amount) {
    weekOffset += amount;
    notifyListeners();
  }

  List<Activity> get dayActivities =>
      activities.where((e) => dayKey(e.date) == dayKey(selectedDay)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  List<DateTime> get weekDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today
        .subtract(Duration(days: today.weekday - 1))
        .add(Duration(days: weekOffset * 7));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  List<WeeklyTask> tasksOn(DateTime date) =>
      tasks.where((e) => dayKey(e.date) == dayKey(date)).toList();
  Future<void> addActivity(Activity item) async {
    await repository.saveActivity(item);
    await load();
  }

  Future<void> removeActivity(String id) async {
    await repository.deleteActivity(id);
    await load();
  }

  Future<void> addTask(WeeklyTask item) async {
    await repository.saveTask(item);
    await load();
  }

  Future<void> toggleTask(WeeklyTask item) async {
    await repository.saveTask(item.copy(done: !item.done));
    await load();
  }

  Future<void> moveTask(WeeklyTask item, DateTime date) async {
    await repository.saveTask(item.copy(date: date, done: false));
    await load();
  }

  Future<void> removeTask(String id) async {
    await repository.deleteTask(id);
    await load();
  }
}

class RoutineAnalysis {
  final List<String> fixed, variable, freeWindows, suggestions;
  RoutineAnalysis(
    this.fixed,
    this.variable,
    this.freeWindows,
    this.suggestions,
  );
}

RoutineAnalysis analyzeRoutine(List<Activity> activities, {DateTime? date}) {
  if (activities.isEmpty) return RoutineAnalysis([], [], [], []);
  final grouped = <String, List<Activity>>{};
  for (final item in activities) {
    grouped.putIfAbsent(item.name.toLowerCase(), () => []).add(item);
  }
  final fixed = <String>[], variable = <String>[];
  for (final group in grouped.values) {
    final days = group.map((e) => dayKey(e.date)).toSet().length;
    final starts = group.map((e) => minuteOf(e.start)).toList();
    final spread =
        starts.reduce((a, b) => a > b ? a : b) -
        starts.reduce((a, b) => a < b ? a : b);
    final label =
        '${group.first.name} · ${group.first.start}–${group.first.end}';
    if (days >= 2 && spread <= 30) {
      fixed.add(label);
    } else {
      variable.add(label);
    }
  }
  final reference = date ?? DateTime.now();
  final dayActs =
      activities.where((e) => dayKey(e.date) == dayKey(reference)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  var cursor = 6 * 60;
  final windows = <String>[];
  for (final item in dayActs) {
    final start = minuteOf(item.start);
    if (start - cursor >= 30) {
      windows.add('${_clock(cursor)}–${_clock(start)} · ${start - cursor} min');
    }
    if (minuteOf(item.end) > cursor) cursor = minuteOf(item.end);
  }
  if (22 * 60 - cursor >= 30) {
    windows.add('${_clock(cursor)}–22:00 · ${22 * 60 - cursor} min');
  }
  return RoutineAnalysis(
    fixed,
    variable,
    windows,
    windows
        .take(2)
        .map((e) => 'Una actividad o hábito breve puede encajar en $e')
        .toList(),
  );
}

String _clock(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
