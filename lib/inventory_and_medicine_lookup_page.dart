import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/pharmacy_wrapper_page.dart';

class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allMedicines = [];
  List<Map<String, dynamic>> filteredMedicines = [];
  bool loading = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInventory();
    searchController.addListener(_filterMedicines);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ✅ Scoped to current pharmacy
  Future<void> _loadInventory() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name, country))')
          .eq('pharmacy_id', PharmacySession.pharmacyId ?? '')
          .order('medicine_name');

      setState(() {
        allMedicines = List<Map<String, dynamic>>.from(res);
        filteredMedicines = allMedicines;
        loading = false;
      });
    } catch (e) {
      _error("Failed to load inventory: $e");
      setState(() => loading = false);
    }
  }

  void _filterMedicines() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredMedicines = allMedicines.where((m) {
        final name = (m['medicine_name'] ?? '').toString().toLowerCase();
        final generic = (m['generic_name'] ?? '').toString().toLowerCase();
        final batch = (m['batch_number'] ?? '').toString().toLowerCase();
        final manufacturer = (m['cartons']?['manufacturers']?['name'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(query) ||
            generic.contains(query) ||
            batch.contains(query) ||
            manufacturer.contains(query);
      }).toList();
    });
  }

  Color _stockColor(int qty) {
    if (qty <= 0) return Colors.redAccent;
    if (qty <= 10) return Colors.orange;
    return Colors.greenAccent;
  }

  String _stockLabel(int qty) {
    if (qty <= 0) return "Out of Stock";
    if (qty <= 10) return "Low Stock";
    return "In Stock";
  }

  IconData _stockIcon(int qty) {
    if (qty <= 0) return Icons.remove_circle;
    if (qty <= 10) return Icons.warning_amber;
    return Icons.check_circle;
  }

  void _showMedicineLookup(Map<String, dynamic> m) {
    final int qty = (m['quantity'] as int?) ?? 0;
    final String name = m['medicine_name']?.toString() ?? '';
    final String generic = m['generic_name']?.toString() ?? '';
    final String batch = m['batch_number']?.toString() ?? '';
    final String unit = m['unit']?.toString() ?? '';
    final String manufacturer =
        m['cartons']?['manufacturers']?['name']?.toString() ?? 'Unknown';
    final String country =
        m['cartons']?['manufacturers']?['country']?.toString() ?? 'N/A';
    final String expiry = m['expiry_date']?.toString() ?? 'N/A';
    final double price = double.tryParse(m['price'].toString()) ?? 0.0;
    final double? pricePerStrip = m['price_per_strip'] != null
        ? double.tryParse(m['price_per_strip'].toString())
        : null;
    final int stripsPerBox = (m['strips_per_box'] as int?) ?? 10;
    final DateTime? expiryDate = DateTime.tryParse(expiry);
    final int? daysLeft = expiryDate?.difference(DateTime.now()).inDays;
    final bool isExpired = daysLeft != null && daysLeft < 0;
    final bool isExpiringSoon =
        daysLeft != null && daysLeft <= 30 && daysLeft >= 0;

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
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _stockColor(qty).withOpacity(0.2),
                    radius: 24,
                    child: Icon(
                      Icons.medication,
                      color: _stockColor(qty),
                      size: 24,
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (generic.isNotEmpty)
                          Text(
                            generic,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _stockColor(qty).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _stockColor(qty).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _stockIcon(qty),
                          color: _stockColor(qty),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _stockLabel(qty),
                          style: TextStyle(
                            color: _stockColor(qty),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              _lookupSection("🏭 Manufacturer Information"),
              _lookupRow("Name", manufacturer),
              _lookupRow("Country", country),
              const SizedBox(height: 12),
              _lookupSection("💊 Medicine Information"),
              _lookupRow("Medicine Name", name),
              if (generic.isNotEmpty) _lookupRow("Generic Name", generic),
              _lookupRow("Batch Number", batch),
              _lookupRow("Unit Type", unit),
              const SizedBox(height: 12),
              _lookupSection("📦 Stock Information"),
              _lookupRow(
                "Quantity",
                "$qty $unit",
                valueColor: _stockColor(qty),
              ),
              _lookupRow("Strips per Box", stripsPerBox.toString()),
              const SizedBox(height: 12),
              _lookupSection("💰 Pricing"),
              _lookupRow("Price per Box", "BDT ${price.toStringAsFixed(2)}"),
              if (pricePerStrip != null)
                _lookupRow(
                  "Price per Strip",
                  "BDT ${pricePerStrip.toStringAsFixed(2)}",
                ),
              const SizedBox(height: 12),
              _lookupSection("📅 Expiry Information"),
              _lookupRow(
                "Expiry Date",
                isExpired
                    ? "⛔ EXPIRED ($expiry)"
                    : isExpiringSoon
                    ? "⚠️ Expires in $daysLeft days ($expiry)"
                    : "✅ $expiry",
                valueColor: isExpired
                    ? Colors.redAccent
                    : isExpiringSoon
                    ? Colors.orange
                    : Colors.greenAccent,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _lookupSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _lookupRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
              style: TextStyle(
                color: valueColor ?? Colors.white,
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

  int get _outOfStock =>
      allMedicines.where((m) => (m['quantity'] as int? ?? 0) <= 0).length;
  int get _lowStock => allMedicines
      .where(
        (m) =>
            (m['quantity'] as int? ?? 0) > 0 &&
            (m['quantity'] as int? ?? 0) <= 10,
      )
      .length;
  int get _goodStock =>
      allMedicines.where((m) => (m['quantity'] as int? ?? 0) > 10).length;

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
                      const Icon(Icons.inventory, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Inventory & Medicine Lookup",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadInventory,
                      ),
                    ],
                  ),
                ),

                // Pharmacy label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_pharmacy,
                          color: Colors.blueAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          PharmacySession.pharmacyName ?? 'Your Pharmacy',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
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
                      hintText: "Search name, generic, batch, manufacturer...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                searchController.clear();
                                _filterMedicines();
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
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
                            "Tap any medicine card to view full details & lookup info",
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

                if (!loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _summaryChip(
                          "✅ Good",
                          _goodStock.toString(),
                          Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        _summaryChip(
                          "⚠️ Low",
                          _lowStock.toString(),
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _summaryChip(
                          "❌ Out",
                          _outOfStock.toString(),
                          Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        _summaryChip(
                          "📦 Total",
                          allMedicines.length.toString(),
                          Colors.blueAccent,
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
                      : filteredMedicines.isEmpty
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
                                    ? "No medicines in inventory"
                                    : "No results for \"${searchController.text}\"",
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredMedicines.length,
                          itemBuilder: (_, i) {
                            final m = filteredMedicines[i];
                            final int qty = (m['quantity'] as int?) ?? 0;
                            final String name =
                                m['medicine_name']?.toString() ?? '';
                            final String generic =
                                m['generic_name']?.toString() ?? '';
                            final String batch =
                                m['batch_number']?.toString() ?? '';
                            final String unit = m['unit']?.toString() ?? '';
                            final String manufacturer =
                                m['cartons']?['manufacturers']?['name']
                                    ?.toString() ??
                                'Unknown';
                            final String expiry =
                                m['expiry_date']?.toString() ?? 'N/A';
                            final double price =
                                double.tryParse(m['price'].toString()) ?? 0.0;
                            final DateTime? expiryDate = DateTime.tryParse(
                              expiry,
                            );
                            final int? daysLeft = expiryDate
                                ?.difference(DateTime.now())
                                .inDays;
                            final bool isExpired =
                                daysLeft != null && daysLeft < 0;
                            final bool isExpiringSoon =
                                daysLeft != null &&
                                daysLeft <= 30 &&
                                daysLeft >= 0;

                            return GestureDetector(
                              onTap: () => _showMedicineLookup(m),
                              child: Card(
                                color: Colors.white.withOpacity(
                                  qty <= 0 ? 0.05 : 0.10,
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: _stockColor(qty).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _stockColor(
                                                qty,
                                              ).withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _stockColor(
                                                  qty,
                                                ).withOpacity(0.5),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _stockIcon(qty),
                                                  color: _stockColor(qty),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _stockLabel(qty),
                                                  style: TextStyle(
                                                    color: _stockColor(qty),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(color: Colors.white12),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _detailItem(
                                              "🏭 Manufacturer",
                                              manufacturer,
                                            ),
                                          ),
                                          Expanded(
                                            child: _detailItem(
                                              "🔢 Batch",
                                              batch,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _detailItem(
                                              "📦 Quantity",
                                              "$qty $unit",
                                              valueColor: _stockColor(qty),
                                            ),
                                          ),
                                          Expanded(
                                            child: _detailItem(
                                              "💰 Price/Box",
                                              "BDT ${price.toStringAsFixed(2)}",
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _detailItem(
                                              "📅 Expiry",
                                              isExpired
                                                  ? "⛔ EXPIRED"
                                                  : isExpiringSoon
                                                  ? "⚠️ $daysLeft days"
                                                  : expiry,
                                              valueColor: isExpired
                                                  ? Colors.redAccent
                                                  : isExpiringSoon
                                                  ? Colors.orange
                                                  : Colors.greenAccent,
                                            ),
                                          ),
                                          Expanded(
                                            child: _detailItem(
                                              "💊 Strips/Box",
                                              "${m['strips_per_box'] ?? 10}",
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.white24,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Tap for full details",
                                            style: TextStyle(
                                              color: Colors.white24,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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

  Widget _detailItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, String count, Color color) {
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
              count,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
