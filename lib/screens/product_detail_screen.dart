// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/product_config_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  static const _sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
  static const _colors = [
    _ColorOption('Blue', Color(0xFF0D52FF)),
    _ColorOption('Yellow', Color(0xFFFFD700)),
    _ColorOption('Gray', Color(0xFF9CA3AF)),
    _ColorOption('Black', Color(0xFF1A1A2E)),
    _ColorOption('White', Color(0xFFE5E7EB)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(productConfigProvider(product.basePrice));
    final notifier = ref.read(productConfigProvider(product.basePrice).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── Hero image AppBar — NO heart icon ──────────────────────
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                // actions removed — heart icon gone
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.blueTint,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.primary, size: 60),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.6, 1.0],
                            colors: [Colors.transparent, AppColors.background],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.blueTint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Title & price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${product.basePrice.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'base price',
                                style: GoogleFonts.outfit(
                                    fontSize: 11, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Rating
                      Row(
                        children: [
                          RatingPill(
                              rating: product.rating,
                              reviewCount: product.reviewCount),
                          const SizedBox(width: 10),
                          Text(
                            '${product.reviewCount} reviews',
                            style: GoogleFonts.outfit(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        product.description,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.65),
                      ),

                      const SizedBox(height: 28),
                      const _Divider(),

                      // ── Size Selection ────────────────────────────────
                      const SizedBox(height: 20),
                      _SectionTitle(
                        'Select Size',
                        required: true,
                        isComplete: config.selectedSize != null,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _sizes.map((size) {
                          final isSelected = config.selectedSize == size;
                          return GestureDetector(
                            onTap: () => notifier.selectSize(size),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                size,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),
                      const _Divider(),

                      // ── Color Selection ───────────────────────────────
                      const SizedBox(height: 20),
                      _SectionTitle(
                        'Select Color',
                        required: true,
                        isComplete: config.selectedColor != null,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _colors.map((c) {
                          final isSelected = config.selectedColor == c.name;
                          return GestureDetector(
                            onTap: () => notifier.selectColor(c.name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? c.color.withOpacity(0.1)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? c.color : AppColors.border,
                                  width: isSelected ? 2 : 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: c.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.black.withOpacity(0.1)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? c.color
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.check_circle_rounded,
                                        color: c.color, size: 16),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),
                      const _Divider(),

                      // ── Optional Accessories ──────────────────────────
                      const SizedBox(height: 20),
                      const _SectionTitle('Add Accessories', required: false),
                      const SizedBox(height: 4),
                      Text(
                        'Optional — enhance your order',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      ...sampleAccessories.map((acc) {
                        final isSelected =
                            config.selectedAccessoryIds.contains(acc.id);
                        return GestureDetector(
                          onTap: () => notifier.toggleAccessory(acc.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.blueTint
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '+\$${acc.price.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 24),
                      const _Divider(),

                      // ── Quantity Selector ─────────────────────────────
                      const SizedBox(height: 20),
                      const _SectionTitle('Quantity', required: false),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          QuantitySelector(
                            quantity: config.quantity,
                            onIncrement: notifier.increment,
                            onDecrement: notifier.decrement,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DiscountHint(
                                  label: '5+ units: 10% off per unit',
                                  isActive: config.quantity >= 5,
                                ),
                                const SizedBox(height: 4),
                                _DiscountHint(
                                  label: '10+ units: 20% off per unit',
                                  isActive: config.quantity >= 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (config.discountLabel.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer_outlined,
                                  color: AppColors.success, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                config.discountLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      const _Divider(),

                      // ── Config Review Card ────────────────────────────
                      const SizedBox(height: 20),
                      _ConfigReviewCard(config: config, product: product),

                      // Spacer for bottom dock
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed Bottom Action Dock ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomActionDock(config: config, product: product),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting types ─────────────────────────────────────────────────────────

class _ColorOption {
  final String name;
  final Color color;
  const _ColorOption(this.name, this.color);
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool required;
  final bool isComplete;

  const _SectionTitle(this.title,
      {required this.required, this.isComplete = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        if (required) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isComplete
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isComplete ? '✓ Selected' : 'Required',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? AppColors.success : AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Discount Hint ────────────────────────────────────────────────────────────

class _DiscountHint extends StatelessWidget {
  final String label;
  final bool isActive;
  const _DiscountHint({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: isActive ? AppColors.success : AppColors.textLight,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isActive ? AppColors.success : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Divider ─────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.border, thickness: 1, height: 1);
}

// ─── Configuration Review Card ────────────────────────────────────────────────

class _ConfigReviewCard extends StatelessWidget {
  final ProductConfigState config;
  final Product product;
  const _ConfigReviewCard({required this.config, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blueTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Order Summary',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(
              color: AppColors.primary, height: 1, thickness: 0.3),
          const SizedBox(height: 16),
          _ReviewRow('Size', config.selectedSize ?? 'Not selected',
              isSelected: config.selectedSize != null),
          _ReviewRow('Color', config.selectedColor ?? 'Not selected',
              isSelected: config.selectedColor != null),
          _ReviewRow(
            'Accessories',
            config.selectedAccessoryIds.isEmpty
                ? 'None'
                : sampleAccessories
                    .where((a) =>
                        config.selectedAccessoryIds.contains(a.id))
                    .map((a) => a.name)
                    .join(', '),
            isSelected: config.selectedAccessoryIds.isNotEmpty,
          ),
          _ReviewRow(
              'Quantity',
              '${config.quantity} unit${config.quantity > 1 ? 's' : ''}',
              isSelected: true),
          if (config.discountRate > 0)
            _ReviewRow(
              'Bulk Discount',
              '-${(config.discountRate * 100).toStringAsFixed(0)}%',
              isSelected: true,
              valueColor: AppColors.success,
            ),
          const SizedBox(height: 8),
          const Divider(
              color: AppColors.primary, height: 1, thickness: 0.3),
          const SizedBox(height: 12),
          _ReviewRow(
              'Base Price',
              '\$${product.basePrice.toStringAsFixed(2)} × ${config.quantity}',
              isSelected: true),
          if (config.accessoriesTotal > 0)
            _ReviewRow('Accessories',
                '+\$${config.accessoriesTotal.toStringAsFixed(2)}',
                isSelected: true),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Text('\$${config.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final Color? valueColor;

  const _ReviewRow(this.label, this.value,
      {required this.isSelected, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      (isSelected
                          ? AppColors.textPrimary
                          : AppColors.error.withOpacity(0.7)))),
        ],
      ),
    );
  }
}

// ─── Bottom Action Dock ───────────────────────────────────────────────────────
// FIX: actually adds item to cartProvider, snackbar at TOP, then pops back

class _BottomActionDock extends ConsumerWidget {
  final ProductConfigState config;
  final Product product;

  const _BottomActionDock({required this.config, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = config.isReadyToAdd;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -6)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isReady) ...[
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.textLight),
                const SizedBox(width: 6),
                Text(
                  _getMissingMessage(config),
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              // Total price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text('\$${config.totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isReady
                        ? () async {
                            // 1. Add to cart with the full unit price
                            //    (base × discount + accessories ÷ quantity)
                            //    config.totalPrice already equals
                            //    unitPrice*qty + accessoriesTotal, so we
                            //    store config.unitPrice as the per-unit price.
                            await ref.read(cartProvider.notifier).addItem(
                                  CartItem(
                                    productId: product.id,
                                    size: config.selectedSize!,
                                    color: config.selectedColor!,
                                    quantity: config.quantity,
                                    unitPrice: config.unitPrice +
                                        (config.accessoriesTotal /
                                            config.quantity),
                                  ),
                                );

                            if (!context.mounted) return;

                            // 2. Pop back to the previous screen immediately,
                            //    then show the snackbar there so it persists.
                            Navigator.pop(context);

                            // Small yield to let the route finish popping
                            // before we grab its ScaffoldMessenger.
                            await Future.delayed(
                                const Duration(milliseconds: 100));
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${product.title} added to cart!',
                                        style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isReady ? AppColors.primary : AppColors.border,
                      foregroundColor:
                          isReady ? Colors.white : AppColors.textLight,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      disabledBackgroundColor: AppColors.border,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isReady
                              ? Icons.shopping_bag_rounded
                              : Icons.touch_app_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isReady
                              ? 'Add to Cart'
                              : 'Select Size & Color',
                          style: GoogleFonts.outfit(
                            fontSize: isReady ? 16 : 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMissingMessage(ProductConfigState config) {
    if (config.selectedSize == null && config.selectedColor == null) {
      return 'Please select a size and color';
    } else if (config.selectedSize == null) {
      return 'Please select a size to continue';
    } else {
      return 'Please select a color to continue';
    }
  }
}