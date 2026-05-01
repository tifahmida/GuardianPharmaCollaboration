import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/pharmacy_wrapper_page.dart';

class CartonTrackingPage extends StatefulWidget {
  const CartonTrackingPage({super.key});

  @override
  State<CartonTrackingPage> createState() => _CartonTrackingPageState();
}

class _CartonTrackingPageState extends State<CartonTrackingPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> manufacturers = [];
  bool loading = true;

  final List<String> _units = [
    'Tablets',
    'Syrup',
    'Powder',
    'Capsules',
    'Injection',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      // ✅ Only load manufacturers that have medicine boxes belonging to this pharmacy
      // We join through cartons -> medicine_boxes filtered by pharmacy_id
      // But manufacturers are global — we show all manufacturers
      // because a manufacturer can serve multiple pharmacies.
      // What we scope is the medicine_boxes shown inside each manufacturer.
      final manufacturersRes = await supabase
          .from('manufacturers')
          .select()
          .order('name');
      setState(() {
        manufacturers = List<Map<String, dynamic>>.from(manufacturersRes);
        loading = false;
      });
    } catch (e) {
      _error("Failed to load data: $e");
      setState(() => loading = false);
    }
  }

  // =========================
  // ADD / EDIT MANUFACTURER
  // =========================
  void _showManufacturerDialog({Map<String, dynamic>? existing}) {
    final nameController = TextEditingController(text: existing?['name'] ?? '');
    final countryController = TextEditingController(
      text: existing?['country'] ?? '',
    );
    final isEditing = existing != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          isEditing ? "Edit Manufacturer" : "Add Manufacturer",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogInput(nameController, "Manufacturer Name", Icons.business),
            const SizedBox(height: 12),
            _dialogInput(countryController, "Country", Icons.flag),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              final name = nameController.text.trim();
              final country = countryController.text.trim();
              if (name.isEmpty) {
                _error("Manufacturer name required");
                return;
              }
              try {
                if (isEditing) {
                  await supabase
                      .from('manufacturers')
                      .update({
                        'name': name,
                        'country': country.isEmpty ? null : country,
                      })
                      .eq('id', existing['id']);
                  _success("Manufacturer updated!");
                } else {
                  final res = await supabase
                      .from('manufacturers')
                      .insert({
                        'name': name,
                        'country': country.isEmpty ? null : country,
                      })
                      .select()
                      .single();
                  await supabase.from('cartons').insert({
                    'manufacturer_id': res['id'],
                    'created_by': supabase.auth.currentUser!.id,
                  });
                  _success("Manufacturer added!");
                }
                if (mounted) Navigator.pop(context);
                _loadData();
              } catch (e) {
                _error("Error: $e");
              }
            },
            child: Text(
              isEditing ? "Update" : "Add",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // DELETE MANUFACTURER
  // =========================
  void _deleteManufacturer(String id) async {
    final confirm = await _confirmDelete(
      "Delete this manufacturer? All medicine boxes will also be deleted!",
    );
    if (!confirm) return;
    try {
      await supabase.from('manufacturers').delete().eq('id', id);
      _success("Manufacturer deleted!");
      _loadData();
    } catch (e) {
      _error("Error: $e");
    }
  }

  // =========================
  // ADD / EDIT MEDICINE BOX
  // ✅ Scoped to current pharmacy
  // =========================
  void _showMedicineBoxDialog(
    String cartonId,
    String manufacturerName, {
    Map<String, dynamic>? existing,
  }) {
    final medicineNameController = TextEditingController(
      text: existing?['medicine_name'] ?? '',
    );
    final genericNameController = TextEditingController(
      text: existing?['generic_name'] ?? '',
    );
    final batchController = TextEditingController(
      text: existing?['batch_number'] ?? '',
    );
    final expiryController = TextEditingController(
      text: existing?['expiry_date'] ?? '',
    );
    final quantityController = TextEditingController(
      text: existing?['quantity']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: existing?['price']?.toString() ?? '',
    );
    final stripsPerBoxController = TextEditingController(
      text: existing?['strips_per_box']?.toString() ?? '10',
    );
    final pricePerStripController = TextEditingController(
      text: existing?['price_per_strip']?.toString() ?? '',
    );
    final customUnitController = TextEditingController();

    String selectedUnit = existing?['unit'] ?? 'Tablets';
    bool isCustomUnit =
        !_units.contains(existing?['unit']) && existing?['unit'] != null;
    if (isCustomUnit) {
      selectedUnit = 'Custom';
      customUnitController.text = existing?['unit'] ?? '';
    }

    final isEditing = existing != null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: Text(
            isEditing ? "Edit Medicine Box" : "Add Medicine Box",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: Colors.greenAccent),
                      const SizedBox(width: 10),
                      Text(
                        manufacturerName,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _dialogInput(
                  medicineNameController,
                  "Medicine Name",
                  Icons.medication,
                ),
                const SizedBox(height: 10),
                _dialogInput(
                  genericNameController,
                  "Generic Name (e.g. Atorvastatin)",
                  Icons.science_outlined,
                ),
                const SizedBox(height: 10),
                _dialogInput(batchController, "Batch Number", Icons.numbers),
                const SizedBox(height: 10),
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
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      expiryController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 10),
                _dialogInput(
                  quantityController,
                  "Quantity (boxes)",
                  Icons.inventory,
                  isNumber: true,
                ),
                const SizedBox(height: 10),
                _dialogInput(
                  stripsPerBoxController,
                  "Strips per Box (default 10)",
                  Icons.view_module,
                  isNumber: true,
                ),
                const SizedBox(height: 10),
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
                    hintStyle: const TextStyle(color: Colors.white38),
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
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedUnit = val!;
                      isCustomUnit = val == 'Custom';
                    });
                  },
                ),
                if (isCustomUnit) ...[
                  const SizedBox(height: 10),
                  _dialogInput(
                    customUnitController,
                    "Enter custom unit",
                    Icons.edit,
                  ),
                ],
                const SizedBox(height: 10),
                _dialogInput(
                  priceController,
                  "Price per Box (BDT)",
                  Icons.attach_money,
                  isDecimal: true,
                ),
                const SizedBox(height: 10),
                _dialogInput(
                  pricePerStripController,
                  "Price per Strip (BDT, optional)",
                  Icons.money,
                  isDecimal: true,
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                final name = medicineNameController.text.trim();
                final genericName = genericNameController.text.trim();
                final batch = batchController.text.trim();
                final expiry = expiryController.text.trim();
                final qty =
                    int.tryParse(
                      quantityController.text.trim().replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      ),
                    ) ??
                    0;
                final stripsPerBox =
                    int.tryParse(
                      stripsPerBoxController.text.trim().replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      ),
                    ) ??
                    10;
                final price =
                    double.tryParse(
                      priceController.text.trim().replaceAll(
                        RegExp(r'[^0-9.]'),
                        '',
                      ),
                    ) ??
                    0.0;
                final pricePerStrip = double.tryParse(
                  pricePerStripController.text.trim().replaceAll(
                    RegExp(r'[^0-9.]'),
                    '',
                  ),
                );
                final unit = isCustomUnit
                    ? customUnitController.text.trim()
                    : selectedUnit;

                if (name.isEmpty || batch.isEmpty || expiry.isEmpty) {
                  _error("Please fill all required fields");
                  return;
                }
                if (isCustomUnit && unit.isEmpty) {
                  _error("Please enter custom unit");
                  return;
                }

                try {
                  if (isEditing) {
                    await supabase
                        .from('medicine_boxes')
                        .update({
                          'medicine_name': name,
                          'generic_name': genericName.isEmpty
                              ? null
                              : genericName,
                          'batch_number': batch,
                          'expiry_date': expiry,
                          'quantity': qty,
                          'strips_per_box': stripsPerBox,
                          'unit': unit,
                          'price': price,
                          'price_per_strip': pricePerStrip,
                        })
                        .eq('id', existing['id']);
                    _success("Medicine box updated!");
                  } else {
                    // ✅ INSERT WITH pharmacy_id from session
                    await supabase.from('medicine_boxes').insert({
                      'carton_id': cartonId,
                      'medicine_name': name,
                      'generic_name': genericName.isEmpty ? null : genericName,
                      'batch_number': batch,
                      'expiry_date': expiry,
                      'quantity': qty,
                      'strips_per_box': stripsPerBox,
                      'unit': unit,
                      'price': price,
                      'price_per_strip': pricePerStrip,
                      'created_by': supabase.auth.currentUser!.id,
                      'pharmacy_id': PharmacySession.pharmacyId, // ✅ scoped
                    });
                    _success("Medicine box added!");
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  _error("Error: $e");
                }
              },
              child: Text(
                isEditing ? "Update" : "Add",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // VIEW MEDICINE BOXES
  // ✅ Filtered by current pharmacy_id
  // =========================
  void _showMedicineBoxes(
    String manufacturerId,
    String manufacturerName,
  ) async {
    final cartonRes = await supabase
        .from('cartons')
        .select()
        .eq('manufacturer_id', manufacturerId)
        .maybeSingle();

    if (cartonRes == null) {
      _error("No carton found for this manufacturer!");
      return;
    }

    final cartonId = cartonRes['id'];

    // ✅ Filter medicine boxes by both carton_id AND pharmacy_id
    final boxes = await supabase
        .from('medicine_boxes')
        .select()
        .eq('carton_id', cartonId)
        .eq('pharmacy_id', PharmacySession.pharmacyId ?? '')
        .order('expiry_date');

    final List<Map<String, dynamic>> boxList = List<Map<String, dynamic>>.from(
      boxes,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "🏭 $manufacturerName",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showMedicineBoxDialog(cartonId, manufacturerName);
                      },
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        "Add Box",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              boxList.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          "No medicine boxes for this pharmacy yet",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: boxList.length,
                        itemBuilder: (_, i) {
                          final box = boxList[i];
                          final expiry = DateTime.parse(box['expiry_date']);
                          final daysLeft = expiry
                              .difference(DateTime.now())
                              .inDays;
                          final isExpiringSoon = daysLeft <= 30;
                          final isExpired = daysLeft < 0;
                          final String genericName =
                              box['generic_name']?.toString() ?? '';

                          return Card(
                            color: isExpired
                                ? Colors.red.withOpacity(0.2)
                                : isExpiringSoon
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.white.withOpacity(0.08),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.medication,
                                color: isExpired
                                    ? Colors.red
                                    : isExpiringSoon
                                    ? Colors.orange
                                    : Colors.greenAccent,
                              ),
                              title: Text(
                                box['medicine_name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (genericName.isNotEmpty)
                                    Text(
                                      "🧬 $genericName",
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  Text(
                                    "Batch: ${box['batch_number']}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    "Qty: ${box['quantity']} ${box['unit']}  |  BDT ${box['price']}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    "Strips/Box: ${box['strips_per_box'] ?? 10}  |  Strip Price: BDT ${box['price_per_strip'] ?? 'N/A'}",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    isExpired
                                        ? "⛔ EXPIRED"
                                        : isExpiringSoon
                                        ? "⚠️ Expires in $daysLeft days"
                                        : "✅ Expires: ${box['expiry_date']}",
                                    style: TextStyle(
                                      color: isExpired
                                          ? Colors.red
                                          : isExpiringSoon
                                          ? Colors.orange
                                          : Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueAccent,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showMedicineBoxDialog(
                                        cartonId,
                                        manufacturerName,
                                        existing: box,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final confirm = await _confirmDelete(
                                        "Delete this medicine box?",
                                      );
                                      if (!confirm) return;
                                      try {
                                        await supabase
                                            .from('medicine_boxes')
                                            .delete()
                                            .eq('id', box['id']);
                                        setSheetState(
                                          () => boxList.removeWhere(
                                            (b) => b['id'] == box['id'],
                                          ),
                                        );
                                        _success("Medicine box deleted!");
                                      } catch (e) {
                                        _error("Error: $e");
                                      }
                                    },
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
      ),
    );
  }

  // =========================
  // STRIP VERIFIER
  // ✅ Scoped to current pharmacy
  // =========================
  void _showStripVerifier() {
    final batchController = TextEditingController();
    Map<String, dynamic>? result;
    bool searched = false;
    bool searching = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🔍 Medicine Strip Verifier",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Enter the batch number on the medicine strip",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: batchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    hintText: "Enter batch number",
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
                    icon: searching
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.verified_user, color: Colors.white),
                    label: const Text(
                      "Verify Strip",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      final batch = batchController.text.trim();
                      if (batch.isEmpty) {
                        _error("Enter a batch number");
                        return;
                      }
                      setSheetState(() {
                        searching = true;
                        searched = false;
                        result = null;
                      });
                      try {
                        // ✅ Scoped to current pharmacy
                        final res = await supabase
                            .from('medicine_boxes')
                            .select(
                              '*, cartons(*, manufacturers(name, country))',
                            )
                            .eq('batch_number', batch)
                            .eq('pharmacy_id', PharmacySession.pharmacyId ?? '')
                            .maybeSingle();
                        setSheetState(() {
                          result = res;
                          searched = true;
                          searching = false;
                        });
                      } catch (e) {
                        setSheetState(() {
                          searched = true;
                          searching = false;
                        });
                        _error("Search error: $e");
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                if (searched) ...[
                  if (result == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.redAccent),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "❌ No match found!\nThis strip does NOT belong to any box in this pharmacy.",
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
                    Builder(
                      builder: (_) {
                        final expiry = DateTime.parse(result!['expiry_date']);
                        final daysLeft = expiry
                            .difference(DateTime.now())
                            .inDays;
                        final isExpired = daysLeft < 0;
                        final isExpiringSoon = daysLeft <= 30 && daysLeft >= 0;
                        final String genericName =
                            result!['generic_name']?.toString() ?? '';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? Colors.red.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isExpired
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isExpired ? Icons.cancel : Icons.verified,
                                    color: isExpired
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isExpired
                                          ? "⛔ STRIP FOUND BUT EXPIRED!"
                                          : "✅ Strip Verified Successfully!",
                                      style: TextStyle(
                                        color: isExpired
                                            ? Colors.redAccent
                                            : Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24),
                              _resultRow(
                                "💊 Medicine",
                                result!['medicine_name'],
                              ),
                              if (genericName.isNotEmpty)
                                _resultRow("🧬 Generic", genericName),
                              _resultRow(
                                "🔢 Batch No",
                                result!['batch_number'],
                              ),
                              _resultRow(
                                "📦 Quantity",
                                "${result!['quantity']} ${result!['unit']}",
                              ),
                              _resultRow("💰 Price", "BDT ${result!['price']}"),
                              _resultRow(
                                "📅 Expiry",
                                isExpired
                                    ? "EXPIRED (${result!['expiry_date']})"
                                    : isExpiringSoon
                                    ? "⚠️ Expires in $daysLeft days"
                                    : result!['expiry_date'],
                              ),
                              const Divider(color: Colors.white24),
                              _resultRow(
                                "🏭 Manufacturer",
                                result!['cartons']['manufacturers']['name'],
                              ),
                              _resultRow(
                                "🌍 Country",
                                result!['cartons']['manufacturers']['country'] ??
                                    'N/A',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  Future<bool> _confirmDelete(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Confirm Delete",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _error(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _success(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  Widget _dialogInput(
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
          Positioned.fill(
            child: Image.asset(
              'assets/images/guardianpharmapills.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.40)),
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
                      const Icon(Icons.widgets, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Carton Tracking",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showStripVerifier,
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          "Verify Strip",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Showing stock for: ${PharmacySession.pharmacyName ?? 'Your Pharmacy'}. Tap a manufacturer to view & manage medicine boxes.",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
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
                      : manufacturers.isEmpty
                      ? const Center(
                          child: Text(
                            "No manufacturers yet.\nTap + to add one!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: manufacturers.length,
                          itemBuilder: (_, i) {
                            final m = manufacturers[i];
                            return Card(
                              color: Colors.white.withOpacity(0.10),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(
                                    Icons.business,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  m['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  m['country'] ?? 'Country not specified',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _showManufacturerDialog(existing: m),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _deleteManufacturer(m['id']),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: Colors.white54,
                                    ),
                                  ],
                                ),
                                onTap: () =>
                                    _showMedicineBoxes(m['id'], m['name']),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "addManufacturer",
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Manufacturer",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: _showManufacturerDialog,
      ),
    );
  }
}
