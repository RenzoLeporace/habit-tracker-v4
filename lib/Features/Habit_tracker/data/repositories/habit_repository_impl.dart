import 'package:habit_tracker_v4/Features/Habit_tracker/domain/repositories/habit_repository.dart';
import 'package:habit_tracker_v4/Features/Habit_tracker/domain/entities/habit_entity.dart';
import 'package:habit_tracker_v4/Features/Habit_tracker/data/datasources/habit_mock_datasource.dart';
import 'package:habit_tracker_v4/Features/Habit_tracker/data/models/habit.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitMockDataSource _dataSource = HabitMockDataSource();

  @override
  Future<List<HabitEntity>> getHabits() async {
    try {
      final models = await _dataSource.fetchHabits();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception("Error al obtener hábitos: $e");
    }
  }

  @override
  Future<void> saveHabit(HabitEntity habit) async {
    final habits = await _dataSource.fetchHabits();
    habits.removeWhere((e) => e.id == habit.id);
    habits.add(HabitModel(id: habit.id, name: habit.name, color: habit.color,
      data: habit.data.map((key, value) => MapEntry(key, HabitEntryModel(date: value.date, done: value.done, time: value.time)))));
    await _dataSource.updateHabits(habits);
  }

  @override
  Future<void> deleteHabit(int id) async {
    await _dataSource.deleteHabit(id);
  }
}
