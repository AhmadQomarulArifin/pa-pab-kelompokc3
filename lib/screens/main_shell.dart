import 'package:flutter/material.dart';
import '../models/role_config.dart';
import '../theme/app_theme.dart';
import '../services/logout_service.dart';
import '../services/order_realtime_service.dart';
import 'dashboard_screen.dart';
import 'menu_screen.dart';
import 'pos_screen.dart';
import 'stok_screen.dart';
import 'riwayat_screen.dart';
import 'staf_screen.dart';
import 'barista_orders_screen.dart';

class MainShell extends StatefulWidget {
  final RoleConfig role;
  final String? initialNotificationPayload;

  const MainShell({
    super.key,
    required this.role,
    this.initialNotificationPayload,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late List<_NavPage> _visiblePages;

  @override
  void initState() {
    super.initState();
    _visiblePages = _buildPagesByRole(widget.role.role);
    _applyInitialNotificationPayload();
    _startRealtimeByRole();
  }

  @override
  void dispose() {
    switch (widget.role.role) {
      case UserRole.barista:
        OrderRealtimeService.instance.stopBaristaListening();
        break;
      case UserRole.kasir:
        OrderRealtimeService.instance.stopCashierListening();
        break;
      case UserRole.owner:
        break;
    }
    super.dispose();
  }

  void _applyInitialNotificationPayload() {
    final payload = widget.initialNotificationPayload;

    if (payload == null || payload.trim().isEmpty) return;

    switch (widget.role.role) {
      case UserRole.barista:
        if (payload == 'barista_order') {
          final index = _visiblePages.indexWhere((e) => e.label == 'Order');
          if (index != -1) {
            _currentIndex = index;
          }
        }
        break;
      case UserRole.kasir:
        if (payload == 'cashier_history') {
          final index = _visiblePages.indexWhere((e) => e.label == 'Riwayat');
          if (index != -1) {
            _currentIndex = index;
          }
        }
        break;
      case UserRole.owner:
        if (payload == 'cashier_history') {
          final index = _visiblePages.indexWhere((e) => e.label == 'Riwayat');
          if (index != -1) {
            _currentIndex = index;
          }
        } else if (payload == 'barista_order') {
          final index = _visiblePages.indexWhere((e) => e.label == 'Dashboard');
          if (index != -1) {
            _currentIndex = index;
          }
        }
        break;
    }
  }

  void _startRealtimeByRole() {
    switch (widget.role.role) {
      case UserRole.barista:
        OrderRealtimeService.instance.startListeningForBaristaOrders();
        break;
      case UserRole.kasir:
        OrderRealtimeService.instance.startListeningForCashierFinishedOrders();
        break;
      case UserRole.owner:
        break;
    }
  }

  List<_NavPage> _buildPagesByRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return const [
          _NavPage(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            page: DashboardScreen(),
          ),
          _NavPage(
            label: 'Menu',
            icon: Icons.restaurant_menu_outlined,
            activeIcon: Icons.restaurant_menu,
            page: MenuScreen(),
          ),
          _NavPage(
            label: 'POS',
            icon: Icons.point_of_sale_outlined,
            activeIcon: Icons.point_of_sale,
            page: PosScreen(),
          ),
          _NavPage(
            label: 'Stok',
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            page: StokScreen(),
          ),
          _NavPage(
            label: 'Riwayat',
            icon: Icons.history_outlined,
            activeIcon: Icons.history,
            page: RiwayatScreen(),
          ),
          _NavPage(
            label: 'Pengguna',
            icon: Icons.group_outlined,
            activeIcon: Icons.group,
            page: StafScreen(),
          ),
        ];

      case UserRole.barista:
        return const [
          _NavPage(
            label: 'Order',
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            page: BaristaOrdersScreen(),
          ),
          _NavPage(
            label: 'Stok',
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            page: StokScreen(),
          ),
        ];

      case UserRole.kasir:
        return const [
          _NavPage(
            label: 'Menu',
            icon: Icons.restaurant_menu_outlined,
            activeIcon: Icons.restaurant_menu,
            page: MenuScreen(),
          ),
          _NavPage(
            label: 'POS',
            icon: Icons.point_of_sale_outlined,
            activeIcon: Icons.point_of_sale,
            page: PosScreen(),
          ),
          _NavPage(
            label: 'Riwayat',
            icon: Icons.history_outlined,
            activeIcon: Icons.history,
            page: RiwayatScreen(),
          ),
        ];
    }
  }

  Future<void> _confirmLogout() async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Keluar dari aplikasi?',
                style: AppTextStyles.headlineSm.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Sesi login akan diakhiri dan Anda akan kembali ke halaman masuk.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await LogoutService.instance.logout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleInitial(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'O';
      case UserRole.barista:
        return 'B';
      case UserRole.kasir:
        return 'K';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _visiblePages[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          currentPage.label,
          style: AppTextStyles.headlineSm.copyWith(fontSize: 22),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') _confirmLogout();
              },
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'role',
                  enabled: false,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.secondary.withOpacity(0.12),
                        child: Text(
                          _roleInitial(widget.role.role),
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(widget.role.label),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.secondary.withOpacity(0.12),
                      child: Text(
                        _roleInitial(widget.role.role),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.role.label,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _visiblePages.map((e) => e.page).toList(),
      ),
      bottomNavigationBar: _RoleBasedBottomNav(
        items: _visiblePages,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class _NavPage {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;

  const _NavPage({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}

class _RoleBasedBottomNav extends StatelessWidget {
  final List<_NavPage> items;
  final int currentIndex;
  final Function(int) onTap;

  const _RoleBasedBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.28),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? AppColors.secondary
                              : AppColors.outline,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'WorkSans',
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? AppColors.secondary
                                : AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}