import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/habit.dart';

class HabitRow extends StatelessWidget {
  final HabitModel habit;
  final DateTime selectedDate;
  final bool isFocused;
  final int daysInMonth;
  final Function(int?) onFocusChanged;
  final Function() onDataChanged;
  final Function(int) onDelete;

  const HabitRow({
    super.key,
    required this.habit,
    required this.selectedDate,
    required this.isFocused,
    required this.daysInMonth,
    required this.onFocusChanged,
    required this.onDataChanged,
    required this.onDelete,
  });
  void _showEditDeleteDialog(BuildContext context) {
  TextEditingController editController = TextEditingController(text: habit.name);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bg2,
      title: const Text("Gestionar Hábito", style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: editController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: "Nombre del hábito", labelStyle: TextStyle(color: AppColors.green)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Lógica para borrar (necesitarás pasar una función onDelete al widget)
            onDelete(habit.id);
            Navigator.pop(context);
          },
          child: const Text("BORRAR", style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () {
            habit.name = editController.text;
            onDataChanged();
            Navigator.pop(context);
          },
          child: const Text("GUARDAR"),
        ),
      ],
    ),
  );
}
  // FUNCIÓN CRÍTICA: Llama al reloj del sistema
Future<void> _internalSelectTime(BuildContext context, String key) async {
  final TimeOfDay now = TimeOfDay.now(); // Hora actual del sistema
  
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: now,
    builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
  );

  if (picked != null) {
    if (!context.mounted) return;
    // 1. Validamos si el día seleccionado es HOY
    DateTime cellDate = DateTime(selectedDate.year, selectedDate.month, int.parse(key.split("-")[2]));
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    bool isToday = cellDate.isAtSameMomentAs(today);

    // 2. Si es hoy, comparamos la hora elegida con la hora actual
    if (isToday) {
      // Convertimos todo a minutos para una comparación simple
      int pickedMinutes = picked.hour * 60 + picked.minute;
      int nowMinutes = now.hour * 60 + now.minute;

      if (pickedMinutes > nowMinutes) {
        // Bloqueamos el guardado si la hora es futura
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No puedes marcar una hora que aún no ha pasado ⏳"),
            backgroundColor: Colors.orange,
          ),
        );
        return; 
      }
    }
    final String formattedTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
    habit.data[key] = HabitEntryModel(
      date: cellDate,
      done: true,
      time: formattedTime,
    );
    onDataChanged();
  }
}

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Nombre del Hábito
        GestureDetector(
          onTap: () => onFocusChanged(isFocused ? null : habit.id),
          onLongPress: () => _showEditDeleteDialog(context),
          child: Container(
            width: 150, height: 70,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isFocused ? habit.color.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: isFocused ? BorderRadius.circular(8) : null,
              border: const Border(
                right: BorderSide(color: AppColors.border, width: 0.5),
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Text(
              habit.name,
              style: TextStyle(
                color: isFocused ? habit.color : AppColors.text,
                fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),

        // Grilla de días
        ...List.generate(daysInMonth, (i) {
          final String key = "${selectedDate.year}-${selectedDate.month}-${i + 1}";
          final bool done = habit.data[key]?.done ?? false;
          DateTime cellDate = DateTime(selectedDate.year, selectedDate.month, i + 1);
          DateTime today = DateTime.now();
          DateTime justToday = DateTime(today.year, today.month, today.day);
          bool isFuture = cellDate.isAfter(justToday);

          return GestureDetector(
            onTap: () {
                  if (isFuture) return; // Ahora sí la reconoce
                  habit.data[key] = HabitEntryModel(
                    date: cellDate,
                    done: !done,
                    time: !done ? "08:00" : "--:--",
                  );
                  onDataChanged();
                },     
            onLongPress: () => isFuture ? null : _internalSelectTime(context, key),
            child: Opacity(
              opacity: isFuture ? 0.3 : 1.0,
              child: Container(
                width: 45, height: 70,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.05), width: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  color: done ? habit.color.withValues(alpha: 0.05) : Colors.transparent,
                ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${i + 1}", style: TextStyle(fontSize: 7, color: AppColors.text2.withValues(alpha: 0.3))),
                  const SizedBox(height: 4),
                  Icon(
                    done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: done ? habit.color : AppColors.border.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  if (done)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        habit.data[key]?.time ?? "08:00",
                        style: const TextStyle(fontSize: 7, color: AppColors.text2, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              ) 
            ),
          );
        }),
        
      ],
    );
  }
}
