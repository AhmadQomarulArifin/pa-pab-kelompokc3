import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['Semua', 'tunai', 'qris'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRp(int n) {
    final s = n.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return 'Rp ${result.toString()}';
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';

    try {
      final dt = DateTime.parse(isoString).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year • $hour:$minute';
    } catch (_) {
      return isoString;
    }
  }

  Color _paymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'qris':
        return const Color(0xFF1565C0);
      case 'tunai':
      case 'cash':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.secondary;
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> data) {
    final keyword = _searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> result = List.from(data);

    if (_selectedFilter != 0) {
      result = result.where((trx) {
        final method = (trx['payment_method'] ?? '').toString().toLowerCase();
        return method == _filters[_selectedFilter];
      }).toList();
    }

    if (keyword.isNotEmpty) {
      result = result.where((trx) {
        final invoice = (trx['invoice_code'] ?? '').toString().toLowerCase();
        final method = (trx['payment_method'] ?? '').toString().toLowerCase();
        final status = (trx['status'] ?? '').toString().toLowerCase();
        final customer =
            (trx['customer_name'] ?? '').toString().toLowerCase();

        return invoice.contains(keyword) ||
            method.contains(keyword) ||
            status.contains(keyword) ||
            customer.contains(keyword);
      }).toList();
    }

    return result;
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isActive = _selectedFilter == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                _filters[index].toUpperCase(),
                style: AppTextStyles.bodyMd.copyWith(
                  color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _miniInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionCard(Map<String, dynamic> trx) {
    final invoice = (trx['invoice_code'] ?? '-').toString();
    final method = (trx['payment_method'] ?? '-').toString();
    final status = (trx['status'] ?? '-').toString();
    final total = (trx['total'] ?? 0) as int;
    final subtotal = (trx['subtotal'] ?? 0) as int;
    final tax = (trx['tax'] ?? 0) as int;
    final time = _formatDate(trx['transaction_time']?.toString());
    final methodColor = _paymentColor(method);
    final customerName = (trx['customer_name'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: methodColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: methodColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  invoice,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: methodColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  method.toUpperCase(),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: methodColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (customerName.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nama Pemesan',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniInfo('Waktu', time, Icons.schedule_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniInfo('Status', status, Icons.verified_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  'Subtotal',
                  _formatRp(subtotal),
                  Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniInfo(
                  'Pajak',
                  _formatRp(tax),
                  Icons.percent_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _formatRp(total),
              style: AppTextStyles.headlineSm.copyWith(
                fontSize: 24,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = SupabaseService.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('transaction_time', ascending: false);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Gagal memuat riwayat transaksi',
                  style: AppTextStyles.bodyMd,
                ),
              );
            }

            final rawData = snapshot.data ?? [];
            final data = _applyFilter(rawData);

            final totalSales = data.fold<int>(
              0,
              (sum, trx) => sum + ((trx['total'] ?? 0) as int),
            );

            final totalQris = data.fold<int>(0, (sum, trx) {
              final method =
                  (trx['payment_method'] ?? '').toString().toLowerCase();
              if (method == 'qris') return sum + ((trx['total'] ?? 0) as int);
              return sum;
            });

            final totalTunai = data.fold<int>(0, (sum, trx) {
              final method =
                  (trx['payment_method'] ?? '').toString().toLowerCase();
              if (method == 'tunai' || method == 'cash') {
                return sum + ((trx['total'] ?? 0) as int);
              }
              return sum;
            });

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Text(
                  'Riwayat Transaksi',
                  style: AppTextStyles.displayLg.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data akan ter-update otomatis setiap ada transaksi baru.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari invoice, nama pelanggan, metode, atau status',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withOpacity(0.45),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                      borderSide: BorderSide(
                        color: AppColors.secondary,
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFilterChips(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _summaryCard(
                      title: 'Total Penjualan',
                      value: _formatRp(totalSales),
                      icon: Icons.payments_outlined,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 10),
                    _summaryCard(
                      title: 'QRIS',
                      value: _formatRp(totalQris),
                      icon: Icons.qr_code_2_outlined,
                      color: const Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 10),
                    _summaryCard(
                      title: 'Tunai',
                      value: _formatRp(totalTunai),
                      icon: Icons.money_outlined,
                      color: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (data.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Belum ada transaksi ditemukan.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...data.map(_transactionCard),
              ],
            );
          },
        ),
      ),
    );
  }
}