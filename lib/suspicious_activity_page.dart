import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuspiciousActivityPage extends StatefulWidget {
  const SuspiciousActivityPage({super.key});

  @override
  State<SuspiciousActivityPage> createState() => _SuspiciousActivityPageState();
}

class _SuspiciousActivityPageState extends State<SuspiciousActivityPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> logs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => loading = true);
    try {
      final res = await supabase
          .from('suspicious_logs')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        logs = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      _error("Failed to load: $e");
      setState(() => loading = false);
    }
  }

  void _showAddDialog() {
    final pharmacyController = TextEditingController();
    final activityController = TextEditingController();
    final descController = TextEditingController();
    final medicineController = TextEditingController();
    final batchController = TextEditingController();
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Flag Suspicious Activity",
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(pharmacyController, "Pharmacy Name", Icons.local_pharmacy),
              const SizedBox(height: 10),
              _field(activityController, "Activity Type", Icons.warning),
              const SizedBox(height: 10),
              _field(
                descController,
                "Description",
                Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              _field(
                medicineController,
                "Medicine Name (optional)",
                Icons.medication,
              ),
              const SizedBox(height: 10),
              _field(batchController, "Batch Number (optional)", Icons.numbers),
              const SizedBox(height: 10),
              _field(
                qtyController,
                "Quantity (optional)",
                Icons.inventory,
                keyboardType: TextInputType.number,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (activityController.text.trim().isEmpty) {
                _error("Activity type required");
                return;
              }
              try {
                await supabase.from('suspicious_logs').insert({
                  'pharmacy_name': pharmacyController.text.trim().isEmpty
                      ? null
                      : pharmacyController.text.trim(),
                  'activity_type': activityController.text.trim(),
                  'description': descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  'medicine_name': medicineController.text.trim().isEmpty
                      ? null
                      : medicineController.text.trim(),
                  'batch_number': batchController.text.trim().isEmpty
                      ? null
                      : batchController.text.trim(),
                  'quantity': qtyController.text.trim().isEmpty
                      ? null
                      : int.tryParse(qtyController.text.trim()),
                  'flagged_by': 'regulatory',
                });
                if (mounted) Navigator.pop(context);
                _loadLogs();
                _success("Activity flagged!");
              } catch (e) {
                _error("Failed: $e");
              }
            },
            child: const Text("Flag", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.white70) : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Suspicious Activity",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadLogs,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.orange),
                        onPressed: _showAddDialog,
                      ),
                    ],
                  ),
                ),

                // SUMMARY
                if (!loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat("Total", "${logs.length}", Colors.white70),
                          _stat(
                            "System Flagged",
                            "${logs.where((l) => l['flagged_by'] == 'system').length}",
                            Colors.orange,
                          ),
                          _stat(
                            "Manual",
                            "${logs.where((l) => l['flagged_by'] == 'regulatory').length}",
                            Colors.blueAccent,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        )
                      : logs.isEmpty
                      ? const Center(
                          child: Text(
                            "No suspicious activity found",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: logs.length,
                          itemBuilder: (_, i) {
                            final log = logs[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.warning,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          log['activity_type']?.toString() ??
                                              '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          log['flagged_by']
                                                  ?.toString()
                                                  .toUpperCase() ??
                                              '',
                                          style: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((log['pharmacy_name'] ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "🏥 ${log['pharmacy_name']}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if ((log['medicine_name'] ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "💊 ${log['medicine_name']}  |  Batch: ${log['batch_number'] ?? 'N/A'}  |  Qty: ${log['quantity'] ?? 'N/A'}",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if ((log['description'] ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      log['description'],
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(log['created_at']),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
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

  Widget _stat(String label, String value, Color color) {
    return Column(
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
    );
  }
}
