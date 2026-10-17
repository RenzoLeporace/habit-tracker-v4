import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/habit_entity.dart';

class HabitProgressSidebar extends StatelessWidget {
  final List<HabitEntity> habits;
  final int daysInMonth;
  final int month;

  const HabitProgressSidebar({
    super.key, 
    required this.habits, 
    required this.daysInMonth,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Text("Sin datos", style: TextStyle(color: AppColors.text2, fontSize: 12));
    }
    
    return Column(
      children: habits.map((h) {
        double pct = (h.data.values.where((e) => e.done && e.date.month == month).length / daysInMonth);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(child: Text(h.name, style: const TextStyle(fontSize: 12, color: AppColors.text), overflow: TextOverflow.ellipsis)),
              Container(
                width: 80, height: 6,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(decoration: BoxDecoration(color: h.color, borderRadius: BorderRadius.circular(4))),
                ),
              ),
              const SizedBox(width: 8),
              Text("${(pct * 100).toStringAsFixed(0)}%", 
                style: TextStyle(color: h.color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}