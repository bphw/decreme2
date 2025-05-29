import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../config/supabase_config.dart';

final storeProvider = StateNotifierProvider<StoreNotifier, AsyncValue<List<Store>>>((ref) {
  return StoreNotifier();
});

class StoreNotifier extends StateNotifier<AsyncValue<List<Store>>> {
  StoreNotifier() : super(const AsyncValue.loading()) {
    loadStores();
  }

  Future<void> loadStores() async {
    try {
      final response = await SupabaseConfig.client
          .from('stores')
          .select()
          .order('name');
      
      final stores = response.map((json) => Store.fromJson(json)).toList();
      state = AsyncValue.data(stores);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addStore(Store store) async {
    try {
      final response = await SupabaseConfig.client
          .from('stores')
          .insert(store.toJson())
          .select()
          .single();
      
      final newStore = Store.fromJson(response);
      state.whenData((stores) {
        state = AsyncValue.data([...stores, newStore]);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStore(Store store) async {
    try {
      final response = await SupabaseConfig.client
          .from('stores')
          .update(store.toJson())
          .eq('id', store.id)
          .select()
          .single();
      
      final updatedStore = Store.fromJson(response);
      state.whenData((stores) {
        state = AsyncValue.data(
          stores.map((s) => s.id == store.id ? updatedStore : s).toList(),
        );
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStore(String id) async {
    try {
      await SupabaseConfig.client
          .from('stores')
          .delete()
          .eq('id', id);
      
      state.whenData((stores) {
        state = AsyncValue.data(
          stores.where((store) => store.id != id).toList(),
        );
      });
    } catch (e) {
      rethrow;
    }
  }
} 