import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import '../services/ingredient_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_error_state.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  final IngredientService _ingredientService = IngredientService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _unitOptions = [
    'kg',
    'gram',
    'liter',
    'ml',
    'pcs',
    'pack',
    'botol',
    'cup',
  ];

  bool _showFab = true;
  double _lastOffset = 0;

  bool _isLoading = true;
  Object? _loadError;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _scrollController.addListener(_handleScroll);
    _loadIngredients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    try {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });

      final data = await _ingredientService.getIngredients();

      setState(() {
        _items = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('STOK LOAD ERROR: $e');
      setState(() {
        _isLoading = false;
        _loadError = e;
      });
    }
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

  bool _isValidIngredientName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_containsEmoji(trimmed)) return false;

    return RegExp(r'^[a-zA-Z ]+$').hasMatch(trimmed);
  }

  bool _isValidDecimal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_containsEmoji(trimmed)) return false;
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed)) return false;

    final parsed = num.tryParse(trimmed);
    if (parsed == null) return false;
    if (parsed < 0) return false;

    return true;
  }

  bool _isValidImageUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return true;
    if (_containsEmoji(trimmed)) return false;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (!uri.isAbsolute) return false;
    if (!(trimmed.startsWith('http://') || trimmed.startsWith('https://'))) {
      return false;
    }

    final host = uri.host.trim();
    if (host.isEmpty) return false;
    if (!host.contains('.')) return false;
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return false;

    return true;
  }

  List<TextInputFormatter> _ingredientNameFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-Z ]'),
      ),
    ];
  }

  List<TextInputFormatter> _decimalFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp(r'[0-9.]'),
      ),
    ];
  }

  List<TextInputFormatter> _urlFormatters() {
    return [
      FilteringTextInputFormatter.deny(
        RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
      ),
      FilteringTextInputFormatter.deny(RegExp(r'\s')),
    ];
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> items) {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return items;

    return items.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final unit = (item['unit'] ?? '').toString().toLowerCase();
      return name.contains(keyword) || unit.contains(keyword);
    }).toList();
  }

  void _showAlert({
    required String title,
    required String message,
    required AppAlertType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    AppAlert.show(
      context,
      title: title,
      message: message,
      type: type,
      duration: duration,
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _displayDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickExpiryDate(
    BuildContext context,
    TextEditingController controller,
    void Function(void Function()) setModalState,
  ) async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 1));

    if (controller.text.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(controller.text.trim());
      if (parsed != null) {
        initialDate = parsed;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(days: 1))
          : initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setModalState(() {
        controller.text = _formatDate(picked);
      });
    }
  }

  Future<void> _showIngredientForm({Map<String, dynamic>? item}) async {
    final isEdit = item != null;

    final nameCtrl =
        TextEditingController(text: item?['name']?.toString() ?? '');
    final stockCtrl = TextEditingController(
      text: item?['stock'] != null ? item!['stock'].toString() : '',
    );
    final minimumCtrl = TextEditingController(
      text: item?['minimum_stock'] != null
          ? item!['minimum_stock'].toString()
          : '',
    );
    final expiryCtrl = TextEditingController(
      text: item?['expiry_date']?.toString() ?? '',
    );
    final imageCtrl = TextEditingController(
      text: item?['image_url']?.toString() ?? '',
    );

    String? selectedUnit = item?['unit']?.toString().toLowerCase();
    if (selectedUnit != null && !_unitOptions.contains(selectedUnit)) {
      selectedUnit = null;
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
            final previewUrl = imageCtrl.text.trim();

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
                      isEdit ? 'Edit Bahan Baku' : 'Tambah Bahan Baku',
                      style: AppTextStyles.headlineSm.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atur stok, satuan, batas minimum, kadaluarsa, dan gambar bahan baku.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: nameCtrl,
                      label: 'Nama Bahan',
                      hint: 'Contoh: Biji Kopi',
                      inputFormatters: _ingredientNameFormatters(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'SATUAN',
                      style: AppTextStyles.labelMd,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: InputDecoration(
                        hintText: 'Pilih satuan',
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
                      items: _unitOptions.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedUnit = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: stockCtrl,
                      label: 'Stok',
                      hint: 'Contoh: 2 atau 3.5',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: _decimalFormatters(),
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: minimumCtrl,
                      label: 'Stok Minimum',
                      hint: 'Contoh: 0.5',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: _decimalFormatters(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'KADALUARSA',
                      style: AppTextStyles.labelMd,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: expiryCtrl,
                      readOnly: true,
                      onTap: () => _pickExpiryDate(
                        context,
                        expiryCtrl,
                        setModalState,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Pilih tanggal kadaluarsa',
                        suffixIcon: IconButton(
                          onPressed: () => _pickExpiryDate(
                            context,
                            expiryCtrl,
                            setModalState,
                          ),
                          icon: const Icon(Icons.calendar_today_outlined),
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
                    const SizedBox(height: 14),
                    _buildField(
                      controller: imageCtrl,
                      label: 'URL Gambar',
                      hint: 'https://contoh.com/gambar.png',
                      keyboardType: TextInputType.url,
                      inputFormatters: _urlFormatters(),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        color: AppColors.surfaceContainerLow,
                        child: previewUrl.isNotEmpty && _isValidImageUrl(previewUrl)
                            ? FancyShimmerImage(
                                imageUrl: previewUrl,
                                boxFit: BoxFit.cover,
                                errorWidget: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.image_outlined, size: 42),
                              ),
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
                            ),
                            child: Text(
                              'Batal',
                              style: AppTextStyles.titleMd,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              final unit = (selectedUnit ?? '').trim();
                              final stockText = stockCtrl.text.trim();
                              final minimumText = minimumCtrl.text.trim();
                              final expiryDate = expiryCtrl.text.trim();
                              final imageUrl = imageCtrl.text.trim();

                              if (!_isNotEmpty(name)) {
                                _showAlert(
                                  title: 'Nama bahan wajib diisi',
                                  message:
                                      'Nama bahan tidak boleh kosong atau hanya spasi.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isValidIngredientName(name)) {
                                _showAlert(
                                  title: 'Nama bahan tidak valid',
                                  message:
                                      'Nama bahan hanya boleh huruf dan tidak boleh emoji, angka, atau karakter aneh.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (unit.isEmpty) {
                                _showAlert(
                                  title: 'Satuan belum dipilih',
                                  message:
                                      'Pilih satuan bahan terlebih dahulu.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isNotEmpty(stockText)) {
                                _showAlert(
                                  title: 'Stok wajib diisi',
                                  message:
                                      'Stok tidak boleh kosong atau hanya spasi.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isValidDecimal(stockText)) {
                                _showAlert(
                                  title: 'Stok tidak valid',
                                  message:
                                      'Stok hanya boleh angka atau desimal.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isNotEmpty(minimumText)) {
                                _showAlert(
                                  title: 'Stok minimum wajib diisi',
                                  message:
                                      'Stok minimum tidak boleh kosong atau hanya spasi.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isValidDecimal(minimumText)) {
                                _showAlert(
                                  title: 'Stok minimum tidak valid',
                                  message:
                                      'Stok minimum hanya boleh angka atau desimal.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isNotEmpty(expiryDate)) {
                                _showAlert(
                                  title: 'Kadaluarsa wajib diisi',
                                  message:
                                      'Tanggal kadaluarsa harus dipilih dari kalender.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              final parsedExpiry = DateTime.tryParse(expiryDate);
                              if (parsedExpiry == null) {
                                _showAlert(
                                  title: 'Kadaluarsa tidak valid',
                                  message:
                                      'Pilih tanggal kadaluarsa yang valid dari kalender.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isValidImageUrl(imageUrl)) {
                                _showAlert(
                                  title: 'URL gambar tidak valid',
                                  message:
                                      'URL gambar boleh kosong, tapi kalau diisi harus URL valid diawali http:// atau https://',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              final stock = num.parse(stockText);
                              final minimumStock = num.parse(minimumText);

                              try {
                                if (isEdit) {
                                  await _ingredientService.updateIngredient(
                                    id: item['id'].toString(),
                                    name: name,
                                    unit: unit,
                                    stock: stock,
                                    minimumStock: minimumStock,
                                    expiryDate: expiryDate,
                                    imageUrl: imageUrl,
                                  );
                                } else {
                                  await _ingredientService.addIngredient(
                                    name: name,
                                    unit: unit,
                                    stock: stock,
                                    minimumStock: minimumStock,
                                    expiryDate: expiryDate,
                                    imageUrl: imageUrl,
                                  );
                                }

                                if (!mounted) return;
                                Navigator.pop(context);
                                await _loadIngredients();
                                _showAlert(
                                  title: isEdit
                                      ? 'Bahan diperbarui'
                                      : 'Bahan ditambahkan',
                                  message: isEdit
                                      ? 'Data bahan baku berhasil diperbarui.'
                                      : 'Bahan baku baru berhasil ditambahkan.',
                                  type: AppAlertType.success,
                                );
                              } catch (e) {
                                _showAlert(
                                  title: 'Gagal menyimpan bahan',
                                  message: '$e',
                                  type: AppAlertType.error,
                                );
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
                              isEdit ? 'Simpan' : 'Tambah',
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

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text('Hapus Bahan'),
        content: Text(
          'Yakin ingin menghapus bahan "${item['name']}"?',
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
                await _ingredientService.deleteIngredient(item['id'].toString());
                if (!mounted) return;
                Navigator.pop(context);
                await _loadIngredients();

                _showAlert(
                  title: 'Bahan dihapus',
                  message: 'Bahan baku berhasil dihapus dari sistem.',
                  type: AppAlertType.info,
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);

                _showAlert(
                  title: 'Gagal menghapus bahan',
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
    ValueChanged<String>? onChanged,
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
          onChanged: onChanged,
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

  Color _stockColor(num stock, num minimumStock) {
    if (stock <= minimumStock) return AppColors.error;
    return const Color(0xFF2E7D32);
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

  Widget _itemCard(Map<String, dynamic> item) {
    final name = (item['name'] ?? '-').toString();
    final unit = (item['unit'] ?? '-').toString();
    final stock = (item['stock'] ?? 0) as num;
    final minimumStock = (item['minimum_stock'] ?? 0) as num;
    final expiryDate = item['expiry_date']?.toString();
    final imageUrl = item['image_url']?.toString();
    final stockColor = _stockColor(stock, minimumStock);
    final isLowStock = stock <= minimumStock;

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
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Container(
              width: double.infinity,
              height: 150,
              color: AppColors.surfaceContainerLow,
              child: imageUrl != null && imageUrl.trim().isNotEmpty
                  ? FancyShimmerImage(
                      imageUrl: imageUrl,
                      boxFit: BoxFit.cover,
                      errorWidget: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 38),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image_outlined, size: 42),
                    ),
            ),
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
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showIngredientForm(item: item);
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        isLowStock ? 'STOK MENIPIS' : 'STOK AMAN',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: stockColor,
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
                        color: AppColors.secondary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        unit.toUpperCase(),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _miniInfo(
                        'Stok',
                        '$stock $unit',
                        Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _miniInfo(
                        'Minimum',
                        '$minimumStock $unit',
                        Icons.warning_amber_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _miniInfo(
                  'Kadaluarsa',
                  _displayDate(expiryDate),
                  Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
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

  @override
  Widget build(BuildContext context) {
    final filteredItems = _applyFilter(_items);
    final totalItems = _items.length;
    final lowStockItems = _items.where((e) {
      final stock = (e['stock'] ?? 0) as num;
      final minimum = (e['minimum_stock'] ?? 0) as num;
      return stock <= minimum;
    }).length;

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
              onPressed: () => _showIngredientForm(),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Bahan'),
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
                    title: 'Gagal memuat stok bahan',
                    error: _loadError,
                    onRetry: _loadIngredients,
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      Text(
                        'Stok Bahan',
                        style: AppTextStyles.displayLg.copyWith(fontSize: 34),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pantau stok bahan baku, batas minimum, dan tanggal kadaluarsa.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _summaryCard(
                            title: 'Total Bahan',
                            value: '$totalItems',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            title: 'Stok Menipis',
                            value: '$lowStockItems',
                            icon: Icons.warning_amber_outlined,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari nama bahan atau satuan',
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
                      const SizedBox(height: 18),
                      if (filteredItems.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Belum ada bahan ditemukan.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ...filteredItems.map(_itemCard),
                    ],
                  ),
      ),
    );
  }
}