import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/login_page.dart';

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
        if (mounted) {
          setState(() {
            _profileExists = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileExists = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
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
                color: Colors.redAccent,
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
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyLogin()),
                ),
                child: const Text("Go Back to Login"),
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
            child: Container(color: Colors.black.withOpacity(0.40)),
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

                      // ── PHARMACY MANAGEMENT ───
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

                      // ── MONITORING ────────────
                      _section("📊 Monitoring & Audit"),
                      _tile(
                        context,
                        "Violation Logs",
                        Icons.report,
                        subtitle: "View flagged violations",
                        color: Colors.redAccent,
                      ),
                      _tile(
                        context,
                        "Suspicious Activity",
                        Icons.warning,
                        subtitle: "Monitor unusual patterns",
                        color: Colors.orange,
                      ),
                      _tile(
                        context,
                        "Audit Reports",
                        Icons.description,
                        subtitle: "Full compliance reports",
                        color: Colors.purple,
                      ),

                      const SizedBox(height: 12),

                      // ── COMPLIANCE ────────────
                      _section("🏥 Compliance & Verification"),
                      _tile(
                        context,
                        "Pharmacy Verification",
                        Icons.verified,
                        subtitle: "Verify pharmacy licenses",
                        color: Colors.teal,
                      ),
                      _tile(
                        context,
                        "Medicine Traceability",
                        Icons.track_changes,
                        subtitle: "Track medicine supply chain",
                        color: Colors.cyan,
                      ),
                      _tile(
                        context,
                        "Stock Authenticity Check",
                        Icons.fact_check,
                        subtitle: "Verify stock authenticity",
                        color: Colors.amber,
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

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "GuardianPharma",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MyLogin()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _headerBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield, color: Colors.redAccent),
          SizedBox(width: 10),
          Text(
            "REGULATORY AUTHORITY",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon, {
    String? subtitle,
    Color color = Colors.redAccent,
    VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.10),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
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
          color: onTap != null ? Colors.white70 : Colors.white24,
        ),
        onTap: onTap,
      ),
    );
  }
}

