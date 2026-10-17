import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/habit_mock_datasource.dart';
import '../../../data/models/habit.dart';
import '../../../../../core/theme/app_colors.dart';
import 'habit_state.dart';

class HabitCubit extends Cubit<HabitState> {
  final HabitMockDataSource _dataSource = HabitMockDataSource();

  HabitCubit() : super(HabitLoading());

Future<void> getHabits() async {
    if (state is HabitLoaded) return; 
    try {
      emit(HabitLoading());
      final data = await _dataSource.fetchHabits();
      
      // Creamos una fecha limpia: Año actual, Mes actual, Día 1.
      final DateTime today = DateTime.now();
      final DateTime cleanSelectedDate = DateTime(today.year, today.month, 1);

      emit(HabitLoaded(
        habits: data,
        selectedDate: cleanSelectedDate, // <-- Usamos la fecha normalizada
        focusedHabitId: data.isNotEmpty ? data.first.id : null,
      ));
    } catch (e) {
      emit(HabitError("No se pudieron cargar los hábitos"));
    }
  }

  void refreshData(List<HabitModel> updatedHabits) {
      _dataSource.updateHabits(List.from(updatedHabits));
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded; // <-- ¡Ahora sí la usamos abajo!
        emit(HabitLoaded(
          habits: List.from(updatedHabits),
          selectedDate: currentState.selectedDate, // Usada aquí
          focusedHabitId: currentState.focusedHabitId, // Usada aquí
        ));
      }
    }
  void changeFocus(int? id) {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      emit(HabitLoaded(
        habits: currentState.habits,
        selectedDate: currentState.selectedDate,
        focusedHabitId: id,
      ));
    }
  }

  void deleteHabit(int id, List<HabitModel> currentHabits) {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      currentHabits.removeWhere((h) => h.id == id);
      _dataSource.updateHabits(List.from(currentHabits));
      int? newFocus = currentState.focusedHabitId == id ? null : currentState.focusedHabitId;
      emit(HabitLoaded(
        habits: List.from(currentHabits),
        selectedDate: currentState.selectedDate,
        focusedHabitId: newFocus,
      ));
    }
  }
void changeMonth(BuildContext context) {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      
      // Variables temporales para capturar la selección del usuario dentro del diálogo
      int selectedYear = currentState.selectedDate.year;
      int selectedMonth = currentState.selectedDate.month;

      List<String> meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];

      showDialog(
        context: context,
        builder: (dialogContext) {
          // Usamos un StatefulBuilder para que la grilla del diálogo se redibuje 
          // localmente cuando el usuario cambie el año o el mes sin tocar la pantalla de fondo.
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: AppColors.bg2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_left, color: AppColors.text),
                      onPressed: () => setDialogState(() => selectedYear--),
                    ),
                    Text(
                      "$selectedYear",
                      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_right, color: AppColors.text),
                      onPressed: () => setDialogState(() => selectedYear++),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 300,
                  height: 220,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // 4 columnas de meses
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      int monthNumber = index + 1;
                      bool isCurrent = monthNumber == selectedMonth;

                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedMonth = monthNumber;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent ? Colors.transparent : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            meses[index],
                            style: TextStyle(
                              color: isCurrent ? Colors.black : AppColors.text,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("CANCELAR", style: TextStyle(color: AppColors.text2)),
                  ),
                  TextButton(
                    onPressed: () {
                      // 1. Cerramos el diálogo de forma prolija
                      Navigator.pop(dialogContext);

                      // 2. Normalizamos la fecha al día 1 del mes/año elegidos
                      final newCleanDate = DateTime(selectedYear, selectedMonth, 1);

                      // 3. Emitimos el nuevo estado para queHomeScreen reaccione
                      emit(HabitLoaded(
                        habits: currentState.habits,
                        selectedDate: newCleanDate,
                        focusedHabitId: currentState.focusedHabitId,
                      ));
                    },
                    child: const Text("ACEPTAR", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  void showAddHabitDialog(BuildContext context, List<HabitModel> currentHabits) {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      String name = "";
      
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog( // Renombramos a dialogContext para evitar confusiones
          backgroundColor: AppColors.bg2,
          title: const Text("Nuevo Hábito", style: TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => name = v,
            decoration: const InputDecoration(hintText: "Nombre...", hintStyle: TextStyle(color: Colors.white24)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  List<Color> palette = [AppColors.amber, AppColors.green, Colors.blueAccent, Colors.pinkAccent, Colors.purpleAccent];
                  
                  final newHabit = HabitModel(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: name,
                    color: palette[currentHabits.length % palette.length],
                    data: {},
                  );
                  
                  currentHabits.add(newHabit);
                  _dataSource.updateHabits(List.from(currentHabits));

                  // 1. CERRAR EL DIÁLOGO PRIMERO: Limpiamos el overlay de la pantalla
                  Navigator.pop(dialogContext);

                  // 2. EMITIR EL ESTADO DESPUÉS: Forzamos el redibujado limpio de la UI de fondo
                  emit(HabitLoaded(
                    habits: List.from(currentHabits),
                    selectedDate: currentState.selectedDate,
                    focusedHabitId: newHabit.id,
                  ));
                } else {
                  // Si está vacío, solo cerramos el diálogo
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Crear", style: TextStyle(color: AppColors.green)),
            ),
          ],
        ),
      );
    }
  }
}
