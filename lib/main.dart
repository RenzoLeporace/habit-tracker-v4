import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mi_espacio/core/demo_data.dart';
import 'package:mi_espacio/core/format.dart';
import 'package:mi_espacio/core/theme/app_colors.dart';
import 'package:mi_espacio/core/theme/app_theme.dart';
import 'package:mi_espacio/features/finance/finance_repository.dart';
import 'package:mi_espacio/features/finance/finance_screen.dart';
import 'package:mi_espacio/features/habits/presentation/cubit/habit_cubit.dart';
import 'package:mi_espacio/features/habits/presentation/screens/home_screen.dart';
import 'package:mi_espacio/features/routine/routine_repository.dart';
import 'package:mi_espacio/features/routine/routine_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(localeApp);
  await DemoData.cargarSiEsPrimeraVez();
  runApp(const MyApp());
}

abstract class AuthRepository {
  Future<bool> signIn(String username, String password);
  Future<void> signOut();
}

/// Acceso local de demostración. No protege datos: reemplazalo por un servicio de identidad real.
class DemoAuthRepository implements AuthRepository {
  static const usuario = 'demo';
  static const clave = 'demo123';

  @override
  Future<bool> signIn(String username, String password) async =>
      username.trim() == usuario && password == clave;

  @override
  Future<void> signOut() async {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mi espacio',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.oscuro(),
    locale: const Locale('es', 'AR'),
    supportedLocales: const [Locale('es', 'AR'), Locale('es')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
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

class _Seccion {
  final String titulo;
  final String corto;
  final IconData icono;
  final IconData iconoActivo;
  const _Seccion(this.titulo, this.corto, this.icono, this.iconoActivo);
}

const _secciones = [
  _Seccion(
    'Hábitos',
    'Hábitos',
    Icons.check_circle_outline,
    Icons.check_circle,
  ),
  _Seccion('Mi día a día', 'Mi día', Icons.today_outlined, Icons.today),
  _Seccion(
    'Tareas semanales',
    'Tareas',
    Icons.view_week_outlined,
    Icons.view_week,
  ),
  _Seccion(
    'Finanzas',
    'Finanzas',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet,
  ),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AuthRepository auth = DemoAuthRepository();
  late FinanceController finance;
  late RoutineController routine;
  late HabitCubit habits;
  var _generacion = 0;
  bool signedIn = false;
  int page = 0;

  @override
  void initState() {
    super.initState();
    _crearControladores();
    _abrirDesdeEnlace();
  }

  /// En la web, `?demo` entra directo a la demo y `&seccion=rutina|tareas|finanzas` abre esa sección.
  void _abrirDesdeEnlace() {
    if (!kIsWeb) return;
    final parametros = Uri.base.queryParameters;
    if (!parametros.containsKey('demo')) return;
    signedIn = true;
    page = switch (parametros['seccion']) {
      'rutina' => 1,
      'tareas' => 2,
      'finanzas' => 3,
      _ => 0,
    };
  }

  void _crearControladores() {
    finance = FinanceController(LocalFinanceRepository());
    routine = RoutineController(LocalRoutineRepository());
    habits = HabitCubit();
  }

  void _liberarControladores() {
    finance.dispose();
    routine.dispose();
    habits.close();
  }

  @override
  void dispose() {
    _liberarControladores();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    await auth.signOut();
    if (mounted) setState(() => signedIn = false);
  }

  /// Ofrece volver a cargar los datos de ejemplo o empezar de cero.
  Future<void> _gestionarDatos() async {
    final opcion = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tus datos'),
        content: const SizedBox(
          width: 420,
          child: Text(
            'Los datos se guardan solo en este dispositivo. Podés volver a cargar los ejemplos '
            'para recorrer la app o borrar todo para empezar con tus propios hábitos, '
            'actividades y movimientos.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'borrar'),
            child: const Text('Empezar de cero'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'ejemplos'),
            child: const Text('Cargar ejemplos'),
          ),
        ],
      ),
    );
    if (opcion == null) return;

    if (opcion == 'borrar') {
      await DemoData.borrarTodo();
    } else {
      await DemoData.restaurar();
    }
    if (!mounted) return;
    setState(() {
      _liberarControladores();
      _crearControladores();
      _generacion++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opcion == 'borrar'
              ? 'Se borraron todos los datos.'
              : 'Se cargaron los datos de ejemplo.',
        ),
      ),
    );
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

    final ancho = MediaQuery.sizeOf(context).width >= 800;
    final contenido = KeyedSubtree(
      key: ValueKey(_generacion),
      child: IndexedStack(
        index: page,
        children: [
          BlocProvider.value(value: habits, child: const HomeScreen()),
          RoutineScreen(controller: routine),
          WeeklyTasksScreen(controller: routine),
          FinanceScreen(controller: finance),
        ],
      ),
    );

    return Scaffold(
      appBar: ancho
          ? null
          : AppBar(
              backgroundColor: AppColors.bg2,
              title: Text(_secciones[page].titulo),
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (v) =>
                      v == 'datos' ? _gestionarDatos() : _cerrarSesion(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'datos', child: Text('Tus datos')),
                    PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
                  ],
                ),
              ],
            ),
      body: Row(
        children: [
          if (ancho) _menuLateral(),
          Expanded(child: contenido),
        ],
      ),
      bottomNavigationBar: ancho
          ? null
          : NavigationBar(
              selectedIndex: page,
              onDestinationSelected: (v) => setState(() => page = v),
              destinations: [
                for (final s in _secciones)
                  NavigationDestination(
                    icon: Icon(s.icono),
                    selectedIcon: Icon(s.iconoActivo),
                    label: s.corto,
                  ),
              ],
            ),
    );
  }

  Widget _menuLateral() => Container(
    width: 232,
    decoration: const BoxDecoration(
      color: AppColors.bg2,
      border: Border(right: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/icono.png',
                    width: 36,
                    height: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi espacio',
                      style: GoogleFonts.syne(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const Text(
                      'Hábitos, rutina y finanzas',
                      style: TextStyle(color: AppColors.text2, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (var i = 0; i < _secciones.length; i++) _opcion(i),
          const Spacer(),
          _accion(Icons.storage_outlined, 'Tus datos', _gestionarDatos),
          _accion(Icons.logout, 'Cerrar sesión', _cerrarSesion),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );

  Widget _opcion(int indice) {
    final seccion = _secciones[indice];
    final activa = page == indice;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: activa ? AppColors.greenDark : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => page = indice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  activa ? seccion.iconoActivo : seccion.icono,
                  size: 20,
                  color: activa ? AppColors.green : AppColors.text2,
                ),
                const SizedBox(width: 14),
                Text(
                  seccion.titulo,
                  style: TextStyle(
                    color: activa ? AppColors.green : AppColors.text,
                    fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accion(IconData icono, String texto, VoidCallback alTocar) =>
      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 26),
        leading: Icon(icono, size: 20, color: AppColors.text2),
        title: Text(texto, style: const TextStyle(color: AppColors.text2)),
        onTap: alTocar,
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
  bool verClave = false;
  String? error;

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> submit([String? usuario, String? clave]) async {
    setState(() {
      busy = true;
      error = null;
    });
    final ok = await widget.onLogin(usuario ?? user.text, clave ?? pass.text);
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/icono.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Mi espacio',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syne(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tus hábitos, tu rutina y tus finanzas en un solo lugar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.text2),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: user,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pass,
                    obscureText: !verClave,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: verClave
                            ? 'Ocultar contraseña'
                            : 'Mostrar contraseña',
                        onPressed: () => setState(() => verClave = !verClave),
                        icon: Icon(
                          verClave
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: const Text('Ingresar'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => submit(
                            DemoAuthRepository.usuario,
                            DemoAuthRepository.clave,
                          ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Probar la demo'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Cuenta de demostración: demo / demo123',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.text2, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
