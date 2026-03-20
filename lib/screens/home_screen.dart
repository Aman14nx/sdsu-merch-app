// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/product_config_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/app_widgets.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0;

  static const _categories = ['All', 'Hoodies', 'T-Shirts', 'Pants'];

  // The three root pages (index 1 and 2 push onto nav stack)
  void _onTabTap(int index) {
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CartScreen()));
      return;
    }
    if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return;
    }
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final notifier = ref.read(catalogProvider.notifier);
    final products = catalog.filteredProducts;
    final cartCount = ref.watch(cartProvider).totalItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ── Header ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile row
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  border: Border.all(
                                      color: AppColors.primaryLight, width: 2),
                                ),
                                child: const Icon(Icons.school_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SDSU Merch Store',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      'Student merchandise ordering',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Cart icon with badge
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const CartScreen())),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                      child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: AppColors.textPrimary,
                                          size: 22),
                                    ),
                                    if (cartCount > 0)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text('$cartCount',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 9,
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Hero banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text('🎉 New arrivals',
                                            style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Spring\nCollection\n2025',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text('Shop now →',
                                            style: GoogleFonts.outfit(
                                                color:
                                                    const Color(0xFF7A5800),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.checkroom_rounded,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Search bar
                          TextFormField(
                            onChanged: notifier.setSearch,
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: AppColors.textLight),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.border, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Category chips
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final cat = _categories[i];
                                final isSelected =
                                    catalog.selectedCategory == cat;
                                return GestureDetector(
                                  onTap: () => notifier.setCategory(cat),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.surface,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section heading
                          SectionHeader(
                            title: products.isEmpty
                                ? 'No Results'
                                : 'All Products',
                            actionLabel:
                                products.isNotEmpty ? 'See all' : null,
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ── Product Grid ───────────────────────────────────────
                  products.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    size: 52, color: AppColors.textLight),
                                const SizedBox(height: 12),
                                Text('No products found',
                                    style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => ProductCard(
                                product: products[i],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                        product: products[i]),
                                  ),
                                ),
                              ),
                              childCount: products.length,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.68,
                            ),
                          ),
                        ),
                ],
              ),
            ),

            // ── Bottom Navigation Bar ────────────────────────────────────
            _BottomNavBar(
              selected: _selectedTab,
              cartCount: cartCount,
              onTap: _onTabTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final int selected;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.selected,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: selected == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Cart',
            isSelected: false, // always unselected since it pushes
            onTap: () => onTap(1),
            badgeCount: cartCount > 0 ? cartCount : null,
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            isSelected: false,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blueTint
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                if (badgeCount != null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}