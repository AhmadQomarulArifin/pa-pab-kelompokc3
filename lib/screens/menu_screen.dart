import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import '../services/menu_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_error_state.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuService _menuService = MenuService();
  final StorageService _storageService = StorageService();

  List<Map<String, dynamic>> _menus = [];
  List<Map<String, dynamic>> _filteredMenus = [];
  bool _isLoading = true;
  int _selectedCat = 0;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showFab = true;
  double _lastOffset = 0;
  Object? _loadError;

  final List<String> _cats = ['Semua', 'kopi', 'non-kopi', 'makanan'];
  final List<String> _menuCategoryOptions = ['kopi', 'non-kopi', 'makanan'];

  @override
  void initState() {
    super.initState();
    _loadMenus();
    _searchController.addListener(_applyFilter);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;

    if (offset > _lastOffset + 8 && _showFab) {
      setState(() => _showFab = false);
    } else if (offset < _lastOffset - 8 && !_showFab) {
      setState(() => _showFab = true);
    }

    _lastOffset = offset;
  }

  bool _isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  bool _containsEmoji(String value) {
    return RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    ).hasMatch(value);
  }

  bool _isValidMenuName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_containsEmoji(trimmed)) return false;
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(trimmed);
  }

  bool _isValidDescription(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_containsEmoji(trimmed)) return false;
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(trimmed);
  }

  bool _isValidPrice(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return false;
    if (_containsEmoji(trimmed)) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) return false;
    if (trimmed.startsWith('0')) return false;

    final price = int.tryParse(trimmed) ?? 0;
    if (price < 100) return false;

    return true;
  }

  List<TextInputFormatter> _menuNameFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-Z ]'),
      ),
    ];
  }

  List<TextInputFormatter> _descriptionFormatters() {
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

  Future<void> _loadMenus() async {
    try {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });

      final data = await _menuService.getMenus();

      setState(() {
        _menus = data;
        _isLoading = false;
      });

      _applyFilter();
    } catch (e) {
      debugPrint('MENU LOAD ERROR: $e');
      setState(() {
        _isLoading = false;
        _loadError = e;
      });
    }
  }

  void _applyFilter() {
    final keyword = _searchController.text.trim().toLowerCase();

    List<Map<String, dynamic>> result = List.from(_menus);

    if (_selectedCat != 0) {
      result = result.where((menu) {
        final cat = (menu['category'] ?? '').toString().toLowerCase();
        return cat == _cats[_selectedCat];
      }).toList();
    }

    if (keyword.isNotEmpty) {
      result = result.where((menu) {
        final name = (menu['name'] ?? '').toString().toLowerCase();
        final category = (menu['category'] ?? '').toString().toLowerCase();
        return name.contains(keyword) || category.contains(keyword);
      }).toList();
    }

    setState(() {
      _filteredMenus = result;
    });
  }

  void _showAlert({
    required String title,
    required String message,
    required AppAlertType type,
  }) {
    AppAlert.show(
      context,
      title: title,
      message: message,
      type: type,
    );
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

  List<Map<String, dynamic>> _uniqueIngredientsById(
    List<Map<String, dynamic>> items,
  ) {
    final Map<String, Map<String, dynamic>> uniqueMap = {};

    for (final item in items) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) continue;
      uniqueMap[id] = item;
    }

    return uniqueMap.values.toList();
  }

  Future<void> _showMenuForm({Map<String, dynamic>? menu}) async {
    final isEdit = menu != null;

    final nameCtrl =
        TextEditingController(text: menu?['name']?.toString() ?? '');
    final priceCtrl = TextEditingController(
      text: menu?['price'] != null ? menu!['price'].toString() : '',
    );
    final descCtrl =
        TextEditingController(text: menu?['description']?.toString() ?? '');

    String? selectedCategory = menu?['category']?.toString().toLowerCase();
    if (selectedCategory != null &&
        !_menuCategoryOptions.contains(selectedCategory)) {
      selectedCategory = null;
    }

    String? imageUrl = menu?['image_url']?.toString();
    bool isAvailable = (menu?['is_available'] ?? true) as bool;
    bool isUploading = false;
    bool isSaving = false;

    List<Map<String, dynamic>> allIngredients = [];
    List<Map<String, dynamic>> selectedIngredients = [];
    String? selectedIngredientId;

    try {
      allIngredients =
          _uniqueIngredientsById(await _menuService.getIngredients());

      if (isEdit) {
        final details =
            await _menuService.getMenuIngredientsDetailed(menu['id'].toString());

        final uniqueSelectedMap = <String, Map<String, dynamic>>{};

        for (final e in details) {
          final ingredientId = e['ingredient_id'].toString();
          uniqueSelectedMap[ingredientId] = {
            'ingredient_id': ingredientId,
            'name': e['name'],
            'unit': e['unit'],
            'stock': e['stock'],
            'qty_used_ctrl': TextEditingController(
              text: (e['qty_used'] ?? '').toString(),
            ),
          };
        }

        selectedIngredients = uniqueSelectedMap.values.toList();
      }
    } catch (e) {
      _showAlert(
        title: 'Gagal memuat bahan menu',
        message: '$e',
        type: AppAlertType.error,
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedIds = selectedIngredients
                .map((e) => e['ingredient_id'].toString())
                .toSet();

            final List<Map<String, dynamic>> availableIngredients =
                _uniqueIngredientsById(
              allIngredients.where((item) {
                final id = item['id']?.toString() ?? '';
                return id.isNotEmpty && !selectedIds.contains(id);
              }).toList(),
            );

            if (selectedIngredientId != null &&
                !availableIngredients.any(
                  (item) => item['id'].toString() == selectedIngredientId,
                )) {
              selectedIngredientId = null;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
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
                      isEdit ? 'Edit Menu' : 'Tambah Menu',
                      style: AppTextStyles.headlineSm.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEdit
                          ? 'Perbarui informasi menu dan bahan yang dipakai.'
                          : 'Tambahkan menu baru beserta bahan yang dipakai.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: nameCtrl,
                      label: 'Nama Menu',
                      hint: 'Contoh: Es Kopi Susu',
                      inputFormatters: _menuNameFormatters(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'KATEGORI',
                      style: AppTextStyles.labelMd,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        hintText: 'Pilih kategori menu',
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
                      items: _menuCategoryOptions.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(_capitalizeCategory(category)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: priceCtrl,
                      label: 'Harga',
                      hint: 'Contoh: 15000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: descCtrl,
                      label: 'Deskripsi',
                      hint: 'Deskripsi singkat menu',
                      maxLines: 3,
                      inputFormatters: _descriptionFormatters(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'GAMBAR MENU',
                      style: AppTextStyles.labelMd,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        height: 170,
                        color: AppColors.surfaceContainerLow,
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? FancyShimmerImage(
                                imageUrl: imageUrl!,
                                boxFit: BoxFit.cover,
                                errorWidget: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 42,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 46,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    try {
                                      setModalState(() => isUploading = true);

                                      final uploadedUrl = await _storageService
                                          .pickAndUploadMenuImage();

                                      if (!mounted) return;

                                      if (uploadedUrl == null ||
                                          uploadedUrl.trim().isEmpty) {
                                        return;
                                      }

                                      setModalState(() {
                                        imageUrl = uploadedUrl;
                                      });

                                      AppAlert.show(
                                        context,
                                        title: 'Upload berhasil',
                                        message:
                                            'Gambar menu berhasil dipilih.',
                                        type: AppAlertType.success,
                                        duration:
                                            const Duration(seconds: 2),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      AppAlert.show(
                                        context,
                                        title: 'Upload gagal',
                                        message: '$e',
                                        type: AppAlertType.error,
                                      );
                                    } finally {
                                      if (mounted) {
                                        setModalState(
                                          () => isUploading = false,
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.upload_outlined),
                            label: Text(
                              isUploading ? 'Uploading...' : 'Upload Gambar',
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (imageUrl != null && imageUrl!.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  imageUrl = null;
                                });
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Hapus Gambar'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                foregroundColor: AppColors.error,
                                side: const BorderSide(
                                  color: AppColors.error,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.outlineVariant.withOpacity(0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Menu tersedia',
                              style: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Switch(
                            value: isAvailable,
                            activeColor: AppColors.secondary,
                            onChanged: (v) {
                              setModalState(() => isAvailable = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'BAHAN MENU',
                      style: AppTextStyles.labelMd,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.outlineVariant.withOpacity(0.45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Satu menu bisa memakai 2 bahan atau lebih.',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (availableIngredients.isNotEmpty)
                            DropdownButtonFormField<String>(
                              key: ValueKey(
                                'ingredient-dropdown-${availableIngredients.map((e) => e['id']).join('-')}',
                              ),
                              value: (selectedIngredientId != null &&
                                      availableIngredients.any(
                                        (item) =>
                                            item['id'].toString() ==
                                            selectedIngredientId,
                                      ))
                                  ? selectedIngredientId
                                  : null,
                              decoration: InputDecoration(
                                hintText: 'Pilih bahan dari stok',
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: availableIngredients.map((item) {
                                final value = item['id'].toString();
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    '${item['name']} (${item['unit']})',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;

                                final ingredient =
                                    availableIngredients.firstWhere(
                                  (e) => e['id'].toString() == value,
                                );

                                setModalState(() {
                                  selectedIngredients.add({
                                    'ingredient_id':
                                        ingredient['id'].toString(),
                                    'name': ingredient['name'],
                                    'unit': ingredient['unit'],
                                    'stock': ingredient['stock'],
                                    'qty_used_ctrl': TextEditingController(
                                      text: '1',
                                    ),
                                  });

                                  selectedIngredientId = null;
                                });
                              },
                            )
                          else
                            Text(
                              'Semua bahan sudah dipilih.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 14),
                          if (selectedIngredients.isEmpty)
                            Text(
                              'Belum ada bahan yang dipilih untuk menu ini.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            )
                          else
                            ...selectedIngredients.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final qtyCtrl =
                                  item['qty_used_ctrl'] as TextEditingController;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item['name']}',
                                            style: AppTextStyles.titleMd.copyWith(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setModalState(() {
                                              selectedIngredients
                                                  .removeAt(index);
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Stok: ${item['stock']} ${item['unit']}',
                                        style: AppTextStyles.bodyMd.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: qtyCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9.]'),
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        labelText:
                                            'Jumlah dipakai (${item['unit']})',
                                        hintText: 'Contoh: 1 / 0.5 / 20',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              side: BorderSide(
                                color:
                                    AppColors.outlineVariant.withOpacity(0.55),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: AppTextStyles.titleMd.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isUploading || isSaving
                                ? null
                                : () async {
                                    final name = nameCtrl.text.trim();
                                    final category =
                                        (selectedCategory ?? '')
                                            .trim()
                                            .toLowerCase();
                                    final priceText = priceCtrl.text.trim();
                                    final description = descCtrl.text.trim();
                                    final price =
                                        int.tryParse(priceText) ?? 0;

                                    if (!_isNotEmpty(name)) {
                                      _showAlert(
                                        title: 'Nama menu wajib diisi',
                                        message:
                                            'Nama menu tidak boleh kosong atau hanya spasi.',
                                        type: AppAlertType.warning,
                                      );
                                      return;
                                    }

                                    if (!_isValidMenuName(name)) {
                                      _showAlert(
                                        title: 'Nama menu tidak valid',
                                        message:
                                            'Nama menu hanya boleh huruf dan spasi saja.',
                                        type: AppAlertType.warning,
                                      );
                                      return;
                                    }

                                    if (category.isEmpty) {
                                      _showAlert(
                                        title: 'Kategori belum dipilih',
                                        message:
                                            'Pilih kategori menu terlebih dahulu.',
                                        type: AppAlertType.warning,
                                      );
                                      return;
                                    }

                                    if (!_isValidPrice(priceText)) {
                                      _showAlert(
                                        title: 'Harga tidak valid',
                                        message:
                                            'Harga harus angka tanpa nol di depan dan minimal Rp 100.',
                                        type: AppAlertType.warning,
                                      );
                                      return;
                                    }

                                    if (!_isNotEmpty(description)) {
                                      _showAlert(
                                        title: 'Deskripsi wajib diisi',
                                        message:
                                            'Deskripsi tidak boleh kosong atau hanya spasi.',
                                        type: AppAlertType.warning,
                                      );
                                      return;
                                    }

                                    if (!_isValidDescription(description)) {
                                      _showAlert(
                                        title: 'Deskripsi tidak valid',
                                        message:
                                            'Deskripsi hanya boleh huruf dan spasi saja.',
                                        type: AppAlertType.warning,
                                      );
                                      return;
                                    }

                                    final ingredientPayload =
                                        <Map<String, dynamic>>[];

                                    for (final item in selectedIngredients) {
                                      final qtyCtrl = item['qty_used_ctrl']
                                          as TextEditingController;
                                      final qtyText = qtyCtrl.text.trim();
                                      final qty =
                                          num.tryParse(qtyText) ?? 0;

                                      if (!_isNotEmpty(qtyText)) {
                                        _showAlert(
                                          title: 'Jumlah bahan kosong',
                                          message:
                                              'Isi jumlah untuk ${item['name']}.',
                                          type: AppAlertType.warning,
                                        );
                                        return;
                                      }

                                      if (qty <= 0) {
                                        _showAlert(
                                          title: 'Jumlah bahan tidak valid',
                                          message:
                                              'Jumlah bahan harus angka lebih dari 0.',
                                          type: AppAlertType.warning,
                                        );
                                        return;
                                      }

                                      ingredientPayload.add({
                                        'ingredient_id':
                                            item['ingredient_id'].toString(),
                                        'qty_used': qty,
                                      });
                                    }

                                    try {
                                      setModalState(() => isSaving = true);

                                      String menuId;

                                      if (isEdit) {
                                        menuId = menu['id'].toString();
                                        await _menuService.updateMenu(
                                          id: menuId,
                                          name: name,
                                          category: category,
                                          price: price,
                                          description: description,
                                          isAvailable: isAvailable,
                                          imageUrl: imageUrl,
                                        );
                                      } else {
                                        await _menuService.addMenu(
                                          name: name,
                                          category: category,
                                          price: price,
                                          description: description,
                                          isAvailable: isAvailable,
                                          imageUrl: imageUrl,
                                        );

                                        final freshMenus =
                                            await _menuService.getMenus();

                                        final createdMenu =
                                            freshMenus.firstWhere(
                                          (e) =>
                                              e['name'].toString() == name &&
                                              e['category'].toString() ==
                                                  category &&
                                              (e['price'] ?? 0) == price,
                                        );

                                        menuId = createdMenu['id'].toString();
                                      }

                                      await _menuService.saveMenuIngredients(
                                        menuId: menuId,
                                        items: ingredientPayload,
                                      );

                                      if (!mounted) return;
                                      Navigator.pop(context);
                                      await _loadMenus();

                                      AppAlert.show(
                                        context,
                                        title: isEdit
                                            ? 'Menu diperbarui'
                                            : 'Menu ditambahkan',
                                        message: isEdit
                                            ? 'Perubahan menu berhasil disimpan.'
                                            : 'Menu baru berhasil disimpan.',
                                        type: AppAlertType.success,
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      AppAlert.show(
                                        context,
                                        title: 'Gagal menyimpan menu',
                                        message: '$e',
                                        type: AppAlertType.error,
                                      );
                                    } finally {
                                      if (mounted) {
                                        setModalState(() => isSaving = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              isSaving
                                  ? 'Menyimpan...'
                                  : (isEdit ? 'Simpan' : 'Tambah'),
                              style: AppTextStyles.titleMd.copyWith(
                                color: Colors.white,
                              ),
                            ),
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
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> menu) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text('Hapus Menu'),
        content: Text(
          'Yakin ingin menghapus menu "${menu['name']}"?',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _menuService.deleteMenu(menu['id'].toString());
                if (!mounted) return;
                Navigator.pop(context);
                await _loadMenus();

                AppAlert.show(
                  context,
                  title: 'Menu dihapus',
                  message: 'Menu berhasil dihapus dari sistem.',
                  type: AppAlertType.info,
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);

                AppAlert.show(
                  context,
                  title: 'Gagal menghapus menu',
                  message: '$e',
                  type: AppAlertType.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelMd,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMd.copyWith(
              color: AppColors.outline,
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
        ),
      ],
    );
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

  Widget _menuImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return FancyShimmerImage(
        imageUrl: imageUrl,
        height: 140,
        width: double.infinity,
        boxFit: BoxFit.cover,
        errorWidget: Container(
          height: 140,
          color: AppColors.surfaceContainerLow,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, size: 36),
          ),
        ),
      );
    }

    return Container(
      height: 140,
      color: AppColors.surfaceContainerLow,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 42),
      ),
    );
  }

  Widget _menuCard(Map<String, dynamic> item) {
    final category = (item['category'] ?? '-').toString();
    final name = (item['name'] ?? '-').toString();
    final description = (item['description'] ?? '').toString();
    final price = (item['price'] ?? 0) as int;
    final isAvailable = (item['is_available'] ?? true) as bool;
    final imageUrl = item['image_url']?.toString();
    final categoryColor = _categoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: _menuImage(imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _capitalizeCategory(category).toUpperCase(),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: categoryColor,
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
                        color: isAvailable
                            ? const Color(0xFF2E7D32).withOpacity(0.10)
                            : AppColors.error.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        isAvailable ? 'TERSEDIA' : 'TIDAK TERSEDIA',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: isAvailable
                              ? const Color(0xFF2E7D32)
                              : AppColors.error,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    description.isEmpty ? 'Tanpa deskripsi' : description,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _formatRp(price),
                      style: AppTextStyles.headlineSm.copyWith(
                        fontSize: 22,
                        color: AppColors.secondary,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showMenuForm(menu: item);
                        } else if (value == 'delete') {
                          _confirmDelete(item);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Hapus'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
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
    final totalMenus = _menus.length;
    final availableMenus =
        _menus.where((e) => (e['is_available'] ?? true) as bool).length;
    final unavailableMenus = totalMenus - availableMenus;

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _showFab ? 1 : 0,
          child: IgnorePointer(
            ignoring: !_showFab,
            child: FloatingActionButton.extended(
              onPressed: () => _showMenuForm(),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Menu'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _loadError != null
                ? AppErrorState(
                    title: 'Gagal memuat menu',
                    error: _loadError,
                    onRetry: _loadMenus,
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      Text(
                        'Menu Cafe',
                        style: AppTextStyles.displayLg.copyWith(fontSize: 34),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kelola daftar menu, kategori, harga, gambar, dan bahan yang dipakai.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _summaryCard(
                            title: 'Total Menu',
                            value: '$totalMenus',
                            icon: Icons.restaurant_menu_outlined,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            title: 'Tersedia',
                            value: '$availableMenus',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            title: 'Nonaktif',
                            value: '$unavailableMenus',
                            icon: Icons.remove_circle_outline,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari menu atau kategori',
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_cats.length, (index) {
                            final isActive = _selectedCat == index;

                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedCat = index);
                                _applyFilter();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.secondary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.secondary
                                        : AppColors.outlineVariant
                                            .withOpacity(0.45),
                                  ),
                                ),
                                child: Text(
                                  _cats[index] == 'Semua'
                                      ? 'Semua'
                                      : _capitalizeCategory(_cats[index]),
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_filteredMenus.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Belum ada menu ditemukan.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._filteredMenus.map(_menuCard),
                    ],
                  ),
      ),
    );
  }
}