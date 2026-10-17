import '../entities/habit_entity.dart';

/// Contrato del repositorio para la gestión de hábitos en la capa de Dominio.
/// Define las operaciones que los Casos de Uso pueden ejecutar.
abstract class HabitRepository {
  
  /// Recupera la lista completa de hábitos del usuario.
  Future<List<HabitEntity>> getHabits();

  /// Guarda un hábito nuevo o actualiza uno existente.
  Future<void> saveHabit(HabitEntity habit);

  /// Elimina un hábito de forma permanente mediante su ID.
  Future<void> deleteHabit(int id);
}