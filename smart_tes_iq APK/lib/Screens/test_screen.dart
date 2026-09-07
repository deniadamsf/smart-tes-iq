import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU
import '../models/question_model.dart';
import '../data/question_data.dart';
import '../helpers/database_helper.dart';
import '../helpers/test_label_helper.dart'; // BARU: Untuk menerjemahkan judul test di App Bar
import 'result_screen.dart';

class TestScreen extends StatefulWidget {
  final String testName; // HARUS tetap string asli (Bahasa Indonesia) untuk Database
  final String testId;

  const TestScreen({super.key, required this.testName, required this.testId});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  int _score = 0;
  late List<QuestionModel> _questions;

  @override
  void initState() {
    super.initState();
    _questions = QuestionData.getQuestionsById(widget.testId);
  }

  void _nextQuestion() async {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('test_screen.pls_select_answer'.tr())),
      );
      return;
    }

    // BARU: Cek bahasa aktif untuk menentukan kunci jawaban yang dipakai mencocokkan
    final langCode = context.locale.languageCode;
    final currentQuestion = _questions[_currentQuestionIndex];
    final String correctAnswer = langCode == 'en' ? currentQuestion.correctAnswerEn : currentQuestion.correctAnswerId;

    if (_selectedAnswer == correctAnswer) {
      _score++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
      });
    } else {
      await _saveResultToDatabase();
      _showResultDialog();
    }
  }

  Future<void> _saveResultToDatabase() async {
    // PENTING: test_name tetap menggunakan widget.testName asli (Bahasa Indonesia)
    await DatabaseHelper.instance.insertTestResult({
      'test_name': widget.testName,
      'score': _score,
      'total_questions': _questions.length,
      'ai_analysis': 'Menunggu sinkronisasi AI...',
      'is_synced': 0,
    });
  }

  void _showResultDialog() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          testName: widget.testName,
          score: _score,
          totalQuestions: _questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil kode bahasa saat ini (id / en)
    final langCode = context.locale.languageCode;
    // Judul App Bar yang diterjemahkan tanpa merusak data database
    final displayTestName = getLocalizedTestLabel(widget.testName, langCode);

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(displayTestName), backgroundColor: const Color(0xFF0D47A1)),
        body: Center(child: Text('test_screen.no_questions'.tr(), style: const TextStyle(fontSize: 16))),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    // BARU: Tentukan Teks Soal & Opsi secara dinamis sesuai bahasa
    final String? displayQuestionText = langCode == 'en' ? currentQuestion.questionTextEn : currentQuestion.questionTextId;
    final List<String> displayOptions = langCode == 'en' ? currentQuestion.optionsEn : currentQuestion.optionsId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(displayTestName),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${'test_screen.question_indicator'.tr()} ${_currentQuestionIndex + 1} / ${_questions.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Center(
                      child: currentQuestion.imagePath != null
                          ? Image.asset(currentQuestion.imagePath!, fit: BoxFit.contain)
                          : Text(
                        displayQuestionText ?? '',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Text(
                'test_screen.instruction'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),

              Expanded(
                flex: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (context, index) {
                    final option = displayOptions[index];
                    final isSelected = _selectedAnswer == option;

                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedAnswer = option;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? const Color(0xFF1976D2) : Colors.white,
                        foregroundColor: isSelected ? Colors.white : Colors.black87,
                        elevation: isSelected ? 4 : 1,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),

              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentQuestionIndex < _questions.length - 1 ? 'test_screen.btn_next'.tr() : 'test_screen.btn_finish'.tr(),
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}