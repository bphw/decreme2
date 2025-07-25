import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<Map<String, String>>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AsyncValue<Map<String, String>>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      
      // Default settings
      final Map<String, String> defaultSettings = {
        'is_activate_fingerprint': 'false',
        'is_use_tax': 'false',
        'is_demo_mode': 'false',
        'store_name': '',
        'store_address': '',
        'store_contact': '',
        'invoice_bank': '',
        'invoice_bank_account_holder': '',
        'invoice_bank_account_number': '',
        'invoice_due_date_in_days': '7',
      };

      try {
        final response = await SupabaseConfig.client
            .from('settings')
            .select()
            .order('name');

        if (response != null && response is List) {
          final settings = Map<String, String>.from(defaultSettings);
          
          for (final item in response) {
            final name = item['name'] as String?;
            final value = item['setting_value'];

            if (name != null) {
              // Handle boolean settings
              if (name.startsWith('is_')) {
                if (value == null) {
                  settings[name] = 'false';
                } else {
                  final stringValue = value.toString().toLowerCase();
                  settings[name] = (stringValue == 'true') ? 'true' : 'false';
                }
              } else {
                // Handle text settings
                settings[name] = value?.toString() ?? '';
              }
            }
          }

          state = AsyncValue.data(settings);
        } else {
          state = AsyncValue.data(defaultSettings);
        }
      } catch (e) {
        print('Error parsing settings: $e');
        state = AsyncValue.data(defaultSettings);
      }
    } catch (error, stackTrace) {
      print('Error loading settings: $error');
      state = AsyncValue.data({
        'is_activate_fingerprint': 'false',
        'is_use_tax': 'false',
        'is_demo_mode': 'false',
        'store_name': '',
        'store_address': '',
        'store_contact': '',
        'invoice_bank': '',
        'invoice_bank_account_holder': '',
        'invoice_bank_account_number': '',
        'invoice_due_date_in_days': '7',
      });
    }
  }

  Future<void> updateSetting(String name, String value) async {
    try {
      // Only allow updating boolean settings
      if (!name.startsWith('is_')) {
        throw Exception('updateSetting can only be used for boolean settings');
      }

      // Get current settings
      final currentSettings = state.value ?? {
        'is_activate_fingerprint': 'false',
        'is_use_tax': 'false',
        'is_demo_mode': 'false',
        'store_name': '',
        'store_address': '',
        'store_contact': '',
        'invoice_bank': '',
        'invoice_bank_account_holder': '',
        'invoice_bank_account_number': '',
        'invoice_due_date_in_days': '7',
      };
      
      // Convert to boolean string
      final stringValue = value.toLowerCase() == 'true' ? 'true' : 'false';
      
      // Optimistically update the UI
      state = AsyncValue.data({...currentSettings, name: stringValue});

      // Update in database
      await SupabaseConfig.client
          .from('settings')
          .update({
            'setting_value': stringValue,
          })
          .eq('name', name);
      
    } catch (error) {
      print('Error updating setting: $error');
      // Revert to previous state on error
      loadSettings();
      rethrow;
    }
  }

  Future<void> updateSettingPreference(String name, String value) async {
    try {
      // Only allow updating store and invoice settings
      if (!name.startsWith('store_') && !name.startsWith('invoice_')) {
        throw Exception('updateSettingPreference can only be used for store and invoice settings');
      }

      // Get current settings
      final currentSettings = state.value ?? {
        'is_activate_fingerprint': 'false',
        'is_use_tax': 'false',
        'is_demo_mode': 'false',
        'store_name': '',
        'store_address': '',
        'store_contact': '',
        'invoice_bank': '',
        'invoice_bank_account_holder': '',
        'invoice_bank_account_number': '',
        'invoice_due_date_in_days': '7',
      };
      
      // Optimistically update the UI
      state = AsyncValue.data({...currentSettings, name: value});

      // Update in database
      final response = await SupabaseConfig.client
          .from('settings')
          .update({
            'setting_value': value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('name', name)
          .select();

      if (response == null || response.isEmpty) {
        // If no record exists, insert it
        await SupabaseConfig.client
            .from('settings')
            .insert({
              'name': name,
              'setting_value': value,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
      
    } catch (error) {
      print('Error updating setting preference: $error');
      // Revert to previous state on error
      loadSettings();
      rethrow;
    }
  }

  String getSetting(String name) {
    final settings = state.value;
    return settings?[name] ?? '';
  }

  bool getBoolSetting(String name) {
    return getSetting(name).toLowerCase() == 'true';
  }
} 