import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/habit_entity.dart';

class HabitHeatmap extends StatelessWidget {
  final List<HabitEntity> habits;
  final int daysInMonth;
  final DateTime selectedDate;

  const HabitHeatmap({
    super.key, 
    required this.habits, 
    required this.daysInMonth, 
    required this.selectedDate
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, 
        mainAxisSpacing: 6, 
        crossAxisSpacing: 6
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, i) {
        int day = i + 1;
        String dateStr = "${day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}";
        
        int countDone = habits.where((h) => 
          h.data["${selectedDate.year}-${selectedDate.month}-$day"]?.done ?? false
        ).length;
        
        double opacity = (countDone / (habits.isEmpty ? 1 : habits.length)).clamp(0.1, 1.0);

        return Tooltip(
          message: dateStr,
          triggerMode: TooltipTriggerMode.tap,
          child: Container(
            decoration: BoxDecoration(
              color: countDone > 0 ? AppColors.green.withValues(alpha: opacity) : AppColors.border.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}