import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/constants/app_colors.dart';

class AcademyFlashcard {
  final dynamic id;
  final String category;
  final String question;
  final String answer;

  AcademyFlashcard({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  factory AcademyFlashcard.fromJson(Map<String, dynamic> json) {
    return AcademyFlashcard(
      id: json['id'],
      category: json['category'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'answer': answer,
    };
  }
}

enum FlashcardMode { daily, custom }
enum TtsPlaylistState { idle, readingQuestion, readingAnswer }

class AcademyFlashcardCard extends StatefulWidget {
  const AcademyFlashcardCard({super.key});

  @override
  State<AcademyFlashcardCard> createState() => _AcademyFlashcardCardState();
}

class _AcademyFlashcardCardState extends State<AcademyFlashcardCard> {
  List<AcademyFlashcard> _dailyCards = [];
  List<AcademyFlashcard> _customCards = [];
  FlashcardMode _mode = FlashcardMode.daily;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;

  // Text-To-Speech properties
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  TtsPlaylistState _ttsState = TtsPlaylistState.idle;

  @override
  void initState() {
    super.initState();
    _loadDailyCards();
    _loadCustomCards();
    _initTts();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('tr-TR');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() async {
        if (!_isSpeaking) return;

        if (_ttsState == TtsPlaylistState.readingQuestion) {
          // Question finished. Flip card to show answer!
          if (mounted) {
            setState(() {
              _isFlipped = true;
            });
          }

          // Wait 1.8 seconds for thinking pause and animation
          await Future.delayed(const Duration(milliseconds: 1800));
          if (!_isSpeaking) return;

          final activeCards = _mode == FlashcardMode.daily ? _dailyCards : _customCards;
          if (_currentIndex >= activeCards.length) return;
          final card = activeCards[_currentIndex];

          if (mounted) {
            setState(() {
              _ttsState = TtsPlaylistState.readingAnswer;
            });
          }
          await _flutterTts.speak("Cevap: ${card.answer}");
        } else if (_ttsState == TtsPlaylistState.readingAnswer) {
          // Answer finished. Wait 2.5 seconds
          await Future.delayed(const Duration(milliseconds: 2500));
          if (!_isSpeaking) return;

          final activeCards = _mode == FlashcardMode.daily ? _dailyCards : _customCards;
          if (_currentIndex < activeCards.length - 1) {
            // Advance card
            if (mounted) {
              setState(() {
                _currentIndex++;
                _isFlipped = false;
              });
            }

            // Delay for transition
            await Future.delayed(const Duration(milliseconds: 400));
            if (!_isSpeaking) return;

            _readCurrentCardQuestion();
          } else {
            // Reached end of cards
            _stopSpeech();
          }
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _stopSpeech();
      });
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
  }

  Future<void> _startSpeechPlaylist() async {
    final activeCards = _mode == FlashcardMode.daily ? _dailyCards : _customCards;
    if (activeCards.isEmpty) return;

    setState(() {
      _isSpeaking = true;
    });
    _readCurrentCardQuestion();
  }

  Future<void> _readCurrentCardQuestion() async {
    final activeCards = _mode == FlashcardMode.daily ? _dailyCards : _customCards;
    if (_currentIndex >= activeCards.length) return;
    final card = activeCards[_currentIndex];

    setState(() {
      _ttsState = TtsPlaylistState.readingQuestion;
    });

    final textToSpeak = "${card.category} dersi hap bilgisi. Soru: ${card.question}";
    await _flutterTts.speak(textToSpeak);
  }

  Future<void> _stopSpeech() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _ttsState = TtsPlaylistState.idle;
      });
    }
  }

  Future<void> _loadDailyCards() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/questions/academy_flashcards.json');
      final List<dynamic> jsonList = json.decode(jsonStr);
      final allCards = jsonList.map((e) => AcademyFlashcard.fromJson(e)).toList();

      if (allCards.isNotEmpty) {
        // Selection of 5 cards deterministically based on today's date
        final now = DateTime.now();
        final int seed = now.year * 10000 + now.month * 100 + now.day;
        final random = Random(seed);

        final shuffled = List<AcademyFlashcard>.from(allCards)..shuffle(random);
        setState(() {
          _dailyCards = shuffled.take(5).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading flashcards: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadCustomCards() {
    try {
      final box = Hive.box('academy_settings_box');
      final rawCards = box.get('custom_flashcards', defaultValue: []);
      final parsed = List<dynamic>.from(rawCards)
          .map((e) => AcademyFlashcard.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _customCards = parsed;
      });
    } catch (e) {
      debugPrint('Error loading custom cards: $e');
    }
  }

  void _toggleMode(FlashcardMode newMode) {
    _stopSpeech();
    setState(() {
      _mode = newMode;
      _currentIndex = 0;
      _isFlipped = false;
    });
  }

  void _nextCard() {
    _stopSpeech();
    final activeCards = _mode == FlashcardMode.daily ? _dailyCards : _customCards;
    if (_currentIndex < activeCards.length - 1) {
      setState(() {
        _isFlipped = false; // Reset flip
        _currentIndex++;
      });
    }
  }

  void _prevCard() {
    _stopSpeech();
    if (_currentIndex > 0) {
      setState(() {
        _isFlipped = false; // Reset flip
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final activeCards = _mode == FlashcardMode.daily ? _dailyCards : _customCards;

    // Bounding index protection
    if (activeCards.isNotEmpty && _currentIndex >= activeCards.length) {
      _currentIndex = 0;
    }

    if (activeCards.isEmpty) {
      // Empty state for Custom cards mode
      if (_mode == FlashcardMode.custom) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                color: theme.colorScheme.surfaceVariant.withOpacity(0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_card,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Henüz kendi hap bilginizi eklemediniz.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddCardBottomSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('İlk Kartını Ekle'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return const SizedBox.shrink();
    }

    final currentCard = activeCards[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        GestureDetector(
          onTap: () {
            _stopSpeech(); // Stop speech if user interacts manually
            setState(() {
              _isFlipped = !_isFlipped;
            });
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _isFlipped ? pi : 0),
            duration: const Duration(milliseconds: 300),
            builder: (context, val, child) {
              final isBack = val >= pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(val),
                child: isBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildCardContent(
                          context: context,
                          theme: theme,
                          category: currentCard.category,
                          text: currentCard.answer,
                          isBack: true,
                        ),
                      )
                    : _buildCardContent(
                        context: context,
                        theme: theme,
                        category: currentCard.category,
                        text: currentCard.question,
                        isBack: false,
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: _currentIndex > 0 ? _prevCard : null,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ),
            ),
            Row(
              children: [
                if (_mode == FlashcardMode.custom) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Kartı Sil',
                    onPressed: () => _confirmDeleteCard(context, currentCard),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Çevirmek için karta dokunun',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentIndex < activeCards.length - 1 ? _nextCard : null,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final activeCards = _mode == FlashcardMode.daily ? _dailyCards : _customCards;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _mode == FlashcardMode.daily ? 'Günün Hap Bilgileri 💡' : 'Kendi Hap Bilgilerim ✍️',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              // Mode Toggle
              if (_customCards.isNotEmpty || _mode == FlashcardMode.custom) ...[
                IconButton(
                  icon: Icon(
                    _mode == FlashcardMode.daily ? Icons.folder_shared : Icons.today,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: _mode == FlashcardMode.daily ? 'Kendi Kartlarım' : 'Günün Kartları',
                  onPressed: () {
                    _toggleMode(_mode == FlashcardMode.daily ? FlashcardMode.custom : FlashcardMode.daily);
                  },
                ),
                const SizedBox(width: 4),
              ],
              // Add custom card
              IconButton(
                icon: const Icon(Icons.add_card, size: 20),
                tooltip: 'Hap Bilgi Ekle',
                onPressed: _showAddCardBottomSheet,
              ),
              const SizedBox(width: 4),
              // Play/Stop Audio Button
              if (activeCards.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _isSpeaking ? Icons.volume_off : Icons.volume_up,
                    size: 20,
                    color: _isSpeaking ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                  tooltip: _isSpeaking ? 'Seslendirmeyi Durdur' : 'Sesli Oku (Eller Serbest)',
                  onPressed: () {
                    if (_isSpeaking) {
                      _stopSpeech();
                    } else {
                      _startSpeechPlaylist();
                    }
                  },
                ),
              const SizedBox(width: 12),
              if (activeCards.isNotEmpty)
                Text(
                  '${_currentIndex + 1} / ${activeCards.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent({
    required BuildContext context,
    required ThemeData theme,
    required String category,
    required String text,
    required bool isBack,
  }) {
    Color catColor = theme.colorScheme.primary;
    if (category == 'Coğrafya') catColor = Colors.orange;
    if (category == 'Vatandaşlık') catColor = Colors.teal;

    final gradientColors = isBack
        ? [catColor.withOpacity(0.12), catColor.withOpacity(0.04)]
        : [theme.colorScheme.surfaceVariant.withOpacity(0.15), theme.colorScheme.surfaceVariant.withOpacity(0.03)];

    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: catColor.withOpacity(0.3), width: 1.5),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: catColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSpeaking) ...[
                  const AnimatedEqualizer(),
                  const SizedBox(width: 8),
                ],
                Text(
                  isBack ? 'Cevap' : 'Soru',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isBack ? FontWeight.bold : FontWeight.w500,
                  height: 1.35,
                  color: isBack ? catColor : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCard(BuildContext context, AcademyFlashcard card) {
    _stopSpeech();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kartı Sil'),
          content: const Text('Bu hap bilgi kartını silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCard(card.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCard(dynamic cardId) async {
    try {
      final box = Hive.box('academy_settings_box');
      final rawCards = box.get('custom_flashcards', defaultValue: []);
      final updatedList = List<dynamic>.from(rawCards)
          .where((e) => e['id'] != cardId)
          .toList();
      await box.put('custom_flashcards', updatedList);
      
      _loadCustomCards();

      setState(() {
        if (_currentIndex >= updatedList.length && _currentIndex > 0) {
          _currentIndex = updatedList.length - 1;
        }
        _isFlipped = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kart başarıyla silindi.')),
      );
    } catch (e) {
      debugPrint('Error deleting card: $e');
    }
  }

  void _showAddCardBottomSheet() {
    _stopSpeech();
    final theme = Theme.of(context);
    String selectedCategory = 'Tarih';
    final TextEditingController questionController = TextEditingController();
    final TextEditingController answerController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kendi Hap Bilgini Ekle ✍️',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ders Seçimi',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Tarih', 'Coğrafya', 'Vatandaşlık'].map((cat) {
                        final isSelected = selectedCategory == cat;
                        Color catColor = theme.colorScheme.primary;
                        if (cat == 'Coğrafya') catColor = Colors.orange;
                        if (cat == 'Vatandaşlık') catColor = Colors.teal;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: catColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? catColor : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedCategory = cat;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: questionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Soru / Hap Bilgi Başlığı',
                        hintText: 'Örn: Divan-ı Hümayun kararlarının yazıldığı defter hangisidir?',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: answerController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Cevap / Açıklama Detayı',
                        hintText: 'Örn: Mühimme Defteri. Bu defterler sadrazamın emriyle tutulurdu.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _saveCustomCard(
                        category: selectedCategory,
                        question: questionController.text.trim(),
                        answer: answerController.text.trim(),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Kartı Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveCustomCard({
    required String category,
    required String question,
    required String answer,
  }) async {
    if (question.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    try {
      final newCardMap = {
        'id': const Uuid().v4(),
        'category': category,
        'question': question,
        'answer': answer,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final box = Hive.box('academy_settings_box');
      final rawCards = box.get('custom_flashcards', defaultValue: []);
      final updatedList = List<dynamic>.from(rawCards)..add(newCardMap);
      await box.put('custom_flashcards', updatedList);

      Navigator.pop(context); // Close bottom sheet
      _loadCustomCards(); // Reload list

      // Switch to custom view mode
      _toggleMode(FlashcardMode.custom);
      
      setState(() {
        _currentIndex = _customCards.length - 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kart başarıyla eklendi! 🎉')),
      );
    } catch (e) {
      debugPrint('Error saving custom card: $e');
    }
  }
}

// ----------------------------------------------------
// Animated Wave/Equalizer Widget for Audio Indicator
// ----------------------------------------------------
class AnimatedEqualizer extends StatefulWidget {
  const AnimatedEqualizer({super.key});

  @override
  State<AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<AnimatedEqualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double val = sin((_controller.value * 2 * pi) + (index * pi / 2));
            final double height = 4.0 + (10.0 * (val + 1.0) / 2.0);
            return Container(
              width: 2.5,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
