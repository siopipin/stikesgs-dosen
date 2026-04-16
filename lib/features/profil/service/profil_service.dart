import '../../../core/network/api_client.dart';
import '../model/profil_response.dart';

class ProfilService {
  ProfilService(this._apiClient);

  final ApiClient _apiClient;

  Future<ProfilResponse> getProfil() async {
    final response = await _apiClient.get('profil');
    return ProfilResponse.fromJson(response);
  }

  Future<ProfilResponse> updateProfil({
    required String email,
    required String handphone,
  }) async {
    final response = await _apiClient.put(
      'profil',
      body: {
        'email': email,
        'handphone': handphone,
      },
    );
    return ProfilResponse.fromJson(response);
  }

  Future<void> updateFoto({
    required String filePath,
  }) async {
    await _apiClient.putMultipart(
      'profil/foto',
      fileField: 'foto',
      filePath: filePath,
    );
  }

  Future<void> updatePassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    await _apiClient.put(
      'profil/password',
      body: {
        'password_lama': passwordLama,
        'password_baru': passwordBaru,
      },
    );
  }
}
