import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import '../auth/auth_bloc.dart';
import '../auth/login_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../injection_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepository = sl<AuthRepository>();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isPasswordAccordionOpen = false;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedGender = '';

  final _pwdFormKey = GlobalKey<FormState>();
  final _currentPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  String _genderToString(Gender? g) {
    if (g == Gender.male) return 'MALE';
    if (g == Gender.female) return 'FEMALE';
    if (g == Gender.other) return 'OTHER';
    return '';
  }

  Gender? _stringToGender(String s) {
    if (s == 'MALE') return Gender.male;
    if (s == 'FEMALE') return Gender.female;
    if (s == 'OTHER') return Gender.other;
    return null;
  }

  void _startEditing(UserProfile user) {
    setState(() {
      _fullNameController.text = user.fullName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
      _selectedGender = _genderToString(user.gender);
      _isEditing = true;
    });
  }

  void _onSaveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _authRepository.updateProfile(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          gender: _stringToGender(_selectedGender),
        );

        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        // Trigger profile refresh
        context.read<AuthBloc>().add(AppStarted());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onChangePassword() async {
    if (_pwdFormKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _authRepository.changePassword(
          currentPassword: _currentPwdController.text,
          newPassword: _newPwdController.text,
          confirmPassword: _confirmPwdController.text,
        );

        setState(() {
          _isSaving = false;
          _isPasswordAccordionOpen = false;
          _currentPwdController.clear();
          _newPwdController.clear();
          _confirmPwdController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đổi mật khẩu thất bại: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return Center(child: CircularProgressIndicator(color: accentColor));
            }

            if (state is! Authenticated) {
              return const Center(child: Text('Chưa đăng nhập.'));
            }

            final user = state.user;
            final initial = user.userName.isNotEmpty ? user.userName[0].toUpperCase() : 'U';
            final joinedDate = user.createdAt != null
                ? DateFormat('dd/MM/yyyy').format(user.createdAt!)
                : '—';

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AuthBloc>().add(AppStarted());
              },
              color: accentColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar Ring Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor, width: 3),
                            ),
                            child: Center(
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.userName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Row Card
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18.0),
                              child: Column(
                                children: [
                                  Text(
                                    '${user.token ?? 0}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Token còn lại', style: TextStyle(fontSize: 11, color: textMuted)),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 40, color: borderColor),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18.0),
                              child: Column(
                                children: [
                                  Text(
                                    joinedDate,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Ngày tham gia', style: TextStyle(fontSize: 11, color: textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile editing form or info cards
                    Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_circle, color: accentColor, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Thông tin cá nhân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              if (!_isEditing)
                                GestureDetector(
                                  onTap: () => _startEditing(user),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Chỉnh sửa',
                                      style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                              else
                                IconButton(
                                  icon: const Icon(LucideIcons.x, size: 20),
                                  onPressed: () => setState(() => _isEditing = false),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (!_isEditing) ...[
                            _buildInfoField('Tên đầy đủ', user.fullName, LucideIcons.user, textMuted),
                            _buildInfoField('Giới tính', user.gender == Gender.male ? 'Nam' : user.gender == Gender.female ? 'Nữ' : 'Khác', LucideIcons.user, textMuted),
                            _buildInfoField('Số điện thoại', user.phoneNumber, LucideIcons.phone, textMuted),
                            _buildInfoField('Địa chỉ', user.address, LucideIcons.mapPin, textMuted),
                          ] else ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildInputField('Tên đầy đủ', _fullNameController, LucideIcons.user, surfaceColor, borderColor),
                                  const SizedBox(height: 14),
                                  
                                  // Gender option selector buttons
                                  Text('Giới tính', style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildGenderBtn('MALE', 'Nam', accentColor, borderColor),
                                      const SizedBox(width: 8),
                                      _buildGenderBtn('FEMALE', 'Nữ', accentColor, borderColor),
                                      const SizedBox(width: 8),
                                      _buildGenderBtn('OTHER', 'Khác', accentColor, borderColor),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  
                                  _buildInputField('Số điện thoại', _phoneController, LucideIcons.phone, surfaceColor, borderColor, keyboardType: TextInputType.phone),
                                  const SizedBox(height: 14),
                                  _buildInputField('Địa chỉ', _addressController, LucideIcons.mapPin, surfaceColor, borderColor, maxLines: 2),
                                  const SizedBox(height: 18),
                                  
                                  ElevatedButton(
                                    onPressed: _isSaving ? null : _onSaveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    child: _isSaving
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(LucideIcons.save, size: 16),
                                              SizedBox(width: 8),
                                              Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Theme Selector Section
                    Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: accentColor, size: 18),
                              const SizedBox(width: 8),
                              const Text('Giao diện (Theme)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeNotifier,
                            builder: (context, mode, _) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(child: Text('Sáng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                      selected: mode == ThemeMode.light,
                                      onSelected: (_) => themeNotifier.value = ThemeMode.light,
                                      selectedColor: accentColor,
                                      labelStyle: TextStyle(color: mode == ThemeMode.light ? Colors.white : textMuted),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(child: Text('Tối', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                      selected: mode == ThemeMode.dark,
                                      onSelected: (_) => themeNotifier.value = ThemeMode.dark,
                                      selectedColor: accentColor,
                                      labelStyle: TextStyle(color: mode == ThemeMode.dark ? Colors.white : textMuted),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(child: Text('Hệ thống', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                      selected: mode == ThemeMode.system,
                                      onSelected: (_) => themeNotifier.value = ThemeMode.system,
                                      selectedColor: accentColor,
                                      labelStyle: TextStyle(color: mode == ThemeMode.system ? Colors.white : textMuted),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Change Password Section
                    Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPasswordAccordionOpen = !_isPasswordAccordionOpen;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.keyRound, color: accentColor, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                                Icon(
                                  _isPasswordAccordionOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                  color: textMuted,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          if (_isPasswordAccordionOpen) ...[
                            const SizedBox(height: 16),
                            Form(
                              key: _pwdFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildInputField('Mật khẩu hiện tại', _currentPwdController, LucideIcons.lock, surfaceColor, borderColor, obscureText: true),
                                  const SizedBox(height: 12),
                                  _buildInputField('Mật khẩu mới', _newPwdController, LucideIcons.lock, surfaceColor, borderColor, obscureText: true),
                                  const SizedBox(height: 12),
                                  _buildInputField('Xác nhận mật khẩu mới', _confirmPwdController, LucideIcons.lock, surfaceColor, borderColor, obscureText: true, validator: (v) {
                                    if (v != _newPwdController.text) {
                                      return 'Mật khẩu xác nhận không khớp';
                                    }
                                    return null;
                                  }),
                                  const SizedBox(height: 18),
                                  ElevatedButton(
                                    onPressed: _isSaving ? null : _onChangePassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    child: _isSaving
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text('Cập nhật mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    OutlinedButton(
                      onPressed: _onLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.red.withOpacity(0.06),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.logOut, size: 18),
                          SizedBox(width: 8),
                          Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Test Crashlytics Button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Force a test crash to report to Firebase Console
                        FirebaseCrashlytics.instance.crash();
                      },
                      icon: const Icon(Icons.bug_report_rounded, color: Colors.orange, size: 18),
                      label: const Text('Thử nghiệm Firebase Crashlytics (Crash App)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String? value, IconData icon, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: textMuted)),
                const SizedBox(height: 2),
                Text(value != null && value.isNotEmpty ? value : '—', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color surfaceColor,
    Color borderColor, {
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16),
            filled: true,
            fillColor: surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
          validator: validator ?? (value) {
            if (value == null || value.isEmpty) {
              return 'Không được để trống';
            }
            return null;
          },
        )
      ],
    );
  }

  Widget _buildGenderBtn(String value, String label, Color accentColor, Color borderColor) {
    final isActive = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGender = value;
          });
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? accentColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? accentColor : borderColor, width: isActive ? 2 : 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? accentColor : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
