import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import '../services/transaction_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_error_state.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TransactionService _transactionService = TransactionService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();

  List<Map<String, dynamic>> _cart = [];
  List<String> _categories = ['Semua'];

  int _selectedCat = 0;
  String _paymentMethod = 'tunai';
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  bool _containsEmoji(String value) {
    return RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    ).hasMatch(value);
  }

  bool _isValidCustomerName(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return false;
    if (_containsEmoji(trimmed)) return false;

    return RegExp(r'^[a-zA-Z ]+$').hasMatch(trimmed);
  }

  List<TextInputFormatter> _customerNameFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-Z ]'),
      ),
    ];
  }

  String _capitalizeWords(String text) {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return text;

    return trimmed
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _capitalizeCategory(String category) {
    if (category.trim().isEmpty) return category;

    return category
        .split('-')
        .map((part) => _capitalizeWords(part))
        .join('-');
  }

  Stream<List<Map<String, dynamic>>> _menuStream() {
    return SupabaseService.client
        .from('menus')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  List<String> _buildCategories(List<Map<String, dynamic>> menus) {
    final cats = menus
        .map((e) => (e['category'] ?? '').toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['Semua', ...cats];
  }

  void _syncCartWithMenus(List<Map<String, dynamic>> menus) {
    if (_cart.isEmpty) return;

    bool changed = false;

    final menuMap = {
      for (final menu in menus) menu['id'].toString(): menu,
    };

    final List<Map<String, dynamic>> updatedCart = [];

    for (final cartItem in _cart) {
      final cartId = cartItem['id'].toString();
      final latestMenu = menuMap[cartId];

      if (latestMenu == null) {
        changed = true;
        continue;
      }

      final isAvailable = (latestMenu['is_available'] ?? true) as bool;
      if (!isAvailable) {
        changed = true;
        continue;
      }

      final updatedItem = {
        ...cartItem,
        'name': latestMenu['name'],
        'price': _parseInt(latestMenu['price']),
        'image_url': latestMenu['image_url'],
        'category': latestMenu['category'],
        'description': latestMenu['description'],
      };

      if (updatedItem['name'] != cartItem['name'] ||
          updatedItem['price'] != cartItem['price'] ||
          updatedItem['image_url'] != cartItem['image_url'] ||
          updatedItem['category'] != cartItem['category'] ||
          updatedItem['description'] != cartItem['description']) {
        changed = true;
      }

      updatedCart.add(updatedItem);
    }

    if (changed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _cart = updatedCart;
        });
      });
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  void _addToCart(Map<String, dynamic> menu) {
    final index = _cart.indexWhere((item) => item['id'] == menu['id']);

    if (index >= 0) {
      _cart[index]['qty'] = (_cart[index]['qty'] ?? 0) + 1;
    } else {
      _cart.add({
        'id': menu['id'],
        'name': menu['name'],
        'price': _parseInt(menu['price']),
        'category': menu['category'],
        'image_url': menu['image_url'],
        'description': menu['description'],
        'qty': 1,
      });
    }

    setState(() {});

    AppAlert.show(
      context,
      title: 'Ditambahkan ke keranjang',
      message: '${menu['name']} berhasil ditambahkan.',
      type: AppAlertType.success,
      duration: const Duration(seconds: 2),
    );
  }

  void _increaseQty(int index) {
    _cart[index]['qty'] = (_cart[index]['qty'] ?? 0) + 1;
    setState(() {});
  }

  void _decreaseQty(int index) {
    final currentQty = (_cart[index]['qty'] ?? 0) as int;

    if (currentQty <= 1) {
      final removedName = _cart[index]['name']?.toString() ?? 'Item';
      _cart.removeAt(index);
      setState(() {});

      AppAlert.show(
        context,
        title: 'Item dihapus',
        message: '$removedName dihapus dari keranjang.',
        type: AppAlertType.info,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    _cart[index]['qty'] = currentQty - 1;
    setState(() {});
  }

  void _removeCartItem(int index) {
    final removedName = _cart[index]['name']?.toString() ?? 'Item';
    _cart.removeAt(index);
    setState(() {});

    AppAlert.show(
      context,
      title: 'Item dihapus',
      message: '$removedName dihapus dari keranjang.',
      type: AppAlertType.info,
      duration: const Duration(seconds: 2),
    );
  }

  int get _subtotal {
    int total = 0;
    for (final item in _cart) {
      final price = _parseInt(item['price']);
      final qty = _parseInt(item['qty']);
      total += price * qty;
    }
    return total;
  }

  int get _tax => (_subtotal * 0.1).toInt();
  int get _grandTotal => _subtotal + _tax;
  int get _totalQty =>
      _cart.fold<int>(0, (sum, item) => sum + _parseInt(item['qty']));

  String _formatRp(int n) {
    final s = n.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return 'Rp ${result.toString()}';
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> menus) {
    final keyword = _searchController.text.trim().toLowerCase();

    List<Map<String, dynamic>> result = menus.where((menu) {
      return (menu['is_available'] ?? true) as bool;
    }).toList();

    if (_selectedCat != 0 && _selectedCat < _categories.length) {
      result = result.where((menu) {
        final category = (menu['category'] ?? '').toString().toLowerCase();
        return category == _categories[_selectedCat];
      }).toList();
    }

    if (keyword.isNotEmpty) {
      result = result.where((menu) {
        final name = (menu['name'] ?? '').toString().toLowerCase();
        final category = (menu['category'] ?? '').toString().toLowerCase();
        final description = (menu['description'] ?? '').toString().toLowerCase();
        return name.contains(keyword) ||
            category.contains(keyword) ||
            description.contains(keyword);
      }).toList();
    }

    return result;
  }

  Widget _menuImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          height: 120,
          color: AppColors.surfaceContainerLow,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, size: 36),
          ),
        ),
        placeholder: (_, __) => Container(
          height: 120,
          color: AppColors.surfaceContainerLow,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Container(
      height: 120,
      color: AppColors.surfaceContainerLow,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 42),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kopi':
        return Icons.local_cafe_outlined;
      case 'non-kopi':
        return Icons.emoji_food_beverage_outlined;
      case 'makanan':
        return Icons.bakery_dining_outlined;
      default:
        return Icons.restaurant_menu_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'kopi':
        return const Color(0xFF8D5A2B);
      case 'non-kopi':
        return const Color(0xFF2E7D32);
      case 'makanan':
        return const Color(0xFF1565C0);
      default:
        return AppColors.secondary;
    }
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      AppAlert.show(
        context,
        title: 'Keranjang kosong',
        message: 'Tambahkan menu dulu sebelum checkout.',
        type: AppAlertType.warning,
      );
      return;
    }

    final customerName = _customerController.text.trim();

    if (customerName.isEmpty) {
      AppAlert.show(
        context,
        title: 'Nama pelanggan wajib diisi',
        message: 'Nama pelanggan tidak boleh kosong atau hanya spasi.',
        type: AppAlertType.warning,
      );
      return;
    }

    if (!_isValidCustomerName(customerName)) {
      AppAlert.show(
        context,
        title: 'Nama pelanggan tidak valid',
        message: 'Nama pelanggan hanya boleh huruf dan spasi saja.',
        type: AppAlertType.warning,
      );
      return;
    }

    try {
      setState(() => _isCheckingOut = true);

      final user = SupabaseService.client.auth.currentUser;

      if (user == null) {
        AppAlert.show(
          context,
          title: 'Belum login',
          message: 'Silakan login ulang untuk melanjutkan transaksi.',
          type: AppAlertType.error,
        );
        return;
      }

      await _transactionService.createTransaction(
        cashierId: user.id,
        cartItems: _cart,
        paymentMethod: _paymentMethod,
        customerName: customerName,
      );

      setState(() {
        _cart.clear();
        _customerController.clear();
        _paymentMethod = 'tunai';
      });

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();

      AppAlert.show(
        context,
        title: 'Transaksi berhasil',
        message: 'Pesanan berhasil disimpan ke sistem.',
        type: AppAlertType.success,
      );
    } catch (e) {
      final raw = e.toString().toLowerCase();
      final isStockIssue =
          raw.contains('stok') || raw.contains('tidak cukup');

      AppAlert.show(
        context,
        title: isStockIssue ? 'Stok tidak cukup' : 'Checkout gagal',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: isStockIssue ? AppAlertType.warning : AppAlertType.error,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari menu atau kategori',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
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
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isActive = _selectedCat == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCat = index);
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
                _categories[index] == 'Semua'
                    ? 'Semua'
                    : _capitalizeCategory(_categories[index]),
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

  Widget _menuCard(Map<String, dynamic> menu) {
    final name = (menu['name'] ?? '-').toString();
    final category = (menu['category'] ?? '-').toString();
    final price = _parseInt(menu['price']);
    final description = (menu['description'] ?? '').toString();
    final imageUrl = menu['image_url']?.toString();
    final categoryColor = _categoryColor(category);

    return GestureDetector(
      onTap: () => _addToCart(menu),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: _menuImage(imageUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _categoryIcon(category),
                          size: 16,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _capitalizeCategory(category),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        description.isEmpty ? 'Tanpa deskripsi' : description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatRp(price),
                            style: AppTextStyles.titleMd.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.45),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _cartItem(
      Map<String, dynamic> item, int index, VoidCallback refreshModal) {
    final name = (item['name'] ?? '-').toString();
    final price = _parseInt(item['price']);
    final qty = _parseInt(item['qty']);
    final imageUrl = item['image_url']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageUrl != null && imageUrl.trim().isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 58,
                      height: 58,
                      color: Colors.white,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  )
                : Container(
                    width: 58,
                    height: 58,
                    color: Colors.white,
                    child: const Icon(Icons.image_outlined),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRp(price),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _qtyButton(
                      icon: Icons.remove,
                      onTap: () {
                        _decreaseQty(index);
                        refreshModal();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$qty',
                        style: AppTextStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _qtyButton(
                      icon: Icons.add,
                      onTap: () {
                        _increaseQty(index);
                        refreshModal();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  _removeCartItem(index);
                  refreshModal();
                },
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _formatRp(price * qty),
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentButton({
    required String method,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: SizedBox(
        height: 46,
        child: isActive
            ? ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  method.toUpperCase(),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: AppColors.outlineVariant.withOpacity(0.55),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  method.toUpperCase(),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPaymentSelector(VoidCallback refreshModal) {
    return Row(
      children: [
        _paymentButton(
          method: 'tunai',
          isActive: _paymentMethod == 'tunai',
          onPressed: () {
            setState(() => _paymentMethod = 'tunai');
            refreshModal();
          },
        ),
        const SizedBox(width: 8),
        _paymentButton(
          method: 'qris',
          isActive: _paymentMethod == 'qris',
          onPressed: () {
            setState(() => _paymentMethod = 'qris');
            refreshModal();
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                color: highlight
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              color: highlight ? AppColors.secondary : AppColors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: highlight ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(VoidCallback refreshModal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keranjang',
          style: AppTextStyles.headlineSm.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Atur pesanan pelanggan sebelum checkout.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _customerController,
          inputFormatters: _customerNameFormatters(),
          onChanged: (_) => refreshModal(),
          decoration: InputDecoration(
            hintText: 'Nama pelanggan',
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withOpacity(0.35),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(
                color: AppColors.secondary,
                width: 1.2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildPaymentSelector(refreshModal),
        const SizedBox(height: 16),
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada item di keranjang.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (_, index) =>
                      _cartItem(_cart[index], index, refreshModal),
                ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 10),
        _buildSummaryRow('Subtotal', _formatRp(_subtotal)),
        _buildSummaryRow('Pajak 10%', _formatRp(_tax)),
        _buildSummaryRow('Total', _formatRp(_grandTotal), highlight: true),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (_cart.isEmpty || _isCheckingOut)
                ? null
                : () async {
                    await _checkout();
                    refreshModal();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.secondary.withOpacity(0.45),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isCheckingOut
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Checkout',
                    style: AppTextStyles.titleMd.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void refreshModal() {
              if (mounted) {
                setState(() {});
              }
              setModalState(() {});
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.82,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: _buildCartContent(refreshModal),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuSection(List<Map<String, dynamic>> menus) {
    _syncCartWithMenus(menus);

    final newCategories = _buildCategories(menus);
    if (newCategories.join('|') != _categories.join('|')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _categories = newCategories;
          if (_selectedCat >= _categories.length) {
            _selectedCat = 0;
          }
        });
      });
    }

    final filteredMenus = _applyFilter(menus);

    if (filteredMenus.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Menu tidak ditemukan.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: filteredMenus.length,
      itemBuilder: (_, index) => _menuCard(filteredMenus[index]),
    );
  }

  Widget _buildDesktopLayout(List<Map<String, dynamic>> menus) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildSearchBox(),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildCategoryFilter(),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildMenuSection(menus)),
            ],
          ),
        ),
        Container(
          width: 370,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(
                color: AppColors.outlineVariant.withOpacity(0.35),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: StatefulBuilder(
              builder: (context, setLocalState) {
                void refreshModal() {
                  if (mounted) {
                    setState(() {});
                  }
                  setLocalState(() {});
                }

                return _buildCartContent(refreshModal);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<Map<String, dynamic>> menus) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildSearchBox(),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildCategoryFilter(),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _buildMenuSection(menus),
            ),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: GestureDetector(
            onTap: _openCartSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _cart.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Keranjang kosong',
                                style: AppTextStyles.titleMd.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pilih menu untuk mulai transaksi',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: Colors.white.withOpacity(0.76),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_totalQty item di keranjang',
                                style: AppTextStyles.titleMd.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatRp(_grandTotal),
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _menuStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              debugPrint('POS MENU STREAM ERROR: ${snapshot.error}');
              return AppErrorState(
                title: 'Gagal memuat menu realtime',
                error: snapshot.error,
                onRetry: () {
                  if (!mounted) return;
                  setState(() {});
                },
              );
            }

            final menus = snapshot.data ?? [];

            if (isDesktop) {
              return _buildDesktopLayout(menus);
            }

            return _buildMobileLayout(menus);
          },
        ),
      ),
    );
  }
}