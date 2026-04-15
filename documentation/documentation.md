# Panduan Implementasi Mobile Flutter (RuangDosen)

Dokumen ini menjadi panduan teknis untuk membangun aplikasi mobile Flutter berdasarkan API dosen yang sudah siap dan sudah diuji pada `documentation/dosen.md`.

---

## 1. Tujuan Dokumen

- Menjadi acuan implementasi Flutter agar konsisten dengan kontrak API backend dosen.
- Menjelaskan alur fitur, mapping endpoint, format data, dan pola error handling.
- Menjadi checklist integrasi sampai aplikasi siap dipakai user dosen.

---

## 2. Baseline Integrasi Backend

- Prefix API dosen: `/dosen/v1`
- Referensi kontrak endpoint: `documentation/dosen.md` (bagian `2.0` s.d. `2.7`)
- Pola response backend:
  - sukses: `200` dengan object `data`
  - validasi gagal: `400`
  - tidak ditemukan: `404`
  - server error: `500`
- Semua endpoint fitur dosen (kecuali login) wajib `Authorization: Bearer <token>`.

Checklist kesesuaian kebutuhan client (ringkas):

- Dashboard dosen: **sudah tercakup** (`GET dashboard`).
- Jadwal mengajar: **sudah tercakup** (`GET jadwal-mengajar`).
- Presensi QR: **sudah tercakup** (aktif/start/kehadiran/koreksi/end), termasuk rule auto close 20 menit dari backend.
- Input nilai: **sudah tercakup** (`jadwal-input`, `mahasiswa`, `update`) dengan rule koordinator tim di backend.
- Notifikasi akademik: **sudah tercakup** (`list`, `total`, `baca`, `tambah` opsional).
- Bimbingan akademik (PA): **sudah tercakup** (list mahasiswa + CRUD log).
- Ubah profil: **sudah tercakup** (`profil`, `profil/foto`, `profil/password`).
- Arsitektur endpoint dosen terpisah `/dosen/v1`: **sudah sesuai**.
- Presensi tanpa validasi GPS: **sudah sesuai** (mobile tidak perlu flow GPS).
- Push notifikasi FCM: **disiapkan bertahap** (integrasi receive di mobile bisa menyusul).

Rekomendasi global config (nama variabel tetap sama seperti aplikasi lama):

```dart
// Pilih environment
const bool isDevelopment = true;

// Development
const String apiDev = 'http://localhost:3000/mobile';
const String fotoUrlDev = 'http://localhost:3000/images';
const String apiPdfDev = 'http://103.167.34.22/sisfo/jur/krs.cetak.php?khsid=';
const String imgurlDev = 'http://localhost:3000/images';

// Production
const String apiProd = 'https://mystikes.gunungsari.id:3000/mobile';
const String fotoUrlProd = 'https://mystikes.gunungsari.id:3000/images';
const String apiPdfProd = 'http://103.167.34.22/sisfo/jur/krs.cetak.php?khsid=';
const String imgurlProd = 'https://mystikes.gunungsari.id:3000/images';

// Variabel global (nama dipertahankan)
final String api = isDevelopment ? apiDev : apiProd;
final String fotoUrl = isDevelopment ? fotoUrlDev : fotoUrlProd;
final String apiPdf = isDevelopment ? apiPdfDev : apiPdfProd;
final String imgurl = isDevelopment ? imgurlDev : imgurlProd;

// Tambahan untuk endpoint dosen
final String apiDosen = api.replaceFirst('/mobile', '/dosen/v1/');
final String fotoDosen = api.replaceFirst('/mobile', '/assets/dosen/photos');
```

Catatan:
- `api`, `fotoUrl`, `apiPdf`, `imgurl` tetap dipakai dengan nama lama.
- Untuk fitur dosen gunakan `apiDosen` sebagai base endpoint.
- Foto profil dosen terbaru gunakan `fotoDosen`.

---

## 3. Rekomendasi Stack Flutter

Minimal paket yang direkomendasikan:

