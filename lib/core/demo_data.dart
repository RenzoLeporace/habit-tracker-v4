import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_espacio/features/finance/finance_repository.dart';
import 'package:mi_espacio/features/habits/data/datasources/habit_local_datasource.dart';
import 'package:mi_espacio/features/routine/routine_repository.dart';

/// Datos de ejemplo para que la demo muestre todas las secciones desde el primer ingreso.
///
/// Solo se cargan una vez, en una instalación sin datos. Desde el menú de datos se pueden
/// volver a cargar o borrar para empezar de cero.
class DemoData {
  static const _marca = 'demo_data_v1';

  static Future<void> cargarSiEsPrimeraVez({DateTime? hoy}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_marca) == true) return;

    final dia = _soloFecha(hoy ?? DateTime.now());
    if (!prefs.containsKey(LocalRoutineRepository.key)) {
      await prefs.setString(
        LocalRoutineRepository.key,
        jsonEncode(rutina(dia)),
      );
    }
    if (!prefs.containsKey(LocalFinanceRepository.storageKey)) {
      await prefs.setString(
        LocalFinanceRepository.storageKey,
        jsonEncode(finanzas(dia)),
      );
    }
    await prefs.setBool(_marca, true);
  }

  /// Vuelve a cargar los datos de ejemplo de todas las secciones.
  static Future<void> restaurar({DateTime? hoy}) async {
    await _borrarClaves();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_marca);
    await cargarSiEsPrimeraVez(hoy: hoy);
  }

  /// Borra todo y deja la app vacía, sin volver a cargar ejemplos.
  static Future<void> borrarTodo() async {
    await _borrarClaves();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marca, true);
    await prefs.setString(HabitLocalDataSource.storageKey, '[]');
  }

  static Future<void> _borrarClaves() async {
    final prefs = await SharedPreferences.getInstance();
    for (final clave in [
      HabitLocalDataSource.storageKey,
      LocalRoutineRepository.key,
      LocalFinanceRepository.storageKey,
    ]) {
      await prefs.remove(clave);
    }
    HabitLocalDataSource.reiniciarCache();
  }

  static Map<String, dynamic> rutina(DateTime hoy) {
    final actividades = <Activity>[];
    var id = 0;
    void agregar(
      DateTime dia,
      String nombre,
      String inicio,
      String fin,
      String categoria,
    ) => actividades.add(
      Activity(
        id: 'demo-a${id++}',
        name: nombre,
        start: inicio,
        end: fin,
        category: categoria,
        date: dia,
      ),
    );

    for (var atras = 6; atras >= 0; atras--) {
      final dia = hoy.subtract(Duration(days: atras));
      final habil = dia.weekday <= DateTime.friday;
      agregar(dia, 'Desayuno y lectura', '07:30', '08:15', 'personal');
      if (habil) {
        agregar(
          dia,
          'Trabajo',
          atras.isEven ? '09:00' : '09:15',
          '13:00',
          'trabajo',
        );
        agregar(dia, 'Almuerzo', '13:00', '14:00', 'personal');
        agregar(dia, 'Trabajo', '14:00', '17:30', 'trabajo');
      }
      if (dia.weekday == DateTime.monday ||
          dia.weekday == DateTime.wednesday ||
          dia.weekday == DateTime.friday) {
        agregar(dia, 'Gimnasio', '19:00', '20:15', 'salud');
      }
      if (dia.weekday == DateTime.tuesday || dia.weekday == DateTime.thursday) {
        agregar(dia, 'Curso de Flutter', '19:30', '21:00', 'estudio');
      }
      if (!habil) agregar(dia, 'Fútbol con amigos', '17:00', '19:00', 'ocio');
    }

    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    final tareas = [
      ('Pagar el alquiler', 0, true),
      ('Llamar al dentista', 0, true),
      ('Entregar el TP de base de datos', 1, true),
      ('Comprar regalo de cumpleaños', 2, false),
      ('Revisar el presupuesto del mes', 3, false),
      ('Ordenar el escritorio', 4, false),
      ('Preparar la semana', 6, false),
    ];
    return {
      'activities': actividades.map((e) => e.toJson()).toList(),
      'tasks': [
        for (var i = 0; i < tareas.length; i++)
          WeeklyTask(
            id: 'demo-t$i',
            text: tareas[i].$1,
            date: lunes.add(Duration(days: tareas[i].$2)),
            done: tareas[i].$3 && tareas[i].$2 < hoy.weekday,
          ).toJson(),
      ],
    };
  }

  static Map<String, dynamic> finanzas(DateTime hoy) {
    final movimientos = <Map<String, dynamic>>[];
    var id = 0;
    void agregar(
      int mesesAtras,
      int dia,
      String descripcion,
      String categoria,
      MovementType tipo,
      double monto,
    ) {
      final mes = DateTime(hoy.year, hoy.month - mesesAtras);
      final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;
      // En el mes actual, lo que todavía no ocurrió se registra hoy para que la demo lo muestre.
      final limite = mesesAtras == 0 ? hoy.day : ultimoDia;
      final fecha = DateTime(mes.year, mes.month, dia.clamp(1, limite));
      movimientos.add({
        'id': 'demo-m${id++}',
        'date': fecha.toIso8601String(),
        'description': descripcion,
        'category': categoria,
        'type': tipo.name,
        'amount': monto,
      });
    }

    for (final atras in [1, 0]) {
      agregar(atras, 1, 'Sueldo', 'Sueldo', MovementType.income, 1250000);
      agregar(atras, 3, 'Alquiler', 'Facturas', MovementType.expense, 420000);
      agregar(
        atras,
        4,
        'Supermercado',
        'Supermercado',
        MovementType.expense,
        96500,
      );
      agregar(atras, 5, 'Luz y gas', 'Servicios', MovementType.expense, 48300);
      agregar(
        atras,
        5,
        'Internet y celular',
        'Servicios',
        MovementType.expense,
        35900,
      );
      agregar(
        atras,
        8,
        'Fondo de emergencia',
        'Ahorros',
        MovementType.expense,
        150000,
      );
      agregar(
        atras,
        10,
        'Tarjeta de débito',
        'Débito',
        MovementType.expense,
        62000,
      );
      agregar(
        atras,
        12,
        'Salida con amigos',
        'Gastos personales',
        MovementType.expense,
        38000,
      );
      agregar(
        atras,
        14,
        'Proyecto freelance',
        'Otros ingresos',
        MovementType.income,
        180000,
      );
      agregar(
        atras,
        18,
        'Supermercado',
        'Supermercado',
        MovementType.expense,
        74200,
      );
      agregar(atras, 20, 'Farmacia', 'Farmacia', MovementType.expense, 21500);
    }

    final plan = {
      'Sueldo': 1250000.0,
      'Otros ingresos': 150000.0,
      'Servicios': 90000.0,
      'Supermercado': 180000.0,
      'Gastos personales': 60000.0,
      'Facturas': 420000.0,
      'Débito': 70000.0,
      'Ahorros': 150000.0,
    };
    return {
      'movements': movimientos,
      'categories': <Map<String, dynamic>>[],
      'plans': {
        for (final atras in [1, 0])
          for (final e in plan.entries)
            '${DateTime(hoy.year, hoy.month - atras).year}-${DateTime(hoy.year, hoy.month - atras).month}-${e.key}':
                e.value,
      },
      'savings': {
        for (var mes = 1; mes < hoy.month; mes++)
          '${hoy.year}-$mes-saving': 150000.0,
      },
    };
  }

  static DateTime _soloFecha(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);
}
