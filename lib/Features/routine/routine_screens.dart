import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'routine_repository.dart';

const categoryNames = {
  'trabajo': '💼 Trabajo',
  'personal': '🏠 Personal',
  'salud': '💪 Salud',
  'estudio': '📚 Estudio',
  'ocio': '🎮 Ocio',
  'otro': '📌 Otro',
};
const categoryColors = {
  'trabajo': Color(0xFF60A5FA),
  'personal': Color(0xFFC084FC),
  'salud': AppColors.green,
  'estudio': AppColors.amber,
  'ocio': Color(0xFFF472B6),
  'otro': Color(0xFF71717A),
};
String shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
Widget panel(String title, Widget body) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.bg2,
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(18),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.toUpperCase(),
        style: GoogleFonts.syne(
          color: AppColors.text2,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      const Divider(height: 24),
      body,
    ],
  ),
);

class RoutineScreen extends StatefulWidget {
  final RoutineController controller;
  const RoutineScreen({super.key, required this.controller});
  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  RoutineController get c => widget.controller;
  String scope = 'week';
  RoutineAnalysis? result;
  @override
  void initState() {
    super.initState();
    c.addListener(_refresh);
    c.load();
  }

  @override
  void dispose() {
    c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> addActivity() async {
    final name = TextEditingController();
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0),
        end = const TimeOfDay(hour: 10, minute: 0);
    String category = 'trabajo';
    String? error;
    final item = await showDialog<Activity>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Nueva actividad'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Actividad'),
                ),
                TextButton(
                  onPressed: () async {
                    final v = await showTimePicker(
                      context: ctx,
                      initialTime: start,
                    );
                    if (v != null) update(() => start = v);
                  },
                  child: Text('Inicio: ${start.format(ctx)}'),
                ),
                TextButton(
                  onPressed: () async {
                    final v = await showTimePicker(
                      context: ctx,
                      initialTime: end,
                    );
                    if (v != null) update(() => end = v);
                  },
                  child: Text('Fin: ${end.format(ctx)}'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: categoryNames.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => update(() => category = v!),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final from = start.hour * 60 + start.minute,
                    to = end.hour * 60 + end.minute;
                if (name.text.trim().isEmpty || to <= from) {
                  update(
                    () => error =
                        'Completá el nombre y elegí un fin posterior al inicio.',
                  );
                  return;
                }
                String fmt(TimeOfDay t) =>
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                Navigator.pop(
                  ctx,
                  Activity(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name.text.trim(),
                    start: fmt(start),
                    end: fmt(end),
                    category: category,
                    date: c.selectedDay,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    if (item != null) await c.addActivity(item);
  }

  void analyze() {
    final now = DateTime.now();
    final selected = c.activities.where((e) {
      if (scope == 'all') return true;
      if (scope == 'day') return dayKey(e.date) == dayKey(c.selectedDay);
      final diff = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(e.date.year, e.date.month, e.date.day)).inDays;
      return diff >= 0 && diff <= 6;
    }).toList();
    setState(() => result = analyzeRoutine(selected, date: c.selectedDay));
  }

  Widget analysis() {
    if (result == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 46),
        child: Center(
          child: Text(
            'Cargá tus actividades y tocá “Analizar mi rutina”.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text2),
          ),
        ),
      );
    }
    if (result!.fixed.isEmpty && result!.variable.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No hay actividades en el período seleccionado.',
          style: TextStyle(color: AppColors.text2),
        ),
      );
    }
    Widget group(String label, List<String> items) => Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Text(
              'Sin datos suficientes',
              style: TextStyle(color: AppColors.text2),
            ),
          for (final e in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '• $e',
                style: const TextStyle(color: AppColors.text2),
              ),
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        group('Bloques fijos · repetidos con horario estable', result!.fixed),
        group('Actividades variables', result!.variable),
        group('Ventanas libres del día seleccionado', result!.freeWindows),
        group('Sugerencias', result!.suggestions),
      ],
    );
  }

  Widget timeline() {
    final acts = c.dayActivities;
    return SizedBox(
      height: 540,
      child: SingleChildScrollView(
        child: SizedBox(
          height: 540,
          child: Stack(
            children: [
              for (var h = 6; h < 24; h++)
                Positioned(
                  top: (h - 6) * 30.0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Text(
                          '${h.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(
                            color: AppColors.text2,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
              for (final a in acts)
                if (minuteOf(a.end) > 360 && minuteOf(a.start) < 1440)
                  Positioned(
                    top: ((minuteOf(a.start).clamp(360, 1440) - 360) / 2)
                        .toDouble(),
                    left: 48,
                    right: 4,
                    height:
                        ((minuteOf(a.end).clamp(360, 1440) -
                                    minuteOf(a.start).clamp(360, 1440)) /
                                2)
                            .clamp(16, 540)
                            .toDouble(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: categoryColors[a.category],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        a.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    final date = c.selectedDay;
    final today = dayKey(date) == dayKey(DateTime.now());
    final header = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          onPressed: () => c.changeDay(-1),
          icon: const Icon(Icons.arrow_back),
        ),
        Text(
          '${today ? 'Hoy · ' : ''}${shortDate(date)}',
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => c.changeDay(1),
          icon: const Icon(Icons.arrow_forward),
        ),
        FilledButton.icon(
          onPressed: addActivity,
          icon: const Icon(Icons.add),
          label: const Text('Agregar actividad'),
        ),
      ],
    );
    final list = panel(
      'Actividades del día',
      c.dayActivities.isEmpty
          ? const SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'No hay actividades. Agregá la primera.',
                  style: TextStyle(color: AppColors.text2),
                ),
              ),
            )
          : Column(
              children: [
                for (final a in c.dayActivities)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 5,
                      backgroundColor: categoryColors[a.category],
                    ),
                    title: Text(a.name),
                    subtitle: Text(
                      '${a.start}–${a.end} · ${categoryNames[a.category]}',
                    ),
                    trailing: IconButton(
                      onPressed: () => c.removeActivity(a.id),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
              ],
            ),
    );
    final ai = panel(
      '✦ Análisis de rutina',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: scope,
            decoration: const InputDecoration(labelText: 'Analizar'),
            items: const [
              DropdownMenuItem(value: 'day', child: Text('Solo este día')),
              DropdownMenuItem(value: 'week', child: Text('Últimos 7 días')),
              DropdownMenuItem(value: 'all', child: Text('Todo el historial')),
            ],
            onChanged: (v) => setState(() => scope = v!),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: analyze,
            icon: const Icon(Icons.search),
            label: const Text('Analizar mi rutina'),
          ),
          const SizedBox(height: 15),
          analysis(),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi día a día',
              style: GoogleFonts.syne(
                color: AppColors.text,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'CARGÁ TU RUTINA · DETECTÁ PATRONES Y VENTANAS LIBRES',
              style: TextStyle(
                color: AppColors.text2,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            header,
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 175, child: panel('Timeline', timeline())),
                  const SizedBox(width: 14),
                  Expanded(child: list),
                  const SizedBox(width: 14),
                  SizedBox(width: 300, child: ai),
                ],
              )
            else
              Column(
                children: [
                  list,
                  const SizedBox(height: 14),
                  ai,
                  const SizedBox(height: 14),
                  panel('Timeline', timeline()),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class WeeklyTasksScreen extends StatefulWidget {
  final RoutineController controller;
  const WeeklyTasksScreen({super.key, required this.controller});
  @override
  State<WeeklyTasksScreen> createState() => _WeeklyTasksScreenState();
}

class _WeeklyTasksScreenState extends State<WeeklyTasksScreen> {
  RoutineController get c => widget.controller;
  final inputs = List.generate(7, (_) => TextEditingController());
  static const names = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  @override
  void initState() {
    super.initState();
    c.addListener(_refresh);
    c.load();
  }

  @override
  void dispose() {
    c.removeListener(_refresh);
    for (final item in inputs) {
      item.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> add(int i, DateTime date) async {
    final value = inputs[i].text.trim();
    if (value.isEmpty) return;
    inputs[i].clear();
    await c.addTask(
      WeeklyTask(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: value,
        date: date,
      ),
    );
  }

  Future<void> move(WeeklyTask task) async {
    final date = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mover tarea'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 7; i++)
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, c.weekDays[i]),
                child: Text('${names[i]} ${c.weekDays[i].day}'),
              ),
          ],
        ),
      ),
    );
    if (date != null && dayKey(date) != dayKey(task.date)) {
      await c.moveTask(task, date);
    }
  }

  Widget dayCard(int i, DateTime date) {
    final tasks = c.tasksOn(date);
    final done = tasks.where((e) => e.done).length;
    final pct = tasks.isEmpty ? 0.0 : done / tasks.length;
    final today = dayKey(date) == dayKey(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: today ? AppColors.green : AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            names[i].toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
              color: today ? AppColors.green : AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            shortDate(date),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.text2, fontSize: 10),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 6,
                    backgroundColor: AppColors.border,
                    color: pct == 1 ? AppColors.green : AppColors.amber,
                  ),
                  Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final task in tasks)
                  InkWell(
                    onDoubleTap: () => move(task),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Checkbox(
                            value: task.done,
                            onChanged: (_) => c.toggleTask(task),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            task.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: task.done
                                  ? AppColors.text2
                                  : AppColors.text,
                              decoration: task.done
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Opciones',
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: (action) {
                            if (action == 'move') {
                              move(task);
                            } else {
                              c.removeTask(task.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'move', child: Text('Mover')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Borrar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          TextField(
            controller: inputs[i],
            onSubmitted: (_) => add(i, date),
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              isDense: true,
              hintText: '+ Tarea…',
              suffixIcon: IconButton(
                onPressed: () => add(i, date),
                icon: const Icon(Icons.add, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = c.weekDays;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tareas semanales',
              style: GoogleFonts.syne(
                color: AppColors.text,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'CREÁ, TACHÁ Y MOVÉ TAREAS ENTRE DÍAS',
              style: TextStyle(
                color: AppColors.text2,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  onPressed: () => c.changeWeek(-1),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text('${shortDate(days.first)} – ${shortDate(days.last)}'),
                IconButton(
                  onPressed: () => c.changeWeek(1),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < 7; i++)
                    SizedBox(
                      width: constraints.maxWidth >= 1250
                          ? (constraints.maxWidth - 60) / 7
                          : 170,
                      height: 280,
                      child: dayCard(i, days[i]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
