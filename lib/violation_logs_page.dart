import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViolationLogsPage extends StatefulWidget {
  const ViolationLogsPage({super.key});

  @override
  State<ViolationLogsPage> createState() => _ViolationLogsPageState();
}

class _ViolationLogsPageState extends State<ViolationLogsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> logs = [];
  bool loading = true;
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'critical', 'high', 'medium', 'low'];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => loading = true);
    try {
      var query = supabase
          .from('violation_logs')
          .select()
          .order('created_at', ascending: false);

      final res = await query;
      List<Map<String, dynamic>> all = List<Map<String, dynamic>>.from(res);

      if (selectedFilter != 'All') {
        all = all.where((l) => l['severity'] == selectedFilter).toList();
      }

      setState(() {
        logs = all;
        loading = false;
      });
    } catch (e) {
      _error("Failed to load: $e");
      setState(() => loading = false);
    }
  }

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'critical':
        return Colors.redAccent;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  IconData _severityIcon(String? severity) {
    switch (severity) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning_rounded;
      case 'medium':
        return Icons.warning_amber;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.help_outline;
    }
  }

  void _showAddViolationDialog() {
    final pharmacyController = TextEditingController();
    final typeController = TextEditingController();
    final descController = TextEditingController();
    String selectedSeverity = 'medium';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text(
            "Log Violation",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  pharmacyController,
                  "Pharmacy Name",
                  Icons.local_pharmacy,
                ),
                const SizedBox(height: 10),
                _field(typeController, "Violation Type", Icons.report),
                const SizedBox(height: 10),
                _field(
                  descController,
                  "Description",
                  Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Severity:",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['low', 'medium', 'high', 'critical'].map((s) {
                    final color = _severityColor(s);
                    final isSelected = selectedSeverity == s;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedSeverity = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.3)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : Colors.white24,
                          ),
                        ),
                        child: Text(
                          s.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? color : Colors.white54,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                if (typeController.text.trim().isEmpty) {
                  _error("Violation type required");
                  return;
                }
                try {
                  await supabase.from('violation_logs').insert({
                    'pharmacy_name': pharmacyController.text.trim().isEmpty
                        ? null
                        : pharmacyController.text.trim(),
                    'violation_type': typeController.text.trim(),
                    'description': descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    'severity': selectedSeverity,
                    'reported_by': supabase.auth.currentUser?.id,
                  });
                  if (mounted) Navigator.pop(context);
                  _loadLogs();
                  _success("Violation logged!");
                } catch (e) {
                  _error("Failed: $e");
                }
              },
              child: const Text("Log", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
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
                // TOP BAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.report, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Violation Logs",
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
                        icon: const Icon(Icons.add, color: Colors.redAccent),
                        onPressed: _showAddViolationDialog,
                        tooltip: "Log Violation",
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
                      final f = filters[i];
                      final isSelected = f == selectedFilter;
                      final color = f == 'All'
                          ? Colors.blueAccent
                          : _severityColor(f);
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedFilter = f);
                          _loadLogs();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.3)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? color : Colors.white24,
                            ),
                          ),
                          child: Text(
                            f == 'All' ? 'All' : f.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? color : Colors.white60,
                              fontSize: 12,
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

                const SizedBox(height: 10),

                // SUMMARY
                if (!loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _countBadge("Total", "${logs.length}", Colors.white70),
                        const SizedBox(width: 8),
                        _countBadge(
                          "Critical",
                          "${logs.where((l) => l['severity'] == 'critical').length}",
                          Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        _countBadge(
                          "High",
                          "${logs.where((l) => l['severity'] == 'high').length}",
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // LIST
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                          ),
                        )
                      : logs.isEmpty
                      ? const Center(
                          child: Text(
                            "No violations found",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: logs.length,
                          itemBuilder: (_, i) {
                            final log = logs[i];
                            final severity = log['severity']?.toString();
                            final color = _severityColor(severity);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _severityIcon(severity),
                                      color: color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                log['violation_type']
                                                        ?.toString() ??
                                                    '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                severity?.toUpperCase() ?? '',
                                                style: TextStyle(
                                                  color: color,
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

  Widget _countBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
