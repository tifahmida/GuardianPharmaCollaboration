// ============================================================
// fefo_system_page.dart  –  pharmacy-scoped
// ============================================================
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/pharmacy_wrapper_page.dart';

class FefoSystemPage extends StatefulWidget {
  const FefoSystemPage({super.key});

  @override
  State<FefoSystemPage> createState() => _FefoSystemPageState();
}

class _FefoSystemPageState extends State<FefoSystemPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> fefoMedicines = [];
  bool loading = true;
  String searchQuery = '';
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFefoData();
    searchController.addListener(() {
      setState(() => searchQuery = searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ✅ Scoped to current pharmacy
  Future<void> _loadFefoData() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name))')
          .eq('pharmacy_id', PharmacySession.pharmacyId ?? '')
          .gt('quantity', 0)
          .order('expiry_date', ascending: true);

      setState(() {
        fefoMedicines = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      _error("Failed to load FEFO data: $e");
      setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get filteredMedicines {
    if (searchQuery.isEmpty) return fefoMedicines;
    return fefoMedicines.where((m) {
      final String name = (m['medicine_name'] ?? '').toString().toLowerCase();
      final String generic = (m['generic_name'] ?? '').toString().toLowerCase();
      final String batch = (m['batch_number'] ?? '').toString().toLowerCase();
      final String mfr = (m['cartons']?['manufacturers']?['name'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(searchQuery) ||
          generic.contains(searchQuery) ||
          batch.contains(searchQuery) ||
          mfr.contains(searchQuery);
    }).toList();
  }

  Map<String, dynamic> _getStatus(String expiryStr) {
    final DateTime? expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) {
      return {
        'label': 'Unknown',
        'color': Colors.grey,
        'icon': Icons.help_outline,
        'priority': 99,
        'daysLeft': 0,
      };
    }
    final int daysLeft = expiry.difference(DateTime.now()).inDays;
    if (daysLeft < 0) {
      return {
        'label': 'EXPIRED',
        'color': Colors.redAccent,
        'icon': Icons.cancel,
        'priority': 1,
        'daysLeft': daysLeft,
      };
    } else if (daysLeft <= 7) {
      return {
        'label': 'Critical ($daysLeft days)',
        'color': Colors.red,
        'icon': Icons.warning_rounded,
        'priority': 2,
        'daysLeft': daysLeft,
      };
    } else if (daysLeft <= 30) {
      return {
        'label': 'Expiring Soon ($daysLeft days)',
        'color': Colors.orange,
        'icon': Icons.warning_amber,
        'priority': 3,
        'daysLeft': daysLeft,
      };
    } else if (daysLeft <= 90) {
      return {
        'label': 'Use Soon ($daysLeft days)',
        'color': Colors.yellow,
        'icon': Icons.info_outline,
        'priority': 4,
        'daysLeft': daysLeft,
      };
    } else {
      return {
        'label': 'Good ($daysLeft days)',
        'color': Colors.greenAccent,
        'icon': Icons.check_circle,
        'priority': 5,
        'daysLeft': daysLeft,
      };
    }
  }

  void _showFefoDetail(
    Map<String, dynamic> medicine,
    Map<String, dynamic> status,
  ) {
    final String name = medicine['medicine_name']?.toString() ?? '';
    final String generic = medicine['generic_name']?.toString() ?? '';
    final String batch = medicine['batch_number']?.toString() ?? '';
    final String expiry = medicine['expiry_date']?.toString() ?? '';
    final int qty = (medicine['quantity'] as int?) ?? 0;
    final String unit = medicine['unit']?.toString() ?? '';
    final String manufacturer =
        medicine['cartons']?['manufacturers']?['name']?.toString() ?? 'Unknown';
    final double price = double.tryParse(medicine['price'].toString()) ?? 0.0;
    final int stripsPerBox = (medicine['strips_per_box'] as int?) ?? 10;
    final int daysLeft = (status['daysLeft'] as int?) ?? 0;
    final Color color = status['color'] as Color;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    radius: 26,
                    child: Icon(
                      status['icon'] as IconData,
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (generic.isNotEmpty)
                          Text(
                            generic,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      status['label'] as String,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysLeft < 0
                          ? "This medicine is expired and must NOT be dispensed!"
                          : daysLeft <= 7
                          ? "⚠️ Dispense this IMMEDIATELY — critically close to expiry!"
                          : daysLeft <= 30
                          ? "Dispense this medicine before newer stock"
                          : daysLeft <= 90
                          ? "Use this before newer batches of the same medicine"
                          : "This medicine is in good condition",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              _detailRow("🏭 Manufacturer", manufacturer),
              _detailRow("🔢 Batch Number", batch),
              _detailRow("📦 Quantity", "$qty $unit"),
              _detailRow("💊 Strips per Box", "$stripsPerBox"),
              _detailRow("💰 Price per Box", "BDT ${price.toStringAsFixed(2)}"),
              _detailRow("📅 Expiry Date", expiry),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📋 FEFO Rule",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "First Expiry First Out — Always dispense the medicine with the earliest expiry date first, regardless of when it was received.",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _error(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> medicines = filteredMedicines;

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
                      const Icon(Icons.autorenew, color: Colors.greenAccent),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "FEFO System",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadFefoData,
                      ),
                    ],
                  ),
                ),

                // Pharmacy + info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "FEFO for ${PharmacySession.pharmacyName ?? 'Your Pharmacy'} — sorted by earliest expiry. Dispense from the top.",
                            style: const TextStyle(
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      hintText: "Search medicine, batch, manufacturer...",
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

                const SizedBox(height: 10),

                if (!loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _legendChip("⛔ Expired", Colors.redAccent),
                          const SizedBox(width: 6),
                          _legendChip("🔴 Critical (≤7d)", Colors.red),
                          const SizedBox(width: 6),
                          _legendChip("🟠 Soon (≤30d)", Colors.orange),
                          const SizedBox(width: 6),
                          _legendChip("🟡 Use Soon (≤90d)", Colors.yellow),
                          const SizedBox(width: 6),
                          _legendChip("✅ Good", Colors.greenAccent),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                          ),
                        )
                      : medicines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white24,
                                size: 60,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                searchController.text.isEmpty
                                    ? "No medicines in stock"
                                    : "No results for \"${searchController.text}\"",
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: medicines.length,
                          itemBuilder: (_, int i) {
                            final Map<String, dynamic> m = medicines[i];
                            final String expiry =
                                m['expiry_date']?.toString() ?? '';
                            final Map<String, dynamic> status = _getStatus(
                              expiry,
                            );
                            final Color color = status['color'] as Color;
                            final String name =
                                m['medicine_name']?.toString() ?? '';
                            final String generic =
                                m['generic_name']?.toString() ?? '';
                            final String batch =
                                m['batch_number']?.toString() ?? '';
                            final int qty = (m['quantity'] as int?) ?? 0;
                            final String unit = m['unit']?.toString() ?? '';
                            final String manufacturer =
                                m['cartons']?['manufacturers']?['name']
                                    ?.toString() ??
                                'Unknown';

                            return GestureDetector(
                              onTap: () => _showFefoDetail(m, status),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: color.withOpacity(0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: color.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${i + 1}",
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (generic.isNotEmpty)
                                            Text(
                                              generic,
                                              style: const TextStyle(
                                                color: Colors.blueAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "🏭 $manufacturer  |  Batch: $batch",
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            "📦 Qty: $qty $unit",
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: color.withOpacity(0.4),
                                              ),
                                            ),
                                            child: Text(
                                              status['label'] as String,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: color.withOpacity(0.5),
                                      size: 14,
                                    ),
                                  ],
                                ),
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

  Widget _legendChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
