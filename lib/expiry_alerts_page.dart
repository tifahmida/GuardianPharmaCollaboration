import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpiryAlertsPage extends StatefulWidget {
  const ExpiryAlertsPage({super.key});

  @override
  State<ExpiryAlertsPage> createState() => _ExpiryAlertsPageState();
}

class _ExpiryAlertsPageState extends State<ExpiryAlertsPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> expiredMedicines = [];
  List<Map<String, dynamic>> expiringSoonMedicines = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadExpiryData();
  }

  // =========================
  // LOAD EXPIRY DATA
  // =========================
  Future<void> _loadExpiryData() async {
    setState(() => loading = true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final in30Days = today.add(const Duration(days: 30));

      // Format dates for Supabase query
      final String todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final String in30DaysStr =
          "${in30Days.year}-${in30Days.month.toString().padLeft(2, '0')}-${in30Days.day.toString().padLeft(2, '0')}";

      // Fetch expired medicines
      final expiredRes = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name))')
          .lt('expiry_date', todayStr)
          .order('expiry_date', ascending: true);

      // Fetch expiring soon medicines (within 30 days)
      final expiringSoonRes = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name))')
          .gte('expiry_date', todayStr)
          .lte('expiry_date', in30DaysStr)
          .order('expiry_date', ascending: true);

      setState(() {
        expiredMedicines = List<Map<String, dynamic>>.from(expiredRes);
        expiringSoonMedicines = List<Map<String, dynamic>>.from(
          expiringSoonRes,
        );
        loading = false;
      });
    } catch (e) {
      _error("Failed to load expiry data: $e");
      setState(() => loading = false);
    }
  }

  // =========================
  // EXPIRED MEDICINE WARNING DIALOG
  // shown before selling expired medicine
  // =========================
  void _showExpiredWarning(Map<String, dynamic> medicine) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text(
              "⛔ Expired Medicine!",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${medicine['medicine_name']}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            _warningRow("Batch", medicine['batch_number']),
            _warningRow("Expired On", medicine['expiry_date']),
            _warningRow(
              "Qty in Stock",
              "${medicine['quantity']} ${medicine['unit'] ?? ''}",
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: const Text(
                "⚠️ This medicine is expired and should NOT be sold. Please remove it from stock immediately.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK, Got it",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _error(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  // =========================
  // MEDICINE CARD
  // =========================
  Widget _medicineCard(Map<String, dynamic> medicine, bool isExpired) {
    final String name = medicine['medicine_name']?.toString() ?? '';
    final String batch = medicine['batch_number']?.toString() ?? '';
    final String expiry = medicine['expiry_date']?.toString() ?? '';
    final int qty = (medicine['quantity'] as int?) ?? 0;
    final String unit = medicine['unit']?.toString() ?? '';
    final String manufacturer =
        medicine['cartons']?['manufacturers']?['name']?.toString() ?? 'Unknown';

    final DateTime? expiryDate = DateTime.tryParse(expiry);
    final int daysLeft = expiryDate != null
        ? expiryDate.difference(DateTime.now()).inDays
        : 0;

    final Color cardColor = isExpired
        ? Colors.red.withOpacity(0.15)
        : Colors.orange.withOpacity(0.12);
    final Color borderColor = isExpired
        ? Colors.redAccent.withOpacity(0.5)
        : Colors.orange.withOpacity(0.5);
    final Color accentColor = isExpired ? Colors.redAccent : Colors.orange;

    return GestureDetector(
      onTap: isExpired ? () => _showExpiredWarning(medicine) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isExpired ? Icons.cancel : Icons.warning_amber_rounded,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine name
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Manufacturer
                  Text(
                    "🏭 $manufacturer",
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 4),

                  // Batch + Qty
                  Row(
                    children: [
                      _infoChip("Batch: $batch", Colors.white24),
                      const SizedBox(width: 6),
                      _infoChip("Qty: $qty $unit", Colors.white24),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Expiry status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      isExpired
                          ? "⛔ EXPIRED on $expiry"
                          : "⚠️ Expires in $daysLeft days ($expiry)",
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Tap hint for expired
                  if (isExpired) ...[
                    const SizedBox(height: 6),
                    const Text(
                      "Tap to see warning",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }

  // =========================
  // SECTION HEADER
  // =========================
  Widget _sectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              "$count",
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
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
                // ── TOP BAR ──────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Expiry Alerts",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadExpiryData,
                      ),
                    ],
                  ),
                ),

                // ── SUMMARY BAR ───────────────────────
                if (!loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Expired count
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.4),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "${expiredMedicines.length}",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "⛔ Expired",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Expiring soon count
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.4),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "${expiringSoonMedicines.length}",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "⚠️ Expiring Soon",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // ── CONTENT ───────────────────────────
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        )
                      : expiredMedicines.isEmpty &&
                            expiringSoonMedicines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                                size: 70,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "All medicines are good! ✅",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "No expired or expiring soon medicines found.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // EXPIRED SECTION
                            if (expiredMedicines.isNotEmpty) ...[
                              _sectionHeader(
                                "⛔ Expired Medicines",
                                expiredMedicines.length,
                                Colors.redAccent,
                              ),
                              ...expiredMedicines.map(
                                (m) => _medicineCard(m, true),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // EXPIRING SOON SECTION
                            if (expiringSoonMedicines.isNotEmpty) ...[
                              _sectionHeader(
                                "⚠️ Expiring Soon (within 30 days)",
                                expiringSoonMedicines.length,
                                Colors.orange,
                              ),
                              ...expiringSoonMedicines.map(
                                (m) => _medicineCard(m, false),
                              ),
                            ],

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
}
