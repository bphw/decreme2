import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../models/models.dart';

class SettingsPreferenceScreen extends ConsumerWidget {
  const SettingsPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings Preference'),
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
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Store Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                'Store Name',
                settings['store_name'] ?? '',
                (value) => ref.read(settingsProvider.notifier)
                    .updateSetting('store_name', value),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                'Store Address',
                settings['store_address'] ?? '',
                (value) => ref.read(settingsProvider.notifier)
                    .updateSetting('store_address', value),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                'Store Contact',
                settings['store_contact'] ?? '',
                (value) => ref.read(settingsProvider.notifier)
                    .updateSetting('store_contact', value),
              ),
              const SizedBox(height: 32),
              const Text(
                'Invoice Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                'Bank Name',
                settings['invoice_bank'] ?? '',
                (value) => ref.read(settingsProvider.notifier)
                    .updateSetting('invoice_bank', value),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                'Bank Account Holder',
                settings['invoice_bank_account_holder'] ?? '',
                (value) => ref.read(settingsProvider.notifier)
                    .updateSetting('invoice_bank_account_holder', value),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                'Bank Account Number',
                settings['invoice_bank_account_number'] ?? '',
                (value) => ref.read(settingsProvider.notifier)
                    .updateSetting('invoice_bank_account_number', value),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                'Invoice Expiry Days',
                settings['invoice_due_date_in_days'] ?? '7',
                (value) => ref.read(settingsProvider.notifier)
                    .updateSetting('invoice_due_date_in_days', value),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    String initialValue,
    Function(String) onChanged, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
} 