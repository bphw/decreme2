import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../config/app_version.dart';
import 'settings_preference_screen.dart';
import 'privacy_policy_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading settings: $error',
                style: const TextStyle(color: Colors.red),
              ),
              TextButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).loadSettings();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Use Tax'),
              subtitle: const Text('Enable 10% tax calculation'),
              trailing: Switch(
                value: settings['is_use_tax'] == 'true',
                onChanged: (value) {
                  ref.read(settingsProvider.notifier)
                    .updateSetting('is_use_tax', value.toString());
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Fingerprint Authentication'),
              subtitle: const Text('Use fingerprint for login'),
              trailing: Switch(
                value: settings['is_activate_fingerprint'] == 'true',
                onChanged: (value) {
                  ref.read(settingsProvider.notifier)
                    .updateSetting('is_activate_fingerprint', value.toString());
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Demo Mode'),
              subtitle: const Text('Enable demo mode features'),
              trailing: Switch(
                value: settings['is_demo_mode'] == 'true',
                onChanged: (value) {
                  ref.read(settingsProvider.notifier)
                    .updateSetting('is_demo_mode', value.toString());
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings Preference'),
              subtitle: const Text('Manage store and invoice settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPreferenceScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const PrivacyPolicyBottomSheet(),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Version'),
              subtitle: Text(
                AppVersion.version,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              enabled: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Decreme'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bams © 2025'),
                        const SizedBox(height: 16),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 