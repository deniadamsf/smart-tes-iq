import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../helpers/ad_helper.dart';
import '../helpers/game_high_score_helper.dart';
import '../helpers/rewarded_ad_manager.dart';

class SudokuGameScreen extends StatefulWidget {
  const SudokuGameScreen({super.key});

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> {
  // Status Permainan
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isVictory = false;
  bool _hasUsedContinueAd = false;
  bool _isPausedForAd = false;

  int _score = 0;
  int _highScore = 0;
  bool _isNewRecord = false;

  int _lives = 3;
  int _timeLeft = 600; // 10 menit (600 detik)
  Timer? _timer;

  String _difficulty = 'easy'; // 'easy', 'medium', 'hard'
  bool _isNotesMode = false;

  // Papan Sudoku 9x9
  List<List<int>> _solution = List.generate(9, (_) => List.filled(9, 0));
  List<List<int>> _board = List.generate(9, (_) => List.filled(9, 0));
  List<List<bool>> _isFixed = List.generate(9, (_) => List.filled(9, false));
  List<List<bool>> _isInitialClue = List.generate(
    9,
    (_) => List.filled(9, false),
  );
  List<List<Set<int>>> _notes = List.generate(
    9,
    (_) => List.generate(9, (_) => <int>{}),
  );

  int? _selectedRow;
  int? _selectedCol;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    RewardedAdManager.loadAd();
  }

  Future<void> _loadHighScore() async {
    final best = await GameHighScoreHelper.getHighScore(
      GameHighScoreHelper.kSudoku,
    );
    if (mounted) {
      setState(() {
        _highScore = best;
      });
    }
  }

