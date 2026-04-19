import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_error_state.dart';

class BaristaOrdersScreen extends StatefulWidget {
  const BaristaOrdersScreen({super.key});

  @override
  State<BaristaOrdersScreen> createState() => _BaristaOrdersScreenState();
}

class _BaristaOrdersScreenState extends State<BaristaOrdersScreen> {
  static const bool isDebugNotif = false;

  Stream<List<Map<String, dynamic>>> _ordersStream() {
    return SupabaseService.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
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

  String _formatTime(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    final date = DateTime.tryParse(value);
    if (date == null) return '-';

    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<int> _fetchItemCount(String transactionId) async {
    final data = await SupabaseService.client
        .from('transaction_items')
        .select('qty')
        .eq('transaction_id', transactionId);

    final rows = List<Map<String, dynamic>>.from(data);
    int total = 0;

    for (final row in rows) {
      final qty = row['qty'];
      if (qty is int) {
        total += qty;
      } else {
        total += int.tryParse(qty.toString()) ?? 0;
      }
    }

    return total;
  }

  Future<void> _testNotification() async {
    await NotificationService.instance.showOrderNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Tes Notifikasi',
      body: 'Kalau ini muncul, notif Android kamu sudah jalan.',
    );
  }

  Future<void> _updateOrderStatus({
    required String transactionId,
    required String status,
    required String successTitle,
    required String successMessage,
  }) async {
    try {
      await SupabaseService.client.from('transactions').update({
        'status': status,
      }).eq('id', transactionId);

      if (!mounted) return;

      AppAlert.show(
        context,
        title: successTitle,
        message: successMessage,
        type: AppAlertType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppAlert.show(
        context,
        title: 'Gagal mengubah status',
        message: '$e',
        type: AppAlertType.error,
      );
    }
  }

  Future<void> _showOrderDetail(Map<String, dynamic> order) async {
    final transactionId = order['id'].toString();
    final currentStatus = (order['status'] ?? 'baru').toString().toLowerCase();

    try {
      final items = await SupabaseService.client
          .from('transaction_items')
          .select()
          .eq('transaction_id', transactionId)
          .order('id', ascending: true);

      final rows = List<Map<String, dynamic>>.from(items);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    (order['invoice_code'] ?? 'Pesanan').toString(),
                    style: AppTextStyles.headlineSm.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detail pesanan yang harus disiapkan barista.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(currentStatus).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      currentStatus.toUpperCase(),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: _statusColor(currentStatus),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Belum ada item pesanan.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...rows.map((item) {
                      final menuName = (item['menu_name'] ?? '-').toString();
                      final qty = item['qty']?.toString() ?? '0';
                      final price =
                          int.tryParse(item['price']?.toString() ?? '0') ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.outlineVariant.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_cafe_outlined,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    menuName,
                                    style: AppTextStyles.titleMd.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$qty x ${_formatRp(price)}',
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  if (currentStatus == 'baru') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _updateOrderStatus(
                            transactionId: transactionId,
                            status: 'diproses',
                            successTitle: 'Pesanan diproses',
                            successMessage:
                                'Pesanan sekarang sedang dibuat barista.',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF6C00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Tandai Diproses'),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (currentStatus == 'baru' || currentStatus == 'diproses') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _updateOrderStatus(
                            transactionId: transactionId,
                            status: 'selesai',
                            successTitle: 'Pesanan selesai',
                            successMessage:
                                'Pesanan berhasil ditandai selesai.',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Tandai Selesai'),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppAlert.show(
        context,
        title: 'Gagal memuat detail',
        message: '$e',
        type: AppAlertType.error,
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return AppColors.secondary;
      case 'diproses':
        return const Color(0xFFEF6C00);
      case 'selesai':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.outline;
    }
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

  Widget _orderCard(Map<String, dynamic> order) {
    final invoice = (order['invoice_code'] ?? '-').toString();
    final customer = (order['customer_name'] ?? '').toString().trim();
    final paymentMethod = (order['payment_method'] ?? '-').toString();
    final total = int.tryParse(order['total']?.toString() ?? '0') ?? 0;
    final createdAt = order['created_at']?.toString();
    final status = (order['status'] ?? 'baru').toString().toLowerCase();

    return FutureBuilder<int>(
      future: _fetchItemCount(order['id'].toString()),
      builder: (context, snapshot) {
        final itemCount = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () => _showOrderDetail(order),
          child: Container(
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
                        color: AppColors.secondary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                            customer.isEmpty ? 'Tanpa nama pelanggan' : customer,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(createdAt),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        paymentMethod.toUpperCase(),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$itemCount item',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatRp(total),
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _ordersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              debugPrint('BARISTA ORDER STREAM ERROR: ${snapshot.error}');
              return AppErrorState(
                title: 'Gagal memuat order barista',
                error: snapshot.error,
                onRetry: () {
                  if (!mounted) return;
                  setState(() {});
                },
              );
            }

            final allOrders = snapshot.data ?? [];
            final orders = allOrders
                .where((e) =>
                    (e['status'] ?? 'baru').toString().toLowerCase() !=
                    'selesai')
                .toList();

            final totalOrders = orders.length;

            final totalItemsFuture = Future.wait(
              orders.map((e) => _fetchItemCount(e['id'].toString())),
            );

            return FutureBuilder<List<int>>(
              future: totalItemsFuture,
              builder: (context, totalItemSnapshot) {
                final totalItems = totalItemSnapshot.hasData
                    ? totalItemSnapshot.data!.fold<int>(0, (a, b) => a + b)
                    : 0;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    Text(
                      'Pesanan Barista',
                      style: AppTextStyles.displayLg.copyWith(fontSize: 34),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pantau pesanan baru dari kasir secara realtime.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    if (isDebugNotif) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _testNotification,
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Tes Notif'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _summaryCard(
                          title: 'Total Pesanan',
                          value: '$totalOrders',
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 10),
                        _summaryCard(
                          title: 'Total Item',
                          value: '$totalItems',
                          icon: Icons.local_cafe_outlined,
                          color: const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (orders.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'Belum ada pesanan masuk.',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ...orders.map(_orderCard),
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