import 'package:expense_splitter/Presentation/PeoplePage/people_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  bool isLogin = true;
  String email = '';
  String password = '';
  final _formKey = GlobalKey<FormState>();

  void _submitAuthForm() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      // Navigate to PeopleScreen after successful login/signup
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (ctx) => PeopleScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  } // Authentication method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,

        title: Center(
          child: Text(
            "Login / Signup",
            style: GoogleFonts.braahOne(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 80),
            Center(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Icon(
                          Icons.currency_rupee,
                          color: Colors.blue,
                          size: 150,
                        ),
                      ),
                      SizedBox(height: 15),

                      Text(
                        "Expense",
                        style: GoogleFonts.braahOne(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                      Text(
                        "Splitter",
                        style: GoogleFonts.braahOne(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintStyle: GoogleFonts.braahOne(
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontSize: 18,
                            ),
                            prefixIcon: Icon(Icons.mail, color: Colors.black),
                            border: InputBorder.none,
                            hintText: "Email",
                          ),
                          key: ValueKey('email'),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => email = value!,
                          validator: (value) =>
                              value!.isEmpty || !value.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextFormField(
                          key: const ValueKey('password'),
                          decoration: InputDecoration(
                            hintStyle: GoogleFonts.braahOne(
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontSize: 18,
                            ),
                            prefixIcon: Icon(
                              Icons.password,
                              color: Colors.black,
                            ),
                            border: InputBorder.none,
                            hintText: "Password",
                          ),
                          obscureText: true,
                          onSaved: (value) => password = value!,
                          validator: (value) => value!.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: _submitAuthForm,
                        child: Text(
                          isLogin ? 'Login' : 'Signup',
                          style: GoogleFonts.braahOne(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => isLogin = !isLogin);
                        },
                        child: Text(
                          isLogin
                              ? 'Create new account'
                              : 'Already have an account? Login',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
