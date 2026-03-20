// lib/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class CartItem {
  final String productId;
  final String size;
  final String color;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.size,
    required this.color,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        size: size,
        color: color,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toMap(String userId) => {
        'user_id': userId,
        'product_id': productId,
        'size': size,
        'color': color,
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        productId: map['product_id'] as String,
        size: map['size'] as String,
        color: map['color'] as String,
        quantity: map['quantity'] as int,
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

  // ── Add or merge item ─────────────────────────────────────────────────────
  Future<void> addItem(CartItem newItem) async {
    final idx = state.items.indexWhere((i) =>
        i.productId == newItem.productId &&
        i.size == newItem.size &&
        i.color == newItem.color);

    List<CartItem> updated = List.from(state.items);
    CartItem toUpsert;

    if (idx >= 0) {
      toUpsert =
          updated[idx].copyWith(quantity: updated[idx].quantity + newItem.quantity);
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

  // ── Update quantity of an existing item ────────────────────────────────────
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

  // ── Remove item ───────────────────────────────────────────────────────────
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

  // ── Clear entire cart ─────────────────────────────────────────────────────
  Future<void> clearCart() async {
    state = state.copyWith(items: []);
    if (_userId != null) {
      await _db.from('cart').delete().eq('user_id', _userId!);
    }
  }

  // ── Reload (call after login) ─────────────────────────────────────────────
  Future<void> reload() => _loadCart();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);