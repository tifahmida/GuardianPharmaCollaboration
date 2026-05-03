import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/login_page.dart';
import 'package:guardianpharma/violation_logs_page.dart';
import 'package:guardianpharma/suspicious_activity_page.dart';
import 'package:guardianpharma/audit_reports_page.dart';
import 'package:guardianpharma/pharmacy_verification_page.dart';
import 'package:guardianpharma/medicine_traceability_page.dart';
import 'package:guardianpharma/stock_authenticity_page.dart';

class RegulatoryHome extends StatefulWidget {
  const RegulatoryHome({super.key});
  @override
  State<RegulatoryHome> createState() => _RegulatoryHomeState();
}

class _RegulatoryHomeState extends State<RegulatoryHome> {
  bool _isLoading = true;
  bool _profileExists = false;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (mounted) {
          setState(() {
            _profileExists = data != null;
            _isLoading = false;
          });
        }
      } else {
        if (mounted)
          setState(() {
            _profileExists = false;
            _isLoading = false;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _profileExists = false;
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (!_profileExists) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.blueAccent,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "Profile Not Found",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyLogin()),
                ),
                child: const Text(
                  "Go Back to Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/guardianpharmapills.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.42)),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _headerBox(),
                      const SizedBox(height: 16),

                      _section("🏥 Pharmacy Management"),
                      _tile(
                        context,
                        "All Pharmacies",
                        Icons.store,
                        subtitle: "View, add, edit & delete pharmacies",
                        color: Colors.blueAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _AllPharmaciesPage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Add New Pharmacy",
                        Icons.add_business,
                        subtitle: "Register a new pharmacy",
                        color: Colors.greenAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _AddPharmacyPage(),
                          ),
                        ).then((_) => setState(() {})),
                      ),

                      const SizedBox(height: 12),
                      _section("📊 Monitoring & Audit"),
                      _tile(
                        context,
                        "Violation Logs",
                        Icons.report,
                        subtitle: "View flagged violations",
                        color: const Color(0xFFEF9A9A),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ViolationLogsPage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Suspicious Activity",
                        Icons.warning_amber_rounded,
                        subtitle: "Monitor unusual patterns",
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SuspiciousActivityPage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Audit Reports",
                        Icons.bar_chart,
                        subtitle: "Full compliance reports",
                        color: Colors.purpleAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuditReportsPage(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      _section("🔍 Compliance & Verification"),
                      _tile(
                        context,
                        "Pharmacy Verification",
                        Icons.verified,
                        subtitle: "Approve or reject pharmacy licenses",
                        color: Colors.tealAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PharmacyVerificationPage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Medicine Traceability",
                        Icons.track_changes,
                        subtitle: "Track medicine supply chain",
                        color: Colors.cyanAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MedicineTraceabilityPage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Stock Authenticity Check",
                        Icons.fact_check,
                        subtitle: "Verify batch is registered & genuine",
                        color: Colors.amberAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StockAuthenticityPage(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Logo icon + GuardianPharma text
  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.local_pharmacy, color: Colors.blueAccent, size: 26),
              SizedBox(width: 8),
              Text(
                "GuardianPharma",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MyLogin()),
                  (r) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ✅ Premium blue-teal gradient header — no red anywhere
  Widget _headerBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF00838F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "REGULATORY AUTHORITY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "GuardianPharma Control Panel",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon, {
    String? subtitle,
    Color color = Colors.blueAccent,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              )
            : null,
        trailing: Icon(
          onTap != null ? Icons.arrow_forward_ios : Icons.lock_outline,
          size: 14,
          color: onTap != null ? Colors.white54 : Colors.white24,
        ),
        onTap: onTap,
      ),
    );
  }
}

// =========================
// ALL PHARMACIES PAGE
// =========================
class _AllPharmaciesPage extends StatefulWidget {
  const _AllPharmaciesPage();
  @override
  State<_AllPharmaciesPage> createState() => _AllPharmaciesPageState();
}

