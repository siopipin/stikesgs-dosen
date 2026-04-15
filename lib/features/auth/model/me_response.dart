class MeResponse {
  MeResponse({
    required this.login,
    required this.nidn,
    required this.nama,
    required this.gelar,
    required this.handphone,
    required this.email,
    required this.foto,
    required this.prodi,
  });

  final String login;
  final String nidn;
  final String nama;
  final String gelar;
  final String handphone;
  final String email;
  final String foto;
  final String prodi;

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return MeResponse(
      login: (data['login'] ?? '').toString(),
      nidn: (data['nidn'] ?? '').toString(),
      nama: (data['nama'] ?? '').toString(),
      gelar: (data['gelar'] ?? '').toString(),
      handphone: (data['handphone'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      foto: (data['foto'] ?? '').toString(),
      prodi: (data['prodi'] ?? '').toString(),
    );
  }
}
