// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';
import 'welcome_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final data = await _supabase
          .from('profiles').select().eq('id', uid).maybeSingle();
      setState(() { _profile = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  void _confirmSignOut() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Sign out?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      content: Text('You will be returned to the welcome screen.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary))),
        TextButton(
          onPressed: () { Navigator.pop(context); _signOut(); },
          child: Text('Sign Out', style: GoogleFonts.outfit(
              color: AppColors.error, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  // ── Edit Profile (name, phone, address, city, zip) ────────────────────────
  void _showEditProfile() {
    final nameCtrl    = TextEditingController(text: _profile?['full_name'] as String? ?? '');
    final phoneCtrl   = TextEditingController(text: _profile?['phone']     as String? ?? '');
    final addressCtrl = TextEditingController(text: _profile?['address']   as String? ?? '');
    final cityCtrl    = TextEditingController(text: _profile?['city']      as String? ?? '');
    final zipCtrl     = TextEditingController(text: _profile?['zip']       as String? ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 36, height: 4,
                      decoration: BoxDecoration(color: AppColors.border,
                          borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text('Edit Profile', style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
                  const SizedBox(height: 20),

                  _SectionLabel('Personal'),
                  const SizedBox(height: 10),
                  _DialogField(ctrl: nameCtrl, label: 'Full Name',
                      icon: Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _DialogField(ctrl: phoneCtrl, label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone),

                  const SizedBox(height: 20),
                  _SectionLabel('Default Delivery Address'),
                  const SizedBox(height: 10),
                  _DialogField(ctrl: addressCtrl, label: 'Street Address',
                      icon: Icons.home_outlined),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(flex: 3, child: _DialogField(ctrl: cityCtrl,
                        label: 'City', icon: Icons.location_city_outlined)),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _DialogField(ctrl: zipCtrl,
                        label: 'ZIP', icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number)),
                  ]),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        setInner(() => saving = true);
                        final uid = _supabase.auth.currentUser?.id;
                        if (uid != null) {
                          await _supabase.from('profiles').upsert({
                            'id'      : uid,
                            'full_name': nameCtrl.text.trim(),
                            'phone'   : phoneCtrl.text.trim(),
                            'address' : addressCtrl.text.trim(),
                            'city'    : cityCtrl.text.trim(),
                            'zip'     : zipCtrl.text.trim(),
                          });
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadProfile();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder()),
                      child: saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Save Changes', style: GoogleFonts.outfit(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Change Password ───────────────────────────────────────────────────────
  void _showChangePassword() {
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false, obscure = true;
    String? error;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setInner) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Password',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _DialogField(ctrl: newCtrl, label: 'New Password',
              icon: Icons.lock_outline_rounded, obscure: obscure,
              suffix: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                    color: AppColors.textLight, size: 20),
                onPressed: () => setInner(() => obscure = !obscure),
              )),
          const SizedBox(height: 12),
          _DialogField(ctrl: confirmCtrl, label: 'Confirm Password',
              icon: Icons.lock_outline_rounded, obscure: obscure),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: GoogleFonts.outfit(
                color: AppColors.error, fontSize: 12)),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: saving ? null : () async {
              if (newCtrl.text.length < 8) {
                setInner(() => error = 'Password must be 8+ characters');
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                setInner(() => error = 'Passwords do not match');
                return;
              }
              setInner(() { saving = true; error = null; });
              try {
                await _supabase.auth.updateUser(
                    UserAttributes(password: newCtrl.text));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _showSnack('Password updated ✓', AppColors.success);
                }
              } on AuthException catch (e) {
                setInner(() { saving = false; error = e.message; });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: const StadiumBorder()),
            child: saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Update', style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ));
  }

  // ── Order History ─────────────────────────────────────────────────────────
  void _showOrderHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderHistorySheet(supabase: _supabase),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showInfoSheet(String title, String body) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.outfit(fontSize: 18,
              fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(body, style: GoogleFonts.outfit(fontSize: 14,
              color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: const StadiumBorder()),
            child: Text('Close', style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user    = _supabase.auth.currentUser;
    final name    = _profile?['full_name'] as String? ?? user?.email?.split('@').first ?? 'SDSU Student';
    final email   = _profile?['email']     as String? ?? user?.email ?? '';
    final phone   = _profile?['phone']     as String? ?? '';
    final address = _profile?['address']   as String? ?? '';
    final city    = _profile?['city']      as String? ?? '';
    final zip     = _profile?['zip']       as String? ?? '';

    final hasAddress = address.isNotEmpty || city.isNotEmpty;
    final initials = name.isNotEmpty
        ? name.trim().split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2).join().toUpperCase()
        : 'JD';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Profile', style: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Avatar card ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: Center(child: Text(initials,
                            style: GoogleFonts.outfit(fontSize: 22,
                                fontWeight: FontWeight.w800, color: Colors.white))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.outfit(fontSize: 18,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 12,
                                  color: Colors.white.withOpacity(0.8))),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(phone, style: GoogleFonts.outfit(fontSize: 12,
                                color: Colors.white.withOpacity(0.7))),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.school_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text('SDSU Jackrabbit', style: GoogleFonts.outfit(
                                  fontSize: 12, color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ],
                      )),
                      GestureDetector(
                        onTap: _showEditProfile,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                  ),

                  // ── Saved address card ──────────────────────────────
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showEditProfile,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: hasAddress ? AppColors.blueTint : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: hasAddress
                                ? AppColors.primary.withOpacity(0.3)
                                : AppColors.border),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hasAddress
                                ? AppColors.primary
                                : AppColors.border.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.local_shipping_rounded,
                              color: hasAddress ? Colors.white : AppColors.textLight,
                              size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saved Delivery Address',
                                style: GoogleFonts.outfit(fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 3),
                            Text(
                              hasAddress
                                  ? [address, city, zip]
                                      .where((s) => s.isNotEmpty)
                                      .join(', ')
                                  : 'Tap to add your delivery address',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 12,
                                  color: hasAddress
                                      ? AppColors.primary
                                      : AppColors.textSecondary),
                            ),
                          ],
                        )),
                        Icon(Icons.chevron_right_rounded,
                            color: AppColors.textLight),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Account section ─────────────────────────────────
                  _SectionLabel('Account'),
                  const SizedBox(height: 10),
                  _MenuCard(items: [
                    _MenuItem(icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        subtitle: 'Name, phone & delivery address',
                        onTap: _showEditProfile),
                    _MenuItem(icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        subtitle: 'Update your password',
                        onTap: _showChangePassword),
                    _MenuItem(icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        subtitle: email.isNotEmpty ? email : 'Not set',
                        onTap: () {},
                        showChevron: false),
                  ]),

                  const SizedBox(height: 20),

                  // ── Orders section ───────────────────────────────────
                  _SectionLabel('Orders'),
                  const SizedBox(height: 10),
                  _MenuCard(items: [
                    _MenuItem(icon: Icons.receipt_long_rounded,
                        label: 'Order History',
                        subtitle: 'View all past orders',
                        onTap: _showOrderHistory),
                    _MenuItem(icon: Icons.shopping_bag_outlined,
                        label: 'Cart Items',
                        subtitle: '${ref.watch(cartProvider).totalItems} item(s) in cart',
                        onTap: () => Navigator.pop(context)),
                  ]),

                  const SizedBox(height: 20),

                  // ── Support section ──────────────────────────────────
                  _SectionLabel('Support'),
                  const SizedBox(height: 10),
                  _MenuCard(items: [
                    _MenuItem(icon: Icons.help_outline_rounded,
                        label: 'Help & FAQ',
                        subtitle: 'Common questions answered',
                        onTap: () => _showInfoSheet('Help & FAQ',
                            'For help with your SDSU Merch order, contact us at merch@sdstate.edu or visit the SDSU Student Union.')),
                    _MenuItem(icon: Icons.info_outline_rounded,
                        label: 'About SDSU Merch',
                        subtitle: 'Version 1.0.0',
                        onTap: () => _showInfoSheet('About',
                            'SDSU Merch Store v1.0\n\nOfficial merchandise ordering app for South Dakota State University Jackrabbits.\n\nBuilt with Flutter & Supabase.')),
                  ]),

                  const SizedBox(height: 28),

                  // ── Sign out ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _confirmSignOut,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: Text('Sign Out', style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: const StadiumBorder()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── Order History Sheet ──────────────────────────────────────────────────────

