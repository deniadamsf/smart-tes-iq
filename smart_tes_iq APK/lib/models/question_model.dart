class QuestionModel {
  final int id;
  final String? imagePath;      // Path gambar (Universal, tidak perlu dua bahasa)

  // Variabel untuk dua bahasa
  final String? questionTextId; // Teks soal Bahasa Indonesia
  final String? questionTextEn; // Teks soal English
  final List<String> optionsId; // Pilihan jawaban Bahasa Indonesia
  final List<String> optionsEn; // Pilihan jawaban English
  final String correctAnswerId; // Kunci jawaban Bahasa Indonesia
  final String correctAnswerEn; // Kunci jawaban English

  QuestionModel({
    required this.id,
    this.imagePath,
    this.questionTextId,
    this.questionTextEn,
    required this.optionsId,
    required this.optionsEn,
    required this.correctAnswerId,
    required this.correctAnswerEn,
  });
}