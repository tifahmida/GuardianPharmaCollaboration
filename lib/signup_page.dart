import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardianpharma/login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool agreeToTerms = false;
  String selectedRole = "pharmacist";

  final licenseController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;

  // Pharmacy selection
  List<Map<String, dynamic>> pharmacies = [];
  String? selectedPharmacyId;
  bool loadingPharmacies = false;

  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  final RegExp _licenseRegex = RegExp(r'^\d{16}$');

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  @override
  void dispose() {
    licenseController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // =========================
  // LOAD PHARMACIES
  // =========================
  Future<void> _loadPharmacies() async {
    setState(() => loadingPharmacies = true);
    try {
      final res = await Supabase.instance.client
          .from('pharmacies')
          .select()
          .eq('is_active', true)
          .order('name');
      setState(() {
        pharmacies = List<Map<String, dynamic>>.from(res);
        loadingPharmacies = false;
      });
    } catch (e) {
      setState(() => loadingPharmacies = false);
    }
  }

  // =========================
  // VALIDATIONS
  // =========================
  String? _getPasswordError(String password) {
    if (password.length < 8) return "Password must be at least 8 characters";
    if (!password.contains(RegExp(r'[A-Z]')))
      return "Must contain at least one uppercase letter";
    if (!password.contains(RegExp(r'[0-9]')))
      return "Must contain at least one number";
    if (!password.contains(
      RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]{};:"\\|,.<>\/?]'),
    ))
      return "Must contain at least one special character";
    return null;
  }

  String? _getEmailError(String email) {
    if (email.isEmpty) return "Email is required";
    if (!_emailRegex.hasMatch(email)) return "Enter a valid email address";
    return null;
  }

  String? _getLicenseError(String license) {
    if (license.isEmpty) return "License number is required";
    if (!_licenseRegex.hasMatch(license))
      return "License number must be exactly 16 digits";
    return null;
  }

  // =========================
  // SIGNUP LOGIC
  // =========================
  Future<void> signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();
    final license = licenseController.text.trim();

    // Validate name
    if (name.isEmpty) {
      _error("Full name is required");
      return;
    }

    // Validate email
    final emailError = _getEmailError(email);
    if (emailError != null) {
      _error(emailError);
      return;
    }

    // Validate password
    final passwordError = _getPasswordError(password);
    if (passwordError != null) {
      _error(passwordError);
      return;
    }

    // Validate confirm password
    if (password != confirm) {
      _error("Passwords do not match");
      return;
    }

    // Validate terms
    if (!agreeToTerms) {
      _error("You must accept terms & conditions");
      return;
    }

    // Validate license for regulatory
    if (selectedRole == "regulatory") {
      final licenseError = _getLicenseError(license);
      if (licenseError != null) {
        _error(licenseError);
        return;
      }
    }

    // ✅ Pharmacist MUST select a pharmacy
    if (selectedRole == "pharmacist" && selectedPharmacyId == null) {
      _error("Please select your pharmacy");
      return;
    }

    setState(() => loading = true);

    try {
      // Step 1: Create auth user
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'role': selectedRole,
          'license_number': selectedRole == "regulatory" ? license : null,
        },
      );

      if (res.user == null) throw "Signup failed";

      // Step 2: Save profile with pharmacy_id locked in
      await Supabase.instance.client.from('profiles').upsert({
        'id': res.user!.id,
        'full_name': name,
        'email': email,
        'role': selectedRole,
        'license_number': selectedRole == "regulatory" ? license : null,
        // ✅ Pharmacy locked to this account forever
        'pharmacy_id': selectedRole == "pharmacist" ? selectedPharmacyId : null,
      });

      debugPrint("✅ Profile created with pharmacy: $selectedPharmacyId");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created! Please login."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyLogin()),
      );
    } catch (e) {
      _error(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),
          Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    width: 350,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ICON
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            color: Colors.blueAccent,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          "Create Account",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 26),

                        // FULL NAME
                        _buildInput(nameController, "Full Name", Icons.person),
                        const SizedBox(height: 12),

                        // EMAIL
                        _buildInput(
                          emailController,
                          "Email",
                          Icons.email_outlined,
                        ),
                        const SizedBox(height: 12),

                        // PASSWORD
                        _buildInput(
                          passwordController,
                          "Password",
                          Icons.lock_outline,
                          isPass: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: const Text(
                            "Min 8 chars, 1 uppercase, 1 number, 1 special char",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // CONFIRM PASSWORD
                        _buildInput(
                          confirmController,
                          "Confirm Password",
                          Icons.lock_reset,
                          isPass: true,
                        ),
                        const SizedBox(height: 12),

                        // ROLE DROPDOWN
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButton<String>(
                            value: selectedRole,
                            dropdownColor: Colors.black,
                            underline: const SizedBox(),
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white),
                            items: const [
                              DropdownMenuItem(
                                value: "pharmacist",
                                child: Text("Pharmacist"),
                              ),
                              DropdownMenuItem(
                                value: "regulatory",
                                child: Text("Regulatory Authority"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value!;
                                // Reset pharmacy selection if role changes
                                selectedPharmacyId = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ✅ PHARMACY SELECTION — only for pharmacist
                        if (selectedRole == "pharmacist") ...[
                          // Section label
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Select Your Pharmacy *",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          loadingPharmacies
                              ? Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.blueAccent,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              : pharmacies.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "No pharmacies available.\nContact your Regulatory Authority.",
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: selectedPharmacyId != null
                                        ? Border.all(
                                            color: Colors.blueAccent
                                                .withOpacity(0.5),
                                          )
                                        : null,
                                  ),
                                  child: DropdownButton<String>(
                                    value: selectedPharmacyId,
                                    dropdownColor: const Color(0xFF1A1A2E),
                                    underline: const SizedBox(),
                                    isExpanded: true,
                                    hint: const Text(
                                      "Choose your pharmacy",
                                      style: TextStyle(color: Colors.white38),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    items: pharmacies.map((p) {
                                      return DropdownMenuItem<String>(
                                        value: p['id'].toString(),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              p['name'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              p['license_number'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => selectedPharmacyId = val);
                                    },
                                  ),
                                ),

                          // Show selected pharmacy info
                          if (selectedPharmacyId != null) ...[
                            const SizedBox(height: 8),
                            Builder(
                              builder: (_) {
                                final selected = pharmacies.firstWhere(
                                  (p) =>
                                      p['id'].toString() == selectedPharmacyId,
                                  orElse: () => {},
                                );
                                if (selected.isEmpty) {
                                  return const SizedBox();
                                }
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.blueAccent,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selected['name'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if ((selected['address'] ?? '')
                                                .isNotEmpty)
                                              Text(
                                                "📍 ${selected['address']}",
                                                style: const TextStyle(
                                                  color: Colors.white54,
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
                          ],

                          // Warning — locked forever
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.lock, color: Colors.orange, size: 12),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "This pharmacy will be permanently linked to your account",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // LICENSE (regulatory only)
                        if (selectedRole == "regulatory") ...[
                          _buildInput(
                            licenseController,
                            "License Number (16 digits)",
                            Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            maxLength: 16,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              "Must be exactly 16 numeric digits",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // TERMS
                        Row(
                          children: [
                            Checkbox(
                              value: agreeToTerms,
                              onChanged: (v) =>
                                  setState(() => agreeToTerms = v!),
                              activeColor: Colors.blueAccent,
                            ),
                            const Expanded(
                              child: Text(
                                "I agree to the Terms & Conditions",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // SIGN UP BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                            ),
                            onPressed: loading ? null : signup,
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyLogin(),
                              ),
                            );
                          },
                          child: const Text(
                            "Already have an account? Log in",
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        counterStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
