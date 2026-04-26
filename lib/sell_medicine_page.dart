import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class SellMedicinePage extends StatefulWidget {
  const SellMedicinePage({super.key});

  @override
  State<SellMedicinePage> createState() => _SellMedicinePageState();
}

class _SellMedicinePageState extends State<SellMedicinePage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allMedicines = [];
  List<Map<String, dynamic>> filteredMedicines = [];
  List<Map<String, dynamic>> topMedicines = [];

  bool loading = true;
  bool loadingTop = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _loadTopMedicines();
    searchController.addListener(_filterMedicines);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================
  // LOAD MEDICINES
  // from medicine_boxes joined with cartons → manufacturers
  // =========================
  Future<void> _loadMedicines() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name, country))')
          .gt('quantity', 0)
          .order('medicine_name');

      setState(() {
        allMedicines = List<Map<String, dynamic>>.from(res);
        filteredMedicines = allMedicines;
        loading = false;
      });
    } catch (e) {
      _error("Failed to load medicines: $e");
      setState(() => loading = false);
    }
  }

  // =========================
  // LOAD WEEKLY TOP MEDICINES
  // calls the SQL function you created
  // =========================
  Future<void> _loadTopMedicines() async {
    setState(() => loadingTop = true);
    try {
      final res = await supabase.rpc('get_weekly_top_medicines');
      setState(() {
        topMedicines = List<Map<String, dynamic>>.from(res);
        loadingTop = false;
      });
    } catch (e) {
      debugPrint("Top medicines error: $e");
      setState(() => loadingTop = false);
    }
  }

  // =========================
  // FILTER — searches name, generic, batch, manufacturer
  // =========================
  void _filterMedicines() {
    final String query = searchController.text.toLowerCase();
    setState(() {
      filteredMedicines = allMedicines.where((m) {
        final String name = (m['medicine_name'] ?? '').toString().toLowerCase();
        final String generic = (m['generic_name'] ?? '')
            .toString()
            .toLowerCase();
        final String batch = (m['batch_number'] ?? '').toString().toLowerCase();
        final String mfr = (m['cartons']?['manufacturers']?['name'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(query) ||
            generic.contains(query) ||
            batch.contains(query) ||
            mfr.contains(query);
      }).toList();
    });
  }

  // =========================
  // BARCODE SCAN
  // =========================
  Future<void> _scanBarcode() async {
    try {
      final String barcode = await FlutterBarcodeScanner.scanBarcode(
        '#FF0000',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );
      if (barcode != '-1') {
        searchController.text = barcode;
        _filterMedicines();
      }
    } catch (e) {
      _error("Scanner error: $e");
    }
  }

  // =========================
  // SELL DIALOG
  // =========================
  void _showSellDialog(Map<String, dynamic> medicine) {
    String saleType = 'strip';
    final TextEditingController qtyController = TextEditingController(
      text: '1',
    );
    final TextEditingController customerController = TextEditingController();

    final int stripsPerBox = (medicine['strips_per_box'] as int?) ?? 10;
    final double pricePerBox =
        double.tryParse(medicine['price'].toString()) ?? 0.0;
    final double pricePerStrip = medicine['price_per_strip'] != null
        ? double.tryParse(medicine['price_per_strip'].toString()) ??
              (pricePerBox / stripsPerBox)
        : pricePerBox / stripsPerBox;
    final int availableBoxes = (medicine['quantity'] as int?) ?? 0;
    final String medicineName = medicine['medicine_name']?.toString() ?? '';
    final String genericName = medicine['generic_name']?.toString() ?? '';
    final String batchNumber = medicine['batch_number']?.toString() ?? '';
    final String manufacturerName =
        medicine['cartons']?['manufacturers']?['name']?.toString() ?? 'Unknown';
    final String unit = medicine['unit']?.toString() ?? 'boxes';
    final String expiryDate = medicine['expiry_date']?.toString() ?? 'N/A';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          double unitPrice;
          int maxQty;

          if (saleType == 'strip') {
            unitPrice = pricePerStrip;
            maxQty = availableBoxes * stripsPerBox;
          } else if (saleType == 'box') {
            unitPrice = pricePerBox;
            maxQty = availableBoxes;
          } else {
            unitPrice = pricePerBox * availableBoxes;
            maxQty = 1;
          }

          final int enteredQty = saleType == 'carton'
              ? 1
              : (int.tryParse(qtyController.text) ?? 1);
          final double total = saleType == 'carton'
              ? unitPrice
              : unitPrice * enteredQty;

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  medicineName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (genericName.isNotEmpty)
                  Text(
                    genericName,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _infoRow("🏭 Manufacturer", manufacturerName),
                        _infoRow("🔢 Batch", batchNumber),
                        _infoRow("📦 Stock", "$availableBoxes $unit"),
                        _infoRow("📅 Expiry", expiryDate),
                        _infoRow(
                          "💰 Price/Box",
                          "BDT ${pricePerBox.toStringAsFixed(2)}",
                        ),
                        _infoRow(
                          "💊 Price/Strip",
                          "BDT ${pricePerStrip.toStringAsFixed(2)}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sale type
                  const Text(
                    "Sell as:",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip(
                        'strip',
                        '💊 Strip',
                        saleType,
                        (v) => setDialogState(() => saleType = v),
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        'box',
                        '📦 Box',
                        saleType,
                        (v) => setDialogState(() => saleType = v),
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        'carton',
                        '🏭 Carton',
                        saleType,
                        (v) => setDialogState(() => saleType = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quantity
                  if (saleType != 'carton') ...[
                    const Text(
                      "Quantity:",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.numbers,
                          color: Colors.white70,
                        ),
                        hintText: saleType == 'strip'
                            ? "Number of strips (max $maxQty)"
                            : "Number of boxes (max $maxQty)",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Customer name
                  const Text(
                    "Customer name (optional):",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customerController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.white70,
                      ),
                      hintText: "Enter customer name",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Total
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total:",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "BDT ${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                ),
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.black,
                  size: 18,
                ),
                label: const Text(
                  "Complete Sale",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  final int qty = saleType == 'carton'
                      ? 1
                      : (int.tryParse(qtyController.text) ?? 1);

                  if (qty <= 0) {
                    _error("Quantity must be at least 1");
                    return;
                  }
                  if (saleType != 'carton' && qty > maxQty) {
                    _error(
                      saleType == 'strip'
                          ? "Only $maxQty strips available"
                          : "Only $maxQty boxes available",
                    );
                    return;
                  }

                  Navigator.pop(context);

                  await _completeSale(
                    medicine: medicine,
                    saleType: saleType,
                    qty: qty,
                    unitPrice: unitPrice,
                    total: saleType == 'carton' ? unitPrice : unitPrice * qty,
                    customer: customerController.text.trim(),
                    availableBoxes: availableBoxes,
                    stripsPerBox: stripsPerBox,
                    medicineName: medicineName,
                    genericName: genericName,
                    batchNumber: batchNumber,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // COMPLETE SALE
  // =========================
  Future<void> _completeSale({
    required Map<String, dynamic> medicine,
    required String saleType,
    required int qty,
    required double unitPrice,
    required double total,
    required String customer,
    required int availableBoxes,
    required int stripsPerBox,
    required String medicineName,
    required String genericName,
    required String batchNumber,
  }) async {
    try {
      final String userId = supabase.auth.currentUser!.id;

      // 1. Save to sales table
      await supabase.from('sales').insert({
        'medicine_box_id': medicine['id'],
        'medicine_name': medicineName,
        'batch_number': batchNumber,
        'sale_type': saleType,
        'quantity_sold': qty,
        'unit_price': unitPrice,
        'total_amount': total,
        'customer_name': customer.isEmpty ? null : customer,
        'sold_by': userId,
      });

      // 2. Deduct stock
      final int currentQty = (medicine['quantity'] as int?) ?? 0;
      int newQty;

      if (saleType == 'carton') {
        newQty = 0;
      } else if (saleType == 'box') {
        newQty = (currentQty - qty).clamp(0, currentQty);
      } else {
        final int boxesUsed = (qty / stripsPerBox.toDouble()).ceil();
        newQty = (currentQty - boxesUsed).clamp(0, currentQty);
      }

      await supabase
          .from('medicine_boxes')
          .update({'quantity': newQty})
          .eq('id', medicine['id']);

      if (!mounted) return;

      // 3. Show receipt
      _showReceipt(
        medicineName: medicineName,
        genericName: genericName,
        batchNumber: batchNumber,
        saleType: saleType,
        qty: qty,
        unitPrice: unitPrice,
        total: total,
        customer: customer,
      );

      // 4. Refresh both lists
      _loadMedicines();
      _loadTopMedicines();
    } catch (e) {
      _error("Sale failed: $e");
    }
  }

  // =========================
  // RECEIPT
  // =========================
  void _showReceipt({
    required String medicineName,
    required String genericName,
    required String batchNumber,
    required String saleType,
    required int qty,
    required double unitPrice,
    required double total,
    required String customer,
  }) {
    final DateTime now = DateTime.now();
    final String dateStr =
        "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.year}  "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text(
              "Sale Receipt",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Store header
            const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.blueAccent,
              size: 36,
            ),
            const SizedBox(height: 4),
            const Text(
              "GuardianPharma",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),

            if (customer.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                "Customer: $customer",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(color: Colors.white24),

            // Medicine details
            _infoRow("💊 Medicine", medicineName),
            if (genericName.isNotEmpty) _infoRow("🧬 Generic", genericName),
            _infoRow("🔢 Batch", batchNumber),
            _infoRow("📦 Type", saleType.toUpperCase()),
            _infoRow("🔢 Quantity", "$qty"),
            _infoRow("💰 Unit Price", "BDT ${unitPrice.toStringAsFixed(2)}"),

            const Divider(color: Colors.white24),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TOTAL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "BDT ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Text(
              "✅ Sale saved successfully!",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text("Done", style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // CHIP HELPER
  // =========================
  Widget _chip(
    String value,
    String label,
    String selected,
    Function(String) onTap,
  ) {
    final bool isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // =========================
  // INFO ROW HELPER
  // =========================
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
                      const Icon(Icons.point_of_sale, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Sell Medicine",
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

                // ── SEARCH + SCAN ─────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            hintText: "Search name, generic, batch...",
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
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                          ),
                          onPressed: _scanBarcode,
                          tooltip: "Scan barcode",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── WEEKLY TOP MEDICINES ──────────────
                if (!loadingTop && topMedicines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: Colors.amber,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Top Selling This Week",
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: topMedicines.length,
                            itemBuilder: (_, int i) {
                              final Map<String, dynamic> t = topMedicines[i];
                              final String name =
                                  t['medicine_name']?.toString() ?? '';
                              final String sold =
                                  t['total_sold']?.toString() ?? '0';
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${i + 1}. $name",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        sold,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                // ── INFO HINT ─────────────────────────
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
                            "Tap any medicine to sell it",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── MEDICINE LIST ─────────────────────
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
                                Icons.medication_outlined,
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
                          itemCount: filteredMedicines.length,
                          itemBuilder: (_, int i) {
                            final Map<String, dynamic> m = filteredMedicines[i];
                            final DateTime? expiry = DateTime.tryParse(
                              m['expiry_date']?.toString() ?? '',
                            );
                            final int? daysLeft = expiry
                                ?.difference(DateTime.now())
                                .inDays;
                            final bool isExpired =
                                daysLeft != null && daysLeft < 0;
                            final bool isExpiringSoon =
                                daysLeft != null &&
                                daysLeft <= 30 &&
                                daysLeft >= 0;

                            // check if this medicine is in top list
                            final bool isTopSeller = topMedicines.any(
                              (t) =>
                                  t['medicine_name']
                                      ?.toString()
                                      .toLowerCase() ==
                                  (m['medicine_name']
                                          ?.toString()
                                          .toLowerCase() ??
                                      ''),
                            );

                            return Card(
                              color: isExpired
                                  ? Colors.red.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.10),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isExpired
                                          ? Colors.redAccent
                                          : isExpiringSoon
                                          ? Colors.orange
                                          : Colors.blueAccent,
                                      child: const Icon(
                                        Icons.medication,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    if (isTopSeller)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Colors.amber,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.trending_up,
                                            size: 8,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m['medicine_name']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isTopSeller)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "🔥 Top",
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((m['generic_name']?.toString() ?? '')
                                        .isNotEmpty)
                                      Text(
                                        m['generic_name'].toString(),
                                        style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    Text(
                                      "🏭 ${m['cartons']?['manufacturers']?['name']?.toString() ?? 'Unknown'}",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "Batch: ${m['batch_number']}  |  Stock: ${m['quantity']} ${m['unit']?.toString() ?? ''}",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "BDT ${m['price']}  |  "
                                      "${isExpired
                                          ? '⛔ EXPIRED'
                                          : isExpiringSoon
                                          ? '⚠️ Expires in $daysLeft days'
                                          : '✅ Exp: ${m['expiry_date']}'}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isExpired
                                            ? Colors.redAccent
                                            : isExpiringSoon
                                            ? Colors.orange
                                            : Colors.greenAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isExpired
                                    ? const Icon(
                                        Icons.block,
                                        color: Colors.redAccent,
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.white54,
                                      ),
                                onTap: isExpired
                                    ? null
                                    : () => _showSellDialog(m),
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
