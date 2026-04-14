import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedFilter = 'hari';

  String _formatRp(int n) {
    final s = n.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return 'Rp ${result.toString()}';
  }

  String _formatCompactRp(int n) {
    if (n >= 1000000) {
      final value = (n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1);
      return 'Rp ${value}jt';
    }
    if (n >= 1000) {
      final value = (n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1);
      return 'Rp ${value}rb';
    }
    return 'Rp $n';
  }

  DateTime? _trxDate(Map<String, dynamic> trx) {
    final raw = trx['created_at'] ?? trx['transaction_time'];
    if (raw == null) return null;

    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;

    return parsed.toLocal();
  }

  bool _isSameLocalDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfWeek(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  bool _isInThisWeek(DateTime value, DateTime now) {
    final start = _startOfWeek(now);
    final end = start.add(const Duration(days: 7));
    return !value.isBefore(start) && value.isBefore(end);
  }

  bool _isInSelectedPeriod(DateTime value, String filter, DateTime now) {
    switch (filter) {
      case 'hari':
        return _isSameLocalDate(value, now);
      case 'minggu':
        return _isInThisWeek(value, now);
      case 'bulan':
        return value.year == now.year && value.month == now.month;
      case 'tahun':
        return value.year == now.year;
      default:
        return false;
    }
  }

  String _filterTitle(String filter) {
    switch (filter) {
      case 'hari':
        return 'Hari Ini';
      case 'minggu':
        return 'Minggu Ini';
      case 'bulan':
        return 'Bulan Ini';
      case 'tahun':
        return 'Tahun Ini';
      default:
        return '';
    }
  }

  int _totalToday(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();

    return transactions.where((trx) {
      final t = _trxDate(trx);
      if (t == null) return false;
      return _isSameLocalDate(t, now);
    }).fold<int>(0, (sum, trx) => sum + ((trx['total'] ?? 0) as int));
  }

  int _totalThisMonth(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();

    return transactions.where((trx) {
      final t = _trxDate(trx);
      if (t == null) return false;
      return t.year == now.year && t.month == now.month;
    }).fold<int>(0, (sum, trx) => sum + ((trx['total'] ?? 0) as int));
  }

  int _totalByFilter(List<Map<String, dynamic>> transactions, String filter) {
    final now = DateTime.now();

    return transactions.where((trx) {
      final t = _trxDate(trx);
      if (t == null) return false;
      return _isInSelectedPeriod(t, filter, now);
    }).fold<int>(0, (sum, trx) => sum + ((trx['total'] ?? 0) as int));
  }

  int _countByFilter(List<Map<String, dynamic>> transactions, String filter) {
    final now = DateTime.now();

    return transactions.where((trx) {
      final t = _trxDate(trx);
      if (t == null) return false;
      return _isInSelectedPeriod(t, filter, now);
    }).length;
  }

  Map<String, int> _paymentSummary(List<Map<String, dynamic>> transactions) {
    int qris = 0;
    int tunai = 0;

    for (final trx in transactions) {
      final method = (trx['payment_method'] ?? '').toString().toLowerCase();
      final total = (trx['total'] ?? 0) as int;

      if (method == 'qris') {
        qris += total;
      } else if (method == 'tunai' || method == 'cash') {
        tunai += total;
      }
    }

    return {
      'qris': qris,
      'tunai': tunai,
    };
  }

  Map<String, dynamic> _bestSeller(List<Map<String, dynamic>> items) {
    final Map<String, int> counter = {};

    for (final item in items) {
      final name = (item['menu_name'] ?? '-').toString();
      final qty = (item['qty'] ?? 0) as int;
      counter[name] = (counter[name] ?? 0) + qty;
    }

    String bestName = '-';
    int bestQty = 0;

    counter.forEach((name, qty) {
      if (qty > bestQty) {
        bestName = name;
        bestQty = qty;
      }
    });

    return {
      'name': bestName,
      'qty': bestQty,
    };
  }

  List<Map<String, dynamic>> _buildLast7DaysSeries(
    List<Map<String, dynamic>> transactions,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> series = [];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      int total = 0;

      for (final trx in transactions) {
        final t = _trxDate(trx);
        if (t == null) continue;

        if (_isSameLocalDate(t, day)) {
          total += (trx['total'] ?? 0) as int;
        }
      }

      series.add({
        'label': _dayLabel(day.weekday),
        'value': total,
      });
    }

    return series;
  }

  String _dayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Sen';
      case DateTime.tuesday:
        return 'Sel';
      case DateTime.wednesday:
        return 'Rab';
      case DateTime.thursday:
        return 'Kam';
      case DateTime.friday:
        return 'Jum';
      case DateTime.saturday:
        return 'Sab';
      case DateTime.sunday:
        return 'Min';
      default:
        return '-';
    }
  }

  List<Map<String, dynamic>> _recentTransactions(
    List<Map<String, dynamic>> transactions,
  ) {
    final sorted = [...transactions];
    sorted.sort((a, b) {
      final aDate = _trxDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _trxDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return sorted.take(3).toList();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.secondary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.headlineSm.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['hari', 'minggu', 'bulan', 'tahun'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isActive = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isActive ? AppColors.secondary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? AppColors.secondary
                      : AppColors.outlineVariant.withOpacity(0.45),
                ),
              ),
              child: Text(
                filter[0].toUpperCase() + filter.substring(1),
                style: AppTextStyles.bodyMd.copyWith(
                  color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _lineChartCard(List<Map<String, dynamic>> transactions) {
    final series = _buildLast7DaysSeries(transactions);

    final double maxY = series
        .map((e) => (e['value'] as int).toDouble())
        .fold<double>(0, (prev, el) => el > prev ? el : prev);

    final double chartMaxY = maxY == 0 ? 100000.0 : maxY * 1.25;

    final spots = List.generate(series.length, (index) {
      return FlSpot(index.toDouble(), (series[index]['value'] as int).toDouble());
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Penjualan 7 Hari Terakhir',
            style: AppTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Grafik ini benar-benar menghitung 7 hari terakhir dari hari ini.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.outlineVariant.withOpacity(0.22),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: chartMaxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatCompactRp(value.toInt()),
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final rounded = value.round();
                        if ((value - rounded).abs() > 0.001) {
                          return const SizedBox();
                        }
                        if (rounded < 0 || rounded >= series.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            series[rounded]['label'].toString(),
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.onSurface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          _formatRp(spot.y.toInt()),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 4,
                    color: AppColors.secondary,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.secondary.withOpacity(0.12),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.secondary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentChartCard(List<Map<String, dynamic>> transactions) {
    final summary = _paymentSummary(transactions);
    final qris = summary['qris'] ?? 0;
    final tunai = summary['tunai'] ?? 0;
    final total = qris + tunai;

    final qrisPercent = total == 0 ? 0 : ((qris / total) * 100).round();
    final tunaiPercent = total == 0 ? 0 : ((tunai / total) * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Komposisi Pembayaran',
            style: AppTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Perbandingan transaksi tunai dan QRIS.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: total == 0
                ? Center(
                    child: Text(
                      'Belum ada data pembayaran',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 58,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(
                              value: qris.toDouble(),
                              radius: 18,
                              showTitle: false,
                              color: AppColors.secondary,
                            ),
                            PieChartSectionData(
                              value: tunai.toDouble(),
                              radius: 18,
                              showTitle: false,
                              color: const Color(0xFF8D5A2B),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCompactRp(total),
                            style: AppTextStyles.titleMd.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          _legendTile(
            color: const Color(0xFF8D5A2B),
            label: 'Tunai',
            percent: '$tunaiPercent%',
            value: _formatRp(tunai),
          ),
          const SizedBox(height: 10),
          _legendTile(
            color: AppColors.secondary,
            label: 'QRIS',
            percent: '$qrisPercent%',
            value: _formatRp(qris),
          ),
        ],
      ),
    );
  }

  Widget _legendTile({
    required Color color,
    required String label,
    required String percent,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          percent,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _bestSellerCard(List<Map<String, dynamic>> items) {
    final best = _bestSeller(items);
    final name = best['name'].toString();
    final qty = best['qty'] as int;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5A2D1F),
            Color(0xFF2E140E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Seller',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$qty item terjual',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentTransactionsCard(List<Map<String, dynamic>> transactions) {
    final recent = _recentTransactions(transactions);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3 Transaksi Terakhir',
            style: AppTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Menampilkan tiga transaksi terbaru secara realtime.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Text(
              'Belum ada transaksi terbaru.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            ...recent.asMap().entries.map((entry) {
              final index = entry.key;
              final trx = entry.value;
              final invoice = (trx['invoice_code'] ?? '-').toString();
              final total = (trx['total'] ?? 0) as int;
              final method = (trx['payment_method'] ?? '-').toString();
              final customerName = (trx['customer_name'] ?? '').toString().trim();
              final createdAt = _trxDate(trx);

              return Container(
                margin: EdgeInsets.only(bottom: index == recent.length - 1 ? 0 : 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice,
                            style: AppTextStyles.titleMd.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${method.toUpperCase()} • ${_formatRp(total)}',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(createdAt),
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          if (customerName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Pemesan: $customerName',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trxStream = SupabaseService.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    final itemStream = SupabaseService.client
        .from('transaction_items')
        .stream(primaryKey: ['id']);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: trxStream,
          builder: (context, trxSnapshot) {
            if (trxSnapshot.connectionState == ConnectionState.waiting &&
                !trxSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (trxSnapshot.hasError) {
              return Center(
                child: Text(
                  'Gagal memuat dashboard',
                  style: AppTextStyles.bodyMd,
                ),
              );
            }

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: itemStream,
              builder: (context, itemSnapshot) {
                if (itemSnapshot.connectionState == ConnectionState.waiting &&
                    !itemSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (itemSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat data best seller',
                      style: AppTextStyles.bodyMd,
                    ),
                  );
                }

                final transactions = trxSnapshot.data ?? [];
                final items = itemSnapshot.data ?? [];

                final totalToday = _totalToday(transactions);
                final totalMonth = _totalThisMonth(transactions);
                final totalTransactions = transactions.length;
                final totalByFilter = _totalByFilter(transactions, _selectedFilter);
                final countByFilter = _countByFilter(transactions, _selectedFilter);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    Text(
                      'Dashboard',
                      style: AppTextStyles.displayLg.copyWith(fontSize: 34),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pantau performa penjualan, pembayaran, dan menu terlaris secara realtime.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildFilterChips(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _summaryCard(
                          title: 'Penjualan Hari Ini',
                          value: _formatRp(totalToday),
                          subtitle: 'Update otomatis hari ini',
                          icon: Icons.payments_outlined,
                        ),
                        const SizedBox(width: 12),
                        _summaryCard(
                          title: 'Total Transaksi',
                          value: '$totalTransactions',
                          subtitle: 'Semua transaksi masuk',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _summaryCard(
                          title: 'Penjualan Bulan Ini',
                          value: _formatRp(totalMonth),
                          subtitle: 'Akumulasi bulan berjalan',
                          icon: Icons.trending_up_outlined,
                        ),
                        const SizedBox(width: 12),
                        _summaryCard(
                          title: 'Filter ${_filterTitle(_selectedFilter)}',
                          value: _formatRp(totalByFilter),
                          subtitle: '$countByFilter transaksi',
                          icon: Icons.filter_alt_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _bestSellerCard(items),
                    const SizedBox(height: 18),
                    _lineChartCard(transactions),
                    const SizedBox(height: 18),
                    _paymentChartCard(transactions),
                    const SizedBox(height: 18),
                    _recentTransactionsCard(transactions),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}