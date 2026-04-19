import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_error_state.dart';

class StafScreen extends StatefulWidget {
  const StafScreen({super.key});

  @override
  State<StafScreen> createState() => _StafScreenState();
}

class _StafScreenState extends State<StafScreen> {
  final client = SupabaseService.client;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  Object? _loadError;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showFab = true;
  double _lastOffset = 0;

  List<TextInputFormatter> _nameFormatters() {
    return [
      FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-Z ]'),
      ),
    ];
  }

  List<TextInputFormatter> _emailFormatters() {
    return [
      FilteringTextInputFormatter.deny(
        RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
      ),
      FilteringTextInputFormatter.deny(RegExp(r'\s')),
    ];
  }

  List<TextInputFormatter> _passwordFormatters() {
    return [
      FilteringTextInputFormatter.deny(
        RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
      ),
      FilteringTextInputFormatter.deny(RegExp(r'\s')),
    ];
  }

  bool _containsEmoji(String value) {
    return RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    ).hasMatch(value);
  }

  bool _isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  bool _isValidFullName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_containsEmoji(trimmed)) return false;

    return RegExp(r'^[a-zA-Z ]+$').hasMatch(trimmed);
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    if (_containsEmoji(trimmed)) return false;

    final basicValid = RegExp(
      r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
    ).hasMatch(trimmed);

    return basicValid;
  }

  bool _isValidPassword(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_containsEmoji(trimmed)) return false;
    if (trimmed.length < 6) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
    searchController.addListener(applyFilter);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
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

  Future<String> _getAccessToken() async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Session owner tidak ditemukan. Silakan login ulang.');
    }

    return accessToken;
  }

  Future<void> loadUsers() async {
    try {
      setState(() {
        isLoading = true;
        _loadError = null;
      });

      final data = await client
          .from('users')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        users = List<Map<String, dynamic>>.from(data);
        filteredUsers = List.from(users);
        isLoading = false;
      });

      applyFilter();
    } catch (e) {
      debugPrint('STAF LOAD ERROR: $e');
      setState(() {
        isLoading = false;
        _loadError = e;
      });
    }
  }

  void applyFilter() {
    final keyword = searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) {
      setState(() => filteredUsers = List.from(users));
      return;
    }

    final result = users.where((user) {
      final name = (user['full_name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();

      return name.contains(keyword) ||
          email.contains(keyword) ||
          role.contains(keyword);
    }).toList();

    setState(() => filteredUsers = result);
  }

  Future<void> toggleActive(String id, bool current) async {
    try {
      final accessToken = await _getAccessToken();

      final res = await client.functions.invoke(
        'manage-staff-user',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
        body: {
          'action': 'update',
          'user_id': id,
          'is_active': !current,
        },
      );

      if (res.status != 200) {
        final msg = (res.data is Map && res.data['error'] != null)
            ? res.data['error'].toString()
            : 'Gagal mengubah status user';
        throw Exception(msg);
      }

      await loadUsers();

      _showAlert(
        title: !current ? 'Pengguna diaktifkan' : 'Pengguna dinonaktifkan',
        message: !current
            ? 'Akun pengguna berhasil diaktifkan.'
            : 'Akun pengguna berhasil dinonaktifkan.',
        type: AppAlertType.info,
      );
    } catch (e) {
      _showAlert(
        title: 'Gagal mengubah status',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppAlertType.error,
      );
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final accessToken = await _getAccessToken();

      final res = await client.functions.invoke(
        'manage-staff-user',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
        body: {
          'action': 'delete',
          'user_id': id,
        },
      );

      if (res.status != 200) {
        final msg = (res.data is Map && res.data['error'] != null)
            ? res.data['error'].toString()
            : 'Gagal menghapus user';
        throw Exception(msg);
      }

      await loadUsers();

      _showAlert(
        title: 'Pengguna dihapus',
        message: 'Data pengguna dan akun login berhasil dihapus.',
        type: AppAlertType.info,
      );
    } catch (e) {
      _showAlert(
        title: 'Gagal menghapus pengguna',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppAlertType.error,
      );
    }
  }

  Future<void> showUserForm({Map<String, dynamic>? user}) async {
    final isEdit = user != null;

    final nameController = TextEditingController(
      text: user?['full_name']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: user?['email']?.toString() ?? '',
    );
    final passwordController = TextEditingController();

    String selectedRole = (user?['role']?.toString() ?? 'kasir').toLowerCase();
    bool isActive = (user?['is_active'] ?? true) as bool;

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
                      isEdit ? 'Edit Pengguna' : 'Tambah Pengguna',
                      style: AppTextStyles.headlineSm.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEdit
                          ? 'Perbarui data pengguna dan akun login.'
                          : 'Tambahkan pengguna baru.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildField(
                      controller: nameController,
                      label: 'Nama Lengkap',
                      hint: 'Contoh: Andi Barista',
                      inputFormatters: _nameFormatters(),
                    ),
                    const SizedBox(height: 14),
                    buildField(
                      controller: emailController,
                      label: 'Email',
                      hint: 'contoh@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: _emailFormatters(),
                    ),
                    const SizedBox(height: 14),
                    buildField(
                      controller: passwordController,
                      label: isEdit
                          ? 'Password Baru (Opsional)'
                          : 'Password Awal',
                      hint: isEdit
                          ? 'Kosongkan jika tidak diubah'
                          : 'Minimal 6 karakter',
                      obscureText: true,
                      inputFormatters: _passwordFormatters(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'ROLE',
                      style: AppTextStyles.labelMd,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
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
                      items: const [
                        DropdownMenuItem(
                          value: 'owner',
                          child: Text('Owner'),
                        ),
                        DropdownMenuItem(
                          value: 'barista',
                          child: Text('Barista'),
                        ),
                        DropdownMenuItem(
                          value: 'kasir',
                          child: Text('Kasir'),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() => selectedRole = value ?? 'kasir');
                      },
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
                            Icons.verified_user_outlined,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Status aktif',
                              style: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeColor: AppColors.secondary,
                            onChanged: (v) {
                              setModalState(() => isActive = v);
                            },
                          ),
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
                              final name = nameController.text.trim();
                              final email =
                                  emailController.text.trim().toLowerCase();
                              final password = passwordController.text.trim();

                              if (!_isNotEmpty(name)) {
                                _showAlert(
                                  title: 'Nama lengkap wajib diisi',
                                  message:
                                      'Nama lengkap tidak boleh kosong atau hanya spasi.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isValidFullName(name)) {
                                _showAlert(
                                  title: 'Nama lengkap tidak valid',
                                  message:
                                      'Nama lengkap hanya boleh huruf dan tidak boleh angka, emoji, atau karakter aneh.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isNotEmpty(email)) {
                                _showAlert(
                                  title: 'Email wajib diisi',
                                  message:
                                      'Email tidak boleh kosong atau hanya spasi.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (_containsEmoji(email)) {
                                _showAlert(
                                  title: 'Email tidak valid',
                                  message:
                                      'Email tidak boleh mengandung emoji.',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!_isValidEmail(email)) {
                                _showAlert(
                                  title: 'Email tidak valid',
                                  message:
                                      'Email harus format benar dan wajib berakhir dengan @gmail.com',
                                  type: AppAlertType.warning,
                                );
                                return;
                              }

                              if (!isEdit) {
                                if (!_isNotEmpty(password)) {
                                  _showAlert(
                                    title: 'Password wajib diisi',
                                    message:
                                        'Password tidak boleh kosong atau hanya spasi.',
                                    type: AppAlertType.warning,
                                  );
                                  return;
                                }

                                if (_containsEmoji(password)) {
                                  _showAlert(
                                    title: 'Password tidak valid',
                                    message:
                                        'Password tidak boleh mengandung emoji.',
                                    type: AppAlertType.warning,
                                  );
                                  return;
                                }

                                if (!_isValidPassword(password)) {
                                  _showAlert(
                                    title: 'Password tidak valid',
                                    message:
                                        'Password minimal 6 karakter dan tidak boleh emoji.',
                                    type: AppAlertType.warning,
                                  );
                                  return;
                                }
                              }

                              if (isEdit && password.isNotEmpty) {
                                if (_containsEmoji(password)) {
                                  _showAlert(
                                    title: 'Password tidak valid',
                                    message:
                                        'Password baru tidak boleh mengandung emoji.',
                                    type: AppAlertType.warning,
                                  );
                                  return;
                                }

                                if (!_isValidPassword(password)) {
                                  _showAlert(
                                    title: 'Password tidak valid',
                                    message:
                                        'Password baru minimal 6 karakter dan tidak boleh emoji.',
                                    type: AppAlertType.warning,
                                  );
                                  return;
                                }
                              }

                              try {
                                if (isEdit) {
                                  final accessToken = await _getAccessToken();

                                  final body = <String, dynamic>{
                                    'action': 'update',
                                    'user_id': user['id'].toString(),
                                    'full_name': name,
                                    'email': email,
                                    'role': selectedRole,
                                    'is_active': isActive,
                                  };

                                  if (password.isNotEmpty) {
                                    body['password'] = password;
                                  }

                                  final res = await client.functions.invoke(
                                    'manage-staff-user',
                                    headers: {
                                      'Authorization': 'Bearer $accessToken',
                                    },
                                    body: body,
                                  );

                                  if (res.status != 200) {
                                    final msg = (res.data is Map &&
                                            res.data['error'] != null)
                                        ? res.data['error'].toString()
                                        : 'Gagal mengupdate user login';
                                    throw Exception(msg);
                                  }
                                } else {
                                  final accessToken = await _getAccessToken();

                                  final res = await client.functions.invoke(
                                    'create-staff-user',
                                    headers: {
                                      'Authorization': 'Bearer $accessToken',
                                    },
                                    body: {
                                      'full_name': name,
                                      'email': email,
                                      'password': password,
                                      'role': selectedRole,
                                      'is_active': isActive,
                                    },
                                  );

                                  if (res.status != 200) {
                                    final msg = (res.data is Map &&
                                            res.data['error'] != null)
                                        ? res.data['error'].toString()
                                        : 'Gagal membuat user login';
                                    throw Exception(msg);
                                  }
                                }

                                if (!mounted) return;
                                Navigator.pop(context);
                                await loadUsers();

                                _showAlert(
                                  title: isEdit
                                      ? 'Pengguna diperbarui'
                                      : 'User login dibuat',
                                  message: isEdit
                                      ? 'Data pengguna dan akun login berhasil diperbarui.'
                                      : 'Akun berhasil dibuat dan sudah bisa login.',
                                  type: AppAlertType.success,
                                );
                              } catch (e) {
                                _showAlert(
                                  title: isEdit
                                      ? 'Gagal menyimpan pengguna'
                                      : 'Gagal membuat user login',
                                  message: e
                                      .toString()
                                      .replaceFirst('Exception: ', ''),
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

  void confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text('Hapus Pengguna'),
        content: Text(
          'Yakin ingin menghapus "${user['full_name']}"?\n\nAkun login juga akan ikut dihapus.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteUser(user['id'].toString());
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

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.labelMd),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
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

  Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return const Color(0xFFEF6C00);
      case 'barista':
        return const Color(0xFF2E7D32);
      case 'kasir':
        return const Color(0xFF1565C0);
      default:
        return Colors.grey;
    }
  }

  IconData roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Icons.admin_panel_settings_outlined;
      case 'barista':
        return Icons.coffee_maker_outlined;
      case 'kasir':
        return Icons.point_of_sale_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Widget userCard(Map<String, dynamic> user) {
    final name = (user['full_name'] ?? '-').toString();
    final email = (user['email'] ?? '-').toString();
    final role = (user['role'] ?? '-').toString();
    final isActive = (user['is_active'] ?? true) as bool;
    final color = roleColor(role);

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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(roleIcon(role), color: color),
              ),
              const SizedBox(width: 14),
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
                      email,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    showUserForm(user: user);
                  } else if (value == 'toggle') {
                    toggleActive(user['id'].toString(), isActive);
                  } else if (value == 'delete') {
                    confirmDelete(user);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text('Aktif / Nonaktif'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus'),
                  ),
                ],
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
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: color,
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
                  color: isActive
                      ? const Color(0xFF2E7D32).withOpacity(0.10)
                      : AppColors.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isActive ? 'AKTIF' : 'NONAKTIF',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: isActive
                        ? const Color(0xFF2E7D32)
                        : AppColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int get totalOwner =>
      users.where((u) => (u['role'] ?? '') == 'owner').length;

  int get totalBarista =>
      users.where((u) => (u['role'] ?? '') == 'barista').length;

  int get totalKasir =>
      users.where((u) => (u['role'] ?? '') == 'kasir').length;

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: AnimatedSlide(
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 220),
        child: AnimatedOpacity(
          opacity: _showFab ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          child: IgnorePointer(
            ignoring: !_showFab,
            child: FloatingActionButton.extended(
              onPressed: () => showUserForm(),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Pengguna'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? AppErrorState(
                    title: 'Gagal memuat pengguna',
                    error: _loadError,
                    onRetry: loadUsers,
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      Text(
                        'Pengguna',
                        style: AppTextStyles.displayLg.copyWith(fontSize: 34),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kelola owner, barista, dan kasir untuk operasional cafe.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _summaryCard(
                            title: 'Owner',
                            value: '$totalOwner',
                            icon: Icons.admin_panel_settings_outlined,
                            color: const Color(0xFFEF6C00),
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            title: 'Barista',
                            value: '$totalBarista',
                            icon: Icons.coffee_maker_outlined,
                            color: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            title: 'Kasir',
                            value: '$totalKasir',
                            icon: Icons.point_of_sale_outlined,
                            color: const Color(0xFF1565C0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari nama, email, atau role',
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
                      if (filteredUsers.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Belum ada pengguna ditemukan.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ...filteredUsers.map(userCard),
                      const SizedBox(height: 90),
                    ],
                  ),
      ),
    );
  }
}