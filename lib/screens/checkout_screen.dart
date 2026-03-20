// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;
  final double subtotal;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _zipCtrl     = TextEditingController();

  int  _step      = 0; // 0 = contact info, 1 = review
  bool _isPlacing = false;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  double get _tax   => widget.subtotal * 0.075;
  double get _total => widget.subtotal + _tax;

  Product _getProduct(String id) => sampleProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => sampleProducts.first,
      );

  void _nextStep() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _step = 1);
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    try {
      final uid = _db.auth.currentUser?.id;

      // Build line-items JSON
      final items = widget.cartItems.map((ci) {
        final p = _getProduct(ci.productId);
        return {
          'product_id' : ci.productId,
          'title'      : p.title,
          'size'       : ci.size,
          'color'      : ci.color,
          'quantity'   : ci.quantity,
          'unit_price' : p.basePrice,
        };
      }).toList();

      // Insert into orders table
      if (uid != null) {
        await _db.from('orders').insert({
          'user_id'  : uid,
          'full_name': _nameCtrl.text.trim(),
          'email'    : _emailCtrl.text.trim(),
          'phone'    : _phoneCtrl.text.trim(),
          'address'  : _addressCtrl.text.trim(),
          'city'     : _cityCtrl.text.trim(),
          'zip'      : _zipCtrl.text.trim(),
          'subtotal' : widget.subtotal,
          'tax'      : _tax,
          'total'    : _total,
          'status'   : 'Confirmed',
          'items'    : items,
        });
      }

      // Clear cart
      await ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;
      setState(() => _isPlacing = false);
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order failed: $e',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration:
                  const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 52),
            ),
            const SizedBox(height: 20),
            Text('Order Placed!',
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Your SDSU merch order has been confirmed.\nConfirmation sent to ${_emailCtrl.text}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.popUntil(context, (r) => r.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Back to Home',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _step == 0 ? 'Contact Info' : 'Review Order',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            Text('Step ${_step + 1} of 2',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          _StepProgress(step: _step),
          Expanded(
            child: _step == 0
                ? _ContactInfoStep(
                    formKey: _formKey,
                    nameCtrl: _nameCtrl,
                    emailCtrl: _emailCtrl,
                    phoneCtrl: _phoneCtrl,
                    addressCtrl: _addressCtrl,
                    cityCtrl: _cityCtrl,
                    zipCtrl: _zipCtrl,
                  )
                : _OrderReviewStep(
                    cartItems: widget.cartItems,
                    subtotal: widget.subtotal,
                    tax: _tax,
                    total: _total,
                    name: _nameCtrl.text,
                    email: _emailCtrl.text,
                    phone: _phoneCtrl.text,
                    address: _addressCtrl.text,
                    city: _cityCtrl.text,
                    zip: _zipCtrl.text,
                    getProduct: _getProduct,
                  ),
          ),

          // ── Bottom CTA ─────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed:
                    _isPlacing ? null : (_step == 0 ? _nextStep : _placeOrder),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  disabledBackgroundColor: AppColors.border,
                ),
                child: _isPlacing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _step == 0
                                ? Icons.arrow_forward_rounded
                                : Icons.check_circle_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _step == 0
                                ? 'Continue to Review'
                                : 'Confirm & Place Order',
                            style: GoogleFonts.outfit(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Progress ────────────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  final int step;
  const _StepProgress({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _StepDot(label: '1', title: 'Contact', active: step == 0, done: step > 0),
          Expanded(
            child: Container(
                height: 2,
                color: step > 0 ? AppColors.primary : AppColors.border),
          ),
          _StepDot(label: '2', title: 'Review', active: step == 1, done: false),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final String title;
  final bool active;
  final bool done;
  const _StepDot(
      {required this.label,
      required this.title,
      required this.active,
      required this.done});

  @override
  Widget build(BuildContext context) {
    final colored = active || done;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: colored ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: colored ? AppColors.primary : AppColors.border,
                  width: 2)),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textLight)),
          ),
        ),
        const SizedBox(height: 4),
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Step 1: Contact Info ─────────────────────────────────────────────────────

class _ContactInfoStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl,
      addressCtrl, cityCtrl, zipCtrl;

  const _ContactInfoStep({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.zipCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blueTint,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your contact info is saved for faster checkout next time.',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: AppColors.primary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Heading('Personal Details'),
            const SizedBox(height: 12),
            _Field(
                ctrl: nameCtrl,
                label: 'Full Name',
                hint: 'John Doe',
                icon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 14),
            _Field(
                ctrl: emailCtrl,
                label: 'Email Address',
                hint: 'you@sdstate.edu',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                }),
            const SizedBox(height: 14),
            _Field(
                ctrl: phoneCtrl,
                label: 'Phone Number',
                hint: '+1 (605) 000-0000',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 28),
            _Heading('Delivery / Pickup Address'),
            const SizedBox(height: 12),
            _Field(
                ctrl: addressCtrl,
                label: 'Street Address',
                hint: '1 University Street',
                icon: Icons.home_outlined,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _Field(
                      ctrl: cityCtrl,
                      label: 'City',
                      hint: 'Brookings',
                      icon: Icons.location_city_outlined,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _Field(
                      ctrl: zipCtrl,
                      label: 'ZIP',
                      hint: '57007',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 5) return 'Invalid';
                        return null;
                      }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
          ),
        ),
      ],
    );
  }
}

// ─── Step 2: Order Review ─────────────────────────────────────────────────────

class _OrderReviewStep extends StatelessWidget {
  final List<CartItem> cartItems;
  final double subtotal, tax, total;
  final String name, email, phone, address, city, zip;
  final Product Function(String) getProduct;

  const _OrderReviewStep({
    required this.cartItems,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.zip,
    required this.getProduct,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact
          _Section(icon: Icons.person_rounded, title: 'Contact Details', children: [
            _Row('Name', name),
            _Row('Email', email),
            _Row('Phone', phone),
            _Row('Address', '$address, $city $zip'),
          ]),
          const SizedBox(height: 16),

          // Items
          _Section(
            icon: Icons.shopping_bag_rounded,
            title: 'Items (${cartItems.length})',
            children: cartItems.map((item) {
              final p = getProduct(item.productId);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(p.imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: AppColors.blueTint,
                                child: const Icon(Icons.image_outlined,
                                    size: 20, color: AppColors.primary))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text(
                              '${item.size} · ${item.color} · Qty ${item.quantity}',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                        '\$${(p.basePrice * item.quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Price summary
          _Section(icon: Icons.receipt_long_rounded, title: 'Price Summary', children: [
            _Row('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
            _Row('Tax (7.5%)', '\$${tax.toStringAsFixed(2)}'),
            const Divider(color: AppColors.border, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text('\$${total.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ],
            ),
          ]),
          const SizedBox(height: 12),

          // Payment note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.success.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payment collected securely at the SDSU merchandise office upon pickup.',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: AppColors.success, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _Section(
      {required this.icon,
      required this.title,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: AppColors.blueTint,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}