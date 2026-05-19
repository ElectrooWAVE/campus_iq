import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<ProfileModel?> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) return null;
    return await getProfile(response.user!.id);
  }

  Future<ProfileModel> signup({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String branch,
    int? year,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Signup failed');

    final userId = response.user!.id;
    await _client.from('profiles').insert({
      'id': userId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'branch': branch,
      'year': year,
    });

    return ProfileModel(
      id: userId,
      fullName: fullName,
      email: email,
      role: role,
      branch: branch,
      year: year,
      createdAt: DateTime.now(),
    );
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<ProfileModel?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(data);
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
