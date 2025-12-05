import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _presenceRef = FirebaseDatabase.instance.ref('presence');
  User? user;
  bool isLoading = true;

  AuthService() {
    _auth.authStateChanges().listen((u) {
      user = u;
      if (user != null) {
        _setPresence(true);
      }
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    user = cred.user;
    await _setPresence(true);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    user = cred.user;
    await _setPresence(true);
    notifyListeners();
  }

  Future<void> signOut() async {
    if (user != null) {
      await _setPresence(false);
    }
    await _auth.signOut();
    user = null;
    notifyListeners();
  }

  Future<void> _setPresence(bool online) async {
    if (user == null) return;
    try {
      await _presenceRef.child(user!.uid).set({'online': online, 'lastSeen': DateTime.now().toIso8601String()});
    } catch (e) {
      print('Presence error: $e');
    }
  }
}