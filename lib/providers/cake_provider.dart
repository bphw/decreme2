import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

final cakesProvider = StateNotifierProvider<CakeNotifier, AsyncValue<List<Cake>>>((ref) {
  return CakeNotifier();
});

class CakeNotifier extends StateNotifier<AsyncValue<List<Cake>>> {
  CakeNotifier() : super(const AsyncValue.loading()) {
    loadCakes();
  }

  final _supabase = Supabase.instance.client;

  Future<void> loadCakes() async {
    try {
      state = const AsyncValue.loading();
      final response = await _supabase
          .from('cakes')
          .select()
          .order('created_at', ascending: false);
      
      final cakes = (response as List).map((json) => Cake.fromJson(json as Map<String, dynamic>)).toList();
      state = AsyncValue.data(cakes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCake(Cake cake) async {
    try {
      final response = await _supabase.from('cakes').insert({
        'name': cake.name,
        'price': cake.price.toString(),
        'images': cake.images,
        'cake_types': cake.cakeTypes,
        'variant': cake.variant,
        'available': cake.isAvailable,
      }).select();
      
      final newCake = Cake.fromJson(response[0] as Map<String, dynamic>);
      state.whenData((cakes) {
        state = AsyncValue.data([newCake, ...cakes]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateCake(Cake cake) async {
    try {
      final response = await _supabase
          .from('cakes')
          .update({
            'name': cake.name,
            'price': cake.price.toString(),
            'images': cake.images,
            'cake_types': cake.cakeTypes,
            'variant': cake.variant,
            'available': cake.isAvailable,
          })
          .eq('id', cake.id)
          .select();
      
      final updatedCake = Cake.fromJson(response[0] as Map<String, dynamic>);
      state.whenData((cakes) {
        state = AsyncValue.data(
          cakes.map((c) => c.id == updatedCake.id ? updatedCake : c).toList(),
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteCake(int id) async {
    try {
      await _supabase.from('cakes').delete().eq('id', id);
      state.whenData((cakes) {
        state = AsyncValue.data(cakes.where((c) => c.id != id).toList());
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Optional: Add a provider for single cake if needed
final cakeProvider = FutureProvider.family<Cake?, int>((ref, id) async {
  try {
    final response = await Supabase.instance.client
        .from('cakes')
        .select()
        .eq('id', id)
        .single();

    if (response == null) {
      return null;
    }

    return Cake.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    print('Error fetching cake: $e');
    throw e;
  }
}); 