import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

// PERBAIKAN 1: Path disesuaikan dengan folder images (tambahkan di pubspec.yaml jika belum)
const String _kLogoAssetPath = 'assets/images/icon.png';

const _kPrimary = Color(0xFF0D47A1);
const _kPrimaryLight = Color(0xFF1E88E5);

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {

  Locale _selectedLocale = const Locale('id');
  bool _isSaving = false;

  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _cardsFade;
  late final Animation<Offset> _cardsSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero)
        .animate(_logoFade);

    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    );

    _cardsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _cardsSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(_cardsFade);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCardTap(Locale locale) {
    if (_isSaving || _selectedLocale == locale) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedLocale = locale);
  }

  Future<void> _confirmSelection() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    await context.setLocale(_selectedLocale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_chosen_language', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, anim, __) => const MainNavigator(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        // PERBAIKAN 2: Menggunakan Column + Expanded agar tata letak tidak mungkin blank/error
        body: Column(
          children: [
            // ===== PANEL ATAS: Logo & Pengenalan Aplikasi =====
            Container(
              height: size.height * 0.48,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kPrimary, _kPrimaryLight],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -30,
                    child: _DecorativeCircle(
                      size: 140,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: -40,
                    child: _DecorativeCircle(
                      size: 160,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _logoFade,
                            child: SlideTransition(
                              position: _logoSlide,
                              child: _AppLogo(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _titleFade,
                            child: Text(
                              'language_picker.intro_title'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: _titleFade,
                            child: Text(
                              'language_picker.intro_desc'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== PANEL BAWAH: Judul Pilih Bahasa & Kartu =====
            Expanded(
              child: FadeTransition(
                opacity: _cardsFade,
                child: SlideTransition(
                  position: _cardsSlide,
                  child: Padding(
                    // Padding dinamis menyesuaikan safe area bawah layar HP
                    padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding > 0 ? bottomPadding + 10 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'language_picker.title'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'language_picker.subtitle'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _LanguageOptionCard(
                          flag: '🇮🇩',
                          label: 'language_picker.option_id'.tr(),
                          selected: _selectedLocale.languageCode == 'id',
                          onTap: () => _onCardTap(const Locale('id')),
                        ),
                        const SizedBox(height: 14),
                        _LanguageOptionCard(
                          flag: '🇬🇧',
                          label: 'language_picker.option_en'.tr(),
                          selected: _selectedLocale.languageCode == 'en',
                          onTap: () => _onCardTap(const Locale('en')),
                        ),
                        const Spacer(), // Sekarang aman menggunakan Spacer di sini
                        _ContinueButton(
                          label: 'language_picker.continue_button'.tr(),
                          isLoading: _isSaving,
                          onPressed: _confirmSelection,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: _kPrimary, // DIUBAH: Menjadi biru seperti tombol "Lanjutkan"
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(0),
      child: ClipOval(
        child: Image.asset(
          _kLogoAssetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.psychology_alt_rounded,
            size: 48,
            color: Colors.white, // DIUBAH: Ikon fallback menjadi putih
          ),
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? _kPrimary.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? _kPrimary : const Color(0xFFE7E9EE),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
            color: _kPrimary.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFF5F7FA),
                  child: Text(flag, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? _kPrimary : const Color(0xFF333333),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: selected
                      ? const Icon(
                    Icons.check_circle_rounded,
                    key: ValueKey('checked'),
                    color: _kPrimary,
                    size: 24,
                  )
                      : Icon(
                    Icons.circle_outlined,
                    key: const ValueKey('unchecked'),
                    color: Colors.grey.shade300,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          disabledBackgroundColor: _kPrimary.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}