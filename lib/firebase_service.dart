import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  Stream<User?> authState() => auth.authStateChanges();

  Future<User?> login(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User?> signUp(String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> logout() async {
    await auth.signOut();
  }

  DatabaseReference sensorRef() => db.child("sensors");

  DatabaseReference relayRef() => db.child("ESP32_RELAY");

  /// Reference for manual control commands under /control/manual
  DatabaseReference controlManualRef() => db.child("control").child("manual");

  /// Reference for switching the system mode under /control/systemMode
  DatabaseReference controlModeRef() => db.child("control").child("systemMode");
}