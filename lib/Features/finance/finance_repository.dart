import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum MovementType { income, expense }

class FinanceCategory {
  final String name;
  final MovementType type;
  const FinanceCategory(this.name, this.type);
}

class Movement {
  final String id;
  final DateTime date;
  final String description;
  final String category;
  final MovementType type;
  final double amount;
  const Movement({required this.id, required this.date, required this.description,
    required this.category, required this.type, required this.amount});
}

abstract class FinanceRepository {
  Future<List<Movement>> movements();
  Future<List<FinanceCategory>> categories();
  Future<Map<String, double>> plans(int year, int month);
  Future<Map<int, double>> savings(int year);
  Future<void> saveMovement(Movement value);
  Future<void> deleteMovement(String id);
  Future<void> saveCategory(FinanceCategory value);
  Future<void> savePlan(int year, int month, String key, double amount);
  Future<void> saveSaving(int year, int month, double amount);
}

// Swap this local adapter for a database adapter without changing the UI.
class LocalFinanceRepository implements FinanceRepository {
  static const _storageKey = 'finance_v1';
  bool _loaded = false;
  final _movements = <Movement>[];
  final _categories = <FinanceCategory>[
    const FinanceCategory('Sueldo', MovementType.income),
    const FinanceCategory('Otros ingresos', MovementType.income),
    const FinanceCategory('Servicios', MovementType.expense),
    const FinanceCategory('Supermercado', MovementType.expense),
    const FinanceCategory('Gastos personales', MovementType.expense),
    const FinanceCategory('Débito', MovementType.expense),
    const FinanceCategory('Ahorros', MovementType.expense),
    const FinanceCategory('Facturas', MovementType.expense),
    const FinanceCategory('Farmacia', MovementType.expense),
  ];
  final _plans = <String, double>{};
  final _savings = <String, double>{};
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _movements.addAll((data['movements'] as List).map((v) { final e = v as Map<String,dynamic>; return Movement(id: e['id'], date: DateTime.parse(e['date']), description: e['description'], category: e['category'], type: MovementType.values.byName(e['type']), amount: (e['amount'] as num).toDouble()); }));
      _categories.addAll((data['categories'] as List).map((v) { final e = v as Map<String,dynamic>; return FinanceCategory(e['name'], MovementType.values.byName(e['type'])); }));
      _plans.addAll((data['plans'] as Map<String,dynamic>).map((k,v) => MapEntry(k,(v as num).toDouble())));
      _savings.addAll((data['savings'] as Map<String,dynamic>).map((k,v) => MapEntry(k,(v as num).toDouble())));
    }
    _loaded = true;
  }
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode({'movements': _movements.map((e) => {'id':e.id,'date':e.date.toIso8601String(),'description':e.description,'category':e.category,'type':e.type.name,'amount':e.amount}).toList(), 'categories': _categories.skip(9).map((e) => {'name':e.name,'type':e.type.name}).toList(), 'plans':_plans, 'savings':_savings}));
  }
  String _key(int year, int month, String name) => '$year-$month-$name';
  @override Future<List<Movement>> movements() async { await _ensureLoaded(); return List.unmodifiable(_movements); }
  @override Future<List<FinanceCategory>> categories() async { await _ensureLoaded(); return List.unmodifiable(_categories); }
  @override Future<Map<String, double>> plans(int year, int month) async { await _ensureLoaded(); return {
    for (final e in _plans.entries) if (e.key.startsWith('$year-$month-'))
      e.key.substring('$year-$month-'.length): e.value,
  }; }
  @override Future<Map<int, double>> savings(int year) async { await _ensureLoaded(); return {
    for (var month = 1; month <= 12; month++) month: _savings[_key(year, month, 'saving')] ?? 0,
  }; }
  @override Future<void> saveMovement(Movement value) async { await _ensureLoaded(); _movements.removeWhere((e) => e.id == value.id); _movements.add(value); await _persist(); }
  @override Future<void> deleteMovement(String id) async { await _ensureLoaded(); _movements.removeWhere((e) => e.id == id); await _persist(); }
  @override Future<void> saveCategory(FinanceCategory value) async { await _ensureLoaded(); if (!_categories.any((e) => e.name.toLowerCase() == value.name.toLowerCase())) _categories.add(value); await _persist(); }
  @override Future<void> savePlan(int year, int month, String key, double amount) async { await _ensureLoaded(); _plans[_key(year, month, key)] = amount; await _persist(); }
  @override Future<void> saveSaving(int year, int month, double amount) async { await _ensureLoaded(); _savings[_key(year, month, 'saving')] = amount; await _persist(); }
}

class FinanceController extends ChangeNotifier {
  final FinanceRepository repository;
  FinanceController(this.repository);
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Movement> entries = [];
  List<FinanceCategory> categories = [];
  Map<String, double> planned = {};
  Map<int, double> manualSavings = {};
  Future<void> load() async {
    entries = await repository.movements(); categories = await repository.categories();
    planned = await repository.plans(selectedMonth.year, selectedMonth.month);
    manualSavings = await repository.savings(selectedMonth.year); notifyListeners();
  }
  Future<void> changeMonth(int delta) async { selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + delta); await load(); }
  Future<void> add(Movement value) async { await repository.saveMovement(value); await load(); }
  Future<void> remove(String id) async { await repository.deleteMovement(id); await load(); }
  Future<void> addCategory(FinanceCategory value) async { await repository.saveCategory(value); await load(); }
  Future<void> setPlan(String key, double amount) async { await repository.savePlan(selectedMonth.year, selectedMonth.month, key, amount); await load(); }
  Future<void> setSaving(int month, double amount) async { await repository.saveSaving(selectedMonth.year, month, amount); await load(); }
  List<Movement> get monthEntries => entries.where((e) => e.date.year == selectedMonth.year && e.date.month == selectedMonth.month).toList()..sort((a,b) => b.date.compareTo(a.date));
  double income(String category) => monthEntries.where((e) => e.type == MovementType.income && e.category == category).fold(0, (sum,e) => sum + e.amount);
  double expense(String category) => monthEntries.where((e) => e.type == MovementType.expense && e.category == category).fold(0, (sum,e) => sum + e.amount);
  double get totalIncome => monthEntries.where((e) => e.type == MovementType.income).fold(0, (sum,e) => sum + e.amount);
  double get operating => expense('Servicios') + expense('Supermercado') + expense('Gastos personales');
  double get remaining => totalIncome - operating - expense('Facturas') - expense('Ahorros') - expense('Débito');
  double get accumulatedSavings => manualSavings.entries.where((e) => e.key <= selectedMonth.month).fold(0, (sum,e) => sum + e.value);
}
