import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DoctorApp());
}

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Clinics',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const ClinicsListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ===============================
// 1️⃣ Clinics List Page (with real-time auth)
// ===============================
class ClinicsListPage extends StatelessWidget {
  const ClinicsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Available Clinics'),
            actions: [
              TextButton(
                onPressed: () {
                  if (user == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                    );
                  } else {
                    FirebaseAuth.instance.signOut();
                  }
                },
                child: Text(
                  user == null ? 'Sign In' : 'Sign Out',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctor_clinics')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No clinics found'));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(data['name'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📧 ${data['email']}"),
                          Text("📞 ${data['phone']}"),
                          Text("🏥 ${data['clinic_address']}"),
                          Text("🎓 ${data['qualification']}"),
                          Text("🆔 ${data['medical_id']}"),
                          Text("🗓️ ${data['clinic_timing']}"),
                          Text("📅 ${data['registration_council_year']}"),
                          Text("🧠 ${data['experience']} years"),
                          Text("✅ Admin Approved: ${data['admin_approved'] ?? false}"),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: user != null
              ? FloatingActionButton(
                  child: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddClinicPage()),
                    );
                  },
                )
              : null,
        );
      },
    );
  }
}

// ===============================
// 2️⃣ Authentication Page
// ===============================
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;

  Future<void> _submitAuthForm() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Sign In' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitAuthForm,
              child: Text(isLogin ? 'Sign In' : 'Register'),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? 'Create new account' : 'I already have an account'),
            )
          ],
        ),
      ),
    );
  }
}

// ===============================
// 3️⃣ Add Clinic Page (resets form after saving)
// ===============================
class AddClinicPage extends StatefulWidget {
  const AddClinicPage({super.key});

  @override
  State<AddClinicPage> createState() => _AddClinicPageState();
}

class _AddClinicPageState extends State<AddClinicPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _medicalIdController = TextEditingController();
  final _registrationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _clinicTimingController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        await FirebaseFirestore.instance.collection('doctor_clinics').add({
          'name': _nameController.text.trim(),
          'email': user.email,
          'phone': _phoneController.text.trim(),
          'clinic_address': _clinicAddressController.text.trim(),
          'medical_id': _medicalIdController.text.trim(),
          'registration_council_year': _registrationController.text.trim(),
          'experience': _experienceController.text.trim(),
          'qualification': _qualificationController.text.trim(),
          'clinic_timing': _clinicTimingController.text.trim(),
          'admin_approved': false,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Reset form
        _formKey.currentState!.reset();
        _nameController.clear();
        _phoneController.clear();
        _clinicAddressController.clear();
        _medicalIdController.clear();
        _registrationController.clear();
        _experienceController.clear();
        _qualificationController.clear();
        _clinicTimingController.clear();

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clinic added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value!.isEmpty ? 'Enter $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Clinic')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, 'Name'),
              _buildTextField(_phoneController, 'Phone Number', inputType: TextInputType.phone),
              _buildTextField(_clinicAddressController, 'Clinic Address'),
              _buildTextField(_medicalIdController, 'Medical ID Number'),
              _buildTextField(_registrationController, 'Registration Council & Year'),
              _buildTextField(_experienceController, 'Years of Experience', inputType: TextInputType.number),
              _buildTextField(_qualificationController, 'Qualification'),
              _buildTextField(_clinicTimingController, 'Clinic Timing'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Clinic'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
