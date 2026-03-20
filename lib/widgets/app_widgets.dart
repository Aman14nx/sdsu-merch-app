// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─── Primary Button ───────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? AppColors.border
              : (backgroundColor ?? AppColors.primary),
          foregroundColor: onPressed == null
              ? AppColors.textLight
              : (textColor ?? Colors.white),
          elevation: 0,
          shape: const StadiumBorder(),
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textLight,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Rating Pill ──────────────────────────────────────────────────────────────

class RatingPill extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool compact;

  const RatingPill({
    super.key,
    required this.rating,
    this.reviewCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded,
              color: AppColors.secondary, size: compact ? 13 : 16),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.outfit(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF92760A),
            ),
          ),
          if (reviewCount != null && !compact) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Quantity Selector ────────────────────────────────────────────────────────

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyButton(icon: Icons.remove, onTap: quantity > 1 ? onDecrement : null),
        Container(
          width: 52,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blueTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$quantity',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        _QtyButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.border : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: onTap == null ? AppColors.textLight : Colors.white,
            size: 20),
      ),
    );
  }
}

// ─── Product Card (OVERFLOW FIXED) ───────────────────────────────────────────
// Root cause: Column had no height constraint so AspectRatio(1.0) image +
// unconstrained text info blew past the grid cell's fixed height.
// Fix: LayoutBuilder gives us the real cell height, image gets 58% of it,
// info gets Expanded to fill the rest. All text is maxLines + ellipsis.

class ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = constraints.maxHeight * 0.58;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed-height image — no AspectRatio, uses explicit height
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: Image.asset(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.blueTint,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.primary, size: 36),
                      ),
                    ),
                  ),
                ),

                // Info — Expanded fills exactly the remaining space, no overflow
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        Text(
                          product.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${product.basePrice.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            RatingPill(rating: product.rating, compact: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.border, thickness: 1, height: 1);
  }
}