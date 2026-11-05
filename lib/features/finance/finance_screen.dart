import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mi_espacio/core/format.dart';
import 'package:mi_espacio/core/theme/app_colors.dart';
import 'package:mi_espacio/features/finance/finance_repository.dart';

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', //
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class FinanceScreen extends StatefulWidget {
  final FinanceController controller;
  const FinanceScreen({super.key, required this.controller});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  FinanceController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_refrescar);
    c.load();
  }

  @override
  void dispose() {
    c.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  String get _mes =>
      '${_meses[c.selectedMonth.month - 1]} ${c.selectedMonth.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;
          final margen = ancho < 700 ? 16.0 : 32.0;
          final contenido = ancho - margen * 2;
          final dosColumnas = contenido >= 980;

          return SingleChildScrollView(
            padding: EdgeInsets.all(margen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finanzas',
                  style: GoogleFonts.syne(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const Text(
                  'PRESUPUESTO Y MOVIMIENTOS',
                  style: TextStyle(
                    color: AppColors.text2,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                _barra(),
                const SizedBox(height: 22),
                _indicadores(contenido),
                const SizedBox(height: 18),
                _columnas(dosColumnas, [_flujo(), _presupuesto()]),
                const SizedBox(height: 18),
                _columnas(dosColumnas, [_gastosPorCategoria(), _ahorro()]),
                const SizedBox(height: 18),
                _movimientos(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _barra() => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      IconButton(
        tooltip: 'Mes anterior',
        onPressed: () => c.changeMonth(-1),
        icon: const Icon(Icons.chevron_left),
      ),
      SizedBox(
        width: 180,
        child: Text(
          _mes,
          textAlign: TextAlign.center,
          style: GoogleFonts.syne(
            fontSize: 20,
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Mes siguiente',
        onPressed: () => c.changeMonth(1),
        icon: const Icon(Icons.chevron_right),
      ),
      const SizedBox(width: 8),
      FilledButton.icon(
        onPressed: () => _editarMovimiento(),
        icon: const Icon(Icons.add),
        label: const Text('Movimiento'),
      ),
      OutlinedButton.icon(
        onPressed: _agregarCategoria,
        icon: const Icon(Icons.category_outlined),
        label: const Text('Categoría'),
      ),
    ],
  );

  Widget _indicadores(double ancho) {
    final columnas = ancho >= 1100 ? 6 : (ancho >= 640 ? 3 : 2);
    const espacio = 12.0;
    final tarjeta = (ancho - espacio * (columnas - 1)) / columnas;
    final restante = c.remaining;
    final datos = [
      ('Ingresos', c.totalIncome, AppColors.green, Icons.south_west),
      (
        'Gastos operativos',
        c.operating,
        AppColors.text,
        Icons.shopping_bag_outlined,
      ),
      (
        'Facturas',
        c.expense('Facturas'),
        AppColors.text,
        Icons.receipt_long_outlined,
      ),
      (
        'Ahorros',
        c.expense('Ahorros'),
        AppColors.amber,
        Icons.savings_outlined,
      ),
      ('Débito', c.expense('Débito'), AppColors.text, Icons.credit_card),
      (
        'Restante',
        restante,
        restante < 0 ? AppColors.red : AppColors.green,
        Icons.account_balance_wallet_outlined,
      ),
    ];
    return Wrap(
      spacing: espacio,
      runSpacing: espacio,
      children: [
        for (final (titulo, importe, color, icono) in datos)
          SizedBox(
            width: tarjeta,
            child: _Indicador(titulo, formatoMoneda(importe), color, icono),
          ),
      ],
    );
  }

  Widget _columnas(bool dosColumnas, List<Widget> paneles) {
    if (!dosColumnas) {
      return Column(
        children: [
          for (var i = 0; i < paneles.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            paneles[i],
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: paneles[0]),
          const SizedBox(width: 18),
          Expanded(flex: 6, child: paneles[1]),
        ],
      ),
    );
  }

  Widget _flujo() => _Panel(
    titulo: 'Flujo de fondos',
    child: Column(
      children: [
        _fila('Ingresos del mes', c.totalIncome),
        _fila('Gastos operativos', -c.operating),
        _fila('Facturas', -c.expense('Facturas')),
        _fila('Ahorros', -c.expense('Ahorros')),
        _fila('Débito', -c.expense('Débito')),
        const Divider(height: 22),
        _fila('Restante', c.remaining, destacado: true),
        const SizedBox(height: 6),
        const Text(
          'Los gastos operativos suman Servicios, Supermercado y Gastos personales. '
          'Otras categorías, como Farmacia, figuran en los movimientos pero no restan.',
          style: TextStyle(color: AppColors.text2, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _fila(String etiqueta, double importe, {bool destacado = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: TextStyle(
                  color: destacado ? AppColors.text : AppColors.text2,
                  fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              formatoMoneda(importe),
              style: TextStyle(
                color: destacado
                    ? (importe < 0 ? AppColors.red : AppColors.green)
                    : AppColors.text,
                fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );

  Widget _presupuesto() {
    const ingresos = ['Sueldo', 'Otros ingresos'];
    const gastos = [
      'Servicios',
      'Supermercado',
      'Gastos personales',
      'Facturas',
      'Débito',
      'Ahorros',
    ];
    return _Panel(
      titulo: 'Presupuesto del mes',
      subtitulo: 'Tocá una fila para cambiar lo planeado',
      child: Column(
        children: [
          for (final nombre in ingresos)
            _filaPresupuesto(nombre, c.income(nombre), esIngreso: true),
          const Divider(height: 18),
          for (final nombre in gastos)
            _filaPresupuesto(nombre, c.expense(nombre)),
        ],
      ),
    );
  }

  Widget _filaPresupuesto(
    String nombre,
    double real, {
    bool esIngreso = false,
  }) {
    final plan = c.planned[nombre] ?? 0;
    final avance = plan <= 0 ? (real > 0 ? 1.0 : 0.0) : real / plan;
    final excedido = !esIngreso && plan > 0 && real > plan;
    final color = excedido
        ? AppColors.red
        : (esIngreso ? AppColors.green : AppColors.blue);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _editarPlan(nombre),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nombre,
                    style: const TextStyle(color: AppColors.text),
                  ),
                ),
                Text(
                  '${formatoMoneda(real)} de ${formatoMoneda(plan)}',
                  style: TextStyle(
                    color: excedido ? AppColors.red : AppColors.text2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: AppColors.text2,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: avance.clamp(0, 1).toDouble(),
                minHeight: 6,
                backgroundColor: AppColors.border,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gastosPorCategoria() {
    final categorias = c.expensesByCategory;
    final total = c.totalExpenses;
    return _Panel(
      titulo: 'Gastos por categoría',
      child: categorias.isEmpty
          ? const _Vacio('Todavía no hay gastos en este mes.')
          : Column(
              children: [
                for (final e in categorias)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text(
                            e.key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.text),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : e.value / total,
                              minHeight: 10,
                              backgroundColor: AppColors.border,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 54,
                          child: Text(
                            formatoPorcentaje(total == 0 ? 0 : e.value / total),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.text2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            formatoMoneda(e.value),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _ahorro() {
    final acumulados = <double>[];
    for (var mes = 1; mes <= 12; mes++) {
      acumulados.add(
        (acumulados.isEmpty ? 0 : acumulados.last) +
            (c.manualSavings[mes] ?? 0),
      );
    }
    return _Panel(
      titulo: 'Ahorro acumulado ${c.selectedMonth.year}',
      subtitulo: 'Carga manual · tocá un mes para editarlo',
      child: Column(
        children: [
          for (var mes = 1; mes <= 12; mes++)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _editarAhorro(mes),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        _meses[mes - 1],
                        style: TextStyle(
                          color: mes == c.selectedMonth.month
                              ? AppColors.green
                              : AppColors.text2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatoMoneda(c.manualSavings[mes] ?? 0),
                        style: const TextStyle(color: AppColors.text),
                      ),
                    ),
                    Text(
                      formatoMoneda(acumulados[mes - 1]),
                      style: const TextStyle(color: AppColors.text2),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 18),
          _fila(
            'Acumulado a ${_meses[c.selectedMonth.month - 1].toLowerCase()}',
            c.accumulatedSavings,
            destacado: true,
          ),
        ],
      ),
    );
  }

  Widget _movimientos() {
    final movimientos = c.monthEntries;
    return _Panel(
      titulo: 'Movimientos de $_mes',
      subtitulo: movimientos.isEmpty
          ? null
          : 'Tocá un movimiento para editarlo',
      child: movimientos.isEmpty
          ? const _Vacio(
              'Todavía no hay movimientos en este mes. Agregá el primero con el botón Movimiento.',
            )
          : Column(
              children: [
                for (final m in movimientos)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    onTap: () => _editarMovimiento(m),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          (m.type == MovementType.income
                                  ? AppColors.green
                                  : AppColors.text2)
                              .withValues(alpha: 0.12),
                      child: Icon(
                        m.type == MovementType.income
                            ? Icons.south_west
                            : Icons.north_east,
                        size: 16,
                        color: m.type == MovementType.income
                            ? AppColors.green
                            : AppColors.text2,
                      ),
                    ),
                    title: Text(m.description),
                    subtitle: Text(
                      '${formatoFecha(m.date)} · ${m.category}',
                      style: const TextStyle(color: AppColors.text2),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatoMoneda(
                            m.type == MovementType.income
                                ? m.amount
                                : -m.amount,
                          ),
                          style: TextStyle(
                            color: m.type == MovementType.income
                                ? AppColors.green
                                : AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Borrar',
                          onPressed: () => _borrar(m),
                          icon: const Icon(Icons.delete_outline, size: 19),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _borrar(Movement movimiento) async {
    final borrado = await c.remove(movimiento.id);
    if (!mounted || borrado == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Se borró "${borrado.description}".'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => c.add(borrado),
          ),
        ),
      );
  }

  Future<double?> _pedirImporte(
    String titulo,
    String etiqueta,
    double actual,
  ) async {
    final texto = TextEditingController(
      text: actual == 0 ? '' : actual.toStringAsFixed(2).replaceAll('.', ','),
    );
    String? error;
    final resultado = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizar) {
          void guardar() {
            final valor = leerImporte(texto.text);
            if (valor == null || valor < 0) {
              actualizar(() => error = 'Ingresá un importe válido.');
              return;
            }
            Navigator.pop(ctx, valor);
          }

          return AlertDialog(
            title: Text(titulo),
            content: TextField(
              controller: texto,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onSubmitted: (_) => guardar(),
              decoration: InputDecoration(
                labelText: etiqueta,
                prefixText: r'$ ',
                errorText: error,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(onPressed: guardar, child: const Text('Guardar')),
            ],
          );
        },
      ),
    );
    texto.dispose();
    return resultado;
  }

  Future<void> _editarPlan(String categoria) async {
    final valor = await _pedirImporte(
      'Planeado para $categoria',
      'Monto planeado',
      c.planned[categoria] ?? 0,
    );
    if (valor != null) await c.setPlan(categoria, valor);
  }

  Future<void> _editarAhorro(int mes) async {
    final valor = await _pedirImporte(
      'Ahorro de ${_meses[mes - 1]}',
      'Ahorro del mes',
      c.manualSavings[mes] ?? 0,
    );
    if (valor != null) await c.setSaving(mes, valor);
  }

  Future<void> _editarMovimiento([Movement? existente]) async {
    final descripcion = TextEditingController(
      text: existente?.description ?? '',
    );
    final importe = TextEditingController(
      text: existente == null
          ? ''
          : existente.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    final hoy = DateTime.now();
    final ultimoDia = DateTime(
      c.selectedMonth.year,
      c.selectedMonth.month + 1,
      0,
    ).day;
    var fecha =
        existente?.date ??
        DateTime(
          c.selectedMonth.year,
          c.selectedMonth.month,
          hoy.day.clamp(1, ultimoDia),
        );
    var tipo = existente?.type ?? MovementType.expense;
    var categoria = existente?.category ?? 'Supermercado';
    String? errorDescripcion;
    String? errorImporte;

    final resultado = await showDialog<Movement>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizar) {
          final categorias = c.categories
              .where((e) => e.type == tipo)
              .map((e) => e.name)
              .toList();
          if (!categorias.contains(categoria)) categoria = categorias.first;

          void guardar() {
            final valor = leerImporte(importe.text);
            actualizar(() {
              errorDescripcion = descripcion.text.trim().isEmpty
                  ? 'Escribí una descripción.'
                  : null;
              errorImporte = valor == null || valor <= 0
                  ? 'Ingresá un importe mayor a cero.'
                  : null;
            });
            if (errorDescripcion != null || errorImporte != null) return;
            Navigator.pop(
              ctx,
              Movement(
                id:
                    existente?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                date: fecha,
                description: descripcion.text.trim(),
                category: categoria,
                type: tipo,
                amount: valor!,
              ),
            );
          }

          return AlertDialog(
            title: Text(
              existente == null ? 'Nuevo movimiento' : 'Editar movimiento',
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<MovementType>(
                      segments: const [
                        ButtonSegment(
                          value: MovementType.expense,
                          label: Text('Gasto'),
                          icon: Icon(Icons.north_east),
                        ),
                        ButtonSegment(
                          value: MovementType.income,
                          label: Text('Ingreso'),
                          icon: Icon(Icons.south_west),
                        ),
                      ],
                      selected: {tipo},
                      onSelectionChanged: (v) =>
                          actualizar(() => tipo = v.first),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey(tipo),
                      initialValue: categoria,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        for (final nombre in categorias)
                          DropdownMenuItem(value: nombre, child: Text(nombre)),
                      ],
                      onChanged: (v) => actualizar(() => categoria = v!),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descripcion,
                      autofocus: existente == null,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        errorText: errorDescripcion,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: importe,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onSubmitted: (_) => guardar(),
                      decoration: InputDecoration(
                        labelText: 'Importe',
                        prefixText: r'$ ',
                        errorText: errorImporte,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final elegida = await showDatePicker(
                            context: ctx,
                            initialDate: fecha,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (elegida != null) {
                            actualizar(() => fecha = elegida);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(formatoFecha(fecha)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: guardar,
                child: Text(existente == null ? 'Agregar' : 'Guardar'),
              ),
            ],
          );
        },
      ),
    );
    descripcion.dispose();
    importe.dispose();
    if (resultado != null) await c.add(resultado);
  }

  Future<void> _agregarCategoria() async {
    final nombre = TextEditingController();
    var tipo = MovementType.expense;
    String? error;
    final resultado = await showDialog<FinanceCategory>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizar) {
          void guardar() {
            final texto = nombre.text.trim();
            if (texto.isEmpty) {
              actualizar(() => error = 'Escribí un nombre.');
            } else if (c.categories.any(
              (e) => e.name.toLowerCase() == texto.toLowerCase(),
            )) {
              actualizar(() => error = 'Esa categoría ya existe.');
            } else {
              Navigator.pop(ctx, FinanceCategory(texto, tipo));
            }
          }

          return AlertDialog(
            title: const Text('Nueva categoría'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<MovementType>(
                  segments: const [
                    ButtonSegment(
                      value: MovementType.expense,
                      label: Text('Gasto'),
                    ),
                    ButtonSegment(
                      value: MovementType.income,
                      label: Text('Ingreso'),
                    ),
                  ],
                  selected: {tipo},
                  onSelectionChanged: (v) => actualizar(() => tipo = v.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nombre,
                  autofocus: true,
                  onSubmitted: (_) => guardar(),
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(onPressed: guardar, child: const Text('Guardar')),
            ],
          );
        },
      ),
    );
    nombre.dispose();
    if (resultado != null) await c.addCategory(resultado);
  }
}

class _Indicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;
  const _Indicador(this.titulo, this.valor, this.color, this.icono);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.bg2,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text2,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Icon(icono, size: 16, color: AppColors.text2),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            style: GoogleFonts.syne(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget child;
  const _Panel({required this.titulo, this.subtitulo, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.bg2,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.syne(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitulo != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitulo!,
              style: const TextStyle(color: AppColors.text2, fontSize: 12),
            ),
          ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _Vacio extends StatelessWidget {
  final String texto;
  const _Vacio(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(texto, style: const TextStyle(color: AppColors.text2)),
  );
}
