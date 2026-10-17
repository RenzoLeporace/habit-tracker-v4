import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Features/Habit_tracker/presentation/habit_tracker/cubit/habit_cubit.dart';
import 'Features/Habit_tracker/presentation/habit_tracker/screens/home_screen.dart';
import 'Features/finance/finance_repository.dart';
import 'Features/finance/finance_screen.dart';
import 'Features/routine/routine_repository.dart';
import 'Features/routine/routine_screens.dart';
import 'core/theme/app_colors.dart';

void main() => runApp(const MyApp());

abstract class AuthRepository {
  Future<bool> signIn(String username, String password);
  Future<void> signOut();
}

class DemoAuthRepository implements AuthRepository {
  @override
  Future<bool> signIn(String username, String password) async =>
      username.trim() == 'demo' && password == 'demo123';
  @override
  Future<void> signOut() async {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mi espacio',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(primary: AppColors.green),
    ),
    scrollBehavior: const MaterialScrollBehavior().copyWith(
      dragDevices: {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
      },
    ),
    home: const AppShell(),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AuthRepository auth = DemoAuthRepository();
  final FinanceController finance = FinanceController(LocalFinanceRepository());
  final RoutineController routine = RoutineController(LocalRoutineRepository());
  final HabitCubit habits = HabitCubit();
  bool signedIn = false;
  int page = 0;
  @override
  void dispose() {
    finance.dispose();
    routine.dispose();
    habits.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!signedIn) {
      return LoginScreen(
        onLogin: (user, pass) async {
          final ok = await auth.signIn(user, pass);
          if (ok && mounted) setState(() => signedIn = true);
          return ok;
        },
      );
    }
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final content = IndexedStack(
      index: page,
      children: [
        BlocProvider.value(value: habits, child: const HomeScreen()),
        RoutineScreen(controller: routine),
        WeeklyTasksScreen(controller: routine),
        FinanceScreen(controller: finance),
      ],
    );
    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              title: Text(
                [
                  'Hábitos',
                  'Mi día a día',
                  'Tareas semanales',
                  'Finanzas',
                ][page],
              ),
              actions: [
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: () async {
                    await auth.signOut();
                    if (mounted) setState(() => signedIn = false);
                  },
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
      body: Row(
        children: [
          if (wide)
            Container(
              width: 220,
              color: AppColors.bg2,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'MI ESPACIO',
                        style: TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    _nav('Hábitos', Icons.check_circle_outline, 0),
                    _nav('Mi día a día', Icons.today_outlined, 1),
                    _nav('Tareas semanales', Icons.view_week_outlined, 2),
                    _nav('Finanzas', Icons.account_balance_wallet_outlined, 3),
                    const Spacer(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Cerrar sesión'),
                      onTap: () async {
                        await auth.signOut();
                        if (mounted) setState(() => signedIn = false);
                      },
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: page,
              onDestinationSelected: (v) => setState(() => page = v),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.check_circle_outline),
                  label: 'Hábitos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.today_outlined),
                  label: 'Mi día',
                ),
                NavigationDestination(
                  icon: Icon(Icons.view_week_outlined),
                  label: 'Tareas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Finanzas',
                ),
              ],
            ),
    );
  }

  Widget _nav(String title, IconData icon, int index) => ListTile(
    selected: page == index,
    selectedColor: AppColors.green,
    leading: Icon(icon),
    title: Text(title),
    onTap: () => setState(() => page = index),
  );
}

class LoginScreen extends StatefulWidget {
  final Future<bool> Function(String, String) onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final user = TextEditingController();
  final pass = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    final ok = await widget.onLogin(user.text, pass.text);
    if (mounted) {
      setState(() {
        busy = false;
        if (!ok) error = 'Usuario o contraseña incorrectos';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppColors.green,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Mi espacio',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: user,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                ),
                TextField(
                  controller: pass,
                  obscureText: true,
                  onSubmitted: (_) => submit(),
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: const Text('Ingresar'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Acceso de demostración: demo / demo123',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text2, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
