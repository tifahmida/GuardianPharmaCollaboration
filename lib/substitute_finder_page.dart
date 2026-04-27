import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubstituteFinderPage extends StatefulWidget {
  const SubstituteFinderPage({super.key});

  @override
  State<SubstituteFinderPage> createState() => _SubstituteFinderPageState();
}

class _SubstituteFinderPageState extends State<SubstituteFinderPage> {
  final supabase = Supabase.instance.client;

  final searchController = TextEditingController();
  bool searching = false;
  bool searched = false;

  Map<String, dynamic>? searchedMedicine;
  List<Map<String, dynamic>> substitutes = [];

  // =========================
  // SEARCH MEDICINE
  // =========================
  Future<void> _searchMedicine(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      searching = true;
      searched = false;
      searchedMedicine = null;
      substitutes = [];
    });

    try {
      // Step 1: Find the medicine by name or generic name
      final res = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name, country))')
          .or('medicine_name.ilike.%$query%,generic_name.ilike.%$query%')
          .order('medicine_name')
          .limit(1)
          .maybeSingle();

      if (res == null) {
        setState(() {
          searchedMedicine = null;
          substitutes = [];
          searched = true;
          searching = false;
        });
        return;
      }

      setState(() => searchedMedicine = res);

      // Step 2: Get the generic name
      final String? genericName = res['generic_name']?.toString();

      if (genericName == null || genericName.trim().isEmpty) {
        setState(() {
          substitutes = [];
          searched = true;
          searching = false;
        });
        return;
      }

      // Step 3: Find substitutes —
      // same generic name, different manufacturer, quantity > 0
      final String currentManufacturer =
          res['cartons']?['manufacturers']?['name']?.toString() ?? '';

      final subRes = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name, country))')
          .ilike('generic_name', '%$genericName%')
          .neq('id', res['id'])
          .gt('quantity', 0)
          .order('medicine_name');

      // Filter out same manufacturer
      final List<Map<String, dynamic>> allSubs =
          List<Map<String, dynamic>>.from(subRes);

      final filtered = allSubs.where((s) {
        final mfr = s['cartons']?['manufacturers']?['name']?.toString() ?? '';
        return mfr != currentManufacturer;
      }).toList();

      setState(() {
        substitutes = filtered;
        searched = true;
        searching = false;
      });
    } catch (e) {
      _error("Search error: $e");
      setState(() {
        searched = true;
        searching = false;
      });
    }
  }

  // =========================
  // MEDICINE DETAIL BOTTOM SHEET
  // =========================
  void _showDetail(Map<String, dynamic> m) {
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
              // HEADER
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.greenAccent.withOpacity(0.2),
                    radius: 24,
                    child: const Icon(
                      Icons.medication,
                      color: Colors.greenAccent,
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
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white24),

              _detailSection("🏭 Manufacturer"),
              _detailRow("Name", manufacturer),
              _detailRow("Country", country),

              const SizedBox(height: 12),

              _detailSection("💊 Medicine Info"),
              _detailRow("Batch Number", batch),
              _detailRow("Unit Type", unit),
              _detailRow("Strips per Box", stripsPerBox.toString()),

              const SizedBox(height: 12),

              _detailSection("📦 Stock"),
              _detailRow(
                "Quantity",
                "$qty $unit",
                valueColor: qty > 10
                    ? Colors.greenAccent
                    : qty > 0
                    ? Colors.orange
                    : Colors.redAccent,
              ),

              const SizedBox(height: 12),

              _detailSection("💰 Pricing"),
              _detailRow("Price per Box", "BDT ${price.toStringAsFixed(2)}"),
              if (pricePerStrip != null)
                _detailRow(
                  "Price per Strip",
                  "BDT ${pricePerStrip.toStringAsFixed(2)}",
                ),

              const SizedBox(height: 12),

              _detailSection("📅 Expiry"),
              _detailRow(
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

  Widget _detailSection(String title) {
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

  Widget _detailRow(String label, String value, {Color? valueColor}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
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
                      const Icon(Icons.search, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Substitute Finder",
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Search a medicine name or generic name to find substitutes from different manufacturers.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (val) => _searchMedicine(val.trim()),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            hintText: "Enter medicine or generic name...",
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
                          color: Colors.blueAccent,
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
                          onPressed: searching
                              ? null
                              : () => _searchMedicine(
                                  searchController.text.trim(),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // RESULTS
                Expanded(
                  child: !searched
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.saved_search,
                                color: Colors.white24,
                                size: 80,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Search for a medicine\nto find substitutes",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SEARCHED MEDICINE CARD
                              if (searchedMedicine == null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.redAccent),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.cancel,
                                        color: Colors.redAccent,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "❌ Medicine not found!\nCheck the name and try again.",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                // SEARCHED MEDICINE
                                const Text(
                                  "🔍 Searched Medicine",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildMedicineCard(
                                  searchedMedicine!,
                                  isSearched: true,
                                ),

                                const SizedBox(height: 20),

                                // SUBSTITUTES
                                Row(
                                  children: [
                                    const Text(
                                      "✅ Available Substitutes",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "${substitutes.length} found",
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                if (substitutes.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber,
                                          color: Colors.orange,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "No substitutes found",
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          searchedMedicine!['generic_name'] ==
                                                  null
                                              ? "This medicine has no generic name recorded. Add a generic name in Carton Tracking to enable substitute finding."
                                              : "No in-stock substitutes found with the same generic name from a different manufacturer.",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...substitutes.map(
                                    (s) => _buildMedicineCard(s),
                                  ),
                              ],

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

  // =========================
  // MEDICINE CARD
  // =========================
  Widget _buildMedicineCard(Map<String, dynamic> m, {bool isSearched = false}) {
    final int qty = (m['quantity'] as int?) ?? 0;
    final String name = m['medicine_name']?.toString() ?? '';
    final String generic = m['generic_name']?.toString() ?? '';
    final String batch = m['batch_number']?.toString() ?? '';
    final String unit = m['unit']?.toString() ?? '';
    final String manufacturer =
        m['cartons']?['manufacturers']?['name']?.toString() ?? 'Unknown';
    final String expiry = m['expiry_date']?.toString() ?? 'N/A';
    final double price = double.tryParse(m['price'].toString()) ?? 0.0;
    final DateTime? expiryDate = DateTime.tryParse(expiry);
    final int? daysLeft = expiryDate?.difference(DateTime.now()).inDays;
    final bool isExpired = daysLeft != null && daysLeft < 0;
    final bool isExpiringSoon =
        daysLeft != null && daysLeft <= 30 && daysLeft >= 0;

    Color stockColor;
    String stockLabel;
    IconData stockIcon;

    if (qty <= 0) {
      stockColor = Colors.redAccent;
      stockLabel = "Out of Stock";
      stockIcon = Icons.remove_circle;
    } else if (qty <= 10) {
      stockColor = Colors.orange;
      stockLabel = "Low Stock";
      stockIcon = Icons.warning_amber;
    } else {
      stockColor = Colors.greenAccent;
      stockLabel = "In Stock";
      stockIcon = Icons.check_circle;
    }

    return GestureDetector(
      onTap: () => _showDetail(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSearched
              ? Colors.blueAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSearched
                ? Colors.blueAccent.withOpacity(0.4)
                : Colors.greenAccent.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NAME + STOCK BADGE
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stockColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stockIcon, color: stockColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        stockLabel,
                        style: TextStyle(
                          color: stockColor,
                          fontSize: 11,
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

            // DETAILS
            Row(
              children: [
                Expanded(child: _cardDetail("🏭 Manufacturer", manufacturer)),
                Expanded(child: _cardDetail("🔢 Batch", batch)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _cardDetail(
                    "📦 Qty",
                    "$qty $unit",
                    valueColor: stockColor,
                  ),
                ),
                Expanded(
                  child: _cardDetail(
                    "💰 Price/Box",
                    "BDT ${price.toStringAsFixed(2)}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _cardDetail(
              "📅 Expiry",
              isExpired
                  ? "⛔ EXPIRED"
                  : isExpiringSoon
                  ? "⚠️ $daysLeft days left"
                  : "✅ $expiry",
              valueColor: isExpired
                  ? Colors.redAccent
                  : isExpiringSoon
                  ? Colors.orange
                  : Colors.greenAccent,
            ),

            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.info_outline, color: Colors.white24, size: 13),
                SizedBox(width: 4),
                Text(
                  "Tap for full details",
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardDetail(String label, String value, {Color? valueColor}) {
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
