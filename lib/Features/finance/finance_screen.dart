import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'finance_repository.dart';

class FinanceScreen extends StatefulWidget {
  final FinanceController controller;
  const FinanceScreen({super.key, required this.controller});
  @override State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  static const months = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
  FinanceController get c => widget.controller;
  String money(double n) => '\$${n.toStringAsFixed(2)}';
  @override void initState() { super.initState(); c.addListener(_refresh); c.load(); }
  @override void dispose() { c.removeListener(_refresh); super.dispose(); }
  void _refresh() { if (mounted) setState(() {}); }
  Widget card(String title, String value, {Color? color}) => Container(
    width: 190, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.bg2,
      border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.toUpperCase(), style: const TextStyle(color: AppColors.text2, fontSize: 11)),
      const SizedBox(height: 9), Text(value, style: GoogleFonts.syne(color: color ?? AppColors.text, fontSize: 24, fontWeight: FontWeight.bold))]));
  Widget section(String title, Widget child) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.bg2,
    border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.syne(color: AppColors.text, fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 15), child]));
  Widget amountRow(String label, double amount, {bool strong = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: strong ? AppColors.text : AppColors.text2))), Text(money(amount), style: TextStyle(color: strong ? AppColors.green : AppColors.text, fontWeight: strong ? FontWeight.bold : FontWeight.normal))]));
  Future<void> editPlan(String key) async {
    final input = TextEditingController(text: (c.planned[key] ?? 0).toString());
    final result = await showDialog<double>(context: context, builder: (ctx) => AlertDialog(title: Text('Planeado: $key'), content: TextField(controller: input, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monto')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, double.tryParse(input.text.replaceAll(',', '.'))), child: const Text('Guardar'))]));
    input.dispose(); if (result != null && result >= 0) await c.setPlan(key, result);
  }
  Widget budgetRow(String key, double actual) => InkWell(onTap: () => editPlan(key), child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text(key, style: const TextStyle(color: AppColors.text))), Text('Plan ${money(c.planned[key] ?? 0)}', style: const TextStyle(color: AppColors.text2)), const SizedBox(width: 16), Text('Real ${money(actual)}', style: const TextStyle(color: AppColors.green)), const SizedBox(width: 5), const Icon(Icons.edit_outlined, size: 14, color: AppColors.text2)])));
  Future<void> addMovement() async {
    final description = TextEditingController(); final amount = TextEditingController();
    var date = DateTime(c.selectedMonth.year, c.selectedMonth.month, DateTime.now().day.clamp(1, DateTime(c.selectedMonth.year,c.selectedMonth.month+1,0).day));
    var type = MovementType.expense; var category = 'Servicios';
    final result = await showDialog<Movement>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
      title: const Text('Nuevo movimiento'), content: SizedBox(width: 390, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<MovementType>(initialValue: type, decoration: const InputDecoration(labelText: 'Tipo'), items: const [DropdownMenuItem(value: MovementType.income, child: Text('Ingreso')), DropdownMenuItem(value: MovementType.expense, child: Text('Gasto'))], onChanged: (v) => update(() { type = v!; category = c.categories.firstWhere((e) => e.type == type).name; })),
        DropdownButtonFormField<String>(key: ValueKey(type), initialValue: category, decoration: const InputDecoration(labelText: 'Categoría'), items: c.categories.where((e) => e.type == type).map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))).toList(), onChanged: (v) => update(() => category = v!)),
        TextField(controller: description, decoration: const InputDecoration(labelText: 'Descripción')),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monto')),
        TextButton.icon(onPressed: () async { final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (picked != null) update(() => date = picked); }, icon: const Icon(Icons.calendar_today), label: Text('${date.day}/${date.month}/${date.year}')),
      ]))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () { final value = double.tryParse(amount.text.replaceAll(',', '.')); if (description.text.trim().isEmpty || value == null || value <= 0) return; Navigator.pop(ctx, Movement(id: DateTime.now().microsecondsSinceEpoch.toString(), date: date, description: description.text.trim(), category: category, type: type, amount: value)); }, child: const Text('Agregar'))])));
    description.dispose(); amount.dispose(); if (result != null) await c.add(result);
  }
  Future<void> addCategory() async {
    final input = TextEditingController(); var type = MovementType.expense;
    final result = await showDialog<FinanceCategory>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(title: const Text('Nueva categoría'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: input, decoration: const InputDecoration(labelText: 'Nombre')), DropdownButton<MovementType>(value: type, items: const [DropdownMenuItem(value: MovementType.income, child: Text('Ingreso')), DropdownMenuItem(value: MovementType.expense, child: Text('Gasto'))], onChanged: (v) => update(() => type = v!))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () { if (input.text.trim().isNotEmpty) Navigator.pop(ctx, FinanceCategory(input.text.trim(), type)); }, child: const Text('Guardar'))])));
    input.dispose(); if (result != null) await c.addCategory(result);
  }
  Future<void> editSaving(int month) async {
    final input = TextEditingController(text: (c.manualSavings[month] ?? 0).toString());
    final result = await showDialog<double>(context: context, builder: (ctx) => AlertDialog(title: Text('Ahorro de ${months[month-1]}'), content: TextField(controller: input, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Ahorro manual')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, double.tryParse(input.text.replaceAll(',', '.'))), child: const Text('Guardar'))]));
    input.dispose(); if (result != null && result >= 0) await c.setSaving(month, result);
  }
  @override Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(backgroundColor: AppColors.bg, body: SingleChildScrollView(padding: EdgeInsets.all(width < 700 ? 16 : 32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Finanzas', style: GoogleFonts.syne(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.text)),
      const Text('PRESUPUESTO Y MOVIMIENTOS', style: TextStyle(color: AppColors.text2, letterSpacing: 1.5)), const SizedBox(height: 24),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [IconButton(onPressed: () => c.changeMonth(-1), icon: const Icon(Icons.chevron_left)), Text('${months[c.selectedMonth.month-1]} ${c.selectedMonth.year}', style: GoogleFonts.syne(fontSize: 20, color: AppColors.text)), IconButton(onPressed: () => c.changeMonth(1), icon: const Icon(Icons.chevron_right)), FilledButton.icon(onPressed: addMovement, icon: const Icon(Icons.add), label: const Text('Movimiento')), OutlinedButton.icon(onPressed: addCategory, icon: const Icon(Icons.category_outlined), label: const Text('Categoría'))]),
      const SizedBox(height: 24), Wrap(spacing: 12, runSpacing: 12, children: [card('Ingreso', money(c.totalIncome), color: AppColors.green), card('Gastos operativos', money(c.operating)), card('Facturas', money(c.expense('Facturas'))), card('Ahorros', money(c.expense('Ahorros'))), card('Débito', money(c.expense('Débito'))), card('Restante', money(c.remaining), color: c.remaining < 0 ? Colors.redAccent : AppColors.green)]),
      const SizedBox(height: 22), Wrap(spacing: 18, runSpacing: 18, children: [SizedBox(width: 420, child: section('Flujo de fondos', Column(children: [amountRow('Ingresos del mes', c.totalIncome), amountRow('Gastos operativos', -c.operating), amountRow('Facturas', -c.expense('Facturas')), amountRow('Ahorros', -c.expense('Ahorros')), amountRow('Débito', -c.expense('Débito')), const Divider(), amountRow('Restante', c.remaining, strong: true)]))), SizedBox(width: 540, child: section('Planeado y actual · tocá para editar', Column(children: [budgetRow('Sueldo', c.income('Sueldo')), budgetRow('Otros ingresos', c.income('Otros ingresos')), budgetRow('Servicios', c.expense('Servicios')), budgetRow('Supermercado', c.expense('Supermercado')), budgetRow('Gastos personales', c.expense('Gastos personales')), budgetRow('Facturas', c.expense('Facturas')), budgetRow('Débito', c.expense('Débito')), budgetRow('Ahorros', c.expense('Ahorros'))])))]),
      const SizedBox(height: 18), section('Ahorro acumulado · carga manual', Column(children: [for (var month = 1; month <= 12; month++) InkWell(onTap: () => editSaving(month), child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [SizedBox(width: 110, child: Text(months[month-1])), Expanded(child: Text(money(c.manualSavings[month] ?? 0))), Text(money(List.generate(month, (i) => c.manualSavings[i+1] ?? 0).fold(0.0, (sum,e) => sum + e))), const Icon(Icons.edit_outlined, size: 14)]))) , const Divider(), amountRow('Acumulado al mes activo', c.accumulatedSavings, strong: true)])),
      const SizedBox(height: 18), section('Registro anual · movimientos de ${months[c.selectedMonth.month-1]}', c.monthEntries.isEmpty ? const Text('Todavía no hay movimientos en este mes.', style: TextStyle(color: AppColors.text2)) : Column(children: [for (final e in c.monthEntries) ListTile(contentPadding: EdgeInsets.zero, title: Text(e.description), subtitle: Text('${e.date.day}/${e.date.month}/${e.date.year} · ${e.category}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${e.type == MovementType.income ? '+' : '-'}${money(e.amount)}', style: TextStyle(color: e.type == MovementType.income ? AppColors.green : AppColors.text)), IconButton(onPressed: () => c.remove(e.id), icon: const Icon(Icons.delete_outline, size: 19))]) )])),
    ])));
  }
}
