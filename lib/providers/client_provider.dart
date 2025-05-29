import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

final clientsProvider = StateNotifierProvider<ClientNotifier, AsyncValue<List<Client>>>((ref) {
  return ClientNotifier();
});

class ClientNotifier extends StateNotifier<AsyncValue<List<Client>>> {
  ClientNotifier() : super(const AsyncValue.loading()) {
    loadClients();
  }

  Future<void> loadClients() async {
    try {
      state = const AsyncValue.loading();
      final response = await SupabaseConfig.client
          .from('clients')
          .select()
          .neq('name', 'Personal') // Filter out Personal client
          .order('name');
      
      final List<Client> clients = (response as List)
          .map((json) => Client.fromJson(json))
          .toList();

      print('Loaded ${clients.length} stores'); // Debug log
      state = AsyncValue.data(clients);
    } catch (error, stackTrace) {
      print('Error loading clients: $error'); // Debug log
      state = AsyncValue.error(error, stackTrace);
    }
  }
} 