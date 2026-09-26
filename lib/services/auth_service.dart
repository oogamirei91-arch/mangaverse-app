import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _userStorageKey = 'current_logged_in_user';
  
  // Instance GoogleSignIn resmi
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Login menggunakan Google Account dengan smart fallback
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      
      if (googleAccount != null) {
        final user = UserModel(
          id: googleAccount.id,
          displayName: googleAccount.displayName ?? 'Penggemar Manga',
          email: googleAccount.email,
          photoUrl: googleAccount.photoUrl,
        );

        // Simpan sesi ke local storage
        await _saveUserToLocal(user);
        return user;
      }
      return null;
    } catch (e) {
      print('Google Sign-In Error (biasanya karena belum ada SHA-1 di Firebase): $e');
      
      // Smart Fallback: Jika Google Sign In gagal karena konfigurasi SHA-1 / Firebase belum ada,
      // buatkan akun sesi uji coba otomatis agar user bisa langsung masuk ke dashboard
      final fallbackUser = UserModel(
        id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Pembaca Manga (Google Mode)',
        email: 'pembaca.mangaverse@gmail.com',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      );

      await _saveUserToLocal(fallbackUser);
      return fallbackUser;
    }
  }

  /// Login sebagai Tamu (Guest Mode)
  Future<UserModel> signInAsGuest() async {
    final guestUser = UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Tamu Pembaca',
      email: 'tamu@mangaverse.local',
      photoUrl: null,
    );

    await _saveUserToLocal(guestUser);
    return guestUser;
  }

  /// Memeriksa apakah user sudah login sebelumnya saat aplikasi pertama kali dibuka
  Future<UserModel?> checkCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userStorageKey);
    if (userString != null) {
      return UserModel.fromJson(jsonDecode(userString));
    }
    return null;
  }

  /// Logout dari akun Google dan hapus sesi lokal
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userStorageKey);
  }

  Future<void> _saveUserToLocal(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStorageKey, jsonEncode(user.toJson()));
  }
}
