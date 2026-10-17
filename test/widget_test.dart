import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker_v4/main.dart';
import 'package:habit_tracker_v4/Features/finance/finance_repository.dart';
import 'package:habit_tracker_v4/Features/routine/routine_repository.dart';
import 'package:habit_tracker_v4/Features/routine/routine_screens.dart';
import 'package:habit_tracker_v4/Features/Habit_tracker/presentation/habit_tracker/widgets/hourly_performance_chart.dart';
import 'package:habit_tracker_v4/Features/Habit_tracker/data/models/habit.dart';
import 'package:habit_tracker_v4/Features/Habit_tracker/presentation/habit_tracker/cubit/habit_cubit.dart';
import 'package:habit_tracker_v4/Features/Habit_tracker/presentation/habit_tracker/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('finance follows the workbook allocation rules', () async {
    final c = FinanceController(LocalFinanceRepository());
    await c.load();
    final month = c.selectedMonth;
    Future<void> add(String category, MovementType type, double amount) =>
        c.add(
          Movement(
            id: '$category-$amount',
            date: month,
            description: category,
            category: category,
            type: type,
            amount: amount,
          ),
        );
    await add('Sueldo', MovementType.income, 1000);
    await add('Servicios', MovementType.expense, 100);
    await add('Supermercado', MovementType.expense, 80);
    await add('Gastos personales', MovementType.expense, 20);
    await add('Facturas', MovementType.expense, 50);
    await add('Ahorros', MovementType.expense, 75);
    await add('Débito', MovementType.expense, 25);
    await add('Farmacia', MovementType.expense, 10);
    expect(c.operating, 200);
    expect(c.remaining, 650);
    await c.setSaving(1, 40);
    await c.setSaving(2, 60);
    await c.changeMonth(2 - c.selectedMonth.month);
    expect(c.accumulatedSavings, 100);
  });

  test('demo credentials authenticate', () async {
    final auth = DemoAuthRepository();
    expect(await auth.signIn('demo', 'demo123'), isTrue);
    expect(await auth.signIn('demo', 'bad'), isFalse);
  });

  test('routine finds recurring blocks and free windows', () {
    final date = DateTime(2026, 10, 16);
    final items = [
      Activity(
        id: '1',
        name: 'Trabajo',
        start: '09:00',
        end: '12:00',
        category: 'trabajo',
        date: date,
      ),
      Activity(
        id: '2',
        name: 'Trabajo',
        start: '09:15',
        end: '12:00',
        category: 'trabajo',
        date: date.subtract(const Duration(days: 1)),
      ),
    ];
    final result = analyzeRoutine(items, date: date);
    expect(result.fixed, hasLength(1));
    expect(result.freeWindows.first, contains('06:00–09:00'));
  });

  test('weekly task changes day and persists', () async {
    final repo = LocalRoutineRepository();
    final c = RoutineController(repo);
    await c.load();
    final monday = c.weekDays.first;
    final tuesday = c.weekDays[1];
    final task = WeeklyTask(id: 'task-1', text: 'Comprar', date: monday);
    await c.addTask(task);
    await c.toggleTask(task);
    expect(c.tasksOn(monday).single.done, isTrue);
    await c.moveTask(c.tasksOn(monday).single, tuesday);
    expect(c.tasksOn(monday), isEmpty);
    expect(c.tasksOn(tuesday).single.done, isFalse);
    final reloaded = RoutineController(LocalRoutineRepository());
    await reloaded.load();
    expect(reloaded.tasksOn(tuesday).single.text, 'Comprar');
  });

  testWidgets('hourly chart fits a narrow card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 210,
            child: HourlyPerformanceChart(
              habits: [
                HabitModel(
                  id: 1,
                  name: 'Agua',
                  color: Colors.green,
                  data: {
                    '2026-10-16': HabitEntryModel(
                      date: DateTime(2026, 10, 16),
                      done: true,
                      time: '09:00',
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly tasks fit a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyTasksScreen(
          controller: RoutineController(LocalRoutineRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('habit overview fits mobile and places insights below the grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => HabitCubit(),
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('MIS HÁBITOS'), findsOneWidget);
    expect(find.text('RENDIMIENTO HORARIO'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('RENDIMIENTO HORARIO')).dy,
      greaterThan(tester.getTopLeft(find.text('MIS HÁBITOS')).dy),
    );
  });

  testWidgets('habit insights form two columns on desktop', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: BlocProvider(
      create: (_) => HabitCubit(), child: const HomeScreen(),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final hourly = tester.getTopLeft(find.text('RENDIMIENTO HORARIO'));
    final weekly = tester.getTopLeft(find.text('PROGRESO SEMANAL'));
    final grid = tester.getTopLeft(find.text('MIS HÁBITOS'));
    expect(hourly.dy, greaterThan(grid.dy));
    expect((hourly.dy - weekly.dy).abs(), lessThan(2));
    expect(weekly.dx, greaterThan(hourly.dx));
  });
}
