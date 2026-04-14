import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class OrderRealtimeService {
  OrderRealtimeService._();

  static final OrderRealtimeService instance = OrderRealtimeService._();

  RealtimeChannel? _baristaChannel;
  RealtimeChannel? _cashierChannel;

  final Set<String> _shownNewOrderIds = {};
  final Set<String> _shownFinishedOrderIds = {};

  DateTime? _baristaListeningStartedAt;
  DateTime? _cashierListeningStartedAt;

  void startListeningForBaristaOrders() {
    stopBaristaListening();
    _shownNewOrderIds.clear();
    _baristaListeningStartedAt = DateTime.now().toUtc();

    _baristaChannel = Supabase.instance.client
        .channel('barista-orders-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          callback: (payload) async {
            final data = payload.newRecord;

            final transactionId = (data['id'] ?? '').toString();
            if (transactionId.isEmpty) return;
            if (_shownNewOrderIds.contains(transactionId)) return;

            final status = (data['status'] ?? '').toString().toLowerCase();
            if (status != 'baru') return;

            final createdAtRaw = data['created_at']?.toString();
            final createdAt = createdAtRaw != null
                ? DateTime.tryParse(createdAtRaw)?.toUtc()
                : null;

            if (createdAt != null && _baristaListeningStartedAt != null) {
              if (createdAt.isBefore(_baristaListeningStartedAt!)) return;
            }

            _shownNewOrderIds.add(transactionId);

            final invoiceCode =
                (data['invoice_code'] ?? 'Pesanan Baru').toString();
            final customerName =
                (data['customer_name'] ?? '').toString().trim();
            final paymentMethod =
                (data['payment_method'] ?? '').toString().toUpperCase();
            final total = int.tryParse(data['total']?.toString() ?? '0') ?? 0;

            final body = customerName.isNotEmpty
                ? '$customerName • $paymentMethod • Rp ${_formatNumber(total)}'
                : '$paymentMethod • Rp ${_formatNumber(total)}';

            await NotificationService.instance.showOrderNotification(
              id: transactionId.hashCode,
              title: invoiceCode,
              body: body,
            );
          },
        )
        .subscribe();
  }

  void startListeningForCashierFinishedOrders() {
    stopCashierListening();
    _shownFinishedOrderIds.clear();
    _cashierListeningStartedAt = DateTime.now().toUtc();

    _cashierChannel = Supabase.instance.client
        .channel('cashier-finished-orders-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'transactions',
          callback: (payload) async {
            final oldData = payload.oldRecord;
            final newData = payload.newRecord;

            final transactionId = (newData['id'] ?? '').toString();
            if (transactionId.isEmpty) return;
            if (_shownFinishedOrderIds.contains(transactionId)) return;

            final oldStatus = (oldData['status'] ?? '').toString().toLowerCase();
            final newStatus = (newData['status'] ?? '').toString().toLowerCase();

            if (newStatus != 'selesai') return;
            if (oldStatus == 'selesai') return;

            final createdAtRaw = newData['created_at']?.toString();
            final createdAt = createdAtRaw != null
                ? DateTime.tryParse(createdAtRaw)?.toUtc()
                : null;

            if (createdAt != null && _cashierListeningStartedAt != null) {
              if (createdAt.isBefore(_cashierListeningStartedAt!)) return;
            }

            _shownFinishedOrderIds.add(transactionId);

            final invoiceCode =
                (newData['invoice_code'] ?? 'Pesanan Selesai').toString();
            final customerName =
                (newData['customer_name'] ?? '').toString().trim();

            final body = customerName.isNotEmpty
                ? 'Pesanan $customerName sudah selesai'
                : 'Pesanan sudah selesai dibuat';

            await NotificationService.instance.showOrderFinishedNotification(
              id: transactionId.hashCode + 9999,
              title: invoiceCode,
              body: body,
            );
          },
        )
        .subscribe();
  }

  void stopBaristaListening() {
    final channel = _baristaChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
      _baristaChannel = null;
    }
  }

  void stopCashierListening() {
    final channel = _cashierChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
      _cashierChannel = null;
    }
  }

  void stopAll() {
    stopBaristaListening();
    stopCashierListening();
  }

  String _formatNumber(int value) {
    final s = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }

    return buffer.toString();
  }
}