class _AllPharmaciesPageState extends State<_AllPharmaciesPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pharmacies = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await supabase.from('pharmacies').select().order('name');
      setState(() {
        pharmacies = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> p) async {
    try {
      final bool cur = p['is_active'] == true;
      await supabase
          .from('pharmacies')
          .update({'is_active': !cur})
          .eq('id', p['id']);
      _load();
      _ok(cur ? "Pharmacy deactivated" : "Pharmacy activated");
    } catch (e) {
      _err("Error: $e");
    }
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Delete Pharmacy",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Delete \"${p['name']}\"?\n\n⚠️ This will also remove all linked data.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await supabase.from('pharmacies').delete().eq('id', p['id']);
      _ok("Pharmacy deleted!");
      _load();
    } catch (e) {
      _err("Delete failed: $e");
    }
  }

  void _edit(Map<String, dynamic> p) {
    final nameC = TextEditingController(text: p['name'] ?? '');
    final licC = TextEditingController(text: p['license_number'] ?? '');
    final addC = TextEditingController(text: p['address'] ?? '');
    final phoneC = TextEditingController(text: p['phone'] ?? '');
    final ownerC = TextEditingController(text: p['owner_name'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Edit Pharmacy",
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _f(nameC, "Pharmacy Name", Icons.store),
              const SizedBox(height: 10),
              _f(licC, "License Number", Icons.badge),
              const SizedBox(height: 10),
              _f(addC, "Address", Icons.location_on),
              const SizedBox(height: 10),
              _f(phoneC, "Phone", Icons.phone),
              const SizedBox(height: 10),
              _f(ownerC, "Owner Name", Icons.person),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              try {
                await supabase
                    .from('pharmacies')
                    .update({
                      'name': nameC.text.trim(),
                      'license_number': licC.text.trim(),
                      'address': addC.text.trim().isEmpty
                          ? null
                          : addC.text.trim(),
                      'phone': phoneC.text.trim().isEmpty
                          ? null
                          : phoneC.text.trim(),
                      'owner_name': ownerC.text.trim().isEmpty
                          ? null
                          : ownerC.text.trim(),
                    })
                    .eq('id', p['id']);
                if (mounted) Navigator.pop(context);
                _load();
                _ok("Pharmacy updated!");
              } catch (e) {
                _err("Update failed: $e");
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _f(TextEditingController c, String hint, IconData icon) => TextField(
    controller: c,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );

  Widget _stat(String label, String val, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    ),
  );

  void _err(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void _ok(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/guardianpharmapills.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.store, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "All Pharmacies",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _load,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_business,
                          color: Colors.greenAccent,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _AddPharmacyPage(),
                          ),
                        ).then((_) => _load()),
                      ),
                    ],
                  ),
                ),

                if (!loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _stat("Total", "${pharmacies.length}", Colors.white70),
                        const SizedBox(width: 8),
                        _stat(
                          "Active",
                          "${pharmacies.where((p) => p['is_active'] == true).length}",
                          Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        _stat(
                          "Verified",
                          "${pharmacies.where((p) => p['is_verified'] == true).length}",
                          Colors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        _stat(
                          "Pending",
                          "${pharmacies.where((p) => p['is_verified'] != true).length}",
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent,
                          ),
                        )
                      : pharmacies.isEmpty
                      ? const Center(
                          child: Text(
                            "No pharmacies found",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: pharmacies.length,
                          itemBuilder: (_, i) {
                            final p = pharmacies[i];
                            final bool active = p['is_active'] == true;
                            final bool verified = p['is_verified'] == true;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? Colors.blueAccent.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: active
                                            ? Colors.blueAccent.withOpacity(0.2)
                                            : Colors.white.withOpacity(0.1),
                                        child: Icon(
                                          Icons.local_pharmacy,
                                          color: active
                                              ? Colors.blueAccent
                                              : Colors.white54,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['name'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              "🪪 ${p['license_number'] ?? 'N/A'}",
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if ((p['address'] ?? '').isNotEmpty)
                                              Text(
                                                "📍 ${p['address']}",
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            if ((p['owner_name'] ?? '')
                                                .isNotEmpty)
                                              Text(
                                                "👤 ${p['owner_name']}",
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          _badge(
                                            active ? "Active" : "Inactive",
                                            active
                                                ? Colors.greenAccent
                                                : Colors.white38,
                                          ),
                                          const SizedBox(height: 4),
                                          _badge(
                                            verified ? "✓ Verified" : "Pending",
                                            verified
                                                ? Colors.tealAccent
                                                : Colors.orange,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(color: Colors.white12),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blueAccent,
                                            side: const BorderSide(
                                              color: Colors.blueAccent,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () => _edit(p),
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 16,
                                          ),
                                          label: const Text("Edit"),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: active
                                                ? Colors.orange
                                                : Colors.greenAccent,
                                            side: BorderSide(
                                              color: active
                                                  ? Colors.orange
                                                  : Colors.greenAccent,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () => _toggleActive(p),
                                          icon: Icon(
                                            active
                                                ? Icons.block
                                                : Icons.check_circle,
                                            size: 16,
                                          ),
                                          label: Text(
                                            active ? "Deactivate" : "Activate",
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(
                                            color: Colors.redAccent,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                        ),
                                        onPressed: () => _delete(p),
                                        child: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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

// =========================
// ADD PHARMACY PAGE
// =========================
class _AddPharmacyPage extends StatefulWidget {
  const _AddPharmacyPage();
  @override
  State<_AddPharmacyPage> createState() => _AddPharmacyPageState();
}

class _AddPharmacyPageState extends State<_AddPharmacyPage> {
  final supabase = Supabase.instance.client;
  bool saving = false;
  final nameC = TextEditingController();
  final licC = TextEditingController();
  final addC = TextEditingController();
  final phoneC = TextEditingController();
  final ownerC = TextEditingController();

  @override
  void dispose() {
    nameC.dispose();
    licC.dispose();
    addC.dispose();
    phoneC.dispose();
    ownerC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (nameC.text.trim().isEmpty) {
      _err("Pharmacy name is required");
      return;
    }
    if (licC.text.trim().isEmpty) {
      _err("License number is required");
      return;
    }
    setState(() => saving = true);
    try {
      await supabase.from('pharmacies').insert({
        'name': nameC.text.trim(),
        'license_number': licC.text.trim(),
        'address': addC.text.trim().isEmpty ? null : addC.text.trim(),
        'phone': phoneC.text.trim().isEmpty ? null : phoneC.text.trim(),
        'owner_name': ownerC.text.trim().isEmpty ? null : ownerC.text.trim(),
        'is_active': true,
        'is_verified': false,
      });
      _ok("Pharmacy added successfully!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _err("Failed: $e");
    }
    if (mounted) setState(() => saving = false);
  }

  void _err(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void _ok(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType? kt,
  }) => TextField(
    controller: c,
    keyboardType: kt,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/guardianpharmapills.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.50)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.add_business, color: Colors.greenAccent),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Add New Pharmacy",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blueAccent,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Pharmacies added here will appear in the pharmacy selection list for pharmacists.",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _field(nameC, "Pharmacy Name *", Icons.local_pharmacy),
                        const SizedBox(height: 12),
                        _field(licC, "License Number *", Icons.badge_outlined),
                        const SizedBox(height: 12),
                        _field(
                          addC,
                          "Address (optional)",
                          Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          phoneC,
                          "Phone Number (optional)",
                          Icons.phone_outlined,
                          kt: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          ownerC,
                          "Owner Name (optional)",
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: saving ? null : _save,
                            icon: saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save, color: Colors.white),
                            label: Text(
                              saving ? "Saving..." : "Add Pharmacy",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
