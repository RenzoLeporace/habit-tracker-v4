import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/habit.dart';
import '../cubit/habit_cubit.dart';
import '../cubit/habit_state.dart';
import '../widgets/kpi_cart.dart';
import '../widgets/weekly_progress_chart.dart';
import '../widgets/hourly_performance_chart.dart';
import '../widgets/habit_progress_sidebar.dart';
import '../widgets/habit_heatmap.dart';
import '../widgets/habit_row.dart';
import '../../../domain/usecases/calculate_global_streak_usecase.dart';
import '../../../domain/usecases/calculate_max_streak_usecase.dart';
import '../../../domain/entities/habit_entity.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 700;

    // Disparamos la carga inicial apenas se dibuja la pantalla
    context.read<HabitCubit>().getHabits();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.8),
            colors: [Color(0xFF1A1A1E), Color(0xFF0C0C0E)],
            radius: 1.5,
          ),
        ),
        child: BlocBuilder<HabitCubit, HabitState>(
          builder: (context, state) {
            // 1. ESTADO DE CARGA
            if (state is HabitLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              );
            }

            // 2. ESTADO DE ERROR
            if (state is HabitError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }

            // 3. ESTADO EXITOSO (CON DATOS)
            if (state is HabitLoaded) {
              final habits = state.habits;
              final selectedDate = state.selectedDate;
              final focusedHabitId = state.focusedHabitId;

              // Cálculos rápidos de interfaz usando los datos del estado
              int daysInMonth = DateTime(
                selectedDate.year,
                selectedDate.month + 1,
                0,
              ).day;
              int totalCompleted = habits.fold(
                0,
                (prev, h) =>
                    prev +
                    h.data.values
                        .where(
                          (e) =>
                              e.done &&
                              e.date.month == selectedDate.month &&
                              e.date.year == selectedDate.year,
                        )
                        .length,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                  vertical: isMobile ? 24 : 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, selectedDate),
                    const SizedBox(height: 32),
                    _buildKPIs(
                      context,
                      habits,
                      selectedDate,
                      focusedHabitId,
                      daysInMonth,
                      totalCompleted,
                    ),
                    const SizedBox(height: 28),
                    _buildMainGridContainer(
                      context,
                      isMobile,
                      habits,
                      selectedDate,
                      focusedHabitId,
                      daysInMonth,
                    ),
                    const SizedBox(height: 24),
                    _buildInsights(
                      habits,
                      selectedDate,
                      focusedHabitId,
                      daysInMonth,
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateTime selectedDate) {
    List<String> meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    String monthName = meses[selectedDate.month - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => context.read<HabitCubit>().changeMonth(context),
          borderRadius: BorderRadius.circular(8),
          child: LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      monthName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: constraints.maxWidth < 380 ? 38 : 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.text2,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(
          'HABIT TRACKER · ${selectedDate.year}',
          style: const TextStyle(
            color: AppColors.text2,
            letterSpacing: 1.5,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildKPIs(
    BuildContext context,
    List<HabitModel> habits,
    DateTime selectedDate,
    int? focusedHabitId,
    int daysInMonth,
    int totalCompleted,
  ) {
    HabitModel? focusedHabit = focusedHabitId != null
        ? habits.firstWhere(
            (h) => h.id == focusedHabitId,
            orElse: () => habits.first,
          )
        : (habits.isNotEmpty ? habits.first : null);

    final CalculateGlobalStreakUseCase globalStreakUseCase =
        CalculateGlobalStreakUseCase();
    final CalculateMaxStreakUseCase maxStreakUseCase =
        CalculateMaxStreakUseCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 340
            ? 1
            : constraints.maxWidth < 850
            ? 2
            : 4;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            KpiCard(
              label: "HÁBITOS",
              value: "${habits.length}",
              subtitle: "activos",
              width: cardWidth,
            ),
            KpiCard(
              label: focusedHabitId == null ? "RACHA GLOBAL" : "RACHA FOCO",
              value: focusedHabitId == null
                  ? "${globalStreakUseCase.execute(habits.map((h) => h.toEntity()).toList())} 🔥"
                  : "${maxStreakUseCase.execute(habits.firstWhere((h) => h.id == focusedHabitId).toEntity())} 🔥",
              subtitle: focusedHabitId == null
                  ? "de cualquier hábito"
                  : focusedHabit?.name ?? "",
              width: cardWidth,
            ),
            KpiCard(
              label: "HECHOS",
              value: "$totalCompleted",
              subtitle: "este mes",
              width: cardWidth,
            ),
            KpiCard(
              label: "PROGRESO",
              value:
                  "${(habits.isEmpty ? 0 : (totalCompleted / (habits.length * daysInMonth)) * 100).toInt()}%",
              subtitle: "del mes",
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainGridContainer(
    BuildContext context,
    bool isMobile,
    List<HabitModel> habits,
    DateTime selectedDate,
    int? focusedHabitId,
    int daysInMonth,
  ) {
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
          _buildHabitSectionHeader(context, isMobile, habits),
          const SizedBox(height: 24),
          habits.isEmpty
              ? _buildEmptyState()
              : _buildHabitGrid(
                  context,
                  habits,
                  selectedDate,
                  focusedHabitId,
                  daysInMonth,
                ),
        ],
      ),
    );
  }

  Widget _buildHabitSectionHeader(
    BuildContext context,
    bool isMobile,
    List<HabitModel> habits,
  ) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MIS HÁBITOS",
          style: GoogleFonts.syne(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
        const Text(
          "Mantén presionado para seleccionar el horario",
          style: TextStyle(
            color: AppColors.text2,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
    final buttonBlock = ElevatedButton.icon(
      onPressed: () =>
          context.read<HabitCubit>().showAddHabitDialog(context, habits),
      icon: const Icon(Icons.add, size: 16),
      label: const Text("AGREGAR"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF143023),
        foregroundColor: AppColors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: buttonBlock),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [titleBlock, buttonBlock],
    );
  }

  Widget _buildHabitGrid(
    BuildContext context,
    List<HabitModel> habits,
    DateTime selectedDate,
    int? focusedHabitId,
    int daysInMonth,
  ) {
    return SizedBox(
      width: double
          .infinity, // Forzamos a que ocupe todo el ancho del contenedor padre
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Agregamos física de rebote para que la Web responda mucho mejor al scroll horizontal
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGridHeader(daysInMonth),
            ...habits.map(
              (h) => HabitRow(
                habit: h,
                selectedDate: selectedDate,
                isFocused: focusedHabitId == h.id,
                daysInMonth: daysInMonth,
                onFocusChanged: (id) =>
                    context.read<HabitCubit>().changeFocus(id),
                onDataChanged: () =>
                    context.read<HabitCubit>().refreshData(habits),
                onDelete: (id) =>
                    context.read<HabitCubit>().deleteHabit(id, habits),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridHeader(int daysInMonth) {
    int totalWeeks = (daysInMonth / 7).ceil();
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 150,
            height: 45,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: const Text(
              "HÁBITO",
              style: TextStyle(
                color: AppColors.text2,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(totalWeeks, (index) {
            int weekNum = index + 1;
            int daysInThisWeek = (weekNum * 7 <= daysInMonth)
                ? 7
                : (daysInMonth % 7);

            return Container(
              width: 45.0 * daysInThisWeek,
              height: 45,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Text(
                "SEMANA $weekNum",
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsights(
    List<HabitModel> habits,
    DateTime selectedDate,
    int? focusedHabitId,
    int daysInMonth,
  ) {
    // 1. FILTRADO EN MODELOS: Filtramos los modelos según el foco (List<HabitModel>)
    final List<HabitModel> modelsFiltered = focusedHabitId != null
        ? habits.where((h) => h.id == focusedHabitId).toList()
        : habits;

    // 2. CONVERSIÓN A ENTIDADES: Creamos las versiones en Entidad de Dominio para los widgets que las pidan
    final List<HabitEntity> entitiesFiltered = modelsFiltered
        .map((h) => h.toEntity())
        .toList();
    final List<HabitEntity> entitiesAll = habits
        .map((h) => h.toEntity())
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 20) / columns;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: width,
              child: HourlyPerformanceChart(habits: modelsFiltered),
            ),
            SizedBox(
              width: width,
              child: WeeklyProgressChart(
                habits: entitiesFiltered,
                selectedDate: selectedDate,
              ),
            ),
            SizedBox(
              width: width,
              child: _sidebarCard(
                "% POR HÁBITO",
                HabitProgressSidebar(
                  habits: entitiesAll,
                  daysInMonth: daysInMonth,
                  month: selectedDate.month,
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: _sidebarCard(
                "HEATMAP DEL MES",
                HabitHeatmap(
                  habits: entitiesAll,
                  daysInMonth: daysInMonth,
                  selectedDate: selectedDate,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sidebarCard(String title, Widget child) {
    return Container(
      width: double.infinity,
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
            title,
            style: const TextStyle(
              color: AppColors.text2,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          "No hay hábitos. ¡Crea uno!",
          style: TextStyle(color: AppColors.text2),
        ),
      ),
    );
  }
}
