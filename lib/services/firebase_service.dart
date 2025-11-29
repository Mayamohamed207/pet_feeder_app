import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();
  static String? _currentUserUid;

  static String get currentUserUid => _currentUserUid ??= _auth.currentUser?.uid ?? '';

  static Future<UserCredential?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _currentUserUid = userCredential.user?.uid;
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  static DatabaseReference get statusRef => _db.child("users/$currentUserUid/status");
  static DatabaseReference get feedingLogsRef => _db.child("users/$currentUserUid/feedingLogs");
  static DatabaseReference get settingsRef => _db.child("users/$currentUserUid/settings");
  static DatabaseReference get commandsRef => _db.child("users/$currentUserUid/commands/dispenseNow");

  static Stream<Map<String, dynamic>?> get deviceStatusStream =>
      _db.child('devices/esp1/status').onValue.map((event) {
        final data = event.snapshot.value;
        if (data is Map) return Map<String, dynamic>.from(data);
        return null;
      });

  static Stream<Map<String, dynamic>?> get statusStream =>
      statusRef.onValue.map((event) {
        final data = event.snapshot.value;
        if (data is Map) return Map<String, dynamic>.from(data);
        return null;
      });

  static Stream<Map<String, dynamic>?> get settingsStream =>
      settingsRef.onValue.map((event) {
        final data = event.snapshot.value;
        if (data is Map) return Map<String, dynamic>.from(data);
        return null;
      });

  static Future<void> feedNow(int portionDispensed) async {
    final logId = '-log_${Random().nextInt(1000000)}';
    
    await feedingLogsRef.child(logId).set({
      "mlOutcome": "pending",
      "portionDispensed": portionDispensed,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });

    await commandsRef.set({
      "status": "pending",
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });

    final snapshot = await statusRef.child('currentFoodWeight').get();
    final currentWeight = (snapshot.value as num?)?.toInt() ?? 0;
    await statusRef.update({
      "currentFoodWeight": (currentWeight - portionDispensed).clamp(0, currentWeight),
      "lastUpdated": DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    _currentUserUid = null;
  }
}
