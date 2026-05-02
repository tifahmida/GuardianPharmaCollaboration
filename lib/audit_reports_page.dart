import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditReportsPage extends StatefulWidget {
  const AuditReportsPage({super.key});

  @override
  State<AuditReportsPage> createState() => _AuditReportsPageState();
}

class _AuditReportsPageState extends State<AuditReportsPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;

  int totalPharmacies = 0;
  int verifiedPharmacies = 0;
  int activePharmacies = 0;
  int monthlyViolations = 0;
  int totalViolations = 0;
  int criticalViolations = 0;
  int suspiciousCount = 0;
  int expiredStockCount = 0;
  int totalMedicines = 0;
  int totalSalesThisMonth = 0;
  double totalRevenueThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => loading = true);
    try {
      final now = DateTime.now().toUtc();
      final monthStart = DateTime.utc(now.year, now.month, 1);
      final today = DateTime.utc(now.year, now.month, now.day);

      // Pharmacies
      final pharmaciesRes = await supabase
          .from('pharmacies')
          .select('is_verified, is_active');
      final List pList = List<Map<String, dynamic>>.from(pharmaciesRes);

      // Violations
      final violationsRes = await supabase
          .from('violation_logs')
          .select('severity, created_at');
      final List vList = List<Map<String, dynamic>>.from(violationsRes);

      // Suspicious
      final suspRes = await supabase.from('suspicious_logs').select('id');

      // Expired medicines
      final expiredRes = await supabase
          .from('medicine_boxes')
          .select('id')
          .lt('expiry_date', today.toIso8601String().split('T')[0]);

      // Total medicines
      final medicinesRes = await supabase.from('medicine_boxes').select('id');

      // Sales this month
      final salesRes = await supabase
          .from('sales')
          .select('total_amount')
          .gte('created_at', monthStart.toIso8601String());
      final List sList = List<Map<String, dynamic>>.from(salesRes);

      double rev = 0;
      for (final s in sList) {
        rev += double.tryParse(s['total_amount'].toString()) ?? 0;
      }

      // Monthly violations
      final monthViolations = vList
          .where((v) => DateTime.parse(v['created_at']).isAfter(monthStart))
          .length;

      setState(() {
        totalPharmacies = pList.length;
        verifiedPharmacies = pList
            .where((p) => p['is_verified'] == true)
            .length;
        activePharmacies = pList.where((p) => p['is_active'] == true).length;
        totalViolations = vList.length;
        monthlyViolations = monthViolations;
        criticalViolations = vList
            .where((v) => v['severity'] == 'critical')
            .length;
        suspiciousCount = suspRes.length;
        expiredStockCount = expiredRes.length;
        totalMedicines = medicinesRes.length;
        totalSalesThisMonth = sList.length;
        totalRevenueThisMonth = rev;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
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
                      const Icon(Icons.description, color: Colors.purple),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Audit Reports",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadStats,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.purple,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // PHARMACIES SECTION
                              _sectionHeader(
                                "🏥 Pharmacies",
                                Colors.blueAccent,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _statCard(
                                    "Total",
                                    "$totalPharmacies",
                                    Colors.white70,
                                  ),
                                  const SizedBox(width: 10),
                                  _statCard(
                                    "Active",
                                    "$activePharmacies",
                                    Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  _statCard(
                                    "Verified",
                                    "$verifiedPharmacies",
                                    Colors.blueAccent,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // VIOLATIONS SECTION
                              _sectionHeader("⚠️ Violations", Colors.redAccent),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _statCard(
                                    "Total",
                                    "$totalViolations",
                                    Colors.white70,
                                  ),
                                  const SizedBox(width: 10),
                                  _statCard(
                                    "This Month",
                                    "$monthlyViolations",
                                    Colors.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  _statCard(
                                    "Critical",
                                    "$criticalViolations",
                                    Colors.redAccent,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // SUSPICIOUS
                              _sectionHeader(
                                "🚨 Suspicious Activity",
                                Colors.orange,
                              ),
                              const SizedBox(height: 10),
                              _bigStat(
                                "Total Flagged Records",
                                "$suspiciousCount",
                                Colors.orange,
                                Icons.warning,
                              ),

                              const SizedBox(height: 16),

                              // MEDICINE STOCK
                              _sectionHeader(
                                "💊 Medicine Stock",
                                Colors.greenAccent,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _statCard(
                                    "Total Boxes",
                                    "$totalMedicines",
                                    Colors.white70,
                                  ),
                                  const SizedBox(width: 10),
                                  _statCard(
                                    "Expired",
                                    "$expiredStockCount",
                                    Colors.redAccent,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // SALES
                              _sectionHeader(
                                "💰 Sales This Month",
                                Colors.amber,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _statCard(
                                    "Transactions",
                                    "$totalSalesThisMonth",
                                    Colors.white70,
                                  ),
                                  const SizedBox(width: 10),
                                  _statCard(
                                    "Revenue (BDT)",
                                    totalRevenueThisMonth.toStringAsFixed(0),
                                    Colors.amber,
                                  ),
                                ],
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

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigStat(String label, String value, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