// =========================
// ALL PHARMACIES PAGE
// View, edit, delete, toggle active
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
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
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
      final bool current = p['is_active'] == true;
      await supabase
          .from('pharmacies')
          .update({'is_active': !current})
          .eq('id', p['id']);
      _loadPharmacies();
      _success(current ? "Pharmacy deactivated" : "Pharmacy activated");
    } catch (e) {
      _error("Error: $e");
    }
  }

  Future<void> _deletePharmacy(Map<String, dynamic> p) async {
    final confirm = await showDialog<bool>(
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
    if (confirm != true) return;
    try {
      await supabase.from('pharmacies').delete().eq('id', p['id']);
      _success("Pharmacy deleted!");
      _loadPharmacies();
    } catch (e) {
      _error("Delete failed: $e");
    }
  }

  void _showEditDialog(Map<String, dynamic> p) {
    final nameController = TextEditingController(text: p['name'] ?? '');
    final licenseController = TextEditingController(
      text: p['license_number'] ?? '',
    );
    final addressController = TextEditingController(text: p['address'] ?? '');
    final phoneController = TextEditingController(text: p['phone'] ?? '');
    final ownerController = TextEditingController(text: p['owner_name'] ?? '');

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
              _field(nameController, "Pharmacy Name", Icons.store),
              const SizedBox(height: 10),
              _field(licenseController, "License Number", Icons.badge),
              const SizedBox(height: 10),
              _field(addressController, "Address", Icons.location_on),
              const SizedBox(height: 10),
              _field(phoneController, "Phone", Icons.phone),
              const SizedBox(height: 10),
              _field(ownerController, "Owner Name", Icons.person),
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
                      'name': nameController.text.trim(),
                      'license_number': licenseController.text.trim(),
                      'address': addressController.text.trim().isEmpty
                          ? null
                          : addressController.text.trim(),
                      'phone': phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      'owner_name': ownerController.text.trim().isEmpty
                          ? null
                          : ownerController.text.trim(),
                    })
                    .eq('id', p['id']);
                if (mounted) Navigator.pop(context);
                _loadPharmacies();
                _success("Pharmacy updated!");
              } catch (e) {
                _error("Update failed: $e");
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return TextField(
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
  }

  void _error(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _success(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

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
                // TOP BAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.store, color: Colors.white),
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
                        onPressed: _loadPharmacies,
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
                        ).then((_) => _loadPharmacies()),
                      ),
                    ],
                  ),
                ),

                // SUMMARY
                if (!loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _statCard(
                          "Total",
                          "${pharmacies.length}",
                          Colors.white70,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          "Active",
                          "${pharmacies.where((p) => p['is_active'] == true).length}",
                          Colors.greenAccent,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          "Inactive",
                          "${pharmacies.where((p) => p['is_active'] != true).length}",
                          Colors.redAccent,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // LIST
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
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
                            final bool isActive = p['is_active'] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.greenAccent.withOpacity(0.3)
                                      : Colors.redAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isActive
                                            ? Colors.greenAccent.withOpacity(
                                                0.2,
                                              )
                                            : Colors.redAccent.withOpacity(0.2),
                                        child: Icon(
                                          Icons.local_pharmacy,
                                          color: isActive
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
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
                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.greenAccent.withOpacity(
                                                  0.15,
                                                )
                                              : Colors.redAccent.withOpacity(
                                                  0.15,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          isActive ? "Active" : "Inactive",
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  const Divider(color: Colors.white12),
                                  const SizedBox(height: 8),

                                  // ACTION BUTTONS
                                  Row(
                                    children: [
                                      // Edit
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
                                          onPressed: () => _showEditDialog(p),
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 16,
                                          ),
                                          label: const Text("Edit"),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Toggle Active
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isActive
                                                ? Colors.orange
                                                : Colors.greenAccent,
                                            side: BorderSide(
                                              color: isActive
                                                  ? Colors.orange
                                                  : Colors.greenAccent,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () => _toggleActive(p),
                                          icon: Icon(
                                            isActive
                                                ? Icons.block
                                                : Icons.check_circle,
                                            size: 16,
                                          ),
                                          label: Text(
                                            isActive
                                                ? "Deactivate"
                                                : "Activate",
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Delete
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
                                        onPressed: () => _deletePharmacy(p),
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

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// ADD PHARMACY PAGE
// Regulatory can add new pharmacies
// =========================
class _AddPharmacyPage extends StatefulWidget {
  const _AddPharmacyPage();

  @override
  State<_AddPharmacyPage> createState() => _AddPharmacyPageState();
}

class _AddPharmacyPageState extends State<_AddPharmacyPage> {
  final supabase = Supabase.instance.client;
  bool saving = false;

  final nameController = TextEditingController();
  final licenseController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final ownerController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    licenseController.dispose();
    addressController.dispose();
    phoneController.dispose();
    ownerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final license = licenseController.text.trim();

    if (name.isEmpty) {
      _error("Pharmacy name is required");
      return;
    }
    if (license.isEmpty) {
      _error("License number is required");
      return;
    }

    setState(() => saving = true);
    try {
      await supabase.from('pharmacies').insert({
        'name': name,
        'license_number': license,
        'address': addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        'owner_name': ownerController.text.trim().isEmpty
            ? null
            : ownerController.text.trim(),
        'is_active': true,
      });
      _success("Pharmacy added successfully!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _error("Failed: $e");
    }
    if (mounted) setState(() => saving = false);
  }

  void _error(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _success(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
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
  }

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
                // TOP BAR
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
                        // INFO
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.greenAccent,
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

                        _field(
                          nameController,
                          "Pharmacy Name *",
                          Icons.local_pharmacy,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          licenseController,
                          "License Number *",
                          Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          addressController,
                          "Address (optional)",
                          Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          phoneController,
                          "Phone Number (optional)",
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          ownerController,
                          "Owner Name (optional)",
                          Icons.person_outline,
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
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
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save, color: Colors.black),
                            label: Text(
                              saving ? "Saving..." : "Add Pharmacy",
                              style: const TextStyle(
                                color: Colors.black,
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
