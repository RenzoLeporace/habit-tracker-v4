import '../entities/habit_entity.dart';

class CalculateGlobalStreakUseCase {
  int execute(List<HabitEntity> habits) {
    if (habits.isEmpty) return 0;

    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    Set<String> doneDates = {};

    for (var h in habits) {
      h.data.forEach((key, entry) { 
        if (entry.done) {
          doneDates.add("${entry.date.year}-${entry.date.month}-${entry.date.day}");
        }
      });
    }
    
    return _calculateContinuity(doneDates, today);
  }

  int _calculateContinuity(Set<String> dates, DateTime today) {
    if (dates.isEmpty) return 0;

    String todayKey = "${today.year}-${today.month}-${today.day}";
    String yesterdayKey = "${today.subtract(const Duration(days: 1)).year}-${today.subtract(const Duration(days: 1)).month}-${today.subtract(const Duration(days: 1)).day}";
    
    if (!dates.contains(todayKey) && !dates.contains(yesterdayKey)) return 0;
    
    int count = 0;
    DateTime checkDate = dates.contains(todayKey) ? today : today.subtract(const Duration(days: 1));
    
    while (dates.contains("${checkDate.year}-${checkDate.month}-${checkDate.day}")) {
      count++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return count;
  }
}