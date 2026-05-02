import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicineTraceabilityPage extends StatefulWidget {
  const MedicineTraceabilityPage({super.key});

  @override
  State<MedicineTraceabilityPage> createState() =>
      _MedicineTraceabilityPageState();
}

class _MedicineTraceabilityPageState extends State<MedicineTraceabilityPage> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();
  List<Map<String, dynamic>> results = [];
  bool searching = false;
  bool searched = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      searching = true;
      searched = false;
      results = [];
    });

    try {
      final res = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name, country))')
          .or(
            'medicine_name.ilike.%$query%,batch_number.ilike.%$query%,generic_name.ilike.%$query%',
          )
          .order('medicine_name');

      List<Map<String, dynamic>> enriched = [];
      for (final m in List<Map<String, dynamic>>.from(res)) {
        Map<String, dynamic> item = Map<String, dynamic>.from(m);

        if (m['pharmacy_id'] != null) {
          try {
            final pharmacy = await supabase
                .from('pharmacies')
                .select('name, license_number, address')
                .eq('id', m['pharmacy_id'])
                .maybeSingle();
            item['pharmacy_info'] = pharmacy;
          } catch (_) {}
        }
        enriched.add(item);
      }

      setState(() {
        results = enriched;
        searching = false;
        searched = true;
      });
    } catch (e) {
      setState(() {
        searching = false;
        searched = true;
      });
    }
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
                      const Icon(Icons.track_changes, color: Colors.cyan),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Medicine Traceability",
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

                // INFO BOX
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.cyan, size: 14),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Search by medicine name, generic name, or batch number to trace supply chain",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _search(),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            hintText: "Medicine name, batch, generic...",
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.cyan,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: searching
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.white),
                          onPressed: searching ? null : _search,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // RESULTS
                Expanded(
                  child: !searched
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.track_changes,
                                color: Colors.white24,
                                size: 70,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Search to trace medicines",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : results.isEmpty
                      ? const Center(
                          child: Text(
                            "No medicines found",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final m = results[i];
                            final String name =
                                m['medicine_name']?.toString() ?? '';
                            final String generic =
                                m['generic_name']?.toString() ?? '';
                            final String batch =
                                m['batch_number']?.toString() ?? '';
                            final String mfr =
                                m['cartons']?['manufacturers']?['name']
                                    ?.toString() ??
                                'Unknown';
                            final String country =
                                m['cartons']?['manufacturers']?['country']
                                    ?.toString() ??
                                'N/A';
                            final String expiry =
                                m['expiry_date']?.toString() ?? 'N/A';
                            final int qty = (m['quantity'] as int?) ?? 0;
                            final String unit = m['unit']?.toString() ?? '';
                            final String price =
                                m['price']?.toString() ?? 'N/A';

                            // ✅ FIXED CAST
                            final Map<String, dynamic>? pharmacyInfo =
                                m['pharmacy_info'] as Map<String, dynamic>?;

                            final DateTime? expiryDate = DateTime.tryParse(
                              expiry,
                            );
                            final int? daysLeft = expiryDate
                                ?.difference(DateTime.now())
                                .inDays;
                            final bool isExpired =
                                daysLeft != null && daysLeft < 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.cyan.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // MEDICINE NAME
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (generic.isNotEmpty)
                                    Text(
                                      "🧬 $generic",
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 12,
                                      ),
                                    ),

                                  const SizedBox(height: 10),
                                  const Divider(color: Colors.white12),
                                  const SizedBox(height: 6),

                                  // SUPPLY CHAIN
                                  const Text(
                                    "📦 Supply Chain",
                                    style: TextStyle(
                                      color: Colors.cyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _infoRow("🏭 Manufacturer", mfr),
                                  _infoRow("🌍 Country", country),
                                  _infoRow("🔢 Batch", batch),
                                  _infoRow("📦 Qty", "$qty $unit"),
                                  _infoRow("💰 Price", "BDT $price"),
                                  _infoRow(
                                    "📅 Expiry",
                                    isExpired ? "⛔ EXPIRED ($expiry)" : expiry,
                                    valueColor: isExpired
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                  ),

                                  // PHARMACY INFO
                                  if (pharmacyInfo != null) ...[
                                    const SizedBox(height: 10),
                                    const Divider(color: Colors.white12),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "🏥 Pharmacy",
                                      style: TextStyle(
                                        color: Colors.cyan,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _infoRow(
                                      "Name",
                                      pharmacyInfo['name']?.toString() ?? 'N/A',
                                    ),
                                    _infoRow(
                                      "License",
                                      pharmacyInfo['license_number']
                                              ?.toString() ??
                                          'N/A',
                                    ),
                                    _infoRow(
                                      "Address",
                                      pharmacyInfo['address']?.toString() ??
                                          'N/A',
                                    ),
                                  ],
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
