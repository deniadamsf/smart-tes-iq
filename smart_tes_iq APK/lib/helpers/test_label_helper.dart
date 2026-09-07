/// PENTING — BACA INI SEBELUM MENGUBAH APAPUN DI FILE INI:
///
/// `test_name` yang disimpan ke SQLite (`test_results`) dan dikirim ke
/// backend Laravel (endpoint /sync, /user-data) HARUS TETAP memakai string
/// asli Bahasa Indonesia seperti sekarang (mis. 'Deret Angka',
/// 'Tes 16 Kepribadian (MBTI)'). JANGAN pernah mengganti nilai yang dikirim
/// ke insertTestResult() / database / server menjadi bahasa Inggris.
///
/// Alasannya:
/// 1. `getCompletedTestsCount()` di database_helper.dart menghitung
///    `DISTINCT test_name` — kalau nilainya berubah-ubah tergantung bahasa
///    aktif user, satu jenis tes bisa terhitung dua kali.
/// 2. `updateLatestTestAnalysis(testName, ...)` mencari baris berdasarkan
///    kecocokan persis `test_name` — analisis AI bisa gagal nyantol ke
///    baris yang benar kalau string-nya berubah.
/// 3. Riwayat yang SUDAH tersimpan di server (sebelum update ini rilis)
///    memakai string Indonesia. Kalau versi baru mengirim string Inggris,
///    data lama & baru dianggap dua tes berbeda oleh backend.
///
/// Solusinya: data yang disimpan/dikirim tidak berubah sama sekali.
/// Widget HANYA memanggil fungsi ini saat MENAMPILKAN nama tes ke user,
/// sesuai bahasa yang sedang aktif.
///
/// Cara pakai di UI (contoh, tidak mengubah logic insertTestResult):
///   Text(getLocalizedTestLabel(result['test_name'], context.locale.languageCode))
///
/// Kalau nanti menambah jenis tes baru, tambahkan juga entrinya di map
/// di bawah ini (key harus SAMA PERSIS dengan string yang dipakai di
/// insertTestResult di masing-masing *_test_screen.dart).
library test_label_helper;

const Map<String, Map<String, String>> _testLabelTranslations = {
  'Analogi Verbal': {
    'id': 'Analogi Verbal',
    'en': 'Verbal Analogy',
  },
  'Deret Angka': {
    'id': 'Deret Angka',
    'en': 'Number Sequence',
  },
  'Deret Angka (PRO)': {
    'id': 'Deret Angka (PRO)',
    'en': 'Number Sequence (PRO)',
  },
  'Penalaran Logis': {
    'id': 'Penalaran Logis',
    'en': 'Logical Reasoning',
  },
  'Penalaran Logis (PRO)': {
    'id': 'Penalaran Logis (PRO)',
    'en': 'Logical Reasoning (PRO)',
  },
  'Spasial (Gambar)': {
    'id': 'Spasial (Gambar)',
    'en': 'Spatial (Image)',
  },
  'Spasial (Gambar) (PRO)': {
    'id': 'Spasial (Gambar) (PRO)',
    'en': 'Spatial (Image) (PRO)',
  },
  'Klasifikasi Gambar': {
    'id': 'Klasifikasi Gambar',
    'en': 'Image Classification',
  },
  'Klasifikasi Gambar (PRO)': {
    'id': 'Klasifikasi Gambar (PRO)',
    'en': 'Image Classification (PRO)',
  },
  'Gaya Belajar (VAK)': {
    'id': 'Gaya Belajar (VAK)',
    'en': 'Learning Style (VAK)',
  },
  'Bakat Minat (RIASEC)': {
    'id': 'Bakat Minat (RIASEC)',
    'en': 'Interests & Aptitude (RIASEC)',
  },
  'Tes 16 Kepribadian (MBTI)': {
    'id': 'Tes 16 Kepribadian (MBTI)',
    'en': '16 Personalities Test (MBTI)',
  },
  'Tes EQ (AI)': {
    'id': 'Tes EQ (AI)',
    'en': 'EQ Test (AI)',
  },
  'Tes SQ (AI)': {
    'id': 'Tes SQ (AI)',
    'en': 'SQ Test (AI)',
  },
  'Tes IQ Komprehensif (PRO)': {
    'id': 'Tes IQ Komprehensif (PRO)',
    'en': 'Comprehensive IQ Test (PRO)',
  },
};

/// Mengembalikan label tampilan sesuai [languageCode] ('id' / 'en').
/// Kalau [rawTestName] tidak ada di map (mis. tes baru yang belum
/// didaftarkan di sini), fungsi ini akan mengembalikan [rawTestName]
/// apa adanya — jadi TIDAK PERNAH error/crash walau lupa didaftarkan,
/// hanya saja tampilannya belum diterjemahkan.
String getLocalizedTestLabel(String rawTestName, String languageCode) {
  final entry = _testLabelTranslations[rawTestName];
  if (entry == null) return rawTestName;
  return entry[languageCode] ?? rawTestName;
}
