// lib/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class CartItem {
  final String productId;
  final String size;
  final String color;
  final int quantity;

  /// Per-unit price locked in at "Add to Cart" time.
  /// Already includes base price + selected accessories + bulk discount.
  /// Defaults to 0 for old Supabase rows that predate this column.
  final double unitPrice;

  const CartItem({
    required this.productId,
    required this.size,
    required this.color,
    required this.quantity,
    this.unitPrice = 0,
  });

  CartItem copyWith({int? quantity, double? unitPrice}) => CartItem(
        productId: productId,
        size: size,
        color: color,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
      );

  Map<String, dynamic> toMap(String userId) => {
        'user_id': userId,
        'product_id': productId,
        'size': size,
        'color': color,
        'quantity': quantity,
        'unit_price': unitPrice,
      };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        productId: map['product_id'] as String,
        size: map['size'] as String,
        color: map['color'] as String,
        quantity: map['quantity'] as int,
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

class CartState {
  final List<CartItem> items;
  final bool isLoading;

  const CartState({this.items = const [], this.isLoading = false});

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  CartState copyWith({List<CartItem>? items, bool? isLoading}) => CartState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState()) {
    _loadCart();
  }

  SupabaseClient get _db => Supabase.instance.client;
  String? get _userId => _db.auth.currentUser?.id;

  Future<void> _loadCart() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final rows = await _db.from('cart').select().eq('user_id', _userId!);
      final items = (rows as List)
          .map((r) => CartItem.fromMap(r as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addItem(CartItem newItem) async {
    final idx = state.items.indexWhere((i) =>
        i.productId == newItem.productId &&
        i.size == newItem.size &&
        i.color == newItem.color);

    List<CartItem> updated = List.from(state.items);
    CartItem toUpsert;

    if (idx >= 0) {
      toUpsert = updated[idx].copyWith(
        quantity: updated[idx].quantity + newItem.quantity,
        unitPrice: newItem.unitPrice,
      );
      updated[idx] = toUpsert;
    } else {
      toUpsert = newItem;
      updated.add(toUpsert);
    }

    state = state.copyWith(items: updated);
    if (_userId != null) {
      await _db.from('cart').upsert(
        toUpsert.toMap(_userId!),
        onConflict: 'user_id,product_id,size,color',
      );
    }
  }

  Future<void> updateQuantity(CartItem item, int newQty) async {
    if (newQty < 1) {
      await removeItem(item);
      return;
    }
    final updated = state.items.map((i) {
      if (i.productId == item.productId &&
          i.size == item.size &&
          i.color == item.color) {
        return i.copyWith(quantity: newQty);
      }
      return i;
    }).toList();

    state = state.copyWith(items: updated);
    if (_userId != null) {
      await _db
          .from('cart')
          .update({'quantity': newQty})
          .eq('user_id', _userId!)
          .eq('product_id', item.productId)
          .eq('size', item.size)
          .eq('color', item.color);
    }
  }

  Future<void> removeItem(CartItem item) async {
    state = state.copyWith(
      items: state.items
          .where((i) =>
              !(i.productId == item.productId &&
                  i.size == item.size &&
                  i.color == item.color))
          .toList(),
    );
    if (_userId != null) {
      await _db
          .from('cart')
          .delete()
          .eq('user_id', _userId!)
          .eq('product_id', item.productId)
          .eq('size', item.size)
          .eq('color', item.color);
    }
  }

  Future<void> clearCart() async {
    state = state.copyWith(items: []);
    if (_userId != null) {
      await _db.from('cart').delete().eq('user_id', _userId!);
    }
  }

  Future<void> reload() => _loadCart();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);