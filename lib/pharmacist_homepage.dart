import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/login_page.dart';
import 'package:guardianpharma/cartontracking_page.dart';
import 'package:guardianpharma/sell_medicine_page.dart';
import 'package:guardianpharma/scan_barcode_page.dart';
import 'package:guardianpharma/add_medicine_page.dart';
import 'package:guardianpharma/transaction_history_page.dart';
import 'package:guardianpharma/inventory_and_medicine_lookup_page.dart';
import 'package:guardianpharma/expiry_alerts_page.dart';
import 'package:guardianpharma/fefo_system_page.dart';
import 'package:guardianpharma/lethal_dose_protection_page.dart';
import 'package:guardianpharma/substitute_finder_page.dart';
import 'package:guardianpharma/pharmacy_wrapper_page.dart';

class PharmacistHome extends StatelessWidget {
  const PharmacistHome({super.key});

  void _logout(BuildContext context) async {
    PharmacySession.clear();
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MyLogin()),
      (route) => false,
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
            child: Container(color: Colors.black.withOpacity(0.42)),
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

  // =========================
  // TOP BAR
  // same style as regulatory
  // =========================
  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.local_pharmacy, color: Colors.blueAccent, size: 26),
              SizedBox(width: 8),
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
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }

  // =========================
  // HEADER BOX
  // green gradient — matches
  // regulatory blue-teal style
  // =========================
  Widget _headerBox() {
    final String pharmacyName = PharmacySession.pharmacyName ?? "My Pharmacy";
    final String licenseNumber = PharmacySession.licenseNumber ?? '';
    final String address = PharmacySession.pharmacyAddress ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF00695C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // ICON CIRCLE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.local_pharmacy_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pharmacyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (licenseNumber.isNotEmpty)
                  Text(
                    "🪪 $licenseNumber",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                if (address.isNotEmpty)
                  Text(
                    "📍 $address",
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "PHARMACIST DASHBOARD",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  // =========================
  // SECTION — matches regulatory
  // =========================
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // TILE — matches regulatory style
  // =========================
  Widget _tile(
    BuildContext context,
    String title,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.22)),
          ),
          child: Icon(icon, color: Colors.greenAccent, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.white54,
        ),
        onTap: onTap,
      ),
    );
  }
}
