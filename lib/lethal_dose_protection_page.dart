import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LethalDoseProtectionPage extends StatefulWidget {
  const LethalDoseProtectionPage({super.key});

  @override
  State<LethalDoseProtectionPage> createState() =>
      _LethalDoseProtectionPageState();
}

class _LethalDoseProtectionPageState extends State<LethalDoseProtectionPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allMedicines = [];
  List<Map<String, dynamic>> filteredMedicines = [];
  bool loading = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    searchController.addListener(_filterMedicines);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name))')
          .gt('quantity', 0)
          .order('medicine_name');
      setState(() {
        allMedicines = List<Map<String, dynamic>>.from(res);
        filteredMedicines = allMedicines;
        loading = false;
      });
    } catch (e) {
      _error("Failed to load: $e");
      setState(() => loading = false);
    }
  }

  void _filterMedicines() {
    final String query = searchController.text.toLowerCase();
    setState(() {
      filteredMedicines = allMedicines.where((m) {
        final String name = (m['medicine_name'] ?? '').toString().toLowerCase();
        final String generic = (m['generic_name'] ?? '')
            .toString()
            .toLowerCase();
        final String batch = (m['batch_number'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            generic.contains(query) ||
            batch.contains(query);
      }).toList();
    });
  }

  String _generateOtp() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<int> _getWeeklyUsage(String medicineName, String customerPhone) async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final res = await supabase
          .from('sales')
          .select('quantity_sold')
          .eq('medicine_name', medicineName)
          .eq('customer_phone', customerPhone)
          .gte('created_at', weekAgo.toIso8601String());
      final List data = List<Map<String, dynamic>>.from(res);
      int total = 0;
      for (final row in data) {
        total += (row['quantity_sold'] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // =========================
  // SELL DIALOG
  // ✅ maxQty removed — was unused
  // =========================
  void _showSellDialog(Map<String, dynamic> medicine) {
    final String medicineName = medicine['medicine_name']?.toString() ?? '';
    final String genericName = medicine['generic_name']?.toString() ?? '';
    final String batchNumber = medicine['batch_number']?.toString() ?? '';
    final int maxPerTransaction =
        (medicine['max_per_transaction'] as int?) ?? 10;
    final int maxPerWeek = (medicine['max_per_week'] as int?) ?? 30;
    final int availableQty = (medicine['quantity'] as int?) ?? 0;
    final int stripsPerBox = (medicine['strips_per_box'] as int?) ?? 10;
    final double pricePerBox =
        double.tryParse(medicine['price'].toString()) ?? 0.0;
    final double pricePerStrip = medicine['price_per_strip'] != null
        ? double.tryParse(medicine['price_per_strip'].toString()) ??
              (pricePerBox / stripsPerBox)
        : pricePerBox / stripsPerBox;

    String saleType = 'strip';
    final qtyController = TextEditingController(text: '1');
    final customerController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          // ✅ FIXED: removed unused maxQty
          // only unitPrice needed for total calc
          double unitPrice;

          if (saleType == 'strip') {
            unitPrice = pricePerStrip;
          } else if (saleType == 'box') {
            unitPrice = pricePerBox;
          } else {
            unitPrice = pricePerBox * availableQty;
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
                      fontSize: 12,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Max/transaction: $maxPerTransaction  |  Max/week: $maxPerWeek",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _infoRow("🔢 Batch", batchNumber),
                        _infoRow("📦 Stock", "$availableQty boxes"),
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
                  const SizedBox(height: 14),

                  const Text(
                    "Sell as:",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip('strip', '💊 Strip', saleType, (v) {
                        setDialogState(() => saleType = v);
                      }),
                      const SizedBox(width: 8),
                      _chip('box', '📦 Box', saleType, (v) {
                        setDialogState(() => saleType = v);
                      }),
                      const SizedBox(width: 8),
                      _chip('carton', '🏭 Carton', saleType, (v) {
                        setDialogState(() => saleType = v);
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),

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
                        hintText: "Max per transaction: $maxPerTransaction",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const Text(
                    "Customer Name (required for high qty):",
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
                      hintText: "Customer name",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    "Phone Number:",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.phone,
                        color: Colors.white70,
                      ),
                      hintText: "Customer phone",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
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
                  "Proceed",
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

                  final String customer = customerController.text.trim();
                  final String phone = phoneController.text.trim();

                  // CHECK 1: max per transaction
                  if (qty > maxPerTransaction) {
                    Navigator.pop(context);
                    _showLimitWarning(
                      title: "⚠️ Transaction Limit Exceeded!",
                      message:
                          "You are trying to sell $qty units of $medicineName.\n\nMax allowed per transaction is $maxPerTransaction units.\n\nThis limit exists to prevent overdose risk.",
                      medicine: medicine,
                      qty: qty,
                      saleType: saleType,
                      unitPrice: unitPrice,
                      total: total,
                      customer: customer,
                      phone: phone,
                    );
                    return;
                  }

                  // CHECK 2: max per week
                  if (phone.isNotEmpty) {
                    final int weeklyUsage = await _getWeeklyUsage(
                      medicineName,
                      phone,
                    );
                    if (weeklyUsage + qty > maxPerWeek) {
                      Navigator.pop(context);
                      _showLimitWarning(
                        title: "⚠️ Weekly Limit Exceeded!",
                        message:
                            "This customer has already purchased $weeklyUsage units of $medicineName in the last 7 days.\n\nAdding $qty more would exceed the weekly limit of $maxPerWeek units.\n\nThis is a lethal dose protection alert.",
                        medicine: medicine,
                        qty: qty,
                        saleType: saleType,
                        unitPrice: unitPrice,
                        total: total,
                        customer: customer,
                        phone: phone,
                      );
                      return;
                    }
                  }

                  // No limit exceeded
                  Navigator.pop(context);
                  await _completeSale(
                    medicine: medicine,
                    saleType: saleType,
                    qty: qty,
                    unitPrice: unitPrice,
                    total: total,
                    customer: customer,
                    phone: phone,
                    medicineName: medicineName,
                    batchNumber: batchNumber,
                    availableBoxes: availableQty,
                    stripsPerBox: stripsPerBox,
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
  // LIMIT WARNING DIALOG
  // =========================
  void _showLimitWarning({
    required String title,
    required String message,
    required Map<String, dynamic> medicine,
    required int qty,
    required String saleType,
    required double unitPrice,
    required double total,
    required String customer,
    required String phone,
  }) {
    final String medicineName = medicine['medicine_name']?.toString() ?? '';
    final String batchNumber = medicine['batch_number']?.toString() ?? '';
    final int availableBoxes = (medicine['quantity'] as int?) ?? 0;
    final int stripsPerBox = (medicine['strips_per_box'] as int?) ?? 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Row(
          children: [
            const Icon(Icons.shield, color: Colors.redAccent, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "To override this limit, OTP verification is required.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel Sale",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            icon: const Icon(Icons.lock_open, color: Colors.white, size: 16),
            label: const Text(
              "Get OTP & Override",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showOtpDialog(
                medicine: medicine,
                qty: qty,
                saleType: saleType,
                unitPrice: unitPrice,
                total: total,
                customer: customer,
                phone: phone,
                medicineName: medicineName,
                batchNumber: batchNumber,
                availableBoxes: availableBoxes,
                stripsPerBox: stripsPerBox,
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // OTP DIALOG
  // =========================
  void _showOtpDialog({
    required Map<String, dynamic> medicine,
    required int qty,
    required String saleType,
    required double unitPrice,
    required double total,
    required String customer,
    required String phone,
    required String medicineName,
    required String batchNumber,
    required int availableBoxes,
    required int stripsPerBox,
  }) {
    final String generatedOtp = _generateOtp();
    final otpController = TextEditingController();
    bool otpError = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "📱 Simulated OTP: $generatedOtp (In real app this would be sent via SMS)",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 15),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "OTP Verification",
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.sms, color: Colors.blueAccent, size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      "OTP Sent (Simulated)",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Your OTP: $generatedOtp",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "(In production this would be sent via SMS)",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLength: 6,
                onChanged: (_) => setDialogState(() => otpError = false),
                decoration: InputDecoration(
                  hintText: "Enter 6-digit OTP",
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: otpError
                        ? const BorderSide(color: Colors.redAccent, width: 2)
                        : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: otpError
                        ? const BorderSide(color: Colors.redAccent, width: 2)
                        : BorderSide.none,
                  ),
                  counterStyle: const TextStyle(color: Colors.white38),
                ),
              ),
              if (otpError)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Incorrect OTP. Please try again.",
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                  ),
                ),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              icon: const Icon(Icons.check, color: Colors.white, size: 16),
              label: const Text(
                "Verify & Sell",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                if (otpController.text.trim() == generatedOtp) {
                  Navigator.pop(context);
                  await _completeSale(
                    medicine: medicine,
                    saleType: saleType,
                    qty: qty,
                    unitPrice: unitPrice,
                    total: total,
                    customer: customer,
                    phone: phone,
                    medicineName: medicineName,
                    batchNumber: batchNumber,
                    availableBoxes: availableBoxes,
                    stripsPerBox: stripsPerBox,
                  );
                } else {
                  setDialogState(() => otpError = true);
                }
              },
            ),
          ],
        ),
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
    required String phone,
    required String medicineName,
    required String batchNumber,
    required int availableBoxes,
    required int stripsPerBox,
  }) async {
    try {
      final String userId = supabase.auth.currentUser!.id;

      await supabase.from('sales').insert({
        'medicine_box_id': medicine['id'],
        'medicine_name': medicineName,
        'batch_number': batchNumber,
        'sale_type': saleType,
        'quantity_sold': qty,
        'unit_price': unitPrice,
        'total_amount': total,
        'customer_name': customer.isEmpty ? null : customer,
        'customer_phone': phone.isEmpty ? null : phone,
        'sold_by': userId,
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

      if (!mounted) return;

      _showReceipt(
        medicineName: medicineName,
        batchNumber: batchNumber,
        saleType: saleType,
        qty: qty,
        unitPrice: unitPrice,
        total: total,
        customer: customer,
        phone: phone,
      );

      _loadMedicines();
    } catch (e) {
      _error("Sale failed: $e");
    }
  }

  // =========================
  // RECEIPT
  // =========================
  void _showReceipt({
    required String medicineName,
    required String batchNumber,
    required String saleType,
    required int qty,
    required double unitPrice,
    required double total,
    required String customer,
    required String phone,
  }) {
    final DateTime now = DateTime.now();
    final String dateStr =
        "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.year}";
    final int hour = now.hour;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int hour12 = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    final String timeStr =
        "${hour12.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')} $period";

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 10),
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            if (customer.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                "Customer: $customer",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            if (phone.isNotEmpty)
              Text(
                "📱 $phone",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            _receiptRow("💊 Medicine", medicineName),
            _receiptRow("🔢 Batch", batchNumber),
            _receiptRow("📦 Type", saleType.toUpperCase()),
            _receiptRow("🔢 Quantity", "$qty"),
            _receiptRow("💰 Unit Price", "BDT ${unitPrice.toStringAsFixed(2)}"),
            const Divider(color: Colors.white24),
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
            const SizedBox(height: 10),
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

  Widget _receiptRow(String label, String value) {
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

  void _error(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

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
                      const Icon(
                        Icons.health_and_safety,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Lethal Dose Protection",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadMedicines,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield, color: Colors.redAccent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Protected sale mode — transaction & weekly limits enforced. OTP required to override.",
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
                      hintText: "Search medicine, batch...",
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

                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
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
                            final String name =
                                m['medicine_name']?.toString() ?? '';
                            final String generic =
                                m['generic_name']?.toString() ?? '';
                            final String mfr =
                                m['cartons']?['manufacturers']?['name']
                                    ?.toString() ??
                                'Unknown';
                            final int maxTx =
                                (m['max_per_transaction'] as int?) ?? 10;
                            final int maxWeek =
                                (m['max_per_week'] as int?) ?? 30;
                            final int qty = (m['quantity'] as int?) ?? 0;
                            final String unit = m['unit']?.toString() ?? '';

                            return GestureDetector(
                              onTap: () => _showSellDialog(m),
                              child: Card(
                                color: Colors.white.withOpacity(0.10),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            backgroundColor: Colors.redAccent,
                                            radius: 18,
                                            child: Icon(
                                              Icons.health_and_safety,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
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
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white54,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "🏭 $mfr  |  Stock: $qty $unit",
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _limitBadge(
                                            "Max/Tx: $maxTx",
                                            Colors.orange,
                                          ),
                                          const SizedBox(width: 8),
                                          _limitBadge(
                                            "Max/Week: $maxWeek",
                                            Colors.redAccent,
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

  Widget _limitBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
