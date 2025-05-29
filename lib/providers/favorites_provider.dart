import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<int>>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<int>>> {
  FavoritesNotifier() : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final response = await SupabaseConfig.client
          .from('favorites')
          .select('cake_id')
          .eq('user_id', user.id);

      final favoriteIds = (response as List).map((item) => item['cake_id'] as int).toList();
      state = AsyncValue.data(favoriteIds);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleFavorite(int cakeId) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final currentState = state.value ?? [];
      final isFavorite = currentState.contains(cakeId);

      if (isFavorite) {
        await SupabaseConfig.client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('cake_id', cakeId);
        state = AsyncValue.data(currentState.where((id) => id != cakeId).toList());
      } else {
        await SupabaseConfig.client.from('favorites').insert({
          'user_id': user.id,
          'cake_id': cakeId,
        });
        state = AsyncValue.data([...currentState, cakeId]);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
} 