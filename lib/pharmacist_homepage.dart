import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/login_page.dart';
import 'package:guardianpharma/cartontracking_page.dart';
import 'package:guardianpharma/sell_medicine_page.dart';
import 'package:guardianpharma/scan_barcode_page.dart';
import 'package:guardianpharma/add_medicine_page.dart';
import 'package:guardianpharma/transaction_history_page.dart';
import 'package:guardianpharma/inventory_and_medicine_lookup_page.dart';
import 'package:guardianpharma/substitute_finder_page.dart';
import 'package:guardianpharma/expiry_alerts_page.dart';
import 'package:guardianpharma/fefo_system_page.dart';
import 'package:guardianpharma/lethal_dose_protection_page.dart';

class PharmacistHome extends StatelessWidget {
  const PharmacistHome({super.key});

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
                _topBar(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _headerBox(),
                      const SizedBox(height: 16),

                      _section("🧾 Sales & Dispensing"),
                      _tile(
                        context,
                        "Sell Medicine",
                        Icons.point_of_sale,
                        subtitle: "Strip, box or carton sales",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SellMedicinePage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Scan Barcode",
                        Icons.qr_code_scanner,
                        subtitle: "Scan medicine barcode",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScanBarcodePage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Transaction History",
                        Icons.receipt_long,
                        subtitle: "View all sales records",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionHistoryPage(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _section("📦 Inventory Management"),
                      _tile(
                        context,
                        "Inventory & Medicine Lookup",
                        Icons.inventory,
                        subtitle: "View & search stock",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InventoryListPage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Add Medicine",
                        Icons.add_box,
                        subtitle: "Add new medicine to stock",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddMedicinePage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Carton Tracking",
                        Icons.widgets,
                        subtitle: "Manage manufacturers & boxes",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartonTrackingPage(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _section("⚠️ Safety & Control"),
                      _tile(
                        context,
                        "Expiry Alerts",
                        Icons.warning_amber,
                        subtitle: "Check expired & expiring medicines",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExpiryAlertsPage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "FEFO System",
                        Icons.autorenew,
                        subtitle: "First expiry first out tracking",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FefoSystemPage(),
                          ),
                        ),
                      ),
                      _tile(
                        context,
                        "Lethal Dose Protection",
                        Icons.health_and_safety,
                        subtitle: "OTP verified overdose protection",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LethalDoseProtectionPage(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _section("🔍 Smart Tools"),
                      _tile(
                        context,
                        "Substitute Finder",
                        Icons.find_replace,
                        subtitle: "Find generic substitutes",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubstituteFinderPage(),
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
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.local_pharmacy, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "GuardianPharma",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MyLogin()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _headerBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, color: Colors.greenAccent),
          SizedBox(width: 10),
          Text(
            "PHARMACIST DASHBOARD",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.12),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              )
            : null,
        trailing: Icon(
          onTap != null ? Icons.arrow_forward_ios : Icons.lock_outline,
          size: 14,
          color: onTap != null ? Colors.white70 : Colors.white24,
        ),
        onTap: onTap,
      ),
    );
  }
}
