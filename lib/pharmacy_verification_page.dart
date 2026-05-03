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
    _load();
  }

  // =========================
  // HELPER — get status
  // avoids repeated null checks
  // =========================
  String _status(Map<String, dynamic> p) {
    final val = p['is_verified'];
    if (val == true) return 'verified';
    if (val == false) return 'rejected';
    return 'pending';
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('pharmacies')
          .select()
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> all = List<Map<String, dynamic>>.from(res);

      if (selectedFilter == 'Pending') {
        all = all.where((p) => _status(p) == 'pending').toList();
      } else if (selectedFilter == 'Verified') {
        all = all.where((p) => _status(p) == 'verified').toList();
      } else if (selectedFilter == 'Rejected') {
        all = all.where((p) => _status(p) == 'rejected').toList();
      }

      setState(() {
        pharmacies = all;
        loading = false;
      });
    } catch (e) {
      _err("Failed to load pharmacies");
      setState(() => loading = false);
    }
  }

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
          "$action \"${p['name']}\"?\n\n"
          "${approve ? '✅ This pharmacy will be marked as verified.' : '❌ This pharmacy will be marked as rejected.'}",
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
              style: TextStyle(
                color: approve ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
      _ok(approve ? "✅ Pharmacy approved!" : "❌ Pharmacy rejected");
      _load();
    } catch (e) {
      _err("Failed to update status");
    }
  }

  Future<void> _cancelVerification(Map<String, dynamic> p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Reset to Pending",
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
            child: const Text(
              "Yes, Reset",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // ✅ set to null = pending
      await supabase
          .from('pharmacies')
          .update({'is_verified': null})
          .eq('id', p['id']);
      _ok("Status reset to Pending");
      _load();
    } catch (e) {
      _err("Failed to reset status");
    }
  }

  Color _filterColor(String f) {
    switch (f) {
      case 'Verified':
        return Colors.tealAccent;
      case 'Rejected':
        return Colors.redAccent;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.blueAccent;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.tealAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'verified':
        return '✅ Verified';
      case 'rejected':
        return '❌ Rejected';
      default:
        return '⏳ Pending';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.pending_outlined;
    }
  }

  int _count(String type) {
    switch (type) {
      case 'Pending':
        return pharmacies.where((p) => _status(p) == 'pending').length;
      case 'Verified':
        return pharmacies.where((p) => _status(p) == 'verified').length;
      case 'Rejected':
        return pharmacies.where((p) => _status(p) == 'rejected').length;
      default:
        return pharmacies.length;
    }
  }

  void _ok(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  void _err(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(
                        Icons.verified,
                        color: Colors.tealAccent,
                        size: 24,
                      ),
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
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        onPressed: _load,
                      ),
                    ],
                  ),
                ),

                // SUMMARY STATS
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
                        const SizedBox(width: 8),
                        _statCard(
                          "Pending",
                          "${_count('Pending')}",
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _statCard(
                          "Verified",
                          "${_count('Verified')}",
                          Colors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        _statCard(
                          "Rejected",
                          "${_count('Rejected')}",
                          Colors.redAccent,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // FILTER CHIPS
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filters.length,
                    itemBuilder: (_, i) {
                      final f = filters[i];
                      final isSelected = selectedFilter == f;
                      final color = _filterColor(f);
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedFilter = f);
                          _load();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.25)
                                : Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: isSelected ? color : Colors.white60,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // LIST
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.tealAccent,
                          ),
                        )
                      : pharmacies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                color: _filterColor(
                                  selectedFilter,
                                ).withOpacity(0.4),
                                size: 64,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No $selectedFilter pharmacies",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: pharmacies.length,
                          itemBuilder: (_, i) {
                            final p = pharmacies[i];

                            // ✅ use helper — no yellow warnings
                            final String status = _status(p);
                            final Color statusColor = _statusColor(status);
                            final String statusLabel = _statusLabel(status);
                            final IconData statusIcon = _statusIcon(status);
                            final bool isPending = status == 'pending';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // PHARMACY INFO
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(
                                              0.15,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: statusColor.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            statusIcon,
                                            color: statusColor,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p['name']?.toString() ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                "🪪 ${p['license_number'] ?? 'N/A'}",
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if ((p['owner_name']
                                                          ?.toString() ??
                                                      '')
                                                  .isNotEmpty)
                                                Text(
                                                  "👤 ${p['owner_name']}",
                                                  style: const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              if ((p['address']?.toString() ??
                                                      '')
                                                  .isNotEmpty)
                                                Text(
                                                  "📍 ${p['address']}",
                                                  style: const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // STATUS BADGE
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: statusColor.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Divider(
                                    color: Colors.white12,
                                    height: 1,
                                  ),

                                  // ACTION BUTTONS
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: isPending
                                        ? Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.greenAccent,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _verify(p, true),
                                                  icon: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.black,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    "Approve",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.redAccent,
                                                    side: const BorderSide(
                                                      color: Colors.redAccent,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _verify(p, false),
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    "Reject",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.orange,
                                                side: const BorderSide(
                                                  color: Colors.orange,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _cancelVerification(p),
                                              icon: const Icon(
                                                Icons.undo,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                "Reset to Pending",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
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

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
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
              value,
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
  }
}
