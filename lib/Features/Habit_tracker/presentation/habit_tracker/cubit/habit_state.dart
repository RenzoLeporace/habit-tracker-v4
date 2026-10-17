import '../../../data/models/habit.dart';

abstract class HabitState {}

class HabitLoading extends HabitState {}

class HabitLoaded extends HabitState {
  final List<HabitModel> habits;
  final DateTime selectedDate;
  final int? focusedHabitId;

  HabitLoaded({
    required this.habits,
    required this.selectedDate,
    this.focusedHabitId,
  });
}

class HabitError extends HabitState {
  final String message;
  HabitError(this.message);
}