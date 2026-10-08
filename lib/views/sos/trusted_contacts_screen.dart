import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _relation = 'Friend';
  String? _editingId;
  bool _isSaving = false;

  final _relations = ['Friend', 'Family', 'Parent', 'Sibling', 'Partner', 'Colleague', 'Other'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (auth.isAnonymous) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          title: Text('Trusted Contacts',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.backgroundPrimary,
          iconTheme: const IconThemeData(color: AppColors.goldLight),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundCard,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AppColors.textHint, size: 48),
                ),
                const SizedBox(height: 20),
                Text('Login Required',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20)),
                const SizedBox(height: 8),
                Text(
                  'Trusted contacts can only be added by\nsigned-in users to ensure your safety network\nis reliably connected.',
                  style: GoogleFonts.inter(
                      color: AppColors.textHint, fontSize: 13, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.login_rounded, color: Colors.black),
                  label: Text('Go Back & Login',
                      style: GoogleFonts.inter(
                          color: Colors.black, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.2),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Trusted Contacts',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.backgroundPrimary,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddEditSheet(context, auth),
            icon: const Icon(Icons.add, color: AppColors.goldLight, size: 18),
            label: Text('Add', style: GoogleFonts.inter(color: AppColors.goldLight, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.goldPrimary.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.goldLight, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These contacts will be notified with your location during an SOS alert.',
                    style: GoogleFonts.inter(
                        color: AppColors.goldLight, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Contacts List
          Expanded(
            child: auth.trustedContacts.isEmpty
                ? _emptyState(context, auth)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: auth.trustedContacts.length,
                    itemBuilder: (_, i) => _ContactCard(
                      contact: auth.trustedContacts[i],
                      index: i,
                      onEdit: () =>
                          _showAddEditSheet(context, auth, existing: auth.trustedContacts[i]),
                      onDelete: () => _confirmDelete(context, auth, auth.trustedContacts[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(context, auth),
        icon: const Icon(Icons.person_add_rounded, color: Colors.black),
        label: Text('Add Contact',
            style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.goldPrimary,
      ),
    );
  }

  Widget _emptyState(BuildContext context, AuthViewModel auth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, color: AppColors.textHint, size: 56),
          const SizedBox(height: 16),
          Text('No Trusted Contacts Yet',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Add family and friends who will be\nalerted during an SOS emergency.',
            style: GoogleFonts.inter(
                color: AppColors.textHint, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditSheet(context, auth),
            icon: const Icon(Icons.person_add_rounded, color: Colors.black),
            label: Text('Add First Contact',
                style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }

  void _showAddEditSheet(BuildContext context, AuthViewModel auth,
      {Map<String, dynamic>? existing}) {
    _editingId = existing?['id'];
    _nameCtrl.text = existing?['name'] ?? '';
    _phoneCtrl.text = existing?['phone'] ?? '';
    _relation = existing?['relation'] ?? 'Friend';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _editingId != null ? 'Edit Contact' : 'Add Trusted Contact',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter contact name' : null,
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (10 digits)',
                      prefixIcon: Icon(Icons.phone_outlined),
                      prefixText: '+91 ',
                      prefixStyle: TextStyle(color: AppColors.goldLight),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter phone number';
                      final clean = v.replaceAll(RegExp(r'[\s\-]'), '');
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                        return 'Enter a valid 10-digit Indian mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Relation Dropdown
                  DropdownButtonFormField<String>(
                    value: _relation,
                    dropdownColor: AppColors.backgroundCard,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      prefixIcon: Icon(Icons.favorite_outline),
                    ),
                    items: _relations
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setS(() => _relation = v ?? 'Friend'),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setS(() => _isSaving = true);

                              String? error;
                              if (_editingId != null) {
                                error = await auth.editTrustedContact(
                                  contactId: _editingId!,
                                  name: _nameCtrl.text,
                                  phone: _phoneCtrl.text,
                                  relation: _relation,
                                );
                              } else {
                                error = await auth.addTrustedContact(
                                  name: _nameCtrl.text,
                                  phone: _phoneCtrl.text,
                                  relation: _relation,
                                );
                              }

                              setS(() => _isSaving = false);
                              if (mounted) Navigator.pop(context);
                              if (error != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : Text(_editingId != null ? 'Save Changes' : 'Add Contact',
                              style: GoogleFonts.inter(
                                  color: Colors.black, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AuthViewModel auth, Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text('Remove Contact?',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove ${contact['name']} from your trusted contacts?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () async {
              await auth.deleteTrustedContact(contact['id'] as String);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Remove', style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final int index;
  final VoidCallback onEdit, onDelete;
  const _ContactCard({
    required this.contact,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
            ),
            child: Center(
              child: Text(
                (contact['name'] as String? ?? 'U')[0].toUpperCase(),
                style: GoogleFonts.inter(
                    color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact['name'] ?? 'Unknown',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 12, color: AppColors.goldLight),
                    const SizedBox(width: 4),
                    Text('+91 ${contact['phone'] ?? ''}',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.goldPrimary.withValues(alpha: 0.1),
                  ),
                  child: Text(contact['relation'] ?? 'Friend',
                      style: GoogleFonts.inter(
                          color: AppColors.goldLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.textHint, size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideX(begin: 0.1);
  }
}