class _OrderHistorySheet extends StatefulWidget {
  final SupabaseClient supabase;
  const _OrderHistorySheet({required this.supabase});

  @override
  State<_OrderHistorySheet> createState() => _OrderHistorySheetState();
}

class _OrderHistorySheetState extends State<_OrderHistorySheet> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = widget.supabase.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final data = await widget.supabase
          .from('orders').select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  String _shortId(String id) =>
      id.replaceAll('-', '').substring(0, 8).toUpperCase();

  String _paymentLabel(String? m) {
    if (m == 'venmo') return 'Venmo';
    if (m == 'cash') return 'Cash on Delivery';
    return 'Card';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.blueTint,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppColors.primary, size: 20)),
              const SizedBox(width: 10),
              Text('Order History', style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(color: AppColors.blueTint,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.receipt_long_outlined,
                              color: AppColors.primary, size: 40)),
                        const SizedBox(height: 16),
                        Text('No orders yet', style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Your completed orders will appear here.',
                            style: GoogleFonts.outfit(fontSize: 13,
                                color: AppColors.textSecondary)),
                      ]))
                    : ListView.separated(
                        controller: ctrl,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final o   = _orders[i];
                          final total = (o['total'] as num?)?.toDouble() ?? 0.0;
                          final date  = DateTime.tryParse(o['created_at'] ?? '') ?? DateTime.now();
                          final status = o['status'] as String? ?? 'Confirmed';
                          final payment = _paymentLabel(o['payment_method'] as String?);
                          final shortId = _shortId(o['id'] as String? ?? 'xxxxxxxx');

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('#$shortId', style: GoogleFonts.outfit(
                                          fontSize: 15, fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                          letterSpacing: 1.5)),
                                      Text('${date.day}/${date.month}/${date.year}  ·  $payment',
                                          style: GoogleFonts.outfit(fontSize: 12,
                                              color: AppColors.textSecondary)),
                                    ],
                                  )),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('\$${total.toStringAsFixed(2)}',
                                        style: GoogleFonts.outfit(fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(status, style: GoogleFonts.outfit(
                                          fontSize: 11, fontWeight: FontWeight.w600,
                                          color: AppColors.success)),
                                    ),
                                  ]),
                                ]),
                                // Delivery address line
                                if ((o['address'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Divider(color: AppColors.border, height: 1),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Icon(Icons.local_shipping_outlined,
                                        size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(
                                      '${o['address']}, ${o['city']} ${o['zip']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(fontSize: 12,
                                          color: AppColors.textSecondary),
                                    )),
                                  ]),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared helper widgets ────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  const _DialogField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 0.5));
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key; final item = entry.value;
          return Column(children: [
            ListTile(
              onTap: item.onTap,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.blueTint,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, color: AppColors.primary, size: 18),
              ),
              title: Text(item.label, style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
              subtitle: item.subtitle != null
                  ? Text(item.subtitle!, style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.textSecondary))
                  : null,
              trailing: item.showChevron
                  ? const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textLight)
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            if (i < items.length - 1)
              const Divider(color: AppColors.border, height: 1,
                  indent: 60, endIndent: 16),
          ]);
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;
  const _MenuItem({required this.icon, required this.label,
      this.subtitle, required this.onTap, this.showChevron = true});
}