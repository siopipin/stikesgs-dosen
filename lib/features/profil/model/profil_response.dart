class ProfilResponse {
  ProfilResponse({
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

  factory ProfilResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return ProfilResponse(
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

  ProfilResponse copyWith({
    String? login,
    String? nidn,
    String? nama,
    String? gelar,
    String? handphone,
    String? email,
    String? foto,
    String? prodi,
  }) {
    return ProfilResponse(
      login: login ?? this.login,
      nidn: nidn ?? this.nidn,
      nama: nama ?? this.nama,
      gelar: gelar ?? this.gelar,
      handphone: handphone ?? this.handphone,
      email: email ?? this.email,
      foto: foto ?? this.foto,
      prodi: prodi ?? this.prodi,
    );
  }
}
