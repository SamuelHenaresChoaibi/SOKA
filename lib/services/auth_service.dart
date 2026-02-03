import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Login
  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return credential.user;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
  // Registro de usuario
  // Future<User> registerUser(AppUser user, String password) async {
  //   final usernameRef = _db.child('usernames/${user.username}');
  //   final snap = await usernameRef.get();
  //   if (snap.exists) {
  //     throw Exception('USERNAME_EXISTS');
  //   }

  //   final credential = await _auth.createUserWithEmailAndPassword(
  //     email: user.email,
  //     password: password,
  //   );

  //   final uid = credential.user!.uid;

  //   final appUser = AppUser(
  //     uid: uid,
  //     username: user.username,
  //     email: user.email,
  //     name: user.name,
  //     surname: user.surname,
  //     phoneNumber: user.phoneNumber,
  //     createdAt: DateTime.now(),
  //   );

  //   await usernameRef.set(uid);

  //   await _db.child('clients/$uid').set(appUser.toMap());

  //   return appUser;
  // }
}
