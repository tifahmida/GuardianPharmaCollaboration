import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/pharmacy_wrapper_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> sales = [];
  bool loading = true;
  String selectedFilter = 'Today';

  final List<String> filters = ['Today', 'This Week', 'This Month', 'All Time'];

  double totalRevenue = 0;
  int totalTransactions = 0;
  int totalStrips = 0;
  int totalBoxes = 0;
  int totalCartons = 0;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  DateTime _toBDTime(String isoString) {
    final utc = DateTime.parse(isoString).toUtc();
    return utc.add(const Duration(hours: 6));
  }

  String _formatTime(String isoString) {
    final dt = _toBDTime(isoString);
    final int hour = dt.hour;
    final int minute = dt.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int hour12 = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    return "${hour12.toString().padLeft(2, '0')}:"
        "${minute.toString().padLeft(2, '0')} $period";
  }

  String _formatDate(String isoString) {
    final dt = _toBDTime(isoString);
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}";
  }

  // =========================
  // LOAD SALES
  // ✅ filtered by pharmacy_id
  // =========================
  Future<void> _loadSales() async {
    setState(() => loading = true);

    try {
      final now = DateTime.now().toUtc();
      final todayStart = DateTime.utc(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime.utc(now.year, now.month, 1);

      final String pharmacyId = PharmacySession.pharmacyId ?? '';

      List<Map<String, dynamic>> res = [];

      if (selectedFilter == 'Today') {
        final result = await supabase
            .from('sales')
            .select('*, profiles(full_name)')
            .eq('pharmacy_id', pharmacyId)
            .gte('created_at', todayStart.toIso8601String())
            .order('created_at', ascending: false);
        res = List<Map<String, dynamic>>.from(result);
      } else if (selectedFilter == 'This Week') {
        final result = await supabase
            .from('sales')
            .select('*, profiles(full_name)')
            .eq('pharmacy_id', pharmacyId)
            .gte('created_at', weekStart.toIso8601String())
            .order('created_at', ascending: false);
        res = List<Map<String, dynamic>>.from(result);
      } else if (selectedFilter == 'This Month') {
        final result = await supabase
            .from('sales')
            .select('*, profiles(full_name)')
            .eq('pharmacy_id', pharmacyId)
            .gte('created_at', monthStart.toIso8601String())
            .order('created_at', ascending: false);
        res = List<Map<String, dynamic>>.from(result);
      } else {
        final result = await supabase
            .from('sales')
            .select('*, profiles(full_name)')
            .eq('pharmacy_id', pharmacyId)
            .order('created_at', ascending: false);
        res = List<Map<String, dynamic>>.from(result);
      }

      double revenue = 0;
      int strips = 0;
      int boxes = 0;
      int cartons = 0;

      for (final sale in res) {
        revenue += double.tryParse(sale['total_amount'].toString()) ?? 0;
        final String type = sale['sale_type']?.toString() ?? '';
        final int qty = (sale['quantity_sold'] as int?) ?? 0;
        if (type == 'strip') strips += qty;
        if (type == 'box') boxes += qty;
        if (type == 'carton') cartons += qty;
      }

      setState(() {
        sales = res;
        totalRevenue = revenue;
        totalTransactions = res.length;
        totalStrips = strips;
        totalBoxes = boxes;
        totalCartons = cartons;
        loading = false;
      });
    } catch (e) {
      _error("Failed to load: $e");
      setState(() => loading = false);
    }
  }

  // =========================
  // DELETE SALE
  // =========================
  void _deleteSale(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Delete Transaction",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this transaction?",
          style: TextStyle(color: Colors.white70),
        ),
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
    if (confirm != true) return;
    try {
      await supabase.from('sales').delete().eq('id', id);
      _success("Transaction deleted!");
      _loadSales();
    } catch (e) {
      _error("Error: $e");
    }
  }

  // =========================
  // SALE DETAIL BOTTOM SHEET
  // =========================
  void _showSaleDetail(Map<String, dynamic> sale) {
    final String dateStr = _formatDate(sale['created_at']);
    final String timeStr = _formatTime(sale['created_at']);
    final String soldBy =
        sale['profiles']?['full_name']?.toString() ?? 'Unknown';
    final String customer = sale['customer_name']?.toString() ?? '';

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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long,
                color: Colors.blueAccent,
                size: 36,
              ),
              const SizedBox(height: 8),
              const Text(
                "Transaction Receipt",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // DATE + TIME
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white54,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    color: Colors.white54,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "(BD)",
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white24),

              _detailRow(
                "💊 Medicine",
                sale['medicine_name']?.toString() ?? 'N/A',
              ),
              _detailRow("🔢 Batch", sale['batch_number']?.toString() ?? 'N/A'),
              _detailRow(
                "📦 Sale Type",
                (sale['sale_type']?.toString() ?? '').toUpperCase(),
              ),
              _detailRow(
                "🔢 Quantity",
                sale['quantity_sold']?.toString() ?? '0',
              ),
              _detailRow(
                "💰 Unit Price",
                "BDT ${double.tryParse(sale['unit_price'].toString())?.toStringAsFixed(2) ?? '0.00'}",
              ),

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
                    "BDT ${double.tryParse(sale['total_amount'].toString())?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              _detailRow("👨‍⚕️ Sold By", soldBy),
              if (customer.isNotEmpty) _detailRow("👤 Customer", customer),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text(
                    "Delete Transaction",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteSale(sale['id']);
                  },
                ),
              ),
              const SizedBox(height: 20),
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

  void _success(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  IconData _saleIcon(String type) {
    if (type == 'strip') return Icons.medication;
    if (type == 'box') return Icons.inventory_2;
    return Icons.widgets;
  }

  Color _saleColor(String type) {
    if (type == 'strip') return Colors.blueAccent;
    if (type == 'box') return Colors.greenAccent;
    return Colors.orangeAccent;
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
                      const Icon(Icons.receipt_long, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Transaction History",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadSales,
                      ),
                    ],
                  ),
                ),

                // FILTER CHIPS
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filters.length,
                    itemBuilder: (_, i) {
                      final String f = filters[i];
                      final bool isSelected = f == selectedFilter;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedFilter = f);
                          _loadSales();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.white24,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // SUMMARY CARDS
                if (!loading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "💰 Total Revenue",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "BDT ${totalRevenue.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "$totalTransactions transactions",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _miniStat(
                              "💊 Strips",
                              totalStrips.toString(),
                              Colors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            _miniStat(
                              "📦 Boxes",
                              totalBoxes.toString(),
                              Colors.greenAccent,
                            ),
                            const SizedBox(width: 8),
                            _miniStat(
                              "🏭 Cartons",
                              totalCartons.toString(),
                              Colors.orangeAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // SALES LIST
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent,
                          ),
                        )
                      : sales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                color: Colors.white24,
                                size: 60,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No transactions for $selectedFilter",
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sales.length,
                          itemBuilder: (_, int i) {
                            final Map<String, dynamic> sale = sales[i];
                            final String type =
                                sale['sale_type']?.toString() ?? '';
                            final double total =
                                double.tryParse(
                                  sale['total_amount'].toString(),
                                ) ??
                                0;
                            final String customer =
                                sale['customer_name']?.toString() ?? '';
                            final String soldBy =
                                sale['profiles']?['full_name']?.toString() ??
                                'Unknown';

                            return GestureDetector(
                              onTap: () => _showSaleDetail(sale),
                              child: Card(
                                color: Colors.white.withOpacity(0.10),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: _saleColor(
                                          type,
                                        ).withOpacity(0.2),
                                        child: Icon(
                                          _saleIcon(type),
                                          color: _saleColor(type),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sale['medicine_name']
                                                      ?.toString() ??
                                                  'Unknown',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Batch: ${sale['batch_number']}  |  ${type.toUpperCase()}  |  Qty: ${sale['quantity_sold']}",
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              "👨‍⚕️ $soldBy",
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  _formatDate(
                                                    sale['created_at'],
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const Text(
                                                  "  •  ",
                                                  style: TextStyle(
                                                    color: Colors.white38,
                                                  ),
                                                ),
                                                Text(
                                                  _formatTime(
                                                    sale['created_at'],
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                if (customer.isNotEmpty) ...[
                                                  const Text(
                                                    "  •  ",
                                                    style: TextStyle(
                                                      color: Colors.white38,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      "👤 $customer",
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 11,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "BDT ${total.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const Text(
                                            "tap for details",
                                            style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 10,
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

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
