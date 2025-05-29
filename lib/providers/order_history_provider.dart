import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

final orderHistoryProvider = StateNotifierProvider<OrderHistoryNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderHistoryNotifier();
});

class OrderHistoryNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  OrderHistoryNotifier() : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      final orders = (response as List)
          .map((json) => Order.fromJson(json))
          .toList();

      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    try {
      await SupabaseConfig.client
          .from('orders')
          .update({'status': newStatus.name})
          .eq('id', orderId);

      // Reload orders to get updated data
      await loadOrders();
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }
} 