import '../../../core/network/api_client.dart';
import '../model/login_response.dart';
import '../model/me_response.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginResponse> login({
    required String nidn,
    required String password,
  }) async {
    final response = await _apiClient.post(
      'auth/login',
      authRequired: false,
      body: {
        'nidn': nidn,
        'password': password,
      },
    );
    return LoginResponse.fromJson(response);
  }

  Future<MeResponse> getMe() async {
    final response = await _apiClient.get('auth/me');
    return MeResponse.fromJson(response);
  }
}
