// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

// ─── Step enum ────────────────────────────────────────────────────────────────
// Step 0 = Delivery Info
// Step 1 = Payment Method
// Step 2 = Review & Confirm

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
  // ── Form keys ──────────────────────────────────────────────────────────────
  final _deliveryFormKey = GlobalKey<FormState>();

  // ── Delivery controllers ───────────────────────────────────────────────────
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _zipCtrl     = TextEditingController();
  bool _saveAddress  = false;
  bool _loadingProfile = true;

  // ── Payment state ──────────────────────────────────────────────────────────
  String _paymentMethod = 'card'; // 'card' | 'cash' | 'venmo'
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl   = TextEditingController();
  final _cardExpCtrl    = TextEditingController();
  final _cardCvvCtrl    = TextEditingController();

  // ── Step & loading ─────────────────────────────────────────────────────────
  int  _step      = 0;
  bool _isPlacing = false;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _autoPopulateFromProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardExpCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  // ── Auto-populate from Supabase profiles ──────────────────────────────────
  Future<void> _autoPopulateFromProfile() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (data != null && mounted) {
        _nameCtrl.text    = data['full_name']  as String? ?? '';
        _emailCtrl.text   = data['email']      as String? ?? '';
        _phoneCtrl.text   = data['phone']      as String? ?? '';
        _addressCtrl.text = data['address']    as String? ?? '';
        _cityCtrl.text    = data['city']       as String? ?? '';
        _zipCtrl.text     = data['zip']        as String? ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingProfile = false);
  }

  // ── Save address back to profile ──────────────────────────────────────────
  Future<void> _saveAddressToProfile() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('profiles').upsert({
      'id'     : uid,
      'address': _addressCtrl.text.trim(),
      'city'   : _cityCtrl.text.trim(),
      'zip'    : _zipCtrl.text.trim(),
      'phone'  : _phoneCtrl.text.trim(),
    });
  }

  // ── Totals ────────────────────────────────────────────────────────────────
  double get _tax   => widget.subtotal * 0.075;
  double get _total => widget.subtotal + _tax;

  Product _getProduct(String id) => sampleProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => sampleProducts.first,
      );

  // ── Navigation ────────────────────────────────────────────────────────────
  void _goNext() {
    if (_step == 0) {
      if (_deliveryFormKey.currentState?.validate() ?? false) {
        if (_saveAddress) _saveAddressToProfile();
        setState(() => _step = 1);
      }
    } else if (_step == 1) {
      // Payment — card fields required only for card method
      if (_paymentMethod == 'card') {
        if (_cardNumberCtrl.text.replaceAll(' ', '').length < 16) {
          _showSnack('Please enter a valid 16-digit card number');
          return;
        }
        if (_cardNameCtrl.text.isEmpty) {
          _showSnack('Please enter the cardholder name');
          return;
        }
        if (_cardExpCtrl.text.length < 5) {
          _showSnack('Please enter a valid expiry (MM/YY)');
          return;
        }
        if (_cardCvvCtrl.text.length < 3) {
          _showSnack('Please enter a valid CVV');
          return;
        }
      }
      setState(() => _step = 2);
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Place Order ───────────────────────────────────────────────────────────
  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    try {
      final uid = _db.auth.currentUser?.id;

      final items = widget.cartItems.map((ci) {
        final p = _getProduct(ci.productId);
        // Use the stored unitPrice (includes accessories + discount).
        // Fall back to basePrice for any legacy cart rows.
        final double unitPrice = ci.unitPrice > 0 ? ci.unitPrice : p.basePrice;
        return {
          'product_id' : ci.productId,
          'title'      : p.title,
          'size'       : ci.size,
          'color'      : ci.color,
          'quantity'   : ci.quantity,
          'unit_price' : unitPrice,
        };
      }).toList();

      String? orderId;
      if (uid != null) {
        final result = await _db.from('orders').insert({
          'user_id'        : uid,
          'full_name'      : _nameCtrl.text.trim(),
          'email'          : _emailCtrl.text.trim(),
          'phone'          : _phoneCtrl.text.trim(),
          'address'        : _addressCtrl.text.trim(),
          'city'           : _cityCtrl.text.trim(),
          'zip'            : _zipCtrl.text.trim(),
          'delivery_type'  : 'delivery',
          'payment_method' : _paymentMethod,
          'subtotal'       : widget.subtotal,
          'tax'            : _tax,
          'total'          : _total,
          'status'         : 'Confirmed',
          'items'          : items,
        }).select('id').single();
        orderId = result['id'] as String?;
      }

      await ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;
      setState(() => _isPlacing = false);
      _showSuccess(orderId ?? 'N/A');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacing = false);
      _showSnack('Order failed. Please try again.');
    }
  }

  // ── Success Dialog ────────────────────────────────────────────────────────
  void _showSuccess(String orderId) {
    // Generate a short human-readable order number from the UUID
    final shortId = orderId.length >= 8
        ? orderId.replaceAll('-', '').substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 52),
            ),
            const SizedBox(height: 20),
            Text('Order Confirmed! 🎉',
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),

            // Order number box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.blueTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text('Your Order Number',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    '#$shortId',
                    style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 3),
                  ),
                  const SizedBox(height: 4),
                  Text('Save this number for your records',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'Your SDSU merch is on its way!\nDelivery to ${_cityCtrl.text.isNotEmpty ? _cityCtrl.text : "your address"}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
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

  // ── CTA label & icon ──────────────────────────────────────────────────────
  String get _ctaLabel {
    if (_step == 0) return 'Continue to Payment';
    if (_step == 1) return 'Review Order';
    return 'Confirm & Place Order';
  }

  IconData get _ctaIcon {
    if (_step == 2) return Icons.check_circle_rounded;
    return Icons.arrow_forward_rounded;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final stepTitles = ['Delivery Info', 'Payment', 'Review Order'];

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
          onPressed: _goBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stepTitles[_step],
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text('Step ${_step + 1} of 3',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── 3-step progress bar ──────────────────────────────────────
          _StepProgress(step: _step),

          // ── Page content ─────────────────────────────────────────────
          Expanded(
            child: _loadingProfile
                ? const Center(child: CircularProgressIndicator())
                : _step == 0
                    ? _DeliveryStep(
                        formKey: _deliveryFormKey,
                        nameCtrl: _nameCtrl,
                        emailCtrl: _emailCtrl,
                        phoneCtrl: _phoneCtrl,
                        addressCtrl: _addressCtrl,
                        cityCtrl: _cityCtrl,
                        zipCtrl: _zipCtrl,
                        saveAddress: _saveAddress,
                        onSaveAddressChanged: (v) =>
                            setState(() => _saveAddress = v),
                      )
                    : _step == 1
                        ? _PaymentStep(
                            selectedMethod: _paymentMethod,
                            onMethodChanged: (m) =>
                                setState(() => _paymentMethod = m),
                            cardNumberCtrl: _cardNumberCtrl,
                            cardNameCtrl: _cardNameCtrl,
                            cardExpCtrl: _cardExpCtrl,
                            cardCvvCtrl: _cardCvvCtrl,
                          )
                        : _ReviewStep(
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
                            paymentMethod: _paymentMethod,
                            cardLast4: _cardNumberCtrl.text.length >= 4
                                ? _cardNumberCtrl.text
                                    .replaceAll(' ', '')
                                    .substring(_cardNumberCtrl.text
                                            .replaceAll(' ', '')
                                            .length -
                                        4)
                                : '',
                            getProduct: _getProduct,
                          ),
          ),

          // ── Bottom CTA ───────────────────────────────────────────────
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
                    offset: const Offset(0, -4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total preview on review step
                if (_step == 2) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total to pay',
                          style: GoogleFonts.outfit(
                              fontSize: 14, color: AppColors.textSecondary)),
                      Text('\$${_total.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isPlacing
                        ? null
                        : (_step == 2 ? _placeOrder : _goNext),
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
                              Icon(_ctaIcon, size: 20),
                              const SizedBox(width: 8),
                              Text(_ctaLabel,
                                  style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
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

// ─── 3-Step Progress Bar ──────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  final int step;
  const _StepProgress({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          _Dot(n: 1, label: 'Delivery', active: step == 0, done: step > 0),
          _Bar(filled: step > 0),
          _Dot(n: 2, label: 'Payment', active: step == 1, done: step > 1),
          _Bar(filled: step > 1),
          _Dot(n: 3, label: 'Review', active: step == 2, done: false),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int n;
  final String label;
  final bool active, done;
  const _Dot({required this.n, required this.label, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final colored = active || done;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: colored ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: colored ? AppColors.primary : AppColors.border,
                  width: 2)),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 15)
                : Text('$n',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textLight)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textSecondary)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final bool filled;
  const _Bar({required this.filled});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 18),
            color: filled ? AppColors.primary : AppColors.border),
      );
}

// ─── Step 0: Delivery Info ────────────────────────────────────────────────────

class _DeliveryStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl,
      addressCtrl, cityCtrl, zipCtrl;
  final bool saveAddress;
  final ValueChanged<bool> onSaveAddressChanged;

  const _DeliveryStep({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.zipCtrl,
    required this.saveAddress,
    required this.onSaveAddressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Home Delivery',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _SectionHeading('Contact Details'),
            const SizedBox(height: 12),
            _Field(
                ctrl: nameCtrl,
                label: 'Full Name',
                hint: 'John Doe',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
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

            const SizedBox(height: 24),
            _SectionHeading('Delivery Address'),
            const SizedBox(height: 12),
            _Field(
                ctrl: addressCtrl,
                label: 'Street Address',
                hint: '123 Main St',
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
                        if (v.length < 5) return 'Invalid ZIP';
                        return null;
                      }),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Save address toggle
            GestureDetector(
              onTap: () => onSaveAddressChanged(!saveAddress),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: saveAddress ? AppColors.blueTint : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: saveAddress
                          ? AppColors.primary
                          : AppColors.border,
                      width: saveAddress ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: saveAddress
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: saveAddress
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2),
                      ),
                      child: saveAddress
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Save address to my profile',
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text(
                              'Auto-fill this address on your next order',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.bookmark_outline_rounded,
                        color: saveAddress
                            ? AppColors.primary
                            : AppColors.textLight,
                        size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1: Payment Method ───────────────────────────────────────────────────

class _PaymentStep extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;
  final TextEditingController cardNumberCtrl, cardNameCtrl,
      cardExpCtrl, cardCvvCtrl;

  const _PaymentStep({
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.cardNumberCtrl,
    required this.cardNameCtrl,
    required this.cardExpCtrl,
    required this.cardCvvCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading('Select Payment Method'),
          const SizedBox(height: 14),

          // ── Method tiles ────────────────────────────────────────────
          _PaymentTile(
            value: 'card',
            selected: selectedMethod,
            icon: Icons.credit_card_rounded,
            title: 'Credit / Debit Card',
            subtitle: 'Visa, Mastercard, Amex',
            onTap: () => onMethodChanged('card'),
          ),
          const SizedBox(height: 10),
          _PaymentTile(
            value: 'venmo',
            selected: selectedMethod,
            icon: Icons.payment_rounded,
            title: 'Venmo',
            subtitle: 'Pay via Venmo @SDSU-Merch',
            onTap: () => onMethodChanged('venmo'),
          ),
          const SizedBox(height: 10),
          _PaymentTile(
            value: 'cash',
            selected: selectedMethod,
            icon: Icons.attach_money_rounded,
            title: 'Cash on Delivery',
            subtitle: 'Pay when your order arrives',
            onTap: () => onMethodChanged('cash'),
          ),

          // ── Card fields ─────────────────────────────────────────────
          if (selectedMethod == 'card') ...[
            const SizedBox(height: 24),
            _SectionHeading('Card Details'),
            const SizedBox(height: 14),

            // Card number with live formatting
            _CardNumberField(ctrl: cardNumberCtrl),
            const SizedBox(height: 14),

            _Field(
                ctrl: cardNameCtrl,
                label: 'Cardholder Name',
                hint: 'JOHN DOE',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _ExpiryField(ctrl: cardExpCtrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                      ctrl: cardCvvCtrl,
                      label: 'CVV',
                      hint: '•••',
                      icon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Security note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Your card details are encrypted and secure.',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.success,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],

          if (selectedMethod == 'venmo') ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3D95CE).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF3D95CE).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D95CE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payment_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send payment to:',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        Text('@SDSU-Merch',
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF3D95CE))),
                        Text('Include your order number in the note.',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (selectedMethod == 'cash') ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.attach_money_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Our delivery person will collect payment when your order arrives at your address.',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.success,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String value, selected, title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blueTint : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card number field with live spacing ─────────────────────────────────────

class _CardNumberField extends StatelessWidget {
  final TextEditingController ctrl;
  const _CardNumberField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Card Number',
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 19, // 16 digits + 3 spaces
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          decoration: InputDecoration(
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card_rounded,
                color: AppColors.textLight, size: 20),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newVal.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryField extends StatelessWidget {
  final TextEditingController ctrl;
  const _ExpiryField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expiry (MM/YY)',
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 5,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ExpiryFormatter(),
          ],
          decoration: const InputDecoration(
            hintText: 'MM/YY',
            prefixIcon: Icon(Icons.calendar_today_outlined,
                color: AppColors.textLight, size: 18),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll('/', '');
    String str = digits;
    if (digits.length >= 2) {
      str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return newVal.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

// ─── Step 2: Review ───────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final List<CartItem> cartItems;
  final double subtotal, tax, total;
  final String name, email, phone, address, city, zip;
  final String paymentMethod, cardLast4;
  final Product Function(String) getProduct;

  const _ReviewStep({
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
    required this.paymentMethod,
    required this.cardLast4,
    required this.getProduct,
  });

  String get _paymentLabel {
    if (paymentMethod == 'card') return 'Card ending in $cardLast4';
    if (paymentMethod == 'venmo') return 'Venmo (@SDSU-Merch)';
    return 'Cash on Delivery';
  }

  IconData get _paymentIcon {
    if (paymentMethod == 'card') return Icons.credit_card_rounded;
    if (paymentMethod == 'venmo') return Icons.payment_rounded;
    return Icons.attach_money_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery details
          _Section(
            icon: Icons.local_shipping_rounded,
            title: 'Delivery Details',
            children: [
              _Row('Name', name),
              _Row('Email', email),
              _Row('Phone', phone),
              _Row('Address', '$address, $city $zip'),
            ],
          ),
          const SizedBox(height: 14),

          // Payment method
          _Section(
            icon: _paymentIcon,
            title: 'Payment Method',
            children: [_Row('Method', _paymentLabel)],
          ),
          const SizedBox(height: 14),

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
                        child: Image.asset(p.imageUrl,
                            fit: BoxFit.cover,
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
                        '\$${((item.unitPrice > 0 ? item.unitPrice : p.basePrice) * item.quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Price summary
          _Section(
            icon: Icons.receipt_long_rounded,
            title: 'Price Summary',
            children: [
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
            ],
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
      {required this.icon, required this.title, required this.children});

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
          Row(children: [
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
          ]),
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
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
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

// ─── Shared Field Widgets ─────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
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
          obscureText: obscureText,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
          ),
        ),
      ],
    );
  }
}