import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../theme.dart';
import 'login_screen.dart';

/// Profile — same content as the web ProfilePage.jsx.
/// Personal info + medical profile are saved on the device.
/// Password change needs Firebase, so it is not available in this build.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _apiUrlController = TextEditingController();
  String _smoking = 'non_smoker';
  String _exposure = 'not_exposed';
  String _message = '';
  bool _messageIsError = false;
  bool _loading = true;

  static const Map<String, String> smokingOptions = {
    'non_smoker': 'Non-Smoker',
    'ex_smoker': 'Ex-Smoker',
    'mild_smoker': 'Mild Smoker (occasional / social)',
    'moderate_smoker': 'Moderate Smoker (10–20 cig/day)',
    'chain_smoker': 'Chain Smoker (20+ cig/day)',
  };

  static const Map<String, String> exposureOptions = {
    'not_exposed': 'Not Exposed',
    'occasionally_exposed': 'Occasionally Exposed (rare contact)',
    'regularly_exposed': 'Regularly Exposed (daily environment)',
    'occupational': 'Occupational Exposure (workplace fumes/chemicals)',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _nameController.text = await SessionService.name;
    _emailController.text = await SessionService.email;
    _ageController.text = await SessionService.age;
    _smoking = await SessionService.smoking;
    _exposure = await SessionService.exposure;
    _apiUrlController.text = await SessionService.apiBaseUrl;
    setState(() => _loading = false);
  }

  void _showMessage(String text, {bool isError = false}) {
    setState(() {
      _message = text;
      _messageIsError = isError;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _message = '');
    });
  }

  Future<void> _saveInfo() async {
    await SessionService.saveNameEmail(
      _nameController.text.trim(),
      _emailController.text.trim(),
    );
    _showMessage('Profile updated successfully.');
  }

  Future<void> _saveMedical() async {
    final age = _ageController.text.trim();
    if (age.isNotEmpty) {
      final n = int.tryParse(age);
      if (n == null || n < 1 || n > 120) {
        _showMessage('Please enter a valid age (1–120).', isError: true);
        return;
      }
    }
    await SessionService.saveMedicalProfile(age, _smoking, _exposure);
    _showMessage('Medical profile saved.');
  }

  Future<void> _saveApiUrl() async {
    final url = _apiUrlController.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      _showMessage('Enter a valid URL starting with http:// or https://',
          isError: true);
      return;
    }
    await SessionService.saveApiBaseUrl(url);
    _showMessage('API URL saved.');
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SessionService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    return parts.map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.blue,
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isEmpty
                            ? 'My Profile'
                            : _nameController.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Manage your account information and security settings',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _messageIsError
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _messageIsError
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    fontSize: 13,
                    color: _messageIsError
                        ? AppColors.redDark
                        : const Color(0xFF16A34A),
                  ),
                ),
              ),

            // Personal information
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                    icon: Icons.person_outline,
                    iconColor: AppColors.blue,
                    iconBg: Color(0xFFEFF6FF),
                    title: 'Personal Information',
                    subtitle: 'Update your name and email address',
                  ),
                  const SizedBox(height: 16),
                  const Text('DISPLAY NAME',
                      style: _labelStyle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Your full name',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('EMAIL ADDRESS', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('ACCOUNT TYPE', style: _labelStyle),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.stone),
                    ),
                    child: const Text(
                      'Email / Password (local session)',
                      style: TextStyle(fontSize: 13, color: AppColors.ink2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveInfo,
                    child: const Text('Save changes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medical profile
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                    icon: Icons.monitor_heart,
                    iconColor: Color(0xFF16A34A),
                    iconBg: Color(0xFFF0FDF4),
                    title: 'Medical Profile',
                    subtitle:
                        'This information helps contextualise your scan results — it is stored on this device only and never shared',
                  ),
                  const SizedBox(height: 16),
                  const Text('AGE', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 45'),
                  ),
                  const Text(
                    'Years (1–120)',
                    style: TextStyle(fontSize: 11, color: AppColors.faint),
                  ),
                  const SizedBox(height: 14),
                  const Text('SMOKING HISTORY', style: _labelStyle),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _smoking,
                    items: smokingOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _smoking = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'OCCUPATIONAL / PASSIVE SMOKING EXPOSURE',
                    style: _labelStyle,
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _exposure,
                    items: exposureOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _exposure = v);
                    },
                  ),
                  const Text(
                    'Are you regularly exposed to second-hand smoke or occupational carcinogens (dust, asbestos, chemical fumes)?',
                    style: TextStyle(fontSize: 11, color: AppColors.faint),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveMedical,
                    child: const Text('Save medical profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Backend connection
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                    icon: Icons.cloud_outlined,
                    iconColor: AppColors.mintDark,
                    iconBg: AppColors.mintDim,
                    title: 'Backend Connection',
                    subtitle: 'Where the AI server runs (FastAPI, port 8000)',
                  ),
                  const SizedBox(height: 16),
                  const Text('API BASE URL', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'http://10.0.2.2:8000',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Android emulator: use http://10.0.2.2:8000\n'
                    'Real phone: use your PC\'s LAN IP, e.g. http://192.168.1.5:8000',
                    style: TextStyle(fontSize: 11, color: AppColors.faint, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveApiUrl,
                    child: const Text('Save API URL'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account actions
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                    icon: Icons.logout,
                    iconColor: AppColors.redDark,
                    iconBg: Color(0xFFFEF2F2),
                    title: 'Account Actions',
                    subtitle: 'Sign out of your account',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Sign out of LungDetect AI'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.redDark,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.stone),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink2,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Important: ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                'This AI tool is a screening aid only and does not replace professional medical diagnosis. All results must be reviewed by a qualified healthcare professional before any clinical decision is made.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

const TextStyle _labelStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppColors.ink2,
  letterSpacing: 0.4,
);

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
