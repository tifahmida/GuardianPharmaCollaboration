import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockAuthenticityPage extends StatefulWidget {
  const StockAuthenticityPage({super.key});

  @override
  State<StockAuthenticityPage> createState() => _StockAuthenticityPageState();
}

class _StockAuthenticityPageState extends State<StockAuthenticityPage> {
  final supabase = Supabase.instance.client;

  final batchController = TextEditingController();

  Map<String, dynamic>? result;

  bool searching = false;
  bool searched = false;

  @override
  void dispose() {
    batchController.dispose();
    super.dispose();
  }

  // =========================
  // VERIFY BATCH
  // =========================
  Future<void> _verify() async {
    final batch = batchController.text.trim();

    if (batch.isEmpty) return;

    setState(() {
      searching = true;
      searched = false;
      result = null;
    });

    try {
      final res = await supabase
          .from('medicine_boxes')
          .select('*, cartons(*, manufacturers(name,country))')
          .eq('batch_number', batch)
          .maybeSingle();

      Map<String, dynamic>? enriched = res != null
          ? Map<String, dynamic>.from(res)
          : null;

      // pharmacy info
      if (enriched != null && enriched['pharmacy_id'] != null) {
        try {
          final pharmacy = await supabase
              .from('pharmacies')
              .select('name, license_number')
              .eq('id', enriched['pharmacy_id'])
              .maybeSingle();

          if (pharmacy != null) {
            enriched['pharmacy_info'] = Map<String, dynamic>.from(pharmacy);
          }
        } catch (_) {}
      }

      setState(() {
        result = enriched;
        searching = false;
        searched = true;
      });
    } catch (e) {
      setState(() {
        searching = false;
        searched = true;
        result = null;
      });
    }
  }

  // =========================
  // INFO ROW
  // =========================
  Widget _infoRow(String label, String value, {Color? valueColor}) {
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

  // =========================
  // MAIN UI
  // =========================
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
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Icon(Icons.fact_check, color: Colors.amber),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Stock Authenticity Check",
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
                      color: Colors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.30)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 14),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Enter batch number to verify if stock is authentic and registered.",
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

                const SizedBox(height: 16),

                // SEARCH
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: batchController,
                          onSubmitted: (_) => _verify(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.numbers,
                              color: Colors.white70,
                            ),
                            hintText: "Enter batch number...",
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
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: searching ? null : _verify,
                          icon: searching
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.fact_check,
                                  color: Colors.black,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // RESULT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildResultSection(),
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
  // RESULT SECTION
  // =========================
  Widget _buildResultSection() {
    if (!searched) {
      return Column(
        children: const [
          SizedBox(height: 60),
          Icon(Icons.fact_check, color: Colors.white24, size: 70),
          SizedBox(height: 12),
          Text(
            "Enter a batch number to verify",
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      );
    }

    // suspicious
    if (result == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Column(
          children: [
            const Icon(Icons.cancel, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            const Text(
              "⚠️ SUSPICIOUS STOCK",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Batch number \"${batchController.text}\" is not registered in the system.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // found
    final String name = result!['medicine_name']?.toString() ?? '';
    final String generic = result!['generic_name']?.toString() ?? '';
    final String batch = result!['batch_number']?.toString() ?? '';
    final String expiry = result!['expiry_date']?.toString() ?? 'N/A';

    final int qty = (result!['quantity'] as int?) ?? 0;

    final String unit = result!['unit']?.toString() ?? '';

    final String manufacturer =
        result!['cartons']?['manufacturers']?['name']?.toString() ?? 'Unknown';

    final String country =
        result!['cartons']?['manufacturers']?['country']?.toString() ?? 'N/A';

    final Map<String, dynamic>? pharmacyInfo = result!['pharmacy_info'] != null
        ? Map<String, dynamic>.from(result!['pharmacy_info'])
        : null;

    final DateTime? expiryDate = DateTime.tryParse(expiry);

    final bool isExpired =
        expiryDate != null && expiryDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.red.withOpacity(0.12)
            : Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired ? Colors.redAccent : Colors.greenAccent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.warning_rounded : Icons.verified_outlined,
                color: isExpired ? Colors.redAccent : Colors.greenAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isExpired ? "⚠️ AUTHENTIC BUT EXPIRED" : "✅ AUTHENTIC STOCK",
                  style: TextStyle(
                    color: isExpired ? Colors.redAccent : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

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
              "🧬 $generic",
              style: const TextStyle(color: Colors.blueAccent),
            ),

          const SizedBox(height: 10),

          _infoRow("🔢 Batch", batch),
          _infoRow("📦 Qty", "$qty $unit"),
          _infoRow(
            "📅 Expiry",
            expiry,
            valueColor: isExpired ? Colors.redAccent : Colors.greenAccent,
          ),
          _infoRow("🏭 Manufacturer", manufacturer),
          _infoRow("🌍 Country", country),

          if (pharmacyInfo != null) ...[
            const Divider(color: Colors.white24),
            _infoRow("🏥 Pharmacy", pharmacyInfo['name']?.toString() ?? 'N/A'),
            _infoRow(
              "🪪 License",
              pharmacyInfo['license_number']?.toString() ?? 'N/A',
            ),
          ],
        ],
      ),
    );
  }
}