  // Generator Papan Sudoku 9x9 Valid
  void _generateSudokuBoard() {
    _solution = List.generate(9, (_) => List.filled(9, 0));
    _fillDiagonalBoxes();
    _solveBoard(_solution);

    // Salin solusi ke papan permainan
    _board = List.generate(9, (r) => List<int>.from(_solution[r]));
    _isFixed = List.generate(9, (_) => List.filled(9, true));
    _isInitialClue = List.generate(9, (_) => List.filled(9, true));
    _notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));

    // Tentukan jumlah kotak kosong berdasarkan tingkat kesulitan
    int emptyCells = 30; // Mudah
    if (_difficulty == 'medium') {
      emptyCells = 40; // Sedang
    } else if (_difficulty == 'hard') {
      emptyCells = 50; // Sulit
    }

    int removed = 0;
    List<int> positions = List.generate(81, (i) => i)..shuffle(_random);
    for (int pos in positions) {
      if (removed >= emptyCells) break;
      int r = pos ~/ 9;
      int c = pos % 9;
      if (_board[r][c] != 0) {
        _board[r][c] = 0;
        _isFixed[r][c] = false;
        _isInitialClue[r][c] = false;
        removed++;
      }
    }

    // Pilih otomatis sel kosong pertama
    _selectedRow = null;
    _selectedCol = null;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (!_isFixed[r][c]) {
          _selectedRow = r;
          _selectedCol = c;
          return;
        }
      }
    }
  }

  void _fillDiagonalBoxes() {
    for (int box = 0; box < 9; box += 3) {
      List<int> nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
      int idx = 0;
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          _solution[box + r][box + c] = nums[idx++];
        }
      }
    }
  }

  bool _isSafe(List<List<int>> grid, int row, int col, int num) {
    for (int x = 0; x < 9; x++) {
      if (grid[row][x] == num || grid[x][col] == num) return false;
    }
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (grid[startRow + r][startCol + c] == num) return false;
      }
    }
    return true;
  }

  bool _solveBoard(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          List<int> nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
          for (int num in nums) {
            if (_isSafe(grid, r, c, num)) {
              grid[r][c] = num;
              if (_solveBoard(grid)) return true;
              grid[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  int _pointsPerCell() {
    if (_difficulty == 'hard') return 30;
    if (_difficulty == 'medium') return 20;
    return 15;
  }

  void _startGame() {
    RewardedAdManager.loadAd();
    setState(() {
      _score = 0;
      _lives = 3;
      _timeLeft = 600;
      _isPlaying = true;
      _isGameOver = false;
      _isVictory = false;
      _hasUsedContinueAd = false;
      _isNewRecord = false;
      _isNotesMode = false;
      _generateSudokuBoard();
    });

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPausedForAd) return;
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _triggerGameOver();
      }
    });
  }

  Future<void> _triggerGameOver() async {
    _timer?.cancel();
    final isNew = await GameHighScoreHelper.updateHighScore(
      GameHighScoreHelper.kSudoku,
      _score,
    );
    final best = await GameHighScoreHelper.getHighScore(
      GameHighScoreHelper.kSudoku,
    );
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
      _isVictory = false;
      _highScore = best;
      if (isNew) _isNewRecord = true;
    });
  }

  Future<void> _triggerVictory() async {
    _timer?.cancel();
    int completionBonus = (_difficulty == 'hard'
            ? 200
            : _difficulty == 'medium'
                ? 150
                : 100) +
        (_timeLeft ~/ 5);
    int finalScore = _score + completionBonus;

    final isNew = await GameHighScoreHelper.updateHighScore(
      GameHighScoreHelper.kSudoku,
      finalScore,
    );
    final best = await GameHighScoreHelper.getHighScore(
      GameHighScoreHelper.kSudoku,
    );
    if (!mounted) return;
    setState(() {
      _score = finalScore;
      _isPlaying = false;
      _isGameOver = false;
      _isVictory = true;
      _highScore = best;
      if (isNew) _isNewRecord = true;
    });
  }

  void _continueWithAd() {
    RewardedAdManager.showAd(
      context,
      () {
        if (!mounted) return;
        setState(() {
          _hasUsedContinueAd = true;
          _isGameOver = false;
          _isPlaying = true;
          if (_lives <= 0) _lives = 1;
          _timeLeft += 15;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('sudoku.msg_continued'.tr()),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startTimer();
      },
    );
  }

  void _useHintWithAd() {
    if (!_isPlaying) return;
    setState(() {
      _isPausedForAd = true;
    });

    RewardedAdManager.showAd(
      context,
      () {
        if (!mounted) return;
        setState(() {
          _isPausedForAd = false;
          _applyHintToBoard();
        });
      },
    ).then((_) {
      if (mounted && _isPausedForAd) {
        setState(() {
          _isPausedForAd = false;
        });
      }
    });
  }

  void _applyHintToBoard() {
    int? targetR = _selectedRow;
    int? targetC = _selectedCol;

    if (targetR == null ||
        targetC == null ||
        _board[targetR][targetC] != 0) {
      List<Point<int>> empties = [];
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (_board[r][c] == 0) {
            empties.add(Point(r, c));
          }
        }
      }
      if (empties.isEmpty) return;
      final chosen = empties[_random.nextInt(empties.length)];
      targetR = chosen.x;
      targetC = chosen.y;
    }

    final int correctNum = _solution[targetR][targetC];
    _board[targetR][targetC] = correctNum;
    _isFixed[targetR][targetC] = true;
    _notes[targetR][targetC].clear();
    _clearRelatedNotes(targetR, targetC, correctNum);
    _selectedRow = targetR;
    _selectedCol = targetC;
    _score += _pointsPerCell();
    if (_score > _highScore) {
      _highScore = _score;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('sudoku.msg_hint_used'.tr()),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    if (_isBoardComplete()) {
      _triggerVictory();
    }
  }

  void _clearRelatedNotes(int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      _notes[row][i].remove(num);
      _notes[i][col].remove(num);
    }
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        _notes[startRow + r][startCol + c].remove(num);
      }
    }
  }

  bool _isBoardComplete() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board[r][c] != _solution[r][c]) return false;
      }
    }
    return true;
  }

  int _countPlacedNumber(int num) {
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board[r][c] == num) count++;
      }
    }
    return count;
  }

  void _onNumberInput(int num) {
    if (!_isPlaying || _selectedRow == null || _selectedCol == null) return;
    final int r = _selectedRow!;
    final int c = _selectedCol!;

    if (_isFixed[r][c] || _board[r][c] != 0) return;

    if (_isNotesMode) {
      setState(() {
        if (_notes[r][c].contains(num)) {
          _notes[r][c].remove(num);
        } else {
          _notes[r][c].add(num);
        }
      });
      return;
    }

    if (_solution[r][c] == num) {
      setState(() {
        _board[r][c] = num;
        _isFixed[r][c] = true;
        _notes[r][c].clear();
        _clearRelatedNotes(r, c, num);
        _score += _pointsPerCell();
        if (_score > _highScore) {
          _highScore = _score;
        }
      });

      if (_isBoardComplete()) {
        _triggerVictory();
      }
    } else {
      setState(() {
        _lives--;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('sudoku.msg_wrong_cell'.tr()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
        ),
      );

      if (_lives <= 0) {
        _triggerGameOver();
      }
    }
  }

  void _eraseSelectedCell() {
    if (!_isPlaying || _selectedRow == null || _selectedCol == null) return;
    final int r = _selectedRow!;
    final int c = _selectedCol!;
    if (_isFixed[r][c]) return;

    setState(() {
      _notes[r][c].clear();
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'sudoku.appbar_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isPlaying
                    ? _buildGameplayScreen(isDarkMode, textColor)
                    : _buildMenuScreen(isDarkMode, textColor),
              ),
            ),
            const CustomBannerAd(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuScreen(bool isDarkMode, Color textColor) {
    final bool showResult = _isGameOver || _isVictory;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isVictory
                  ? Icons.emoji_events_rounded
                  : (_isGameOver
                      ? Icons.sentiment_dissatisfied_rounded
                      : Icons.grid_on_rounded),
              size: 76,
              color: _isVictory
                  ? Colors.amber
                  : (_isGameOver ? Colors.redAccent : Colors.indigo),
            ),
            const SizedBox(height: 16),
            Text(
              _isVictory
                  ? 'sudoku.victory_title'.tr()
                  : (_isGameOver
                      ? (_lives <= 0
                          ? 'sudoku.game_over_lives'.tr()
                          : 'sudoku.game_over_time'.tr())
                      : 'sudoku.game_title'.tr()),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            if (_highScore > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'game_menu.high_score_badge'.tr(
                        args: [_highScore.toString()],
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.amber.shade300
                            : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),

            if (showResult) ...[
              if (_isNewRecord)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'game_menu.new_record'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              Text(
                'sudoku.final_score'.tr(),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 16),
              if (_isGameOver && !_hasUsedContinueAd) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _continueWithAd,
                    icon: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      'sudoku.btn_continue_ad'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'sudoku.rules'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Pilihan Tingkat Kesulitan
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'sudoku.select_difficulty'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildDifficultyChip(
                  'easy',
                  'sudoku.level_easy'.tr(),
                  isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildDifficultyChip(
                  'medium',
                  'sudoku.level_medium'.tr(),
                  isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildDifficultyChip(
                  'hard',
                  'sudoku.level_hard'.tr(),
                  isDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  showResult
                      ? 'sudoku.btn_play_again'.tr()
                      : 'game_menu.btn_start'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(
    String value,
    String label,
    bool isDarkMode,
  ) {
    final bool isSelected = _difficulty == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _difficulty = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.indigo
                : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.indigo
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameplayScreen(bool isDarkMode, Color textColor) {
    final int? selectedValue = (_selectedRow != null && _selectedCol != null)
        ? _board[_selectedRow!][_selectedCol!]
        : null;

    return Column(
      children: [
        // Bar Informasi Atas: Skor, Nyawa, Waktu
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'sudoku.score'.tr()} $_score',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  if (_highScore > 0)
                    Text(
                      'Best: $_highScore',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                ],
              ),
              Row(
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Icon(
                      index < _lives
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  );
                }),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _timeLeft <= 30
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 16,
                      color: _timeLeft <= 30 ? Colors.red : Colors.indigo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_timeLeft),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft <= 30 ? Colors.red : Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Grid Papan Sudoku 9x9
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.indigo.shade300
                        : Colors.indigo.shade900,
                    width: 2.2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Column(
                    children: List.generate(9, (r) {
                      return Expanded(
                        child: Row(
                          children: List.generate(9, (c) {
                            return Expanded(
                              child: _buildSudokuCell(
                                r,
                                c,
                                selectedValue,
                                isDarkMode,
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Bar Tombol Aksi: Hapus, Catatan, Petunjuk (Iklan)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _eraseSelectedCell,
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: Text(
                  'sudoku.btn_erase'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isNotesMode = !_isNotesMode;
                  });
                },
                icon: Icon(
                  _isNotesMode ? Icons.edit_note_rounded : Icons.edit_outlined,
                  size: 18,
                ),
                label: Text(
                  _isNotesMode
                      ? 'sudoku.btn_notes_on'.tr()
                      : 'sudoku.btn_notes'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isNotesMode
                      ? Colors.indigo
                      : (isDarkMode
                          ? const Color(0xFF334155)
                          : Colors.grey.shade200),
                  foregroundColor: _isNotesMode
                      ? Colors.white
                      : (isDarkMode ? Colors.white : Colors.black87),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: _useHintWithAd,
                icon: const Icon(
                  Icons.lightbulb_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  'sudoku.btn_hint_ad'.tr(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Papan Angka 1 - 9
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            children: List.generate(9, (idx) {
              final int num = idx + 1;
              final bool isExhausted = _countPlacedNumber(num) >= 9;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: isExhausted ? null : () => _onNumberInput(num),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isExhausted
                            ? (isDarkMode
                                ? Colors.grey.shade900
                                : Colors.grey.shade200)
                            : Colors.indigo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$num',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isExhausted ? Colors.grey : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSudokuCell(
    int r,
    int c,
    int? selectedValue,
    bool isDarkMode,
  ) {
    final int val = _board[r][c];
    final bool isSelected = (_selectedRow == r && _selectedCol == c);
    final bool isSameGroup = (_selectedRow != null &&
        _selectedCol != null &&
        (_selectedRow == r ||
            _selectedCol == c ||
            ((_selectedRow! ~/ 3 == r ~/ 3) &&
                (_selectedCol! ~/ 3 == c ~/ 3))));
    final bool isSameNumber =
        (val != 0 && selectedValue != null && selectedValue == val);

    Color cellBg = Colors.transparent;
    if (isSelected) {
      cellBg = Colors.indigo.withValues(alpha: 0.35);
    } else if (isSameNumber) {
      cellBg = Colors.amber.withValues(alpha: 0.28);
    } else if (isSameGroup) {
      cellBg = Colors.indigo.withValues(alpha: isDarkMode ? 0.14 : 0.08);
    }

    final Color thickBorderColor =
        isDarkMode ? Colors.indigo.shade300 : Colors.indigo.shade900;
    final Color thinBorderColor = isDarkMode
        ? Colors.grey.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRow = r;
          _selectedCol = c;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          border: Border(
            right: BorderSide(
              color: (c == 2 || c == 5) ? thickBorderColor : thinBorderColor,
              width: (c == 2 || c == 5) ? 2.0 : 0.6,
            ),
            bottom: BorderSide(
              color: (r == 2 || r == 5) ? thickBorderColor : thinBorderColor,
              width: (r == 2 || r == 5) ? 2.0 : 0.6,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: val != 0
            ? Text(
                '$val',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isInitialClue[r][c]
                      ? (isDarkMode ? Colors.white : const Color(0xFF1E293B))
                      : (isDarkMode
                          ? Colors.indigo.shade200
                          : Colors.indigo.shade700),
                ),
              )
            : _buildCellNotes(r, c, isDarkMode),
      ),
    );
  }

  Widget _buildCellNotes(int r, int c, bool isDarkMode) {
    final Set<int> cellNotes = _notes[r][c];
    if (cellNotes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (nr) {
          return Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (nc) {
                final int n = nr * 3 + nc + 1;
                return Expanded(
                  child: Center(
                    child: Text(
                      cellNotes.contains(n) ? '$n' : '',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: isDarkMode
                            ? Colors.indigo.shade200
                            : Colors.indigo.shade700,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
