import 'package:decimal/decimal.dart';

class Cake {
  final int id;
  final DateTime createdAt;
  final String name;
  final String cakeTypes;
  final Decimal price;
  final String variant;
  final String? images;
  final bool? isAvailable;

  Cake({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.cakeTypes,
    required this.price,
    required this.variant,
    this.images,
    this.isAvailable,
  });

  factory Cake.fromJson(Map<String, dynamic> json) {
    return Cake(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'],
      cakeTypes: json['cake_types'],
      price: Decimal.parse(json['price'].toString()),
      variant: json['variant'],
      images: json['images'],
      isAvailable: json['available'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'name': name,
    'cake_types': cakeTypes,
    'price': price.toString(),
    'variant': variant,
    'images': images,
    'available': isAvailable,
  };
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  completed,
  cancelled,
  paid,
}

class Order {
  final int id;
  final DateTime createdAt;
  final String? createdBy;
  final String orderNumber;
  final Decimal deliveryFee;
  final Decimal ppn;
  final OrderStatus status;
  final int clientId;
  final Decimal totalAmount;
  final String? buyerName;
  final String? buyerPhone;
  final String? notes;

  Order({
    required this.id,
    required this.createdAt,
    this.createdBy,
    required this.orderNumber,
    required this.deliveryFee,
    required this.ppn,
    required this.status,
    required this.clientId,
    required this.totalAmount,
    this.buyerName,
    this.buyerPhone,
    this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
      orderNumber: json['order_number'],
      deliveryFee: Decimal.parse(json['delivery_fee'].toString()),
      ppn: Decimal.parse(json['ppn'].toString()),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      clientId: json['client_id'],
      totalAmount: Decimal.parse(json['total_amount'].toString()),
      buyerName: json['buyer_name'],
      buyerPhone: json['buyer_phone'],
      notes: json['notes'],
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int cakeId;
  final int quantity;
  final Decimal price;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.cakeId,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      cakeId: json['cake_id'],
      quantity: json['quantity'],
      price: Decimal.parse(json['price'].toString()),
    );
  }
}

class Client {
  final int id;
  final DateTime createdAt;
  final String name;
  final String contact;
  final String phone;
  final String email;
  final String address;
  final String city;
  final Decimal? deliveryFee;
  final String location;
  final String? logo;
  final String? type;

  Client({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.contact,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    this.deliveryFee,
    required this.location,
    this.logo,
    this.type,
  });

  bool get isPersonal => type == 'personal';

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'],
      contact: json['contact'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      deliveryFee: json['delivery_fee'] != null 
          ? Decimal.parse(json['delivery_fee'].toString())
          : null,
      location: json['location'],
      logo: json['logo'],
      type: json['type'],
    );
  }
}

class CartItem {
  final Cake cake;
  final int quantity;

  const CartItem({
    required this.cake,
    required this.quantity,
  });

  Decimal get total => cake.price * Decimal.fromInt(quantity);

  CartItem copyWith({
    Cake? cake,
    int? quantity,
  }) {
    return CartItem(
      cake: cake ?? this.cake,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Setting {
  final int id;
  final String name;
  final String settingValue;

  const Setting({
    required this.id,
    required this.name,
    required this.settingValue,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      id: json['id'],
      name: json['name'],
      settingValue: json['setting_value'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'setting_value': settingValue,
  };
}

class Store {
  final String? id;
  final String name;
  final String address;
  final String phone;
  final String? logo;
  final DateTime createdAt;

  Store({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.logo,
    required this.createdAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      logo: json['logo'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'logo': logo,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 