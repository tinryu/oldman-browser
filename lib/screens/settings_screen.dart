import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // _buildSectionHeader('Account', context),
          // _buildSettingsItem(
          //   context,
          //   Icons.account_circle_outlined,
          //   'Account info',
          //   'Update your profile and security',
          //   () => _showSimpleDialog(
          //     context,
          //     'Account Info',
          //     'Manage your account security and profile settings.',
          //   ),
          // ),

          // const SizedBox(height: 24),
          // _buildSectionHeader('Privacy & Payments', context),
          // _buildSettingsItem(
          //   context,
          //   Icons.person_outline_rounded,
          //   'Personal info',
          //   'Manage your personal details and privacy preferences.',
          //   () => _showSimpleDialog(
          //     context,
          //     'Personal Info',
          //     'Manage your personal details and privacy preferences.',
          //   ),
          // ),
          // _buildSettingsItem(
          //   context,
          //   Icons.payment_rounded,
          //   'Payment',
          //   'Methods and subscription',
          //   () => _showSimpleDialog(
          //     context,
          //     'Payment',
          //     'Manage your payment methods and active subscriptions.',
          //   ),
          // ),
          const SizedBox(height: 24),
          _buildSectionHeader('User Interface', context),
          _buildSettingsItem(
            context,
            Icons.palette_outlined,
            'Appearance',
            'Dark mode, themes, and styles',
            () => _showAppearanceDialog(context),
          ),

          // _buildSettingsItem(
          //   context,
          //   Icons.add_box_outlined,
          //   'New tab',
          //   'Customize your new tab page experience.',
          //   () => _showSimpleDialog(
          //     context,
          //     'New Tab',
          //     'Customize your new tab page experience.',
          //   ),
          // ),
          // _buildSettingsItem(
          //   context,
          //   Icons.tab_unselected_rounded,
          //   'Tabs',
          //   'Grid layout and group settings',
          //   () => _showSimpleDialog(
          //     context,
          //     'Tabs',
          //     'Configure tab grid layout and group behavior.',
          //   ),
          // ),
          // _buildSettingsItem(
          //   context,
          //   Icons.accessibility_new_rounded,
          //   'Accessibility',
          //   'Text size and visual assistance features.',
          //   () => _showSimpleDialog(
          //     context,
          //     'Accessibility',
          //     'Adjust text size and visual assistance features.',
          //   ),
          // ),
          const SizedBox(height: 24),
          _buildSectionHeader('General', context),
          _buildSettingsItem(
            context,
            Icons.language_rounded,
            'Language',
            'Choose your preferred language',
            () => _showLanguageDialog(context),
          ),

          // _buildSettingsItem(
          //   context,
          //   Icons.settings_input_component_rounded,
          //   'Site setting',
          //   'Permissions and content controls',
          //   () => _showSimpleDialog(
          //     context,
          //     'Site Setting',
          //     'Manage site-specific permissions and content controls.',
          //   ),
          // ),
          const SizedBox(height: 24),
          _buildSectionHeader('About', context),
          // _buildSettingsItem(
          //   context,
          //   Icons.auto_awesome_outlined,
          //   "What's new",
          //   'Discover the latest features and updates.',
          //   () => _showSimpleDialog(
          //     context,
          //     "What's New",
          //     'Discover the latest features and updates.',
          //   ),
          // ),
          _buildSettingsItem(
            context,
            Icons.info_outline_rounded,
            'About browser',
            'Version info and legal',
            () => _showAboutDialog(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Function? onTap,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null ? () => onTap() : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.textTheme.titleLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade700,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Consumer<ThemeProvider>(
          builder: (context, provider, child) => AlertDialog(
            backgroundColor: theme.cardTheme.color,
            title: Text(
              'Appearance',
              style: TextStyle(color: theme.textTheme.titleLarge?.color),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Theme Mode'),
                  _buildThemeOption(
                    context,
                    'System Default',
                    Icons.brightness_auto,
                    provider.themeMode == ThemeMode.system,
                    () => provider.setThemeMode(ThemeMode.system),
                  ),
                  _buildThemeOption(
                    context,
                    'Light Mode',
                    Icons.light_mode_outlined,
                    provider.themeMode == ThemeMode.light,
                    () => provider.setThemeMode(ThemeMode.light),
                  ),
                  _buildThemeOption(
                    context,
                    'Dark Mode',
                    Icons.dark_mode_outlined,
                    provider.themeMode == ThemeMode.dark,
                    () => provider.setThemeMode(ThemeMode.dark),
                  ),
                  const Divider(height: 32),
                  _buildSectionLabel('Seed Color'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        [
                          Colors.amber,
                          Colors.blue,
                          Colors.red,
                          Colors.green,
                          Colors.purple,
                          Colors.orange,
                          Colors.pink,
                          Colors.tealAccent,
                        ].map((color) {
                          final isSelected =
                              provider.seedColor.value == color.value;
                          return GestureDetector(
                            onTap: () => provider.setSeedColor(color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.1,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: Text(
          'Language',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(context, 'English', true),
            _buildDialogOption(context, 'Spanish', false),
            _buildDialogOption(context, 'French', false),
            _buildDialogOption(context, 'Chinese', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showAboutDialog(
      context: context,
      applicationName: 'PlayerM3U8',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.webhook_outlined,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      children: [
        const Text('A powerful M3U8 browser and video capturing tool.'),
      ],
    );
  }

  // void _showSimpleDialog(BuildContext context, String title, String message) {
  //   final theme = Theme.of(context);
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: theme.cardTheme.color,
  //       title: Text(
  //         title,
  //         style: TextStyle(color: theme.textTheme.titleLarge?.color),
  //       ),
  //       content: Text(
  //         message,
  //         style: TextStyle(color: theme.textTheme.bodyLarge?.color),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text(
  //             'OK',
  //             style: TextStyle(color: theme.colorScheme.primary),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDialogOption(
    BuildContext context,
    String title,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: () => Navigator.pop(context),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
