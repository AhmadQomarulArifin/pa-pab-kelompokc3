import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/role_config.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/secure_storage_service.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedRoleIndex = 0;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final List<Map<String, dynamic>> _roles = [
    {
      'label': 'Owner',
      'value': 'owner',
      'icon': Icons.admin_panel_settings_outlined,
      'emailHint': 'owner@gmail.com',
      'desc': 'Akses penuh seluruh sistem',
    },
    {
      'label': 'Barista',
      'value': 'barista',
      'icon': Icons.coffee_maker_outlined,
      'emailHint': 'barista@gmail.com',
      'desc': 'Kelola stok dan bahan baku',
    },
    {
      'label': 'Kasir',
      'value': 'kasir',
      'icon': Icons.point_of_sale_outlined,
      'emailHint': 'kasir@gmail.com',
      'desc': 'Kelola transaksi dan penjualan',
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _selectedRoleValue =>
      _roles[_selectedRoleIndex]['value'] as String;

  String get _selectedRoleLabel =>
      _roles[_selectedRoleIndex]['label'] as String;

  String get _selectedEmailHint =>
      _roles[_selectedRoleIndex]['emailHint'] as String;

  String get _selectedRoleDesc =>
      _roles[_selectedRoleIndex]['desc'] as String;

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage(
        title: 'Data belum lengkap',
        message: 'Masukkan email dan kata sandi terlebih dahulu.',
        isError: true,
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final response = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Akun tidak ditemukan.');
      }

      final profile = await _userService.getUserProfile(user.id);
      if (profile == null) {
        throw Exception('Profil pengguna tidak ditemukan.');
      }

      final dbRole = (profile['role'] as String).toLowerCase();
      final isActive = profile['is_active'] as bool? ?? true;

      if (!isActive) {
        throw Exception('Akun ini sudah dinonaktifkan.');
      }

      if (dbRole != _selectedRoleValue) {
        throw Exception(
          'Role yang dipilih tidak sesuai. Akun ini terdaftar sebagai ${_labelFromRole(dbRole)}.',
        );
      }

      await SecureStorageService.instance.saveLogin(
        userId: user.id,
        email: user.email ?? _emailController.text.trim(),
      );

      final roleConfig = RoleConfig.fromRoleString(dbRole);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(role: roleConfig),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final raw = e.toString().toLowerCase();
      String friendlyMessage = 'Terjadi kesalahan saat masuk.';

      if (raw.contains('invalid login credentials')) {
        friendlyMessage =
            'Email atau kata sandi salah. Periksa kembali akun ${_selectedRoleLabel.toLowerCase()} Anda.';
      } else if (raw.contains('profil pengguna tidak ditemukan') ||
          raw.contains('data profil user tidak ditemukan')) {
        friendlyMessage =
            'Profil akun belum terhubung ke sistem. Hubungi owner untuk pengecekan data pengguna.';
      } else if (raw.contains('role yang dipilih tidak sesuai')) {
        friendlyMessage = 'Role yang dipilih tidak sesuai dengan akun ini.';
      } else if (raw.contains('akun ini sudah dinonaktifkan')) {
        friendlyMessage = 'Akun ini sudah dinonaktifkan. Hubungi owner.';
      }

      _showMessage(
        title: 'Login gagal',
        message: friendlyMessage,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _labelFromRole(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'barista':
        return 'Barista';
      case 'kasir':
        return 'Kasir';
      default:
        return role;
    }
  }

  void _showMessage({
    required String title,
    required String message,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
                  color: isError
                      ? AppColors.error.withOpacity(0.10)
                      : AppColors.secondary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? AppColors.error : AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: AppTextStyles.headlineSm.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isError ? AppColors.error : AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Mengerti',
                    style: AppTextStyles.titleMd.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMd.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.outline,
          fontSize: 15,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.secondary,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: List.generate(_roles.length, (index) {
        final role = _roles[index];
        final isSelected = _selectedRoleIndex == index;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedRoleIndex = index;
                _emailController.clear();
                _passwordController.clear();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: index < _roles.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary.withOpacity(0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.outlineVariant.withOpacity(0.45),
                  width: isSelected ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary.withOpacity(0.12)
                          : AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      role['icon'] as IconData,
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    role['label'] as String,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRoleInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _roles[_selectedRoleIndex]['icon'] as IconData,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masuk sebagai $_selectedRoleLabel',
                  style: AppTextStyles.titleMd.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedRoleDesc,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.secondary.withOpacity(0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Masuk',
                    style: AppTextStyles.titleMd.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.coffee_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Nol Persen Kafe',
                          style: AppTextStyles.headlineSm.copyWith(
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Masuk ke sistem operasional cafe sesuai peran akun Anda.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildRoleInfoCard(),
                  const SizedBox(height: 20),

                  Text(
                    'PILIH ROLE',
                    style: AppTextStyles.labelMd.copyWith(
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRoleSelector(),
                  const SizedBox(height: 24),

                  Text(
                    'EMAIL ${_selectedRoleLabel.toUpperCase()}',
                    style: AppTextStyles.labelMd.copyWith(
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _emailController,
                    hint: _selectedEmailHint,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'KATA SANDI',
                    style: AppTextStyles.labelMd.copyWith(
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _passwordController,
                    hint: 'Masukkan kata sandi',
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.outline,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}