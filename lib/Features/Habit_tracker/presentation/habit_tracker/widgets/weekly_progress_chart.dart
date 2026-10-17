import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/habit_entity.dart';

class WeeklyProgressChart extends StatelessWidget {
  final List<HabitEntity> habits;
  final DateTime selectedDate;

  const WeeklyProgressChart({
    super.key,
    required this.habits,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Cálculo seguro de estadísticas semanales
    List<double> weeklyStats = List.generate(5, (index) {
      if (habits.isEmpty) return 0.0;

      int startDay = (index * 7) + 1;
      int endDay = (index + 1) * 7;
      int completed = 0;

      for (var h in habits) {
        completed += h.data.values
            .where(
              (e) =>
                  e.done &&
                  e.date.month == selectedDate.month &&
                  e.date.day >= startDay &&
                  e.date.day <= endDay,
            )
            .length;
      }

      // 2. Cálculo del ratio (Division entre doubles para evitar errores de tipo)
      double totalPossible = habits.length * 7.0;
      return (totalPossible > 0)
          ? (completed / totalPossible).clamp(0.0, 1.0)
          : 0.0;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bg2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PROGRESO SEMANAL",
            style: GoogleFonts.syne(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth < 220 ? 220 : constraints.maxWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    5,
                    (i) => _buildBar(weeklyStats[i], "S${i + 1}"),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double pct, String label) {
    // 3. Conversión explícita a int para el texto del porcentaje
    int percentText = (pct * 100).toInt();

    Color getBarColor(double pct) {
      if (pct >= 0.7) return AppColors.green;
      if (pct <= 0.3) return Colors.redAccent;
      return AppColors.amber;
    }

    return Column(
      children: [
        Text(
          "$percentText%",
          style: const TextStyle(color: AppColors.text2, fontSize: 10),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 85,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.bottomCenter,
            // 4. El factor de altura DEBE ser un double entre 0.0 y 1.0
            heightFactor: pct > 0 ? pct : 0.05,
            child: Container(
              decoration: BoxDecoration(
                color: pct > 0
                    ? getBarColor(pct)
                    : AppColors.border.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.text2, fontSize: 10),
        ),
      ],
    );
  }
}
