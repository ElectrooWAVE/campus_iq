import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _profile?.role == 'admin';
  bool get isAuthenticated => _profile != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _loadProfile(user.id);
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn && event.session?.user != null) {
        _loadProfile(event.session!.user.id);
      } else if (event.event == AuthChangeEvent.signedOut) {
        _profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      _profile = await _repo.getProfile(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await _repo.login(email, password);
      _profile = profile;
      return null;
    } catch (e) {
      _error = 'Incorrect email or password. Please try again.';
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signup({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String branch,
    int? year,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repo.signup(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        branch: branch,
        year: year,
      );
      return null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _profile = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
