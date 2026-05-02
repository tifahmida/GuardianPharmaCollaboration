import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PharmacyVerificationPage extends StatefulWidget {
  const PharmacyVerificationPage({super.key});

  @override
  State<PharmacyVerificationPage> createState() =>
      _PharmacyVerificationPageState();
}

class _PharmacyVerificationPageState extends State<PharmacyVerificationPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> pharmacies = [];
  bool loading = true;

  String selectedFilter = 'Pending';
  final List<String> filters = ['Pending', 'Verified', 'Rejected', 'All'];

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  // ===============================
  // LOAD PHARMACIES
  // ===============================
  Future<void> _loadPharmacies() async {
    setState(() => loading = true);

    try {
      final res = await supabase
          .from('pharmacies')
          .select()
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> all = List<Map<String, dynamic>>.from(res);

      if (selectedFilter == 'Pending') {
        all = all.where((p) => p['is_verified'] == null).toList();
      } else if (selectedFilter == 'Verified') {
        all = all.where((p) => p['is_verified'] == true).toList();
      } else if (selectedFilter == 'Rejected') {
        all = all.where((p) => p['is_verified'] == false).toList();
      }

      setState(() {
        pharmacies = all;
        loading = false;
      });
    } catch (e) {
      _error("Failed to load pharmacies");
      setState(() => loading = false);
    }
  }

  // ===============================
  // APPROVE / REJECT
  // ===============================
  Future<void> _verify(Map<String, dynamic> p, bool approve) async {
    final action = approve ? "Approve" : "Reject";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          "$action Pharmacy",
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          "$action \"${p['name']}\"?",
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
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.greenAccent : Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              action,
              style: TextStyle(color: approve ? Colors.black : Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('pharmacies')
          .update({'is_verified': approve})
          .eq('id', p['id']);

      _success(
        approve ? "Pharmacy approved successfully" : "Pharmacy rejected",
      );

      _loadPharmacies();
    } catch (e) {
      _error("Failed to update status");
    }
  }

  // ===============================
  // CANCEL VERIFICATION
  // Back to Pending
  // ===============================
  Future<void> _cancelVerification(Map<String, dynamic> p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Cancel Verification",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Move \"${p['name']}\" back to Pending status?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('pharmacies')
          .update({'is_verified': null})
          .eq('id', p['id']);

      _success("Verification cancelled");

      _loadPharmacies();
    } catch (e) {
      _error("Failed to cancel verification");
    }
  }

  void _success(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _error(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ===============================
  // UI
  // ===============================
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
                // HEADER
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.verified, color: Colors.teal),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Pharmacy Verification",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _loadPharmacies,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // FILTERS
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filters.length,
                    itemBuilder: (_, i) {
                      final f = filters[i];
                      final selected = selectedFilter == f;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter = f;
                          });
                          _loadPharmacies();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.teal
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // LIST
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        )
                      : pharmacies.isEmpty
                      ? const Center(
                          child: Text(
                            "No pharmacies found",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: pharmacies.length,
                          itemBuilder: (_, i) {
                            final p = pharmacies[i];

                            final bool isVerified = p['is_verified'] == true;

                            final bool isRejected = p['is_verified'] == false;

                            final bool isPending = p['is_verified'] == null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    "License: ${p['license_number'] ?? 'N/A'}",
                                    style: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isVerified
                                          ? Colors.teal.withOpacity(0.2)
                                          : isRejected
                                          ? Colors.red.withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isVerified
                                          ? "✅ Verified"
                                          : isRejected
                                          ? "❌ Rejected"
                                          : "⏳ Pending",
                                      style: TextStyle(
                                        color: isVerified
                                            ? Colors.teal
                                            : isRejected
                                            ? Colors.redAccent
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // ACTIONS
                                  if (isPending)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.greenAccent,
                                            ),
                                            onPressed: () => _verify(p, true),
                                            child: const Text(
                                              "Approve",
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                            ),
                                            onPressed: () => _verify(p, false),
                                            child: const Text(
                                              "Reject",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  if (isVerified || isRejected)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.orange,
                                          side: const BorderSide(
                                            color: Colors.orange,
                                          ),
                                        ),
                                        onPressed: () => _cancelVerification(p),
                                        icon: const Icon(Icons.undo),
                                        label: const Text(
                                          "Cancel Verification",
                                        ),
                                      ),
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
