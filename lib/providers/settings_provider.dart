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
              // Convert null or non-string values to boolean strings
              if (value == null) {
                settings[name] = 'false';
              } else {
                // Convert any non-null value to string and check if it's 'true'
                final stringValue = value.toString().toLowerCase();
                settings[name] = (stringValue == 'true') ? 'true' : 'false';
              }
            }
          }

          state = AsyncValue.data(settings);
        } else {
          // If response is null or not a List, use default settings
          state = AsyncValue.data(defaultSettings);
        }
      } catch (e) {
        print('Error parsing settings: $e');
        // If there's an error parsing, use default settings
        state = AsyncValue.data(defaultSettings);
      }
    } catch (error, stackTrace) {
      print('Error loading settings: $error');
      // On error, still provide default settings instead of error state
      state = AsyncValue.data({
        'is_activate_fingerprint': 'false',
        'is_use_tax': 'false',
      });
    }
  }

  Future<void> updateSetting(String name, String value) async {
    try {
      // Get current settings
      final currentSettings = state.value ?? {
        'is_activate_fingerprint': 'false',
        'is_use_tax': 'false',
      };
      
      // Convert value to boolean string
      final boolValue = value.toLowerCase() == 'true' ? 'true' : 'false';
      
      // Optimistically update the UI
      state = AsyncValue.data({...currentSettings, name: boolValue});

      // Update in database
      await SupabaseConfig.client
          .from('settings')
          .upsert({
            'name': name,
            'setting_value': boolValue,
          })
          .eq('name', name);
      
    } catch (error) {
      print('Error updating setting: $error');
      // Revert to previous state on error
      loadSettings();
      rethrow;
    }
  }

  String getSetting(String name) {
    final settings = state.value;
    return settings?[name] ?? 'false';
  }

  bool getBoolSetting(String name) {
    return getSetting(name).toLowerCase() == 'true';
  }
} 