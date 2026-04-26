import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/login_page.dart';

class RegulatoryHome extends StatefulWidget {
  const RegulatoryHome({super.key});

  @override
  State<RegulatoryHome> createState() => _RegulatoryHomeState();
}

class _RegulatoryHomeState extends State<RegulatoryHome> {
  bool _isLoading = true;
  bool _profileExists = false;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  // Verification logic to ensure the profile exists in Supabase
  Future<void> _checkProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _profileExists = data != null;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _profileExists = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileExists = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while checking the database
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );
    }

    // Handle the case where the profile was not found
    if (!_profileExists) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "Profile Not Found",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyLogin()),
                ),
                child: const Text("Go Back to Login"),
              ),
            ],
          ),
        ),
      );
    }

    // YOUR ORIGINAL UI (UNTOUCHED)
    return Scaffold(
      body: Stack(
        children: [
          // 🌄 BACKGROUND
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
                      _section("📊 Monitoring & Audit"),
                      _tile("Violation Logs", Icons.report),
                      _tile("Suspicious Activity", Icons.warning),
                      _tile("Audit Reports", Icons.description),
                      const SizedBox(height: 12),
                      _section("🏥 Compliance & Verification"),
                      _tile("Pharmacy Verification", Icons.verified),
                      _tile("Medicine Traceability", Icons.track_changes),
                      _tile("Stock Authenticity Check", Icons.fact_check),
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
  // UI HELPER METHODS (EXACTLY AS YOU WROTE THEM)
  // =========================

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "GuardianPharma",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await supabase.auth.signOut();
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
        border: Border.all(color: Colors.redAccent),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield, color: Colors.redAccent),
          SizedBox(width: 10),
          Text(
            "REGULATORY AUTHORITY",
            style: TextStyle(
              color: Colors.redAccent,
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

  Widget _tile(String title, IconData icon) {
    return Card(
      color: Colors.white.withOpacity(0.10),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.white,
        ),
        onTap: () {},
      ),
    );
  }
}
