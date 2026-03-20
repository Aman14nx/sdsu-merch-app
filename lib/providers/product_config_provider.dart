// lib/providers/product_config_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class ProductConfigState {
  final String? selectedSize;
  final String? selectedColor;
  final Set<String> selectedAccessoryIds;
  final int quantity;
  final double basePrice;

  const ProductConfigState({
    this.selectedSize,
    this.selectedColor,
    this.selectedAccessoryIds = const {},
    this.quantity = 1,
    this.basePrice = 54.99,
  });

  bool get isReadyToAdd => selectedSize != null && selectedColor != null;

  double get discountRate {
    if (quantity >= 10) return 0.20;
    if (quantity >= 5) return 0.10;
    return 0.0;
  }

  double get accessoriesTotal {
    return sampleAccessories
        .where((a) => selectedAccessoryIds.contains(a.id))
        .fold(0.0, (sum, a) => sum + a.price);
  }

  double get unitPrice => basePrice * (1 - discountRate);

  double get totalPrice => (unitPrice * quantity) + accessoriesTotal;

  String get discountLabel {
    if (discountRate == 0.20) return '20% bulk discount applied';
    if (discountRate == 0.10) return '10% bulk discount applied';
    return '';
  }

  ProductConfigState copyWith({
    String? selectedSize,
    bool clearSize = false,
    String? selectedColor,
    bool clearColor = false,
    Set<String>? selectedAccessoryIds,
    int? quantity,
    double? basePrice,
  }) {
    return ProductConfigState(
      selectedSize: clearSize ? null : (selectedSize ?? this.selectedSize),
      selectedColor: clearColor ? null : (selectedColor ?? this.selectedColor),
      selectedAccessoryIds: selectedAccessoryIds ?? this.selectedAccessoryIds,
      quantity: quantity ?? this.quantity,
      basePrice: basePrice ?? this.basePrice,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ProductConfigNotifier extends StateNotifier<ProductConfigState> {
  ProductConfigNotifier(double basePrice)
      : super(ProductConfigState(basePrice: basePrice));

  void selectSize(String size) {
    state = state.copyWith(selectedSize: size);
  }

  void selectColor(String color) {
    state = state.copyWith(selectedColor: color);
  }

  void toggleAccessory(String id) {
    final updated = Set<String>.from(state.selectedAccessoryIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(selectedAccessoryIds: updated);
  }

  void increment() {
    state = state.copyWith(quantity: state.quantity + 1);
  }

  void decrement() {
    if (state.quantity > 1) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }

  void reset(double basePrice) {
    state = ProductConfigState(basePrice: basePrice);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final productConfigProvider =
    StateNotifierProvider.family<ProductConfigNotifier, ProductConfigState, double>(
  (ref, basePrice) => ProductConfigNotifier(basePrice),
);

// ─── Catalog Filter State ──────────────────────────────────────────────────────

class CatalogState {
  final String selectedCategory;
  final String searchQuery;

  const CatalogState({
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  List<Product> get filteredProducts {
    return sampleProducts.where((p) {
      final matchCategory =
          selectedCategory == 'All' || p.category == selectedCategory;
      final matchSearch = searchQuery.isEmpty ||
          p.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  CatalogState copyWith({String? selectedCategory, String? searchQuery}) {
    return CatalogState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  CatalogNotifier() : super(const CatalogState());

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final catalogProvider =
    StateNotifierProvider<CatalogNotifier, CatalogState>(
  (ref) => CatalogNotifier(),
);