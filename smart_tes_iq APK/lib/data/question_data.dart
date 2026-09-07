import '../models/question_model.dart';

class QuestionData {
  // 1. BANK SOAL ANALOGI VERBAL (Teks)
  static final List<QuestionModel> analogiVerbal = [
    QuestionModel(
      id: 1,
      // DIUBAH: Menggunakan dua bahasa
      questionTextId: "Mobil : Bensin = Pelari : ...",
      questionTextEn: "Car : Gas = Runner : ...",
      optionsId: ["A. Makanan", "B. Sepatu", "C. Lintasan", "D. Istirahat"],
      optionsEn: ["A. Food", "B. Shoes", "C. Track", "D. Rest"],
      correctAnswerId: "A. Makanan",
      correctAnswerEn: "A. Food",
    ),
    QuestionModel(
      id: 2,
      questionTextId: "Dingin : Selimut = Hujan : ...",
      questionTextEn: "Cold : Blanket = Rain : ...",
      optionsId: ["A. Air", "B. Payung", "C. Basah", "D. Awan"],
      optionsEn: ["A. Water", "B. Umbrella", "C. Wet", "D. Cloud"],
      correctAnswerId: "B. Payung",
      correctAnswerEn: "B. Umbrella",
    ),
  ];

  // 2. BANK SOAL SPASIAL (Gambar)
  static final List<QuestionModel> spasial = [
    QuestionModel(
      id: 1,
      imagePath: "assets/images/spasial_01.png",
      // Gambar tidak perlu diterjemahkan, tapi opsi (A,B,C,D) harus tetap diisi dua-duanya
      optionsId: ["A", "B", "C", "D"],
      optionsEn: ["A", "B", "C", "D"],
      correctAnswerId: "B",
      correctAnswerEn: "B",
    ),
    QuestionModel(
      id: 2,
      imagePath: "assets/images/spasial_02.png",
      optionsId: ["A", "B", "C", "D"],
      optionsEn: ["A", "B", "C", "D"],
      correctAnswerId: "C",
      correctAnswerEn: "C",
    ),
  ];

  // 3. BANK SOAL KLASIFIKASI GAMBAR
  static final List<QuestionModel> klasifikasi = [
    QuestionModel(
      id: 1,
      imagePath: "assets/images/klasifikasi_01.png",
      optionsId: ["A", "B", "C", "D"],
      optionsEn: ["A", "B", "C", "D"],
      correctAnswerId: "B",
      correctAnswerEn: "B",
    ),
  ];

  static List<QuestionModel> getQuestionsById(String idTes) {
    switch (idTes) {
      case 'verbal':
        return analogiVerbal;
      case 'spasial':
        return spasial;
      case 'klasifikasi':
        return klasifikasi;
      default:
        return [];
    }
  }
}