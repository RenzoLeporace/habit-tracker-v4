import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/habit.dart';

// ... imports ...

class HourlyPerformanceChart extends StatefulWidget {
  final List<HabitModel> habits;
  const HourlyPerformanceChart({super.key, required this.habits});

  @override
  State<HourlyPerformanceChart> createState() => _HourlyPerformanceChartState();
}

class _HourlyPerformanceChartState extends State<HourlyPerformanceChart> {
  int? selectedHabitId;

  // --- LÓGICA PARA CALCULAR LA MEJOR FRANJA ---
  Map<String, dynamic> _getBestSlot(HabitModel? habit) {
    if (habit == null || habit.data.isEmpty) {
      return {"name": "Sin datos", "emoji": "🌑", "range": "--"};
    }

    // Contadores para cada franja
    Map<String, int> slots = {
      "Madrugada": 0,
      "Mañana": 0,
      "Mediodía": 0,
      "Tarde": 0,
      "Noche": 0,
    };

    for (var entry in habit.data.values) {
      if (!entry.done) continue;
      int hour = int.parse(entry.time.split(":")[0]);

      if (hour >= 5 && hour < 9) {
        slots["Madrugada"] = slots["Madrugada"]! + 1;
      } else if (hour >= 9 && hour < 13)
        slots["Mañana"] = slots["Mañana"]! + 1;
      else if (hour >= 13 && hour < 16)
        slots["Mediodía"] = slots["Mediodía"]! + 1;
      else if (hour >= 16 && hour < 20)
        slots["Tarde"] = slots["Tarde"]! + 1;
      else
        slots["Noche"] = slots["Noche"]! + 1;
    }

    // Encontrar el máximo
    var bestEntry = slots.entries.reduce((a, b) => a.value >= b.value ? a : b);

    if (bestEntry.value == 0) {
      return {"name": "Sin actividad", "emoji": "☕", "range": "--"};
    }

    Map<String, String> emojis = {
      "Madrugada": "🌅",
      "Mañana": "☀️",
      "Mediodía": "🌤️",
      "Tarde": "🌇",
      "Noche": "🌙",
    };
    Map<String, String> ranges = {
      "Madrugada": "5-9hs",
      "Mañana": "9-13hs",
      "Mediodía": "13-16hs",
      "Tarde": "16-20hs",
      "Noche": "20-05hs",
    };

    return {
      "name": bestEntry.key,
      "emoji": emojis[bestEntry.key],
      "range": ranges[bestEntry.key],
    };
  }

  @override
  Widget build(BuildContext context) {
    // ELIMINAMOS el shrink() para que sea siempre visible
    final selectedHabit = widget.habits.isNotEmpty
        ? widget.habits.firstWhere(
            (h) => h.id == selectedHabitId,
            orElse: () => widget.habits.first,
          )
        : null;

    final bestSlot = _getBestSlot(selectedHabit);

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
            "RENDIMIENTO HORARIO",
            style: GoogleFonts.syne(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),

          if (widget.habits.isNotEmpty) ...[
            _buildSelector(),
            const SizedBox(height: 24),
            _buildBars(selectedHabit!),
            const SizedBox(height: 24),
            // TARJETA DINÁMICA
            _buildInsightCard(bestSlot),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Agregá un hábito para ver el análisis",
                  style: TextStyle(color: AppColors.text2, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: () {
          // 1. Extraemos de forma segura todos los IDs de hábitos que existen actualmente en este widget
          final List<int> validIds = widget.habits.map((h) => h.id).toList();

          // 2. Determinamos cuál sería el ID candidato a mostrarse
          final int? candidateId =
              selectedHabitId ??
              (widget.habits.isNotEmpty ? widget.habits.first.id : null);

          // 3. BLINDAJE: Si el candidato es válido, lo usamos. Si no, tomamos el primero disponible o null.
          final int? resolvedValue = validIds.contains(candidateId)
              ? candidateId
              : (validIds.isNotEmpty ? validIds.first : null);

          return DropdownButton<int>(
            value:
                resolvedValue, // Usamos el valor blindado que garantizadamente existe
            dropdownColor: AppColors.bg2,
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.text2),
            isExpanded: true,
            onChanged: (int? newValue) {
              setState(() {
                selectedHabitId = newValue;
              });
            },
            items: widget.habits.map<DropdownMenuItem<int>>((HabitModel habit) {
              return DropdownMenuItem<int>(
                value: habit.id,
                child: Text(
                  habit.name,
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                ),
              );
            }).toList(),
          );
        }(), // Invocamos la función anónima inmediatamente
      ),
    );
  }

  // --- GRÁFICO DE BARRAS (REINTEGRADO) ---
  Widget _buildBars(HabitModel habit) {
    // Definimos las franjas horarias
    final List<String> labels = [
      "5-8",
      "8-10",
      "10-12",
      "12-14",
      "14-17",
      "17-19",
      "19-21",
      "21-24",
    ];

    // Calculamos los datos reales del hábito
    Map<int, int> counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    for (var entry in habit.data.values) {
      if (!entry.done) continue;
      int hour = int.parse(entry.time.split(":")[0]);

      if (hour >= 5 && hour < 8) {
        counts[0] = counts[0]! + 1;
      } else if (hour >= 8 && hour < 10)
        counts[1] = counts[1]! + 1;
      else if (hour >= 10 && hour < 12)
        counts[2] = counts[2]! + 1;
      else if (hour >= 12 && hour < 14)
        counts[3] = counts[3]! + 1;
      else if (hour >= 14 && hour < 17)
        counts[4] = counts[4]! + 1;
      else if (hour >= 17 && hour < 19)
        counts[5] = counts[5]! + 1;
      else if (hour >= 19 && hour < 21)
        counts[6] = counts[6]! + 1;
      else if (hour >= 21 || hour < 5)
        counts[7] = counts[7]! + 1;
    }

    int maxVal = counts.values.reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth < 320 ? 320 : constraints.maxWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(labels.length, (i) {
              double val = counts[i]!.toDouble();
              double heightPct = maxVal > 0 ? (val / maxVal) : 0.05;

              return SizedBox(
                width: 36,
                child: Column(
                  children: [
                    if (val > 0)
                      Text(
                        "${val.toInt()}",
                        style: TextStyle(
                          color: habit.color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 12,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.border.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: heightPct.clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: val > 0
                                ? habit.color
                                : AppColors.border.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: val > 0
                                ? [
                                    BoxShadow(
                                      color: habit.color.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[i],
                      style: const TextStyle(
                        color: AppColors.text2,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> slot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(slot["emoji"], style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "${slot["name"]}: ${slot["range"]} es tu mejor franja.",
              style: const TextStyle(color: AppColors.text2, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
