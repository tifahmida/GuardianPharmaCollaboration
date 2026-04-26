import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> manufacturers = [];
  String? selectedManufacturerId;
  String? selectedCartonId;
  String selectedUnit = 'Tablets';
  bool isCustomUnit = false;
  bool loading = false;
  bool scanning = false;

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
    _loadManufacturers();
  }

  @override
  void dispose() {
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

  // =========================
  // LOAD MANUFACTURERS
  // =========================
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

  // =========================
  // WEB-FRIENDLY BARCODE SCANNER
  // =========================
  Future<void> _scanBarcode() async {
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
              "Point camera at barcode or enter batch number manually:",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: manualController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.numbers, color: Colors.white70),
                hintText: "Enter batch number",
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

    if (result != null && result.isNotEmpty) {
      setState(() => batchController.text = result);
      _success("✅ Batch number filled from barcode!");
    }
  }

  // =========================
  // SAVE MEDICINE
  // =========================
  Future<void> _saveMedicine() async {
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

    // Validation
    if (name.isEmpty) {
      _error("Medicine name is required");
      return;
    }
    if (batch.isEmpty) {
      _error("Batch number is required");
      return;
    }
    if (expiry.isEmpty) {
      _error("Expiry date is required");
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

    setState(() => loading = true);

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
      });

      _success("✅ Medicine added successfully!");
      _clearForm();
    } catch (e) {
      _error("Failed to save: $e");
    }

    setState(() => loading = false);
  }

  // =========================
  // CLEAR FORM
  // =========================
  void _clearForm() {
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
    });
  }

  void _error(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _success(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

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
                      const Icon(Icons.add_box, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Add Medicine",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // CLEAR BUTTON
                      TextButton.icon(
                        onPressed: _clearForm,
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white54,
                          size: 18,
                        ),
                        label: const Text(
                          "Clear",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),

                // FORM
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER INFO BOX
                        Container(
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
                                  "Scan the barcode on the medicine box to auto-fill the batch number, then complete the remaining details.",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SCAN BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _scanBarcode,
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Scan Barcode → Auto-fill Batch No",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SECTION: MANUFACTURER
                        _sectionTitle("🏭 Manufacturer"),
                        const SizedBox(height: 8),
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
                            hintStyle: const TextStyle(color: Colors.white38),
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
                            setState(() => selectedCartonId = carton?['id']);
                          },
                        ),

                        const SizedBox(height: 20),

                        // SECTION: MEDICINE DETAILS
                        _sectionTitle("💊 Medicine Details"),
                        const SizedBox(height: 8),
                        _fieldInput(
                          medicineNameController,
                          "Medicine Name *",
                          Icons.medication,
                        ),
                        const SizedBox(height: 12),
                        _fieldInput(
                          genericNameController,
                          "Generic Name (e.g. Paracetamol)",
                          Icons.science_outlined,
                        ),
                        const SizedBox(height: 12),

                        // BATCH NUMBER — highlighted since barcode fills this
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: batchController.text.isNotEmpty
                                  ? Colors.greenAccent.withOpacity(0.5)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: _fieldInput(
                            batchController,
                            "Batch Number *",
                            Icons.numbers,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // EXPIRY DATE
                        TextField(
                          controller: expiryController,
                          style: const TextStyle(color: Colors.white),
                          readOnly: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                            ),
                            hintText: "Expiry Date *",
                            hintStyle: const TextStyle(color: Colors.white38),
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

                        const SizedBox(height: 20),

                        // SECTION: STOCK & PRICING
                        _sectionTitle("📦 Stock & Pricing"),
                        const SizedBox(height: 8),
                        _fieldInput(
                          quantityController,
                          "Quantity (number of boxes)",
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

                        // UNIT DROPDOWN
                        StatefulBuilder(
                          builder: (context, setLocalState) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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

                        const SizedBox(height: 30),

                        // SAVE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: loading ? null : _saveMedicine,
                            icon: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save, color: Colors.white),
                            label: Text(
                              loading ? "Saving..." : "Save Medicine",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
