import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nocodb_app_flutter/l10n/app_localizations.dart';
import 'package:nocodb_app_flutter/services/nocodb_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyExpensePage extends StatefulWidget {
  const FamilyExpensePage({super.key});

  @override
  State<FamilyExpensePage> createState() => _FamilyExpensePageState();
}

class _FamilyExpensePageState extends State<FamilyExpensePage> {
  static const int _pageSize = 20;

  final _service = NocoDBService();
  final _scrollController = ScrollController();

  String _tableId = '';
  String _monthlyTableId = '';
  String _dailyTableId = '';
  String _typeTableId = '';

  final List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _monthlyRows = [];
  List<Map<String, dynamic>> _dailyRows = [];
  List<Map<String, dynamic>> _typeRows = [];

  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  bool _isMonthlyLoading = false;
  String? _monthlyError;
  bool _isDailyLoading = false;
  String? _dailyError;
  bool _isTypeLoading = false;
  String? _typeError;
  late DateTime _dailyFocusedMonth;
  late int _monthlyFocusedYear;
  int _dailyHeatmapMode = 1;
  static const int _dailyHeatLevels = 20;
  static const double _heatmapOpacity = 0.75;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dailyFocusedMonth = DateTime(now.year, now.month);
    _monthlyFocusedYear = now.year;
    _scrollController.addListener(_onScroll);
    _initLoad();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (maxScroll - current <= 400) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    await _loadExpenseConfig();
    setState(() {
      _rows.clear();
      _monthlyRows = [];
      _dailyRows = [];
      _typeRows = [];
      _offset = 0;
      _hasMore = true;
      _error = null;
      _monthlyError = null;
      _dailyError = null;
      _typeError = null;
    });
    await Future.wait([_loadDaily(), _loadMonthly(), _loadTypes(), _loadMore()]);
  }

  Future<void> _loadExpenseConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final tableId = (prefs.getString('family_expense_table_id') ?? '').trim();
    final monthlyTableId =
        (prefs.getString('family_expense_monthly_table_id') ?? '').trim();
    final dailyTableId =
        (prefs.getString('family_expense_daily_table_id') ?? '').trim();
    final typeTableId =
        (prefs.getString('family_expense_type_table_id') ?? '').trim();
    if (!mounted) return;
    setState(() {
      _tableId = tableId;
      _monthlyTableId = monthlyTableId;
      _dailyTableId = dailyTableId;
      _typeTableId = typeTableId;
    });
  }

  Future<void> _initLoad() async {
    await _loadExpenseConfig();
    if (!mounted) return;
    await Future.wait([_loadDaily(), _loadMonthly(), _loadTypes(), _loadMore()]);
  }

  Future<void> _loadDaily() async {
    if (_isDailyLoading) return;
    setState(() {
      _isDailyLoading = true;
      _dailyError = null;
    });

    try {
      if (_dailyTableId.isEmpty) {
        throw AppLocalizations.of(context)!.familyExpenseMissingConfig;
      }
      final List<Map<String, dynamic>> all = [];
      int offset = 0;
      const int limit = 200;
      for (int i = 0; i < 50; i++) {
        final batch = await _service.fetchRowsFromTable(
          _dailyTableId,
          offset,
          limit: limit,
        );
        all.addAll(batch);
        offset += batch.length;
        if (batch.length < limit) break;
      }
      if (!mounted) return;
      setState(() {
        _dailyRows = all;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dailyError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDailyLoading = false;
        });
      }
    }
  }

  Future<void> _loadMonthly() async {
    if (_isMonthlyLoading) return;
    setState(() {
      _isMonthlyLoading = true;
      _monthlyError = null;
    });

    try {
      if (_monthlyTableId.isEmpty) {
        throw AppLocalizations.of(context)!.familyExpenseMissingConfig;
      }
      final List<Map<String, dynamic>> all = [];
      int offset = 0;
      const int limit = 100;
      for (int i = 0; i < 50; i++) {
        final batch = await _service.fetchRowsFromTable(
          _monthlyTableId,
          offset,
          limit: limit,
        );
        all.addAll(batch);
        offset += batch.length;
        if (batch.length < limit) break;
      }
      if (!mounted) return;
      setState(() {
        _monthlyRows = all;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _monthlyError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isMonthlyLoading = false;
        });
      }
    }
  }

  Future<void> _loadTypes() async {
    if (_isTypeLoading) return;
    setState(() {
      _isTypeLoading = true;
      _typeError = null;
    });

    try {
      if (_typeTableId.isEmpty) {
        throw AppLocalizations.of(context)!.familyExpenseMissingConfig;
      }
      final List<Map<String, dynamic>> all = [];
      int offset = 0;
      const int limit = 200;
      for (int i = 0; i < 50; i++) {
        final batch = await _service.fetchRowsFromTable(
          _typeTableId,
          offset,
          limit: limit,
        );
        all.addAll(batch);
        offset += batch.length;
        if (batch.length < limit) break;
      }
      if (!mounted) return;
      setState(() {
        _typeRows = all;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _typeError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTypeLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_tableId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = AppLocalizations.of(context)!.familyExpenseMissingConfig;
          _hasMore = false;
        });
        return;
      }
      final newRows = await _service.fetchRowsFromTable(
        _tableId,
        _offset,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _rows.addAll(newRows);
        _offset += newRows.length;
        _hasMore = newRows.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double? _tryParseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final cleaned = text.replaceAll(RegExp(r'[^0-9.\\-]'), '');
    return double.tryParse(cleaned);
  }

  double? _rowAmount(Map<String, dynamic> row) {
    const keys = [
      '金额',
      '支出',
      '花费',
      '总支出',
      '合计',
      'Total',
      'total',
      'Amount',
      'amount',
      'price',
      'cost',
    ];
    for (final k in keys) {
      if (row.containsKey(k)) {
        final v = _tryParseAmount(row[k]);
        if (v != null) return v;
      }
    }
    return null;
  }

  String _rowTitle(Map<String, dynamic> row) {
    const keys = ['商品', 'Title', '标题', '名称', '用途', '分类', '项目', 'Id', 'id'];
    for (final k in keys) {
      final v = row[k];
      if (v == null) continue;
      if(v is Map){
        if(v.containsKey('Title')){
          return v['Title'];
        }
        continue;
      }
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '记录';
  }

  String _formatSubtitle(Map<String, dynamic> row) {
    final parts = <String>[];
    const dateKeys = ['交易时间', '日期', 'date', 'Date', 'created_at', 'CreatedAt'];
    for (final k in dateKeys) {
      final v = row[k];
      if (v == null) continue;
      final s = v.toString().split('+')[0].trim();
      if (s.isNotEmpty) {
        parts.add(s);
        break;
      }
    }

    final amount = _rowAmount(row);
    if (amount != null) {
      parts.add('¥${amount.toStringAsFixed(2)}');
    }

    const categoryKeys = ['分类', 'category', 'Category', '标签', 'tag', 'Tag'];
    for (final k in categoryKeys) {
      final v = row[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) {
        parts.add(s);
        break;
      }
    }

    return parts.join(' · ');
  }

  String? _normalizeMonth(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');
    final isoMatch = iso.firstMatch(s);
    if (isoMatch != null) {
      return '${isoMatch.group(1)}-${isoMatch.group(2)}';
    }

    final isoMonth = RegExp(r'^(\d{4})-(\d{2})');
    final isoMonthMatch = isoMonth.firstMatch(s);
    if (isoMonthMatch != null) {
      return '${isoMonthMatch.group(1)}-${isoMonthMatch.group(2)}';
    }

    final slash = RegExp(r'^(\d{4})/(\\d{1,2})/(\\d{1,2})');
    final slashMatch = slash.firstMatch(s);
    if (slashMatch != null) {
      final m = int.parse(slashMatch.group(2)!);
      final mm = m.toString().padLeft(2, '0');
      return '${slashMatch.group(1)}-$mm';
    }

    final ymSlash = RegExp(r'^(\d{4})/(\\d{1,2})');
    final ymSlashMatch = ymSlash.firstMatch(s);
    if (ymSlashMatch != null) {
      final m = int.parse(ymSlashMatch.group(2)!);
      final mm = m.toString().padLeft(2, '0');
      return '${ymSlashMatch.group(1)}-$mm';
    }

    final chinese = RegExp(r'(\\d{4}).*?(\\d{1,2})');
    final chineseMatch = chinese.firstMatch(s);
    if (chineseMatch != null) {
      final m = int.parse(chineseMatch.group(2)!);
      final mm = m.toString().padLeft(2, '0');
      return '${chineseMatch.group(1)}-$mm';
    }

    final ym = RegExp(r'^(\\d{4})(\\d{2})(\\d{2})$');
    final ymMatch = ym.firstMatch(s);
    if (ymMatch != null) {
      return '${ymMatch.group(1)}-${ymMatch.group(2)}';
    }

    return s;
  }

  String? _normalizeDay(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final iso = RegExp(r'^(\\d{4})-(\\d{2})-(\\d{2})');
    final isoMatch = iso.firstMatch(s);
    if (isoMatch != null) {
      return '${isoMatch.group(1)}-${isoMatch.group(2)}-${isoMatch.group(3)}';
    }

    final slash = RegExp(r'^(\\d{4})/(\\d{1,2})/(\\d{1,2})');
    final slashMatch = slash.firstMatch(s);
    if (slashMatch != null) {
      final m = int.parse(slashMatch.group(2)!);
      final d = int.parse(slashMatch.group(3)!);
      final mm = m.toString().padLeft(2, '0');
      final dd = d.toString().padLeft(2, '0');
      return '${slashMatch.group(1)}-$mm-$dd';
    }

    final chinese = RegExp(r'(\\d{4}).*?(\\d{1,2}).*?(\\d{1,2})');
    final chineseMatch = chinese.firstMatch(s);
    if (chineseMatch != null) {
      final m = int.parse(chineseMatch.group(2)!);
      final d = int.parse(chineseMatch.group(3)!);
      final mm = m.toString().padLeft(2, '0');
      final dd = d.toString().padLeft(2, '0');
      return '${chineseMatch.group(1)}-$mm-$dd';
    }

    final compact = RegExp(r'^(\\d{4})(\\d{2})(\\d{2})$');
    final compactMatch = compact.firstMatch(s);
    if (compactMatch != null) {
      return '${compactMatch.group(1)}-${compactMatch.group(2)}-${compactMatch.group(3)}';
    }

    return s;
  }

  String? _rowDay(Map<String, dynamic> row) {
    const keys = [
      '日期',
      '日',
      'date',
      'Date',
      'day',
      'Day',
      'created_at',
      'CreatedAt',
    ];
    for (final k in keys) {
      final v = row[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) {
        return _normalizeDay(s) ?? s;
      }
    }
    return null;
  }

  String? _rowMonth(Map<String, dynamic> row) {
    const keys = [
      '月份',
      '月',
      '年月',
      'month',
      'Month',
      'yearMonth',
      'YearMonth',
    ];
    for (final k in keys) {
      final v = row[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) {
        return _normalizeMonth(s) ?? s;
      }
    }
    return null;
  }

  String? _rowType(Map<String, dynamic> row) {
    String? pickTitleFromMap(Map map) {
      final v = map['Title'] ?? map['title'] ?? map['Name'] ?? map['name'];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    String? pickFromDynamic(dynamic v) {
      if (v == null) return null;
      if (v is Map) return pickTitleFromMap(v);
      if (v is List) {
        for (final e in v) {
          final picked = pickFromDynamic(e);
          if (picked != null && picked.isNotEmpty) return picked;
        }
        return null;
      }
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    const keys = [
      'Title',
      'title',
      '类型',
      '支出类型',
      '分类',
      '标签',
      'type',
      'Type',
      'category',
      'Category',
      'tag',
      'Tag',
    ];
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final picked = pickFromDynamic(row[k]);
      if (picked != null && picked.isNotEmpty) return picked;
    }
    return null;
  }

  int? _rowProductCount(Map<String, dynamic> row) {
    const keys = [
      '商品',
      '商品s',
      'products',
      'Products',
      'items',
      'Items',
    ];
    for (final k in keys) {
      final v = row[k];
      if (v == null) continue;
      if (v is num) return v.toInt();
      if (v is List) return v.length;
      if (v is Map) {
        final candidates = [
          v['count'],
          v['Count'],
          v['length'],
          v['Length'],
          v['total'],
          v['Total'],
        ];
        for (final c in candidates) {
          if (c is num) return c.toInt();
          if (c is String) {
            final match = RegExp(r'(\d+)').firstMatch(c);
            if (match != null) return int.tryParse(match.group(1)!);
          }
        }
      }
      final s = v.toString();
      final match = RegExp(r'(\d+)').firstMatch(s);
      if (match != null) return int.tryParse(match.group(1)!);
    }
    return null;
  }

  Map<String, double> _monthlyTotals() {
    final Map<String, double> totals = {};
    for (final r in _monthlyRows) {
      final month = _rowMonth(r);
      final amount = _rowAmount(r);
      if (month == null || amount == null) continue;
      totals[month] = (totals[month] ?? 0) + amount;
    }
    return totals;
  }

  DateTime? _tryParseIsoDay(String raw) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw.trim());
    if (match == null) return null;
    final y = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    final d = int.tryParse(match.group(3)!);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Map<DateTime, double> _dailyTotals() {
    final Map<DateTime, double> totals = {};
    for (final r in _dailyRows) {
      final dayStr = _rowDay(r);
      final amount = _rowAmount(r);
      if (dayStr == null || amount == null) continue;
      final dt = _tryParseIsoDay(dayStr);
      if (dt == null) continue;
      final key = DateTime(dt.year, dt.month, dt.day);
      totals[key] = (totals[key] ?? 0) + amount;
    }
    return totals;
  }

  int _toHeatLevel(double amount, double maxInMonth) {
    if (maxInMonth <= 0) return 0;
    final t = (amount / maxInMonth).clamp(0.0, 1.0);
    final level = (t * _dailyHeatLevels).ceil();
    if (level < 0) return 0;
    if (level > _dailyHeatLevels) return _dailyHeatLevels;
    return level;
  }

  int _toHeatLevelInRange(double amount, double minInMonth, double maxInMonth) {
    if (maxInMonth <= 0) return 0;
    if (maxInMonth <= minInMonth) {
      return amount > 0 ? _dailyHeatLevels : 0;
    }
    final t = ((amount - minInMonth) / (maxInMonth - minInMonth)).clamp(0.0, 1.0);
    final level = (t * (_dailyHeatLevels - 1)).round() + 1;
    if (level < 1) return 1;
    if (level > _dailyHeatLevels) return _dailyHeatLevels;
    return level;
  }

  Color _applyHeatOpacity(Color color) {
    if (_heatmapOpacity >= 1.0) return color;
    if (_heatmapOpacity <= 0.0) return Colors.white;
    return Color.alphaBlend(
      color.withValues(alpha: _heatmapOpacity),
      Colors.white,
    );
  }

  Color _monoHeatColor(int level) {
    if (level <= 0) return Colors.white;
    final t = level / _dailyHeatLevels;
    final base = Color.lerp(Colors.white, Colors.black, t * 0.85)!;
    return _applyHeatOpacity(base);
  }

  Color _colorHeatColor(int level) {
    if (level <= 0) return Colors.white;
    const palette = <Color>[
      Color(0xFF313695),
      Color(0xFF3B5AA9),
      Color(0xFF457BBE),
      Color(0xFF4F97CE),
      Color(0xFF63ADD4),
      Color(0xFF7BC2DF),
      Color(0xFF9BD3EA),
      Color(0xFFBDE0F0),
      Color(0xFFD8E9F4),
      Color(0xFFEEF2F7),
      Color(0xFFF7EFEA),
      Color(0xFFF6D9C7),
      Color(0xFFF5BCA3),
      Color(0xFFF29A80),
      Color(0xFFEA7B67),
      Color(0xFFDE5C58),
      Color(0xFFCB444B),
      Color(0xFFB5333E),
      Color(0xFFA0222F),
      Color(0xFF7F0000),
    ];
    final idx = (level - 1).clamp(0, palette.length - 1);
    return _applyHeatOpacity(palette[idx]);
  }

  Widget _buildDailyCard(BuildContext context) {
    final totals = _dailyTotals();
    final focused = _dailyFocusedMonth;
    final year = focused.year;
    final month = focused.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.familyExpenseDaily,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _dailyHeatmapMode == 0
                    ? Icons.grid_view
                    : (_dailyHeatmapMode == 1
                        ? Icons.tonality
                        : Icons.palette_outlined),
              ),
              color: Colors.black87,
              onPressed: () {
                setState(() {
                  _dailyHeatmapMode = (_dailyHeatmapMode + 1) % 3;
                });
              },
              tooltip: 'View mode',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              color: Colors.black87,
              onPressed: () {
                setState(() {
                  _dailyFocusedMonth = DateTime(year, month - 1);
                });
              },
              tooltip: 'Previous month',
            ),
            Text(
              '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: Colors.black87,
              onPressed: () {
                setState(() {
                  _dailyFocusedMonth = DateTime(year, month + 1);
                });
              },
              tooltip: 'Next month',
            ),
          ],
        ),
      ),
    ];

    if (_dailyError != null && _dailyRows.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Text(
            _dailyError!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    } else if (_isDailyLoading && _dailyRows.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      final isZh = Localizations.localeOf(context).languageCode == 'zh';
      final weekdays = isZh
          ? const ['一', '二', '三', '四', '五', '六', '日']
          : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      final now = DateTime.now();
      final cells = leadingEmpty + daysInMonth;
      final rows = ((cells + 6) ~/ 7);
      final totalCells = rows * 7;
      final bool heatmapOn = _dailyHeatmapMode != 0;
      double minInMonth = double.infinity;
      double maxInMonth = 0.0;
      if (heatmapOn) {
        for (final e in totals.entries) {
          final k = e.key;
          if (k.year == year && k.month == month) {
            final v = e.value;
            if (v > maxInMonth) maxInMonth = v;
            if (v < minInMonth) minInMonth = v;
          }
        }
        if (minInMonth == double.infinity) minInMonth = 0.0;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.85,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNumber = index - leadingEmpty + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(year, month, dayNumber);
              final key = DateTime(date.year, date.month, date.day);
              final amount = totals[key];

              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              Color bgColor = Colors.white;
              Color borderColor = Colors.grey[300]!;

              if (heatmapOn) {
                final level = (amount != null && maxInMonth > 0)
                    ? _toHeatLevelInRange(amount, minInMonth, maxInMonth)
                    : 0;
                bgColor = _dailyHeatmapMode == 1
                    ? _monoHeatColor(level)
                    : _colorHeatColor(level);
                borderColor = isToday ? Colors.black87 : Colors.transparent;
              } else {
                borderColor = isToday ? Colors.black87 : Colors.grey[300]!;
                bgColor = amount != null ? Colors.grey[100]! : Colors.white;
              }

              final valueTextColor = bgColor.computeLuminance() < 0.45 ? Colors.white : Colors.black87;

              return Material(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: amount == null
                      ? null
                      : () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              final ds =
                                  '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                              return SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        ds,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '¥${amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                color: valueTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (amount != null)
                          SizedBox(
                            height: 14,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '¥${amount.toStringAsFixed(0)}',
                                maxLines: 1,
                                style: TextStyle(
                                  color: valueTextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      if (!_isDailyLoading && totals.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              AppLocalizations.of(context)!.noDailyData,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        );
      }

      if (_isDailyLoading) {
        children.add(
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildMonthlyCard(BuildContext context) {
    final totals = _monthlyTotals();
    final year = _monthlyFocusedYear;
    final heatmapOn = _dailyHeatmapMode != 0;
    double maxInYear = 0.0;
    for (int m = 1; m <= 12; m++) {
      final key = '${year.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}';
      final v = totals[key];
      if (v != null && v > maxInYear) maxInYear = v;
    }

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.familyExpenseMonthly,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _dailyHeatmapMode == 0
                    ? Icons.grid_view
                    : (_dailyHeatmapMode == 1 ? Icons.tonality : Icons.palette_outlined),
              ),
              color: Colors.black87,
              onPressed: () {
                setState(() {
                  _dailyHeatmapMode = (_dailyHeatmapMode + 1) % 3;
                });
              },
              tooltip: 'View mode',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              color: Colors.black87,
              onPressed: () {
                setState(() {
                  _monthlyFocusedYear = year - 1;
                });
              },
              tooltip: 'Previous year',
            ),
            Text(
              year.toString(),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: Colors.black87,
              onPressed: () {
                setState(() {
                  _monthlyFocusedYear = year + 1;
                });
              },
              tooltip: 'Next year',
            ),
          ],
        ),
      ),
    ];

    if (_monthlyError != null && _monthlyRows.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Text(
            _monthlyError!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    } else if (_isMonthlyLoading && _monthlyRows.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (totals.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Text(
            AppLocalizations.of(context)!.noMonthlyData,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    } else {
      final now = DateTime.now();
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final key = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
              final amount = totals[key];
              final isCurrent = year == now.year && month == now.month;

              Color bgColor = Colors.white;
              Color borderColor = Colors.grey[300]!;
              if (heatmapOn) {
                final level = (amount != null && maxInYear > 0)
                    ? _toHeatLevel(amount, maxInYear)
                    : 0;
                bgColor = _dailyHeatmapMode == 1
                    ? _monoHeatColor(level)
                    : _colorHeatColor(level);
                borderColor = isCurrent ? Colors.black87 : Colors.transparent;
              } else {
                borderColor = isCurrent ? Colors.black87 : Colors.grey[300]!;
                bgColor = amount != null ? Colors.grey[100]! : Colors.white;
              }
              final valueTextColor =
                  bgColor.computeLuminance() < 0.45 ? Colors.white : Colors.black87;

              final isZh = Localizations.localeOf(context).languageCode == 'zh';
              final label = isZh
                  ? '$month月'
                  : const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][month - 1];

              return Material(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _MonthlyDailyCalendarPage(
                          initialMonth: DateTime(year, month),
                          initialHeatmapMode: _dailyHeatmapMode,
                          initialDailyRows: _dailyRows,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: valueTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (amount != null)
                          SizedBox(
                            height: 18,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '¥${amount.toStringAsFixed(0)}',
                                maxLines: 1,
                                style: TextStyle(
                                  color: valueTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      if (_isMonthlyLoading) {
        children.add(
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context) {
    final Map<String, double> totals = {};
    final Map<String, int> productCounts = {};
    for (final r in _typeRows) {
      final title = _rowType(r) ?? _rowTitle(r);
      final amount = _rowAmount(r);
      final count = _rowProductCount(r) ?? 0;
      if (amount == null) continue;
      totals[title] = (totals[title] ?? 0) + amount;
      productCounts[title] = (productCounts[title] ?? 0) + count;
    }

    final entries = totals.entries.where((e) => e.value != 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    const int pieTopN = 6;
    final Map<String, Color> typeColors = {};
    final int topCount = min(pieTopN, entries.length);
    for (int i = 0; i < topCount; i++) {
      typeColors[entries[i].key] = Colors.primaries[i % Colors.primaries.length].shade600;
    }
    final othersColor = Colors.grey[600]!;
    final List<_PieSlice> pieSlices = [];
    double pieOtherValue = 0.0;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (i < topCount) {
        pieSlices.add(
          _PieSlice(
            value: e.value,
            color: typeColors[e.key]!,
            label: e.key,
          ),
        );
      } else {
        pieOtherValue += e.value;
      }
    }
    if (pieOtherValue != 0) {
      pieSlices.add(
        _PieSlice(
          value: pieOtherValue,
          color: othersColor,
          label: isZh ? '其他' : 'Others',
        ),
      );
    }

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          AppLocalizations.of(context)!.familyExpenseType,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];

    if (_typeError != null && _typeRows.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Text(
            _typeError!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    } else if (_isTypeLoading && _typeRows.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (entries.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Text(
            AppLocalizations.of(context)!.noTypeData,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    } else {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
              final chartWidth = min(w, 360.0);
              return Center(
                child: SizedBox(
                  width: chartWidth,
                  height: 220,
                  child: _TypePieChart(slices: pieSlices),
                ),
              );
            },
          ),
        ),
      );
      for (int i = 0; i < entries.length; i++) {
        final e = entries[i];
        final count = productCounts[e.key] ?? 0;
        final ratio = maxValue > 0 ? (e.value / maxValue).clamp(0.0, 1.0) : 0.0;
        final dotColor = typeColors[e.key] ?? othersColor;

        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$count 商品',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '¥${e.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        );
        if (i != entries.length - 1) {
          children.add(Divider(height: 1, color: Colors.grey[200]));
        }
      }

      if (_isTypeLoading) {
        children.add(
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSummaryCard() {
    int amountCount = 0;
    double sum = 0;
    for (final r in _rows) {
      final a = _rowAmount(r);
      if (a != null) {
        amountCount += 1;
        sum += a;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '记录数: ${_rows.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (amountCount > 0)
              Text(
                '合计: ¥${sum.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowCard(Map<String, dynamic> row) {
    final title = _rowTitle(row);
    final subtitle = _formatSubtitle(row);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = AppLocalizations.of(context)!.familyExpense;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: 1 + _rows.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              final topChildren = <Widget>[
                _buildMonthlyCard(context),
                _buildDailyCard(context),
                _buildTypeCard(context),
              ];

              if (_error != null && _rows.isEmpty) {
                topChildren.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (_rows.isEmpty && _isLoading) {
                topChildren.add(
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              } else {
                topChildren.add(_buildSummaryCard());
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: topChildren,
              );
            }

            final rowsStartIndex = 1;
            final rowIndex = index - rowsStartIndex;
            if (rowIndex < _rows.length) {
              return _buildRowCard(_rows[rowIndex]);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryBillsPage extends StatelessWidget {
  final String category;
  final int year;
  final int month;
  final List<Map<String, dynamic>> rows;

  const _CategoryBillsPage({
    required this.category,
    required this.year,
    required this.month,
    required this.rows,
  });

  String? _pickStringFromDynamic(dynamic v) {
    if (v == null) return null;
    if (v is Map) {
      final candidate = v['Title'] ?? v['title'] ?? v['Name'] ?? v['name'];
      if (candidate == null) return null;
      final s = candidate.toString().trim();
      return s.isEmpty ? null : s;
    }
    if (v is List) {
      for (final e in v) {
        final picked = _pickStringFromDynamic(e);
        if (picked != null && picked.isNotEmpty) return picked;
      }
      return null;
    }
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String _rowTitle(Map<String, dynamic> row) {
    const keys = ['商品', 'Title', '标题', '名称', '用途', '分类', '项目', 'Id', 'id'];
    for (final k in keys) {
      final v = row[k];
      if (v == null) continue;
      if (v is Map) {
        if (v.containsKey('Title')) {
          final t = v['Title']?.toString().trim();
          if (t != null && t.isNotEmpty) return t;
        }
        continue;
      }
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '记录';
  }

  String? _rowUser(Map<String, dynamic> row) {
    const keys = [
      '用户',
      'user',
      'User',
      '付款人',
      '支付人',
      '成员',
      'member',
      'Member',
      'person',
      'Person',
    ];
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final picked = _pickStringFromDynamic(row[k]);
      if (picked != null && picked.isNotEmpty) return picked;
    }
    return null;
  }

  String? _rowPayMethod(Map<String, dynamic> row) {
    const keys = [
      'Type (from 源文件)',
      '支付方式',
      '支付渠道',
      '支付',
      'payment',
      'Payment',
      'payMethod',
      'PayMethod',
      'channel',
      'Channel',
      '账户',
      'account',
      'Account',
    ];
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final picked = _pickStringFromDynamic(row[k]);
      if (picked != null && picked.isNotEmpty) return picked;
    }
    return null;
  }

  Widget _badge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[900],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ms =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(
        title: Text('$category  $ms'),
      ),
      body: ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final r = rows[index];
          final title = _rowTitle(r);
          final dayStr = _MonthlyDailyCalendarPageState._rowDay(r);
          final amount = _MonthlyDailyCalendarPageState._rowAmount(r) ?? 0.0;
          final user = _rowUser(r);
          final payMethod = _rowPayMethod(r);
          final datePart = () {
            if (dayStr == null) return '';
            final dt = _MonthlyDailyCalendarPageState._tryParseIsoDay(dayStr);
            if (dt == null) return dayStr;
            return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          }();
          final parts = <String>[];
          if (datePart.isNotEmpty) parts.add(datePart);
          parts.add('¥${amount.toStringAsFixed(2)}');
          if (user != null && user.isNotEmpty) parts.add(user);
          if (payMethod != null && payMethod.isNotEmpty) parts.add(payMethod);
          return ListTile(
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in parts) _badge(context, p),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
class _DayBillsPage extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> rows;

  const _DayBillsPage({
    required this.date,
    required this.rows,
  });

  String? _pickStringFromDynamic(dynamic v) {
    if (v == null) return null;
    if (v is Map) {
      final candidate = v['Title'] ?? v['title'] ?? v['Name'] ?? v['name'];
      if (candidate == null) return null;
      final s = candidate.toString().trim();
      return s.isEmpty ? null : s;
    }
    if (v is List) {
      for (final e in v) {
        final picked = _pickStringFromDynamic(e);
        if (picked != null && picked.isNotEmpty) return picked;
      }
      return null;
    }
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String _rowTitle(Map<String, dynamic> row) {
    const keys = ['商品', 'Title', '标题', '名称', '用途', '分类', '项目', 'Id', 'id'];
    for (final k in keys) {
      final v = row[k];
      if (v == null) continue;
      if (v is Map) {
        if (v.containsKey('Title')) {
          final t = v['Title']?.toString().trim();
          if (t != null && t.isNotEmpty) return t;
        }
        continue;
      }
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '记录';
  }

  String? _rowUser(Map<String, dynamic> row) {
    const keys = [
      '用户',
      'user',
      'User',
      '付款人',
      '支付人',
      '成员',
      'member',
      'Member',
      'person',
      'Person',
    ];
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final picked = _pickStringFromDynamic(row[k]);
      if (picked != null && picked.isNotEmpty) return picked;
    }
    return null;
  }

  String? _rowPayMethod(Map<String, dynamic> row) {
    const keys = [
      'Type (from 源文件)',
      '支付方式',
      '支付渠道',
      '支付',
      'payment',
      'Payment',
      'payMethod',
      'PayMethod',
      'channel',
      'Channel',
      '账户',
      'account',
      'Account',
    ];
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final picked = _pickStringFromDynamic(row[k]);
      if (picked != null && picked.isNotEmpty) return picked;
    }
    return null;
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[900],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final total = rows.fold<double>(
      0.0,
      (s, r) => s + ((_MonthlyDailyCalendarPageState._rowAmount(r) ?? 0.0).abs()),
    );
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final emptyText = isZh ? '暂无账单' : 'No bills';

    return Scaffold(
      appBar: AppBar(
        title: Text(ds),
      ),
      body: rows.isEmpty
          ? Center(
              child: Text(
                emptyText,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : ListView.separated(
              itemCount: rows.length + 1,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isZh ? '合计' : 'Total',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '¥${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final r = rows[index - 1];
                final title = _rowTitle(r);
                final amount = _MonthlyDailyCalendarPageState._rowAmount(r) ?? 0.0;
                final user = _rowUser(r);
                final payMethod = _rowPayMethod(r);
                final parts = <String>[];
                parts.add('¥${amount.toStringAsFixed(2)}');
                if (user != null && user.isNotEmpty) parts.add(user);
                if (payMethod != null && payMethod.isNotEmpty) parts.add(payMethod);

                return ListTile(
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: parts.isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final p in parts) _badge(p),
                            ],
                          ),
                        ),
                );
              },
            ),
    );
  }
}
class _PieSlice {
  final double value;
  final Color color;
  final String label;

  const _PieSlice({required this.value, required this.color, required this.label});
}

class _TypePieChart extends StatelessWidget {
  final List<_PieSlice> slices;

  const _TypePieChart({required this.slices});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TypePieChartPainter(slices),
    );
  }
}

class _TypePieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;

  _TypePieChartPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0.0, (sum, s) => sum + s.value.abs());
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    const labelMargin = 44.0;
    final radius = min(size.width, size.height) / 2 - labelMargin;
    if (radius <= 0) return;
    final ringWidth = max(10.0, radius * 0.26);
    final arcRadius = radius - ringWidth / 2;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.butt
      ..color = Colors.grey[200]!;
    canvas.drawCircle(center, arcRadius, bg);

    double start = -pi / 2;
    final labelInfos = <_PieLabelInfo>[];
    for (final slice in slices) {
      final v = slice.value.abs();
      if (v <= 0) continue;
      final sweep = (v / total) * pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.butt
        ..color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        start,
        sweep,
        false,
        paint,
      );
      if (slice.label.trim().isNotEmpty && sweep >= 0.22) {
        final mid = start + sweep / 2;
        final side = cos(mid) >= 0 ? _PieLabelSide.right : _PieLabelSide.left;
        labelInfos.add(
          _PieLabelInfo(
            label: slice.label,
            color: slice.color,
            value: v,
            midAngle: mid,
            side: side,
          ),
        );
      }
      start += sweep;
    }

    if (labelInfos.isEmpty) return;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey[600]!;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    final availableLabelWidth = max(0.0, size.width / 2 - radius - 18);
    final left = <_PieLabelLayout>[];
    final right = <_PieLabelLayout>[];

    for (final info in labelInfos) {
      final outer = center + Offset(cos(info.midAngle) * radius, sin(info.midAngle) * radius);
      final knee = center +
          Offset(cos(info.midAngle) * (radius + 10), sin(info.midAngle) * (radius + 10));
      final anchorX =
          info.side == _PieLabelSide.right ? center.dx + radius + 18 : center.dx - radius - 18;

      final percent = (info.value / total) * 100;
      final percentText = percent.toStringAsFixed(1);
      final amountText = info.value.toStringAsFixed(2);
      final tp = TextPainter(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: '${info.label}\n'),
            TextSpan(
              text: '$percentText%  ¥$amountText',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        maxLines: 2,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
        textAlign: info.side == _PieLabelSide.right ? TextAlign.left : TextAlign.right,
      );
      tp.layout(maxWidth: availableLabelWidth);

      final layout = _PieLabelLayout(
        info: info,
        outer: outer,
        knee: knee,
        anchorX: anchorX,
        textPainter: tp,
        targetY: knee.dy,
      );
      if (info.side == _PieLabelSide.right) {
        right.add(layout);
      } else {
        left.add(layout);
      }
    }

    double leftGap = 14;
    double rightGap = 14;
    if (left.isNotEmpty) {
      leftGap = left
              .map((e) => e.textPainter.height)
              .reduce((a, b) => a > b ? a : b) +
          6;
    }
    if (right.isNotEmpty) {
      rightGap = right
              .map((e) => e.textPainter.height)
              .reduce((a, b) => a > b ? a : b) +
          6;
    }
    _layoutPieLabels(left, minY: 10, maxY: size.height - 10, gap: leftGap);
    _layoutPieLabels(right, minY: 10, maxY: size.height - 10, gap: rightGap);

    for (final l in [...left, ...right]) {
      dotPaint.color = l.info.color;
      canvas.drawCircle(l.outer, 2.2, dotPaint);

      final anchor = Offset(l.anchorX, l.y);
      final labelEdgeX = l.info.side == _PieLabelSide.right
          ? (l.anchorX + 6)
          : (l.anchorX - 6);

      final path = Path()
        ..moveTo(l.outer.dx, l.outer.dy)
        ..lineTo(l.knee.dx, l.knee.dy)
        ..lineTo(anchor.dx, anchor.dy)
        ..lineTo(labelEdgeX, l.y);
      canvas.drawPath(path, linePaint);

      final tp = l.textPainter;
      final textOffset = l.info.side == _PieLabelSide.right
          ? Offset(l.anchorX + 6, l.y - tp.height / 2)
          : Offset(l.anchorX - 6 - tp.width, l.y - tp.height / 2);
      tp.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _TypePieChartPainter oldDelegate) {
    if (oldDelegate.slices.length != slices.length) return true;
    for (int i = 0; i < slices.length; i++) {
      final a = slices[i];
      final b = oldDelegate.slices[i];
      if (a.value != b.value ||
          a.color.toARGB32() != b.color.toARGB32() ||
          a.label != b.label) {
        return true;
      }
    }
    return false;
  }
}

enum _PieLabelSide { left, right }

class _PieLabelInfo {
  final String label;
  final Color color;
  final double value;
  final double midAngle;
  final _PieLabelSide side;

  const _PieLabelInfo({
    required this.label,
    required this.color,
    required this.value,
    required this.midAngle,
    required this.side,
  });
}

class _PieLabelLayout {
  final _PieLabelInfo info;
  final Offset outer;
  final Offset knee;
  final double anchorX;
  final TextPainter textPainter;
  final double targetY;
  double y;

  _PieLabelLayout({
    required this.info,
    required this.outer,
    required this.knee,
    required this.anchorX,
    required this.textPainter,
    required this.targetY,
  }) : y = targetY;
}

void _layoutPieLabels(
  List<_PieLabelLayout> layouts, {
  required double minY,
  required double maxY,
  required double gap,
}) {
  if (layouts.isEmpty) return;
  layouts.sort((a, b) => a.targetY.compareTo(b.targetY));

  double y = minY;
  for (final l in layouts) {
    l.y = max(l.targetY, y);
    y = l.y + gap;
  }

  final last = layouts.last;
  if (last.y > maxY) {
    final shift = last.y - maxY;
    for (final l in layouts) {
      l.y -= shift;
    }
    for (int i = layouts.length - 2; i >= 0; i--) {
      final next = layouts[i + 1];
      final curr = layouts[i];
      curr.y = min(curr.y, next.y - gap);
    }
    final first = layouts.first;
    if (first.y < minY) {
      final down = minY - first.y;
      for (final l in layouts) {
        l.y += down;
      }
    }
  }
}

class _MonthlyDailyCalendarPage extends StatefulWidget {
  final DateTime initialMonth;
  final int initialHeatmapMode;
  final List<Map<String, dynamic>> initialDailyRows;

  const _MonthlyDailyCalendarPage({
    required this.initialMonth,
    required this.initialHeatmapMode,
    required this.initialDailyRows,
  });

  @override
  State<_MonthlyDailyCalendarPage> createState() => _MonthlyDailyCalendarPageState();
}

class _MonthlyDailyCalendarPageState extends State<_MonthlyDailyCalendarPage> {
  static const int _dailyHeatLevels = 20;
  static const double _heatmapOpacity = 0.75;

  final _service = NocoDBService();
  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _error;
  String? _detailError;
  late DateTime _focusedMonth;
  late int _heatmapMode;
  List<Map<String, dynamic>> _dailyRows = [];
  List<Map<String, dynamic>> _detailRows = [];
  bool _didScheduleInitialLoad = false;

  String _rowTitleInDetail(Map<String, dynamic> row) {
    const keys = ['商品', 'Title', '标题', '名称', '用途', '分类', '项目', 'Id', 'id'];
    for (final k in keys) {
      final v = row[k];
      if (v == null) continue;
      if (v is Map) {
        if (v.containsKey('Title')) {
          final t = v['Title']?.toString().trim();
          if (t != null && t.isNotEmpty) return t;
        }
        continue;
      }
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '记录';
  }

  String? _pickStringFromDynamic(dynamic v) {
    if (v == null) return null;
    if (v is Map) {
      final candidate = v['Title'] ?? v['title'] ?? v['Name'] ?? v['name'];
      if (candidate == null) return null;
      final s = candidate.toString().trim();
      return s.isEmpty ? null : s;
    }
    if (v is List) {
      for (final e in v) {
        final picked = _pickStringFromDynamic(e);
        if (picked != null && picked.isNotEmpty) return picked;
      }
      return null;
    }
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String? _rowUserInDetail(Map<String, dynamic> row) {
    const keys = [
      '用户',
      'user',
      'User',
      '付款人',
      '支付人',
      '成员',
      'member',
      'Member',
      'person',
      'Person',
    ];
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final picked = _pickStringFromDynamic(row[k]);
      if (picked != null && picked.isNotEmpty) return picked;
    }
    return null;
  }

  String? _rowPayMethodInDetail(Map<String, dynamic> row) {
    const keys = [
      'Type (from 源文件)',
      '支付方式',
      '支付渠道',
      '支付',
      'payment',
      'Payment',
      'payMethod',
      'PayMethod',
      'channel',
      'Channel',
      '账户',
      'account',
      'Account',
    ];
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final picked = _pickStringFromDynamic(row[k]);
      if (picked != null && picked.isNotEmpty) return picked;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.initialMonth.year, widget.initialMonth.month);
    _heatmapMode = widget.initialHeatmapMode % 3;
    _dailyRows = List<Map<String, dynamic>>.from(widget.initialDailyRows);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didScheduleInitialLoad) return;
    _didScheduleInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_dailyRows.isEmpty) {
        _loadDaily();
      }
      _loadDetails();
    });
  }

  Future<void> _loadDaily() async {
    if (_isLoading) return;
    final missingConfig = AppLocalizations.of(context)!.familyExpenseMissingConfig;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyTableId =
          (prefs.getString('family_expense_daily_table_id') ?? '').trim();
      if (dailyTableId.isEmpty) {
        throw missingConfig;
      }

      final List<Map<String, dynamic>> all = [];
      int offset = 0;
      const int limit = 200;
      for (int i = 0; i < 50; i++) {
        final batch = await _service.fetchRowsFromTable(
          dailyTableId,
          offset,
          limit: limit,
        );
        all.addAll(batch);
        offset += batch.length;
        if (batch.length < limit) break;
      }
      if (!mounted) return;
      setState(() {
        _dailyRows = all;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDetails() async {
    if (_isDetailLoading) return;
    final missingConfig = AppLocalizations.of(context)!.familyExpenseMissingConfig;
    setState(() {
      _isDetailLoading = true;
      _detailError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final tableId = (prefs.getString('family_expense_table_id') ?? '').trim();
      if (tableId.isEmpty) {
        throw missingConfig;
      }

      final List<Map<String, dynamic>> all = [];
      int offset = 0;
      const int limit = 200;
      for (int i = 0; i < 50; i++) {
        final batch = await _service.fetchRowsFromTable(
          tableId,
          offset,
          limit: limit,
        );
        all.addAll(batch);
        offset += batch.length;
        if (batch.length < limit) break;
      }
      if (!mounted) return;
      setState(() {
        _detailRows = all;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDetailLoading = false;
        });
      }
    }
  }

  static double? _tryParseAmount(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final cleaned = s
        .replaceAll(',', '')
        .replaceAll('¥', '')
        .replaceAll('￥', '')
        .replaceAll(RegExp(r'\s+'), '');
    return double.tryParse(cleaned);
  }

  static DateTime? _tryParseIsoDay(String s) {
    final raw = s.trim();
    if (raw.isEmpty) return null;
    var base = raw.split('T').first.split('+').first.split(' ').first.trim();
    base = base.replaceAll('/', '-');
    if (base.length >= 10) base = base.substring(0, 10);
    return DateTime.tryParse(base);
  }

  static String? _rowDay(Map<String, dynamic> row) {
    const keys = [
      '日期',
      '日',
      'date',
      'Date',
      'day',
      'Day',
      'created_at',
      'CreatedAt',
    ];
    for (final k in keys) {
      final v = row[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static double? _rowAmount(Map<String, dynamic> row) {
    const keys = [
      '金额',
      '支出',
      '花费',
      '总支出',
      '合计',
      'Total',
      'total',
      'Amount',
      'amount',
      'price',
      'cost',
    ];
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final v = _tryParseAmount(row[k]);
      if (v != null) return v;
    }
    return null;
  }

  static String? _rowType(Map<String, dynamic> row) {
    String? pickTitleFromMap(Map map) {
      final v = map['Title'] ?? map['title'] ?? map['Name'] ?? map['name'];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    String? pickFromDynamic(dynamic v) {
      if (v == null) return null;
      if (v is Map) return pickTitleFromMap(v);
      if (v is List) {
        for (final e in v) {
          final picked = pickFromDynamic(e);
          if (picked != null && picked.isNotEmpty) return picked;
        }
        return null;
      }
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    const keys = [
      'Title',
      'title',
      '类型',
      '支出类型',
      '分类',
      '标签',
      'type',
      'Type',
      'category',
      'Category',
      'tag',
      'Tag',
    ];
    for (final k in keys) {
      if (!row.containsKey(k)) continue;
      final picked = pickFromDynamic(row[k]);
      if (picked != null && picked.isNotEmpty) return picked;
    }
    return null;
  }

  Map<DateTime, double> _dailyTotals() {
    final Map<DateTime, double> totals = {};
    for (final r in _dailyRows) {
      final dayStr = _rowDay(r);
      final amount = _rowAmount(r);
      if (dayStr == null || amount == null) continue;
      final dt = _tryParseIsoDay(dayStr);
      if (dt == null) continue;
      final key = DateTime(dt.year, dt.month, dt.day);
      totals[key] = (totals[key] ?? 0) + amount;
    }
    return totals;
  }

  Map<String, double> _typeTotalsInMonth(int year, int month) {
    final Map<String, double> totals = {};
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final uncategorized = isZh ? '未分类' : 'Uncategorized';
    for (final r in _detailRows) {
      final dayStr = _rowDay(r);
      final amount = _rowAmount(r);
      if (dayStr == null || amount == null) continue;
      final dt = _tryParseIsoDay(dayStr);
      if (dt == null || dt.year != year || dt.month != month) continue;
      final type = (_rowType(r) ?? '').trim();
      final key = type.isEmpty ? uncategorized : type;
      totals[key] = (totals[key] ?? 0) + amount;
    }
    return totals;
  }

  List<_PieSlice> _buildTypePieSlicesInMonth(int year, int month) {
    final totals = _typeTotalsInMonth(year, month);
    final entries = totals.entries.where((e) => e.value != 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    const int pieTopN = 6;
    final Map<String, Color> typeColors = {};
    final int topCount = min(pieTopN, entries.length);
    for (int i = 0; i < topCount; i++) {
      typeColors[entries[i].key] =
          Colors.primaries[i % Colors.primaries.length].shade600;
    }
    final othersColor = Colors.grey[600]!;
    final List<_PieSlice> pieSlices = [];
    double pieOtherValue = 0.0;

    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (i < topCount) {
        pieSlices.add(
          _PieSlice(
            value: e.value,
            color: typeColors[e.key]!,
            label: e.key,
          ),
        );
      } else {
        pieOtherValue += e.value;
      }
    }
    if (pieOtherValue != 0) {
      pieSlices.add(
        _PieSlice(
          value: pieOtherValue,
          color: othersColor,
          label: isZh ? '其他' : 'Others',
        ),
      );
    }
    return pieSlices;
  }

  int _toHeatLevelInRange(double value, double min, double max) {
    if (max <= 0) return 0;
    final denom = (max - min).abs();
    if (denom <= 0.000001) return value > 0 ? 1 : 0;
    final t = ((value - min) / denom).clamp(0.0, 1.0);
    return (t * (_dailyHeatLevels - 1)).round() + 1;
  }

  Color _applyHeatOpacity(Color c) => c.withValues(alpha: _heatmapOpacity);

  Color _monoHeatColor(int level) {
    if (level <= 0) return Colors.grey[100]!;
    const palette = [
      Color(0xFFF7F7F7),
      Color(0xFFEDEDED),
      Color(0xFFE2E2E2),
      Color(0xFFD7D7D7),
      Color(0xFFCCCCCC),
      Color(0xFFC1C1C1),
      Color(0xFFB6B6B6),
      Color(0xFFABABAB),
      Color(0xFFA0A0A0),
      Color(0xFF959595),
      Color(0xFF8A8A8A),
      Color(0xFF7F7F7F),
      Color(0xFF747474),
      Color(0xFF696969),
      Color(0xFF5E5E5E),
      Color(0xFF535353),
      Color(0xFF484848),
      Color(0xFF3D3D3D),
      Color(0xFF323232),
      Color(0xFF272727),
    ];
    final idx = (level - 1).clamp(0, palette.length - 1);
    return _applyHeatOpacity(palette[idx]);
  }

  Color _colorHeatColor(int level) {
    if (level <= 0) return Colors.grey[100]!;
    const palette = [
      Color(0xFFF7EFEA),
      Color(0xFFF6D9C7),
      Color(0xFFF5BCA3),
      Color(0xFFF29A80),
      Color(0xFFEA7B67),
      Color(0xFFDE5C58),
      Color(0xFFCB444B),
      Color(0xFFB5333E),
      Color(0xFFA0222F),
      Color(0xFF7F0000),
      Color(0xFF6F0E3A),
      Color(0xFF601B6E),
      Color(0xFF4C2C8A),
      Color(0xFF2D3B8F),
      Color(0xFF174C96),
      Color(0xFF0062A3),
      Color(0xFF007BB0),
      Color(0xFF0095B5),
      Color(0xFF00AEB1),
      Color(0xFF00C59F),
    ];
    final idx = (level - 1).clamp(0, palette.length - 1);
    return _applyHeatOpacity(palette[idx]);
  }

  @override
  Widget build(BuildContext context) {
    final totals = _dailyTotals();
    final focused = _focusedMonth;
    final year = focused.year;
    final month = focused.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final ms =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final weekdays = isZh
        ? const ['一', '二', '三', '四', '五', '六', '日']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final bool heatmapOn = _heatmapMode != 0;
    double minInMonth = double.infinity;
    double maxInMonth = 0.0;
    if (heatmapOn) {
      for (final e in totals.entries) {
        final k = e.key;
        if (k.year == year && k.month == month) {
          final v = e.value;
          if (v > maxInMonth) maxInMonth = v;
          if (v < minInMonth) minInMonth = v;
        }
      }
      if (minInMonth == double.infinity) minInMonth = 0.0;
    }

    final now = DateTime.now();
    final cells = leadingEmpty + daysInMonth;
    final rows = ((cells + 6) ~/ 7);
    final totalCells = rows * 7;

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context)!.familyExpenseDaily}  $ms'),
        actions: [
          IconButton(
            icon: Icon(
              _heatmapMode == 0
                  ? Icons.grid_view
                  : (_heatmapMode == 1
                      ? Icons.tonality
                      : Icons.palette_outlined),
            ),
            onPressed: () {
              setState(() {
                _heatmapMode = (_heatmapMode + 1) % 3;
              });
            },
            tooltip: 'View mode',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(year, month - 1);
              });
            },
            tooltip: 'Previous month',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(year, month + 1);
              });
            },
            tooltip: 'Next month',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadDaily(), _loadDetails()]);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  for (final w in weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  final dayNumber = index - leadingEmpty + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final date = DateTime(year, month, dayNumber);
                  final key = DateTime(date.year, date.month, date.day);
                  final amount = totals[key];

                  final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

                  Color bgColor = Colors.white;
                  Color borderColor = Colors.grey[300]!;

                  if (heatmapOn) {
                    final level = (amount != null && maxInMonth > 0)
                        ? _toHeatLevelInRange(amount, minInMonth, maxInMonth)
                        : 0;
                    bgColor = _heatmapMode == 1
                        ? _monoHeatColor(level)
                        : _colorHeatColor(level);
                    borderColor = isToday ? Colors.black87 : Colors.transparent;
                  } else {
                    borderColor = isToday ? Colors.black87 : Colors.grey[300]!;
                    bgColor = amount != null ? Colors.grey[100]! : Colors.white;
                  }

                  final valueTextColor = bgColor.computeLuminance() < 0.45
                      ? Colors.white
                      : Colors.black87;

                  return Material(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (_isDetailLoading && _detailRows.isEmpty) {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => const SafeArea(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            ),
                          );
                          return;
                        }
                        final dayRows = _detailRows.where((r) {
                          final dayStr = _rowDay(r);
                          if (dayStr == null) return false;
                          final dt = _tryParseIsoDay(dayStr);
                          if (dt == null) return false;
                          return dt.year == date.year &&
                              dt.month == date.month &&
                              dt.day == date.day;
                        }).toList()
                          ..sort((a, b) {
                            final va = (_rowAmount(a) ?? 0.0).abs();
                            final vb = (_rowAmount(b) ?? 0.0).abs();
                            return vb.compareTo(va);
                          });
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _DayBillsPage(
                              date: date,
                              rows: dayRows,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 14,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    color: valueTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (amount != null)
                              SizedBox(
                                height: 16,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '¥${amount.toStringAsFixed(0)}',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: valueTextColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_error != null && _dailyRows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_isLoading && _dailyRows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            Builder(
              builder: (context) {
                if (_isDetailLoading && _detailRows.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (_detailError != null && _detailRows.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _detailError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final slices = _buildTypePieSlicesInMonth(year, month);
                if (slices.isEmpty) return const SizedBox.shrink();
                final totalsMap = _typeTotalsInMonth(year, month);
                final entries = totalsMap.entries
                    .where((e) => e.value != 0)
                    .toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final double sumTotal =
                    entries.fold(0.0, (s, e) => s + e.value.abs());
                const int pieTopN = 6;
                final Map<String, Color> typeColors = {};
                final int topCount = min(pieTopN, entries.length);
                for (int i = 0; i < topCount; i++) {
                  typeColors[entries[i].key] = Colors
                      .primaries[i % Colors.primaries.length]
                      .shade600;
                }
                final othersColor = Colors.grey[600]!;
                final monthRows = _detailRows.where((r) {
                  final dayStr = _rowDay(r);
                  final amount = _rowAmount(r);
                  if (dayStr == null || amount == null) return false;
                  final dt = _tryParseIsoDay(dayStr);
                  return dt != null && dt.year == year && dt.month == month;
                }).toList()
                  ..sort((a, b) {
                    final va = _rowAmount(a) ?? 0.0;
                    final vb = _rowAmount(b) ?? 0.0;
                    return vb.compareTo(va);
                  });
                final top10 = monthRows.take(10).toList();
                final top10Sum = top10.fold<double>(
                  0.0,
                  (s, r) => s + ((_rowAmount(r) ?? 0.0).abs()),
                );
                final monthSum = monthRows.fold<double>(
                  0.0,
                  (s, r) => s + ((_rowAmount(r) ?? 0.0).abs()),
                );
                final top10Percent =
                    monthSum > 0 ? (top10Sum * 100 / monthSum) : 0.0;
                final isZh = Localizations.localeOf(context).languageCode == 'zh';
                final topTitle = isZh ? '本月最高支出 Top 10' : 'Top 10 Expenses';
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                AppLocalizations.of(context)!.familyExpenseType,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final w = constraints.maxWidth.isFinite
                                      ? constraints.maxWidth
                                      : 320.0;
                                  final chartWidth = min(w, 420.0);
                                  return Center(
                                    child: SizedBox(
                                      width: chartWidth,
                                      height: 240,
                                      child: _TypePieChart(slices: slices),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                children: [
                                  for (final e in entries)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () {
                                            final target = e.key;
                                            final isZh = Localizations.localeOf(context).languageCode == 'zh';
                                            final uncategorized = isZh ? '未分类' : 'Uncategorized';
                                            final filtered = _detailRows.where((r) {
                                              final dayStr = _rowDay(r);
                                              final amount = _rowAmount(r);
                                              if (dayStr == null || amount == null) return false;
                                              final dt = _tryParseIsoDay(dayStr);
                                              if (dt == null || dt.year != year || dt.month != month) return false;
                                              final t = (_rowType(r) ?? '').trim();
                                              if (target == uncategorized) {
                                                return t.isEmpty;
                                              }
                                              return t == target;
                                            }).toList()
                                              ..sort((a, b) {
                                                final va = _rowAmount(a) ?? 0.0;
                                                final vb = _rowAmount(b) ?? 0.0;
                                                return vb.compareTo(va);
                                              });
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => _CategoryBillsPage(
                                                  category: e.key,
                                                  year: year,
                                                  month: month,
                                                  rows: filtered,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: typeColors[e.key] ?? othersColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    e.key,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${sumTotal > 0 ? (e.value.abs() * 100 / sumTotal).toStringAsFixed(1) : '0.0'}%  ¥${e.value.abs().toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: Colors.grey[800],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (top10.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        topTitle,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '¥${top10Sum.toStringAsFixed(2)} (${top10Percent.toStringAsFixed(1)}%)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              for (final r in top10)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _rowTitleInDetail(r),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Builder(
                                              builder: (_) {
                                                final parts = <String>[];
                                                final dayStr = _rowDay(r);
                                                if (dayStr != null) {
                                                  final dt = _tryParseIsoDay(dayStr);
                                                  final ds = dt == null
                                                      ? dayStr
                                                      : '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                                                  if (ds.isNotEmpty) parts.add(ds);
                                                }
                                                final user = _rowUserInDetail(r);
                                                if (user != null && user.isNotEmpty) parts.add(user);
                                                final payMethod = _rowPayMethodInDetail(r);
                                                if (payMethod != null && payMethod.isNotEmpty) parts.add(payMethod);
                                                if (parts.isEmpty) return const SizedBox.shrink();
                                                return Text(
                                                  parts.join(' · '),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '¥${(_rowAmount(r) ?? 0.0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
