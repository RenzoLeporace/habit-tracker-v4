import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_espacio/core/demo_data.dart';
import 'package:mi_espacio/core/format.dart';
import 'package:mi_espacio/features/finance/finance_repository.dart';
import 'package:mi_espacio/features/habits/data/datasources/habit_local_datasource.dart';
import 'package:mi_espacio/features/routine/routine_repository.dart';
import 'package:mi_espacio/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting(localeApp));
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HabitLocalDataSource.reiniciarCache();
  });

  group('Formatos', () {
    test('los importes usan separadores argentinos y el signo adelante', () {
      expect(formatoMoneda(1234.5), r'$ 1.234,50');
      expect(formatoMoneda(1250000), r'$ 1.250.000,00');
      expect(formatoMoneda(-180700), r'−$ 180.700,00');
    });

    test('nunca se muestra un cero negativo', () {
      expect(formatoMoneda(-0.0), r'$ 0,00');
      expect(formatoMoneda(-0.001), r'$ 0,00');
    });

    test('se entienden los importes escritos de distintas formas', () {
      expect(leerImporte('1.234,50'), 1234.5);
      expect(leerImporte(r'$ 1.250.000'), 1250000);
      expect(leerImporte('1234.5'), 1234.5);
      expect(leerImporte('1,234.50'), 1234.5);
      expect(leerImporte('1234,5'), 1234.5);
      expect(leerImporte('1.234'), 1234);
      expect(leerImporte('abc'), isNull);
      expect(leerImporte(''), isNull);
    });

    test('las fechas se muestran como dd/mm/aaaa', () {
      expect(formatoFecha(DateTime(2026, 3, 7)), '07/03/2026');
    });
  });

  group('Datos de ejemplo', () {
    final hoy = DateTime(2026, 11, 5);

    test('se cargan una sola vez y llenan rutina, tareas y finanzas', () async {
      await DemoData.cargarSiEsPrimeraVez(hoy: hoy);
      await DemoData.cargarSiEsPrimeraVez(hoy: hoy);

      final rutina = LocalRoutineRepository();
      final actividades = await rutina.activities();
      final tareas = await rutina.tasks();
      final finanzas = FinanceController(LocalFinanceRepository())
        ..selectedMonth = DateTime(2026, 11);
      await finanzas.load();

      expect(actividades, isNotEmpty);
      expect(
        actividades.map((e) => e.id).toSet(),
        hasLength(actividades.length),
      );
      expect(tareas, hasLength(7));
      expect(finanzas.totalIncome, greaterThan(0));
      expect(finanzas.monthEntries.every((e) => !e.date.isAfter(hoy)), isTrue);
      expect(finanzas.planned['Sueldo'], 1250000);
    });

    test('no pisan datos que el usuario ya tenía', () async {
      SharedPreferences.setMockInitialValues({
        LocalRoutineRepository.key: jsonEncode({'activities': [], 'tasks': []}),
      });
      await DemoData.cargarSiEsPrimeraVez(hoy: hoy);

      expect(await LocalRoutineRepository().activities(), isEmpty);
    });

    test('empezar de cero deja todas las secciones vacías', () async {
      await DemoData.cargarSiEsPrimeraVez(hoy: hoy);
      await DemoData.borrarTodo();

      expect(await LocalRoutineRepository().activities(), isEmpty);
      expect(await LocalFinanceRepository().movements(), isEmpty);
      expect(await HabitLocalDataSource().fetchHabits(), isEmpty);

      await DemoData.cargarSiEsPrimeraVez(hoy: hoy);
      expect(await LocalRoutineRepository().activities(), isEmpty);
    });

    test('se pueden volver a cargar después de borrar todo', () async {
      await DemoData.borrarTodo();
      await DemoData.restaurar(hoy: hoy);

      expect(await LocalRoutineRepository().activities(), isNotEmpty);
      expect(await HabitLocalDataSource().fetchHabits(), hasLength(3));
    });
  });

  group('Repositorios', () {
    test('dos pantallas que cargan a la vez no duplican los datos', () async {
      await DemoData.cargarSiEsPrimeraVez(hoy: DateTime(2026, 11, 5));
      final rutina = LocalRoutineRepository();
      final esperado =
          (jsonDecode(
                    (await SharedPreferences.getInstance()).getString(
                      LocalRoutineRepository.key,
                    )!,
                  )
                  as Map<String, dynamic>)['activities']
              as List;

      final resultados = await Future.wait([
        rutina.activities(),
        rutina.activities(),
        rutina.tasks(),
      ]);

      expect(resultados[0], hasLength(esperado.length));
      expect(resultados[1], hasLength(esperado.length));
    });

    test('los hábitos tampoco se duplican con cargas simultáneas', () async {
      final fuente = HabitLocalDataSource();
      final resultados = await Future.wait([
        fuente.fetchHabits(),
        fuente.fetchHabits(),
      ]);

      expect(resultados[0], hasLength(3));
      expect(resultados[1], hasLength(3));
    });

    test(
      'las categorías propias se guardan sin repetir las de la app',
      () async {
        await LocalFinanceRepository().saveCategory(
          const FinanceCategory('Mascotas', MovementType.expense),
        );
        await LocalFinanceRepository().saveCategory(
          const FinanceCategory('mascotas', MovementType.expense),
        );

        final categorias = await LocalFinanceRepository().categories();
        expect(
          categorias.where((e) => e.name.toLowerCase() == 'mascotas'),
          hasLength(1),
        );
        expect(categorias.where((e) => e.name == 'Sueldo'), hasLength(1));
        expect(
          categorias,
          hasLength(LocalFinanceRepository.categoriasBase.length + 1),
        );
      },
    );

    test('un movimiento borrado se puede recuperar', () async {
      final c = FinanceController(LocalFinanceRepository());
      await c.load();
      final movimiento = Movement(
        id: 'm1',
        date: c.selectedMonth,
        description: 'Supermercado',
        category: 'Supermercado',
        type: MovementType.expense,
        amount: 5000,
      );
      await c.add(movimiento);

      final borrado = await c.remove('m1');
      expect(c.monthEntries, isEmpty);

      await c.add(borrado!);
      expect(c.monthEntries.single.description, 'Supermercado');
    });

    test('los gastos por categoría se ordenan de mayor a menor', () async {
      final c = FinanceController(LocalFinanceRepository());
      await c.load();
      Future<void> gasto(String id, String categoria, double monto) => c.add(
        Movement(
          id: id,
          date: c.selectedMonth,
          description: categoria,
          category: categoria,
          type: MovementType.expense,
          amount: monto,
        ),
      );
      await gasto('1', 'Servicios', 100);
      await gasto('2', 'Supermercado', 300);
      await gasto('3', 'Servicios', 50);

      expect(c.expensesByCategory.map((e) => e.key), [
        'Supermercado',
        'Servicios',
      ]);
      expect(c.expensesByCategory.last.value, 150);
      expect(c.totalExpenses, 450);
    });
  });

  testWidgets('el botón de demo entra con la cuenta de demostración', (
    tester,
  ) async {
    String? usuario;
    String? clave;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (u, c) async {
            usuario = u;
            clave = c;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Probar la demo'));
    await tester.pump();

    expect(usuario, DemoAuthRepository.usuario);
    expect(clave, DemoAuthRepository.clave);
  });
}
