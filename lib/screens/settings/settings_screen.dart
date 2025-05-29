import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import 'privacy_policy_screen.dart';

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
              subtitle: const Text('Enable 11% tax calculation'),
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
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
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