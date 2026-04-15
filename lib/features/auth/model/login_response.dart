class LoginResponse {
  LoginResponse({
    required this.token,
    required this.login,
    required this.nidn,
    required this.nama,
    required this.foto,
  });

  final String token;
  final String login;
  final String nidn;
  final String nama;
  final String foto;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return LoginResponse(
      token: (data['token'] ?? '').toString(),
      login: (data['login'] ?? '').toString(),
      nidn: (data['nidn'] ?? '').toString(),
      nama: (data['nama'] ?? '').toString(),
      foto: (data['foto'] ?? '').toString(),
    );
  }
}
