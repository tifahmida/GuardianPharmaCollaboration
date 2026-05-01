import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/pharmacy_wrapper_page.dart';

class ScanBarcodePage extends StatefulWidget {
  const ScanBarcodePage({super.key});

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  String scannedCode = '';
  bool scanning = false;
  bool searched = false;

  Map<String, dynamic>? foundMedicine;

  List<Map<String, dynamic>> manufacturers = [];
  String? selectedManufacturerId;
  String? selectedCartonId;
  String selectedUnit = 'Tablets';
  bool isCustomUnit = false;

  final List<String> _units = [
    'Tablets',
    'Syrup',
    'Powder',
    'Capsules',
    'Injection',
    'Custom',
  ];

  final medicineNameController = TextEditingController();
  final genericNameController = TextEditingController();
  final batchController = TextEditingController();
  final expiryController = TextEditingController();
  final quantityController = TextEditingController();
  final stripsPerBoxController = TextEditingController(text: '10');
  final priceController = TextEditingController();
  final pricePerStripController = TextEditingController();
  final customUnitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadManufacturers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    medicineNameController.dispose();
    genericNameController.dispose();
    batchController.dispose();
    expiryController.dispose();
    quantityController.dispose();
    stripsPerBoxController.dispose();
    priceController.dispose();
    pricePerStripController.dispose();
    customUnitController.dispose();
    super.dispose();
  }

  Future<void> _loadManufacturers() async {
    try {
      final res = await supabase.from('manufacturers').select().order('name');
      setState(() {
        manufacturers = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      _error("Failed to load manufacturers: $e");
    }
  }

  Future<String?> _scanBarcode() async {
    final manualController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text("Scan Barcode", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Point camera at barcode or enter manually:",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: manualController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.numbers, color: Colors.white70),
                hintText: "Enter barcode / batch number",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) => Navigator.pop(context, val.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () =>
                Navigator.pop(context, manualController.text.trim()),
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result;
  }

  // ✅ Search scoped to current pharmacy
  Future<void> _scanAndSell() async {
    setState(() => scanning = true);
    final barcode = await _scanBarcode();
    if (barcode == null || barcode.isEmpty) {
      setState(() => scanning = false);
      return;
    }
    setState(() {
      scannedCode = barcode;
      searched = false;
      foundMedicine = null;
    });
    await _searchMedicine(barcode);
    setState(() => scanning = false);
  }

  // ✅ Scoped to current pharmacy
  Future<void> _searchMedicine(String query) async {
    setState(() => scanning = true);
    try {
      final res = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name, country))')
          .eq('pharmacy_id', PharmacySession.pharmacyId ?? '')
          .or('batch_number.eq.$query,medicine_name.ilike.%$query%')
          .gt('quantity', 0)
          .maybeSingle();

      setState(() {
        foundMedicine = res;
        searched = true;
        scanning = false;
      });
    } catch (e) {
      _error("Search error: $e");
      setState(() {
        searched = true;
        scanning = false;
      });
    }
  }

  Future<void> _scanAndFill() async {
    setState(() => scanning = true);
    final barcode = await _scanBarcode();
    if (barcode == null || barcode.isEmpty) {
      setState(() => scanning = false);
      return;
    }
    setState(() {
      batchController.text = barcode;
      scannedCode = barcode;
      scanning = false;
    });
    _success("Barcode scanned! Batch number filled ✅");
  }

  void _showSellDialog(Map<String, dynamic> medicine) {
    String saleType = 'strip';
    final qtyController = TextEditingController(text: '1');
    final customerController = TextEditingController();

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
                    ),
                  ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        _infoRow("📦 Stock", "$availableBoxes boxes"),
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
                  if (saleType != 'carton') ...[
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
                            ? "Strips (max $maxQty)"
                            : "Boxes (max $maxQty)",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: customerController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.white70,
                      ),
                      hintText: "Customer name (optional)",
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
                  if (qty <= 0 || qty > maxQty) {
                    _error("Invalid quantity");
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

  // ✅ Sale saved with pharmacy_id
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
      await supabase.from('sales').insert({
        'medicine_box_id': medicine['id'],
        'medicine_name': medicineName,
        'batch_number': batchNumber,
        'sale_type': saleType,
        'quantity_sold': qty,
        'unit_price': unitPrice,
        'total_amount': total,
        'customer_name': customer.isEmpty ? null : customer,
        'sold_by': supabase.auth.currentUser!.id,
        'pharmacy_id': PharmacySession.pharmacyId, // ✅ scoped
      });

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

      _success("✅ Sale completed!");
      setState(() {
        foundMedicine?['quantity'] = newQty;
      });
    } catch (e) {
      _error("Sale failed: $e");
    }
  }

  // ✅ Medicine insert scoped to pharmacy
  Future<void> _saveMedicineBox() async {
    final name = medicineNameController.text.trim();
    final generic = genericNameController.text.trim();
    final batch = batchController.text.trim();
    final expiry = expiryController.text.trim();
    final qty =
        int.tryParse(
          quantityController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final strips =
        int.tryParse(
          stripsPerBoxController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        10;
    final price =
        double.tryParse(
          priceController.text.trim().replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
    final pricePerStrip = double.tryParse(
      pricePerStripController.text.trim().replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final unit = isCustomUnit ? customUnitController.text.trim() : selectedUnit;

    if (name.isEmpty || batch.isEmpty || expiry.isEmpty) {
      _error("Medicine name, batch number and expiry are required");
      return;
    }
    if (selectedCartonId == null) {
      _error("Please select a manufacturer");
      return;
    }
    if (isCustomUnit && unit.isEmpty) {
      _error("Please enter custom unit");
      return;
    }
    if (!PharmacySession.isLoaded) {
      _error("Pharmacy session not loaded. Please restart the app.");
      return;
    }

    try {
      await supabase.from('medicine_boxes').insert({
        'carton_id': selectedCartonId,
        'medicine_name': name,
        'generic_name': generic.isEmpty ? null : generic,
        'batch_number': batch,
        'expiry_date': expiry,
        'quantity': qty,
        'strips_per_box': strips,
        'unit': unit,
        'price': price,
        'price_per_strip': pricePerStrip,
        'created_by': supabase.auth.currentUser!.id,
        'pharmacy_id': PharmacySession.pharmacyId, // ✅ scoped
      });

      _success("✅ Medicine box added successfully!");

      medicineNameController.clear();
      genericNameController.clear();
      batchController.clear();
      expiryController.clear();
      quantityController.clear();
      stripsPerBoxController.text = '10';
      priceController.clear();
      pricePerStripController.clear();
      customUnitController.clear();
      setState(() {
        selectedManufacturerId = null;
        selectedCartonId = null;
        selectedUnit = 'Tablets';
        isCustomUnit = false;
        scannedCode = '';
      });
    } catch (e) {
      _error("Failed to save: $e");
    }
  }

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

  Widget _fieldInput(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isNumber = false,
    bool isDecimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : isNumber
          ? const TextInputType.numberWithOptions(decimal: false, signed: false)
          : TextInputType.text,
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.qr_code_scanner, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Scan Barcode",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              PharmacySession.pharmacyName ?? 'Your Pharmacy',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: const [
                      Tab(text: "💊 Sell Medicine"),
                      Tab(text: "➕ Add Medicine"),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ── TAB 1: SELL ──────────────────
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: scanning ? null : _scanAndSell,
                                icon: scanning
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.qr_code_scanner,
                                        color: Colors.white,
                                      ),
                                label: Text(
                                  scanning
                                      ? "Scanning..."
                                      : "Scan Barcode to Sell",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              style: const TextStyle(color: Colors.white),
                              onSubmitted: (val) => _searchMedicine(val.trim()),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white70,
                                ),
                                hintText:
                                    "Or type batch / medicine name & press Enter",
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (searched) ...[
                              if (foundMedicine == null)
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
                                          "❌ No medicine found in this pharmacy!\nCheck the batch number or name.",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Card(
                                  color: Colors.white.withOpacity(0.10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          foundMedicine!['medicine_name'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if ((foundMedicine!['generic_name']
                                                    ?.toString() ??
                                                '')
                                            .isNotEmpty)
                                          Text(
                                            foundMedicine!['generic_name'],
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 13,
                                            ),
                                          ),
                                        const SizedBox(height: 10),
                                        _infoRow(
                                          "🏭 Manufacturer",
                                          foundMedicine!['cartons']?['manufacturers']?['name'] ??
                                              'N/A',
                                        ),
                                        _infoRow(
                                          "🔢 Batch",
                                          foundMedicine!['batch_number'],
                                        ),
                                        _infoRow(
                                          "📦 Stock",
                                          "${foundMedicine!['quantity']} ${foundMedicine!['unit']}",
                                        ),
                                        _infoRow(
                                          "💰 Price/Box",
                                          "BDT ${foundMedicine!['price']}",
                                        ),
                                        _infoRow(
                                          "📅 Expiry",
                                          foundMedicine!['expiry_date'],
                                        ),
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.greenAccent,
                                            ),
                                            icon: const Icon(
                                              Icons.point_of_sale,
                                              color: Colors.black,
                                            ),
                                            label: const Text(
                                              "Sell This Medicine",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _showSellDialog(foundMedicine!),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      // ── TAB 2: ADD ───────────────────
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Pharmacy badge
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.3),
                                ),
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
                                    "Adding to: ${PharmacySession.pharmacyName ?? 'Your Pharmacy'}",
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: scanning ? null : _scanAndFill,
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Scan Barcode to Auto-fill Batch No",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: selectedManufacturerId,
                              dropdownColor: const Color(0xFF1E1E2E),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.business,
                                  color: Colors.white70,
                                ),
                                hintText: "Select Manufacturer",
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: manufacturers.map((m) {
                                return DropdownMenuItem<String>(
                                  value: m['id'],
                                  child: Text(
                                    m['name'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) async {
                                setState(() => selectedManufacturerId = val);
                                final carton = await supabase
                                    .from('cartons')
                                    .select()
                                    .eq('manufacturer_id', val!)
                                    .maybeSingle();
                                setState(
                                  () => selectedCartonId = carton?['id'],
                                );
                              },
                            ),

                            const SizedBox(height: 12),
                            _fieldInput(
                              medicineNameController,
                              "Medicine Name",
                              Icons.medication,
                            ),
                            const SizedBox(height: 12),
                            _fieldInput(
                              genericNameController,
                              "Generic Name (e.g. Atorvastatin)",
                              Icons.science_outlined,
                            ),
                            const SizedBox(height: 12),
                            _fieldInput(
                              batchController,
                              "Batch Number",
                              Icons.numbers,
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: expiryController,
                              style: const TextStyle(color: Colors.white),
                              readOnly: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white70,
                                ),
                                hintText: "Expiry Date",
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(
                                    const Duration(days: 30),
                                  ),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  expiryController.text =
                                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _fieldInput(
                              quantityController,
                              "Quantity (boxes)",
                              Icons.inventory,
                              isNumber: true,
                            ),
                            const SizedBox(height: 12),
                            _fieldInput(
                              stripsPerBoxController,
                              "Strips per Box (default 10)",
                              Icons.view_module,
                              isNumber: true,
                            ),
                            const SizedBox(height: 12),

                            StatefulBuilder(
                              builder: (context, setLocalState) => Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: selectedUnit,
                                    dropdownColor: const Color(0xFF1E1E2E),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.category,
                                        color: Colors.white70,
                                      ),
                                      hintText: "Unit Type",
                                      hintStyle: const TextStyle(
                                        color: Colors.white38,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.08),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    items: _units.map((u) {
                                      return DropdownMenuItem<String>(
                                        value: u,
                                        child: Text(
                                          u,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setLocalState(() {
                                        selectedUnit = val!;
                                        isCustomUnit = val == 'Custom';
                                      });
                                      setState(() {
                                        selectedUnit = val!;
                                        isCustomUnit = val == 'Custom';
                                      });
                                    },
                                  ),
                                  if (isCustomUnit) ...[
                                    const SizedBox(height: 12),
                                    _fieldInput(
                                      customUnitController,
                                      "Enter custom unit",
                                      Icons.edit,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            _fieldInput(
                              priceController,
                              "Price per Box (BDT)",
                              Icons.attach_money,
                              isDecimal: true,
                            ),
                            const SizedBox(height: 12),
                            _fieldInput(
                              pricePerStripController,
                              "Price per Strip (BDT, optional)",
                              Icons.money,
                              isDecimal: true,
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _saveMedicineBox,
                                icon: const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Save Medicine Box",
                                  style: TextStyle(
                                    color: Colors.white,
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