- HTTP client: `http` (`package:http/http.dart`)
- State management: `provider` sederhana dengan `MultiProvider`, `context.watch`, dan `context.read`
- JSON model: generate model dari response menggunakan [QuickType](https://quicktype.io/dart)
- Penyimpanan token: `shared_preferences`
- Upload file/foto: multipart form-data dari library `http` (`http.MultipartRequest`)
- Notifikasi push: `firebase_messaging` (bisa diintegrasikan belakangan)
- UI framework: `Flutter Material 3` (light theme only)
- Typography: gunakan font lokal `Roboto` dari folder `assets/fonts` (family tunggal untuk heading + body)

Pola state management yang digunakan:

- Daftarkan provider di root app menggunakan `MultiProvider` pada `main`.
- Gunakan `context.watch<T>()` untuk rebuild UI saat state berubah.
- Gunakan `context.read<T>()` untuk memanggil action tanpa trigger rebuild berlebih.

Struktur folder yang disarankan (sesuai pola kerja per fitur):

```text
lib/
  core/
    network/
      api_client.dart        # wrapper request http + auth header helper + error mapper
    storage/
      app_prefs.dart         # wrapper shared_preferences
    constants/
      global_config.dart     # api, fotoUrl, apiPdf, imgurl, apiDosen, fotoDosen
  features/
    auth/
      screen/
        login_screen.dart
      provider/
        auth_provider.dart
      model/
        login_response.dart
        me_response.dart
      service/
        auth_service.dart
    dashboard/
      screen/
        dashboard_screen.dart
      provider/
        dashboard_provider.dart
      model/
        dashboard_response.dart
      service/
        dashboard_service.dart
    jadwal/
      screen/
      provider/
      model/
      service/
    presensi/
      screen/
      provider/
      model/
      service/
    nilai/
      screen/
      provider/
      model/
      service/
    notifikasi/
      screen/
      provider/
      model/
      service/
    bimbingan/
      screen/
      provider/
      model/
      service/
    profil/
      screen/
        profil_screen.dart
        ubah_password_screen.dart
      provider/
        profil_provider.dart
      model/
        profil_response.dart
      service/
        profil_service.dart
  shared/
    widgets/
    utils/
```

Aturan implementasi per fitur:

- `screen`: fokus UI dan interaksi user.
- `provider`: simpan state + logic tampilan (`loading`, `error`, `success`) menggunakan `ChangeNotifier`.
- `service`: khusus komunikasi API (`http`) dan parsing response awal.
- `model`: class hasil generate JSON to Dart dari QuickType.
- Hindari request API langsung dari `screen`; panggil method di `provider`.
- Hindari URL hardcode di fitur; ambil dari `global_config.dart`.

---

## 3A. Standar UI Mobile Android (Final)

Bagian ini menjadi acuan final tampilan modern, profesional, dan konsisten untuk aplikasi dosen STIKESGS.

### 3A.1 Platform dan Prinsip Desain

- Target platform utama: Android.
- Design system: Material 3.
- Mode tema: **light only**.
- Karakter visual: bersih, informatif, modern, profesional.
- Prioritas UX: informasi cepat, aksi inti jelas, minim friction.

### 3A.2 Final Design Tokens (Light Theme)

Gunakan token ini secara konsisten di seluruh widget/screen.

#### a) Color Tokens

| Token | Hex | Kegunaan |
|---|---|---|
| `colorPrimary` | `#0B57D0` | tombol utama, active state |
| `colorOnPrimary` | `#FFFFFF` | teks/icon di atas primary |
| `colorPrimaryContainer` | `#D8E2FF` | surface elemen penting |
| `colorSecondary` | `#00639A` | highlight data sekunder |
| `colorBackground` | `#F3F6FB` | background app |
| `colorSurface` | `#FFFFFF` | card, dialog, bottom bar |
| `colorOnSurface` | `#1A1C1E` | teks utama |
| `colorOnSurfaceVariant` | `#5F6368` | teks deskripsi/meta |
| `colorOutline` | `#D0D7E2` | border/stroke |
| `colorSuccess` | `#1E8E3E` | status berhasil/hadir |
| `colorWarning` | `#F29900` | status peringatan |
| `colorError` | `#D93025` | status error/gagal |
| `colorInfo` | `#1A73E8` | banner informasi/notifikasi |

#### b) Typography Tokens

- Font family: `Roboto` (local asset, dideklarasikan di `pubspec.yaml`).
- `displayLarge`: 32 / 40 / `700`
- `headlineMedium`: 24 / 32 / `700`
- `titleLarge`: 20 / 28 / `600`
- `titleMedium`: 16 / 24 / `600`
- `bodyLarge`: 16 / 24 / `400`
- `bodyMedium`: 14 / 20 / `400`
- `labelLarge`: 14 / 20 / `600`
- `labelMedium`: 12 / 16 / `500`

Format: `size / line-height / fontWeight`.

#### c) Spacing, Radius, Elevation

- Spacing scale: `4, 8, 12, 16, 20, 24, 32`.
- Screen horizontal padding default: `16`.
- Card padding default: `16`.
- Border radius: `12` (small card), `16` (main card), `24` (pill/CTA besar).
- Elevation:
  - level 0: flat (`0`)
  - level 1: card normal (`1`)
  - level 2: emphasis (`3`)

#### d) Iconography

- Gunakan icon Material Symbols Rounded.
- Ukuran standar:
  - `20` untuk inline metadata
  - `24` untuk action default
  - `28` untuk ikon ringkasan besar
- Hindari emoji sebagai icon UI.

### 3A.2.1 Branding dan Asset Policy

- Lokasi asset resmi:
  - font: `assets/fonts/`
  - image/logo: `assets/images/`
- Logo aplikasi resmi: `assets/images/logo.png`.
- Semua asset wajib didaftarkan di `pubspec.yaml`; jangan mengandalkan path yang belum diregister.
- Untuk elemen branding (login/splash/header), gunakan logo resmi dari path di atas.
- Jika logo gagal dimuat, tampilkan fallback berupa nama aplikasi (`RuangDosen STIKESGS`) agar UI tetap informatif.
- Jika font custom gagal dimuat, gunakan fallback sistem sans-serif (`TextTheme` default Material) tanpa memblokir alur pengguna.

### 3A.3 Struktur Navigasi Utama

Bottom navigation final terdiri dari 4 menu:

1. `Jadwal`
2. `Presensi`
3. `Penilaian`
4. `Bimbingan`

Ketentuan:

- `Presensi` menjadi tab default saat login sukses.
- Tab `Presensi` menampilkan **dashboard ringkas + informasi cepat** di bagian atas, lalu daftar aksi presensi.
- Semua tab menyimpan state scroll/tab saat berpindah menu (`IndexedStack` disarankan).

### 3A.4 Komponen Inti yang Wajib Konsisten

- **Top header profil ringkas**
  - menampilkan salam waktu, nama dosen, foto profil, badge notifikasi.
- **Quick info cards (KPI)**
  - minimal 4 item: jadwal hari ini, total SKS, mahasiswa PA, notifikasi akademik.
  - format: angka besar + label singkat + ikon.
- **Kartu jadwal hari ini**
  - menampilkan jam, mata kuliah, ruang, dan tombol detail.
- **Panel pengumuman kampus**
  - tampilkan 2-3 item terbaru + tombol `Lihat Semua`.
- **Bottom navigation**
  - label wajib tampil (jangan icon-only), active color pakai `colorPrimary`.

### 3A.5 Spesifikasi Per Screen (MVP)

#### a) Screen Login

- Komponen:
  - logo institusi + judul aplikasi
  - input `nidn`
  - input `password` + toggle show/hide
  - tombol `Masuk`
- State:
  - loading pada tombol saat request berjalan
  - error text di bawah field atau snackbar untuk error global
- Acceptance:
  - validasi field wajib sebelum hit API
  - tombol nonaktif saat loading (anti double submit)

#### b) Screen Utama (Tab `Presensi` sebagai Home)

- Komponen urutan:
  1. header profil + greeting
  2. kartu jadwal hari ini
  3. quick info cards (2x2 grid)
  4. panel pengumuman kampus
- Data source:
  - `GET dashboard` untuk profil + ringkasan
  - `GET notifikasi` untuk list pengumuman
- Interaction:
  - pull-to-refresh untuk sinkron data terbaru
  - klik quick card menavigasi ke fitur terkait

#### c) Screen `Jadwal`

- Tampilkan list jadwal mengajar dalam card list.
- Filter minimal: hari ini / semua.
- Empty state: ilustrasi sederhana + teks "Belum ada jadwal."
- Data source: `GET jadwal-mengajar`.

#### d) Screen `Presensi`

- Daftar kelas aktif/tersedia untuk presensi.
- Aksi utama:
  - cek sesi aktif
  - start sesi QR
  - lihat kehadiran real-time
  - end sesi
- Tampilkan status sesi: `OPEN`, `CLOSED`, `AUTO-CLOSED`.
- Jika auto-close 20 menit tercapai, tombol koreksi harus disabled.

#### e) Screen `Penilaian`

- Daftar jadwal input nilai + detail mahasiswa per jadwal.
- Form nilai gunakan komponen numerik yang konsisten.
- Tombol simpan sticky di bawah (tetap terlihat saat scroll panjang).
- Tampilkan pesan sukses setelah `PUT nilai/update`.

#### f) Screen `Bimbingan`

- List mahasiswa PA.
- Detail log bimbingan per mahasiswa.
- CRUD log dengan dialog/form sederhana.
- Data source: endpoint `bimbingan/*`.

### 3A.6 Standar State UI

Setiap screen wajib punya 4 state ini:

- `loading`: skeleton/shimmer ringan.
- `empty`: icon + judul + deskripsi + CTA opsional.
- `error`: pesan jelas + tombol `Coba Lagi`.
- `success`: data tampil normal.

### 3A.7 Standar Aksesibilitas Android

- Semua tombol/icon penting memiliki `Semantics(label: ...)`.
- Minimum tap target: `48x48`.
- Kontras teks minimum: 4.5:1.
- Urutan fokus logis untuk TalkBack.
- Wajib uji manual dengan TalkBack minimal pada flow login, presensi, dan penilaian.

### 3A.8 Do and Don't

Do:

- Gunakan copywriting singkat dan jelas.
- Prioritaskan informasi akademik yang actionable.
- Pertahankan layout stabil saat loading/error.

Don't:

- Jangan campur banyak warna aksen dalam satu screen.
- Jangan gunakan teks abu-abu terlalu pudar.
- Jangan gunakan komponen kustom jika Material 3 default sudah memadai.

---

## 4. Endpoint Mapping untuk Flutter

Semua path di bawah relatif ke `{{URL_DOSEN}}`.

### 4.1 Auth

- `POST auth/login`
  - body: `nidn`, `password`
  - output penting: `data.token`, `data.login`, `data.nama`, `data.foto`
- `GET auth/me`
  - untuk rehydrate sesi saat app dibuka ulang

### 4.2 Dashboard

- `GET dashboard`
  - gunakan `data.profil` dan `data.ringkasan`

### 4.3 Jadwal Mengajar

- `GET jadwal-mengajar`
  - gunakan list `data.jadwal`

### 4.4 Presensi QR

- `GET presensi/aktif?jadwal_id=<id>`
- `POST presensi/start`
- `GET presensi/<presensi_id>/kehadiran`
- `PUT presensi/kehadiran`
- `POST presensi/end`

Catatan:
- endpoint scan QR ada di sisi mahasiswa, bukan di app dosen.
- app dosen fokus membuat sesi QR, memantau status, lihat rekap, dan koreksi kehadiran.
- backend menerapkan auto-close 20 menit per sesi; setelah auto-close, koreksi tidak diizinkan.
- flow presensi dosen tidak memerlukan validasi GPS.

### 4.5 Input Nilai

- `GET nilai/jadwal-input?tahunid=<tahun>`
- `GET nilai/mahasiswa?jadwal_id=<id>`
- `PUT nilai/update`

Catatan:
- untuk kelas team teaching, input nilai hanya untuk dosen koordinator (`jadwaldosen.JenisDosenID = 'DSN'`) sesuai rule backend.

### 4.6 Notifikasi

- `GET notifikasi`
- `GET notifikasi/total`
- `PUT notifikasi/baca`
- `POST notifikasi` (jika fitur kirim notifikasi diaktifkan pada aplikasi dosen)

### 4.7 Bimbingan Akademik (PA)

- `GET bimbingan/mahasiswa`
- `GET bimbingan/log/<mhswid>`
- `POST bimbingan/log`
- `PUT bimbingan/log/<logId>`
- `DELETE bimbingan/log/<logId>`

### 4.8 Profil Dosen

- `GET profil`
- `PUT profil`
- `PUT profil/foto` (multipart, field file: `foto`)
- `PUT profil/password`

### 4.9 Contoh Penggunaan Endpoint + Response (ringkas)

Semua contoh di bawah mengikuti data yang sudah diuji pada `documentation/dosen.md`.

#### 1) Login dosen

- Route: `POST {{URL_DOSEN}}auth/login`

Body:

```json
{
  "nidn": "20240001",
  "password": "20240930"
}
```

Response:

```json
{
  "data": {
    "login": "20240001",
    "nidn": "6458764665230230",
    "nama": "HERLIANTY",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.<payload>.<signature>"
  }
}
```

#### 2) Auth Me

- Route: `GET {{URL_DOSEN}}auth/me`
- Header: `Authorization: Bearer <token>`

Response:

```json
{
  "data": {
    "login": "20240001",
    "nidn": "6458764665230230",
    "nama": "HERLIANTY",
    "gelar": "S.ST, SKM.,M.KES",
    "handphone": "",
    "email": "",
    "foto": "",
    "prodi": ".D3 Kebidanan.Profesi Bidan.S1 Kebidanan."
  }
}
```

#### 3) Dashboard

- Route: `GET {{URL_DOSEN}}dashboard`

Response:

```json
{
  "data": {
    "profil": {
      "login": "20240001",
      "nama": "HERLIANTY",
      "foto": ""
    },
    "ringkasan": {
      "tahunid": "20251",
      "jumlah_jadwal_hari_ini": 1,
      "total_sks_semester": 16,
      "jumlah_mhs_bimbingan": 28,
      "jumlah_notif_akademik": 0
    }
  }
}
```

#### 4) Jadwal Mengajar

- Route: `GET {{URL_DOSEN}}jadwal-mengajar`

Response:

```json
{
  "data": {
    "tahunid": "20251",
    "total": 5,
    "jadwal": [
      {
        "JadwalID": 2418,
        "MKKode": "BD.204",
        "nama_mk": "ASUHAN KEBIDANAN NEONATUS, BAYI DAN BALITA",
        "SKS": 4,
        "nama_hari": "Kamis",
        "jam_mulai": "08:00",
        "jam_selesai": "10:50"
      }
    ]
  }
}
```

#### 5) Presensi QR (alur dosen)

- Cek sesi aktif: `GET {{URL_DOSEN}}presensi/aktif?jadwal_id=2418`
- Start sesi: `POST {{URL_DOSEN}}presensi/start`
- Lihat kehadiran: `GET {{URL_DOSEN}}presensi/19043/kehadiran`
- Koreksi: `PUT {{URL_DOSEN}}presensi/kehadiran`
- End sesi: `POST {{URL_DOSEN}}presensi/end`

Body start:

```json
{
  "jadwal_id": 2418,
  "pertemuan": 1
}
```

Contoh response start:

```json
{
  "data": {
    "presensi_id": 19043,
    "jadwal_id": 2418,
    "dosen_id": "20240001",
    "qr_session_token": "773144cafd80be92bafeae79c82d094e42df482332b56f7bf84d1ed1b018e64e",
    "status": "OPEN"
  }
}
```

#### 6) Input Nilai

- Daftar jadwal input: `GET {{URL_DOSEN}}nilai/jadwal-input?tahunid=20251`
- Daftar mahasiswa: `GET {{URL_DOSEN}}nilai/mahasiswa?jadwal_id=2416`
- Update nilai: `PUT {{URL_DOSEN}}nilai/update`

Body update:

```json
{
  "krs_id": 104812,
  "tugas1": 80,
  "tugas2": 85,
  "tugas3": 78,
  "tugas4": 90,
  "tugas5": 88,
  "uts": 84,
  "uas": 86
}
```

Response update:

```json
{
  "data": {
    "krs_id": 104812,
    "jadwal_id": 2416,
    "tugas1": 80,
    "tugas2": 85,
    "tugas3": 78,
    "tugas4": 90,
    "tugas5": 88,
    "uts": 84,
    "uas": 86
  }
}
```

#### 7) Notifikasi

- List: `GET {{URL_DOSEN}}notifikasi`
- Total unread: `GET {{URL_DOSEN}}notifikasi/total`
- Tandai baca: `PUT {{URL_DOSEN}}notifikasi/baca`
- Tambah notifikasi: `POST {{URL_DOSEN}}notifikasi`

Body tandai baca:

```json
{
  "id": 18
}
```

Response tandai baca:

```json
{
  "data": {
    "id": 18,
    "status": 1
  }
}
```

#### 8) Bimbingan PA

- Mahasiswa bimbingan: `GET {{URL_DOSEN}}bimbingan/mahasiswa`
- Log per mahasiswa: `GET {{URL_DOSEN}}bimbingan/log/24246004`
- Tambah log: `POST {{URL_DOSEN}}bimbingan/log`
- Ubah log: `PUT {{URL_DOSEN}}bimbingan/log/1`
- Hapus log (soft delete): `DELETE {{URL_DOSEN}}bimbingan/log/1`

Body tambah log:

```json
{
  "mhsw_id": "24246004",
  "tanggal_konsultasi": "2026-04-14",
  "tema": "Konsultasi Peminatan",
  "ringkasan": "Mahasiswa mengalami kendala dalam belajar topik B",
  "hasil": "Direkomendasikan pindah jurusan."
}
```

Response tambah log:

```json
{
  "data": {
    "id": 3,
    "mhsw_id": "24246004",
    "dosen_id": "20240001",
    "tanggal_konsultasi": "2026-04-14",
    "tema": "Konsultasi Peminatan",
    "ringkasan": "Mahasiswa mengalami kendala dalam belajar topik B",
    "hasil": "Direkomendasikan pindah jurusan."
  }
}
```

#### 9) Profil Dosen

- `GET {{URL_DOSEN}}profil`

```json
{
  "data": {
    "login": "20240001",
    "nidn": "6458764665230230",
    "nama": "HERLIANTY",
    "gelar": "S.ST, SKM.,M.KES",
    "handphone": "082277889990",
    "email": "email@mail.com",
    "foto": "",
    "prodi": ".D3 Kebidanan.Profesi Bidan.S1 Kebidanan."
  }
}
```

- `PUT {{URL_DOSEN}}profil`

Body:

```json
{
  "email": "email@mail.com",
  "handphone": "082277889990"
}
```

Response:

```json
{
  "data": {
    "login": "20240001",
    "email": "email@mail.com",
    "handphone": "082277889990"
  }
}
```

- `PUT {{URL_DOSEN}}profil/foto` (form-data: `foto=<file>`)

```json
{
  "data": {
    "login": "20240001",
    "foto": "dosen_20240001_1776235571363.jpeg"
  }
}
```

- `PUT {{URL_DOSEN}}profil/password`

Body:

```json
{
  "password_lama": "20240930",
  "password_baru": "20240930"
}
```

Response:

```json
{
  "data": {
    "login": "20240001",
    "message": "Password berhasil diubah"
  }
}
```

Catatan:
- Untuk payload lengkap (termasuk data list yang panjang), gunakan `documentation/dosen.md` bagian `2.0` sampai `2.7` sebagai sumber utama.
- Bagian ini fokus untuk kebutuhan implementasi cepat di sisi Flutter.

---

## 5. Alur Aplikasi yang Disarankan

### 5.1 Splash dan Validasi Sesi

1. Baca token dari `shared_preferences`.
2. Jika token kosong -> ke halaman login.
3. Jika token ada -> panggil `GET auth/me`.
4. Jika `200` -> masuk home/dashboard.
5. Jika `401/403/500` karena token invalid/expired -> hapus token, kembali ke login.

### 5.2 Login

1. User input `nidn` dan `password`.
2. Call `POST auth/login`.
3. Simpan `token` ke `shared_preferences`.
4. Simpan profil ringkas (opsional cache lokal) untuk menampilkan cepat.

### 5.3 Home Dashboard

1. Call `GET dashboard`.
2. Render ringkasan (jadwal hari ini, SKS, jumlah bimbingan, notifikasi).
3. Sediakan pull-to-refresh agar data real-time.

### 5.4 Presensi QR

1. Dosen pilih jadwal.
2. Cek sesi aktif via `GET presensi/aktif`.
3. Jika tidak ada sesi aktif -> `POST presensi/start`.
4. Tampilkan QR/token sesi dan countdown.
5. Lihat rekap hadir via `GET presensi/<id>/kehadiran`.
6. Koreksi sebelum tutup via `PUT presensi/kehadiran`.
7. Tutup manual via `POST presensi/end`.
8. Jika sesi ditutup otomatis (20 menit), UI harus menganggap koreksi terkunci.

### 5.5 Profil

1. Tampil data dari `GET profil`.
2. Ubah email + handphone via `PUT profil`.
3. Ubah foto via `PUT profil/foto`.
4. Ubah password via `PUT profil/password`.

---

## 6. Kontrak Data Inti untuk Model Flutter

Field inti yang sering dipakai di beberapa endpoint:

- `login` (`String`)
- `nidn` (`String`)
- `nama` (`String`)
- `gelar` (`String`)
- `handphone` (`String`)
- `email` (`String`)
- `foto` (`String`) -> nama file foto di server
- `prodi` (`String`)

Untuk URL foto:

- Jika `foto` kosong (`""`), tampilkan avatar default.
- Jika `foto` berisi nama file, bentuk URL:
  - `"$BASE_URL/assets/dosen/photos/$foto"`

---

## 7. Standar HTTP Layer Flutter

### 7.1 Request Header

- `Content-Type: application/json` untuk request biasa.
- `Authorization: Bearer <token>` untuk endpoint protected.
- Multipart upload foto otomatis set `multipart/form-data`.

### 7.2 Auth Header Helper (`http`)

Karena menggunakan library `http`, buat helper sederhana untuk:

- mengambil token dari `shared_preferences` sebelum request
- inject header `Authorization` pada request yang butuh autentikasi
- handle `401/403` secara global di layer repository/service (force logout jika token tidak valid)

### 7.3 Error Mapping

Map error backend ke pesan yang ramah user:

- `400`: tampilkan pesan validasi dari backend jika ada.
- `404`: tampilkan data tidak ditemukan.
- `500`: tampilkan pesan umum, sarankan coba ulang.
- timeout/no internet: tampilkan status koneksi dan tombol retry.

### 7.4 Kontrak Teknis Tambahan (Pra Coding)

Standar tambahan ini disarankan agar implementasi mobile lebih stabil:

- **Status code sukses:** anggap sukses jika `200` atau `201` (beberapa endpoint create memakai `201`).
- **Kontrak error fallback:** jika response error tidak memiliki field khusus, gunakan fallback:

```json
{
  "message": "Terjadi kesalahan",
  "data": null
}
```

- **Format waktu/tanggal:** simpan nilai datetime dari server apa adanya (string), lalu format di UI sesuai locale user; hindari parse paksa jika format belum seragam.
- **Anti duplicate submit:** pada action penting (`presensi/start`, `presensi/end`, `nilai/update`, `bimbingan/log`), disable tombol saat loading untuk mencegah request ganda.
- **Upload foto profil:** validasi di sisi app (jpg/jpeg/png), batasi ukuran file (mis. maksimal 2MB), dan lakukan kompresi ringan sebelum upload jika memungkinkan.
- **Device testing:** jika testing di device fisik, `localhost` tidak bisa langsung dipakai; gunakan IP LAN komputer atau domain dev.
- **Shared preferences keys (disarankan):**
  - `sp_token_dosen`
  - `sp_login_dosen`
  - `sp_profile_dosen_json`

### 7.5 Konvensi Model QuickType

- Nama file model mengikuti endpoint, contoh: `login_response.dart`, `dashboard_response.dart`, `profil_response.dart`.
- Regenerate model setiap ada perubahan struktur response dari backend.
- Simpan source contoh JSON (raw response) di folder dokumentasi internal tim agar proses regenerate konsisten.

---

## 8. Validasi Input UI (Sebelum Hit API)

- Login:
  - `nidn` wajib isi
  - `password` wajib isi
- Profil update:
  - `email` dan `handphone` wajib tetap dikirim (boleh string kosong sesuai kontrak backend)
- Ubah password:
  - `password_lama` wajib
  - `password_baru` wajib
  - tambahkan validasi panjang minimal di sisi UI agar UX lebih baik

---

## 9. Checklist Implementasi Flutter

- [ ] Setup project Flutter + environment dev/prod (`--dart-define`)
- [ ] Terapkan `Material 3` + light theme only
- [ ] Implement file tema global (`app_theme.dart`) berbasis design token final
- [ ] Daftarkan asset `assets/images/` dan font `Roboto` di `pubspec.yaml`
- [ ] Gunakan logo resmi `assets/images/logo.png` pada screen branding (minimal login/splash)
- [ ] Implement `ApiClient` berbasis `http` + auth header helper
- [ ] Implement `shared_preferences` untuk token sesi
- [ ] Integrasi Auth (`login`, `me`, logout)
- [ ] Integrasi Dashboard
- [ ] Integrasi Jadwal Mengajar
- [ ] Integrasi Presensi QR (start, aktif, kehadiran, end, koreksi)
- [ ] Integrasi Input Nilai
- [ ] Integrasi Notifikasi (list, total, baca)
- [ ] Integrasi Bimbingan PA (list + CRUD log)
- [ ] Integrasi Profil (get/update/foto/password)
- [ ] Implement bottom navigation 4 menu (`Jadwal`, `Presensi`, `Penilaian`, `Bimbingan`)
- [ ] Implement quick info cards di tab `Presensi`
- [ ] Integrasi Firebase Messaging untuk push notifikasi (tahap berikutnya)
- [ ] Tambahkan empty state, loading state, dan retry state
- [ ] Tambahkan standar aksesibilitas (`Semantics`, kontras, tap target)
- [ ] Pastikan handler sukses menerima `200` dan `201`
- [ ] Tambahkan guard duplicate submit pada action kritikal
- [ ] Tetapkan key `shared_preferences` final dan gunakan konsisten
- [ ] UAT lengkap berdasarkan skenario Postman
- [ ] Verifikasi fallback asset (logo/font) tidak membuat app crash saat asset bermasalah

---

## 10. Skenario UAT Minimum (Mobile)

1. Login valid -> masuk dashboard, data tampil.
2. Login invalid -> tampil error dari backend.
3. Tutup app, buka lagi -> sesi tetap login (rehydrate via `auth/me`).
4. Ubah profil text -> data berubah dan persist setelah refresh.
5. Upload foto profil -> `foto` berubah dan URL foto dapat diakses.
6. Ganti password -> berhasil login ulang dengan password baru.
7. Presensi: start -> aktif -> lihat kehadiran -> end.
8. Notifikasi: list terbaca + hitung total.
9. Bimbingan: tambah/edit/hapus log berjalan normal.
10. Semua endpoint gagal (simulasi offline/server down) menampilkan error state yang jelas.
11. Token invalid/expired (`401/403`) memaksa logout dan kembali ke login.
12. Request create (`POST`) yang mengembalikan `201` tetap dianggap sukses oleh app.
13. Upload foto gagal (file terlalu besar/format salah) menampilkan pesan validasi yang jelas.
14. Double tap tombol simpan/start tidak membuat data ganda.
15. Bottom navigation 4 menu tampil konsisten di semua screen utama.
16. Tab `Presensi` menampilkan informasi cepat (jadwal hari ini, SKS, PA, notifikasi).
17. Seluruh state `loading/empty/error/success` muncul sesuai kondisi data.
18. Pengujian TalkBack: label komponen penting terbaca dengan benar.
19. Font `Roboto` tampil konsisten pada komponen utama sesuai tema aplikasi.
20. Logo `assets/images/logo.png` tampil pada layar branding yang ditetapkan.
21. Simulasi asset gagal muat tidak menyebabkan crash (fallback UI berjalan).

---

## 11. Catatan Operasional

- Kontrak API sumber kebenaran tetap di `documentation/dosen.md`.
- Jika ada perubahan field response, update model Flutter dan dokumen ini bersamaan.
- Prioritaskan kompatibilitas mundur agar aplikasi mobile lama tidak langsung rusak saat backend update.
- Rule bisnis utama (auto-close QR 20 menit, tanpa GPS, koordinator nilai `DSN`) mengikuti backend; UI hanya menyesuaikan perilaku.

