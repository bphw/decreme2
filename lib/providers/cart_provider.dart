import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'settings_provider.dart';

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

class CartState {
  final List<CartItem> items;
  final Decimal deliveryFee;
  final bool isUseTax;

  CartState({
    List<CartItem>? items,
    Decimal? deliveryFee,
    this.isUseTax = false,
  }) : 
    items = items ?? const [],
    deliveryFee = deliveryFee ?? Decimal.parse('0');

  Decimal get subtotal => items.fold(
        Decimal.parse('0'),
        (sum, item) => sum + item.total,
      );

  Decimal get tax => isUseTax ? subtotal * Decimal.parse('0.10') : Decimal.parse('0');
  
  Decimal get total => subtotal + tax + deliveryFee;

  String get formattedSubtotal => formatPrice(subtotal);
  String get formattedTax => formatPrice(tax);
  String get formattedDeliveryFee => formatPrice(deliveryFee);
  String get formattedTotal => formatPrice(total);

  static String formatPrice(Decimal price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price.toDouble());
  }

  CartState copyWith({
    List<CartItem>? items,
    Decimal? deliveryFee,
    bool? isUseTax,
  }) {
    return CartState(
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isUseTax: isUseTax ?? this.isUseTax,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;

  CartNotifier(this.ref) : super(CartState()) {
    _initializeTaxSetting();
  }

  void _initializeTaxSetting() {
    ref.listen(settingsProvider, (previous, next) {
      next.whenData((settings) {
        final isUseTax = settings['is_use_tax'] == 'true';
        state = state.copyWith(isUseTax: isUseTax);
      });
    });
  }

  void setDeliveryFee(String fee) {
    try {
      final newFee = Decimal.parse(fee.replaceAll(',', ''));
      state = state.copyWith(deliveryFee: newFee);
    } catch (e) {
      print('Error parsing delivery fee: $e');
    }
  }

  void addItem(Cake cake, int quantity) {
    final existingIndex = state.items.indexWhere((item) => item.cake.id == cake.id);
    
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = CartItem(
        cake: cake,
        quantity: state.items[existingIndex].quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(cake: cake, quantity: quantity)],
      );
    }
  }

  void removeItem(int cakeId) {
    state = state.copyWith(
      items: state.items.where((item) => item.cake.id != cakeId).toList(),
    );
  }

  void updateQuantity(int cakeId, int quantity) {
    if (quantity <= 0) {
      removeItem(cakeId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.cake.id == cakeId) {
        return CartItem(cake: item.cake, quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void clear() {
    state = CartState();
  }
} 