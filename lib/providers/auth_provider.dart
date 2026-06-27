import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/dev_bypass.dart';
import '../models/user.dart';
import '../services/supabase_client.dart';

enum AuthStatus { uninitialized, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  AppUser? _currentUser;
  String _phoneNumber = '';
  bool _isLoading = false;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String get phoneNumber => _phoneNumber;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _tryRestoreSession();
  }

  void _tryRestoreSession() {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null && session.user.phone != null) {
        final phone = '+${session.user.phone!.replaceAll('+', '')}';
        _fetchUser(phone);
        return;
      }
    } catch (_) {
      // Supabase not initialized (e.g. in tests)
    }
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _fetchUser(String phone) async {
    try {
      final result = await SupabaseService.client
          .from('users_whitelist')
          .select('id, phone_number, role')
          .eq('phone_number', phone)
          .single();
      _currentUser = AppUser.fromMap(result);
      _status = AuthStatus.authenticated;
    } catch (e) {
      debugPrint('_fetchUser error: $e');
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    notifyListeners();
  }

  Future<bool> sendOtp() async {
    if (DevBypass.enabled && _phoneNumber == DevBypass.phone) {
      return true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.client.auth.signInWithOtp(
        phone: _phoneNumber,
      );
      return true;
    } catch (e) {
      debugPrint('sendOtp error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (DevBypass.enabled && _phoneNumber == DevBypass.phone) {
        if (code != DevBypass.code) return false;
        _currentUser = AppUser(
          id: 'dev-bypass-id',
          phoneNumber: '0770000000',
          role: UserRole.admin,
        );
        _status = AuthStatus.authenticated;
        return true;
      }

      debugPrint('verifyOtp: phone=$_phoneNumber, code=$code');
      final response = await SupabaseService.client.auth.verifyOTP(
        phone: _phoneNumber,
        token: code,
        type: OtpType.sms,
      );
      debugPrint('verifyOtp: response phone=${response.user?.phone}');

      await _fetchUser(_phoneNumber);
      return _status == AuthStatus.authenticated;
    } catch (e) {
      debugPrint('verifyOtp error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    _currentUser = null;
    _phoneNumber = '';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
