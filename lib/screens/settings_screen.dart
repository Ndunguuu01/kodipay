import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _isLoading = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;
  String _selectedLanguage = 'English';
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _emailNotificationsEnabled = prefs.getBool('email_notifications_enabled') ?? true;
      _smsNotificationsEnabled = prefs.getBool('sms_notifications_enabled') ?? false;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('notifications_enabled', _notificationsEnabled),
      prefs.setBool('biometric_enabled', _biometricEnabled),
      prefs.setBool('email_notifications_enabled', _emailNotificationsEnabled),
      prefs.setBool('sms_notifications_enabled', _smsNotificationsEnabled),
      prefs.setString('selected_language', _selectedLanguage),
    ]);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF90CAF9),
                      Colors.blue.shade700,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Back Button
                    Positioned(
                      top: 40,
                      left: 20,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    // Title
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize your app experience',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notifications Section
                  _SettingsSection(
                    title: 'Notification Preferences',
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Notifications'),
                        subtitle: const Text('Receive updates about your properties'),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                            if (!value) {
                              _emailNotificationsEnabled = false;
                              _smsNotificationsEnabled = false;
                            }
                          });
                          _saveSettings();
                        },
                      ),
                      if (_notificationsEnabled) ...[
                        SwitchListTile(
                          title: const Text('Email Notifications'),
                          subtitle: const Text('Receive notifications via email'),
                          value: _emailNotificationsEnabled,
                          onChanged: (value) {
                            setState(() => _emailNotificationsEnabled = value);
                            _saveSettings();
                          },
                        ),
                        SwitchListTile(
                          title: const Text('SMS Notifications'),
                          subtitle: const Text('Receive notifications via SMS'),
                          value: _smsNotificationsEnabled,
                          onChanged: (value) {
                            setState(() => _smsNotificationsEnabled = value);
                            _saveSettings();
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Appearance Section
                  _SettingsSection(
                    title: 'Appearance',
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Switch between light and dark theme'),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Language'),
                        subtitle: Text(_selectedLanguage),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => SimpleDialog(
                              title: const Text('Select Language'),
                              children: [
                                'English',
                                'Swahili',
                                'French',
                              ].map((language) => SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, language),
                                child: Text(language),
                              )).toList(),
                            ),
                          );
                          if (result != null) {
                            setState(() => _selectedLanguage = result);
                            _saveSettings();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Security Section
                  _SettingsSection(
                    title: 'Security',
                    children: [
                      SwitchListTile(
                        title: const Text('Biometric Authentication'),
                        subtitle: const Text('Use fingerprint or face ID to login'),
                        value: _biometricEnabled,
                        onChanged: (value) async {
                          if (value) {
                            final canAuthenticate = await _localAuth.canCheckBiometrics;
                            if (!canAuthenticate) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Biometric authentication is not available'),
                                  ),
                                );
                              }
                              return;
                            }
                          }
                          setState(() => _biometricEnabled = value);
                          _saveSettings();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // About Section
                  _SettingsSection(
                    title: 'About',
                    children: [
                      const _SettingsTile(
                        icon: Icons.info,
                        title: 'App Version',
                        subtitle: '1.0.0',
                      ),
                      _SettingsTile(
                        icon: Icons.description,
                        title: 'Terms of Service',
                        onTap: () {
                          // Navigate to terms of service
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip,
                        title: 'Privacy Policy',
                        onTap: () {
                          // Navigate to privacy policy
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF90CAF9)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }
}