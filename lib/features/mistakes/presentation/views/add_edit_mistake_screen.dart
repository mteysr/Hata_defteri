import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/file_service.dart';
import '../../../lessons/data/models/lesson.dart';
import '../../../lessons/presentation/controllers/lesson_controller.dart';
import '../../domain/models/mistake.dart';
import '../controllers/mistake_controller.dart';
import 'package:hive/hive.dart';

class AddEditMistakeScreen extends ConsumerStatefulWidget {
  final String? mistakeId;

  const AddEditMistakeScreen({super.key, this.mistakeId});

  @override
  ConsumerState<AddEditMistakeScreen> createState() => _AddEditMistakeScreenState();
}

class _AddEditMistakeScreenState extends ConsumerState<AddEditMistakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Form Fields
  String? _selectedLessonId;
  String? _selectedSubject;
  final _bookController = TextEditingController();
  final _examController = TextEditingController();
  final _testController = TextEditingController();
  final _pageController = TextEditingController();
  final _questionNumController = TextEditingController();
  String _difficulty = 'MEDIUM';
  String _reason = 'CARELESSNESS';
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  // Images
  String? _questionImagePath;
  String? _solutionImagePath;
  bool _isLoading = false;
  String? _correctAnswerOption;

  @override
  void initState() {
    super.initState();
    if (widget.mistakeId != null) {
      _loadMistakeData();
    } else {
      _loadLastSelections();
    }
  }

  void _loadLastSelections() {
    final settingsBox = Hive.box(AppConstants.settingsBoxName);
    _selectedLessonId = settingsBox.get('last_selected_lesson_id') as String?;
    _selectedSubject = settingsBox.get('last_selected_subject') as String?;
  }

  void _loadMistakeData() {
    final mistake = ref.read(mistakeListProvider).firstWhere((m) => m.id == widget.mistakeId);
    _selectedLessonId = mistake.lessonId;
    _selectedSubject = mistake.subject;
    _bookController.text = mistake.sourceBook ?? '';
    _examController.text = mistake.mockExamName ?? '';
    _testController.text = mistake.testName ?? '';
    _pageController.text = mistake.pageNumber?.toString() ?? '';
    _questionNumController.text = mistake.questionNumber?.toString() ?? '';
    _difficulty = mistake.difficulty;
    _reason = mistake.reason;
    _notesController.text = mistake.note ?? '';
    _tagsController.text = mistake.tags.join(', ');
    _questionImagePath = mistake.questionImagePath;
    _solutionImagePath = mistake.solutionImagePath;
    _correctAnswerOption = mistake.correctAnswerOption;
  }

  @override
  void dispose() {
    _bookController.dispose();
    _examController.dispose();
    _testController.dispose();
    _pageController.dispose();
    _questionNumController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isQuestion, ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (isQuestion) {
            _questionImagePath = pickedFile.path;
          } else {
            _solutionImagePath = pickedFile.path;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilirken bir hata oluştu: $e')),
      );
    }
  }

  void _showImageSourceSheet(bool isQuestion) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera ile Çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isQuestion, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isQuestion, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog to Add a New Lesson
  void _showAddLessonDialog() {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.lightPrimary;
    IconData selectedIcon = Icons.menu_book;

    final List<Color> colorPresets = [
      AppColors.math,
      AppColors.turkish,
      AppColors.history,
      AppColors.geography,
      AppColors.civics,
      AppColors.geometry,
      AppColors.physics,
      AppColors.chemistry,
      AppColors.biology,
      AppColors.english,
    ];

    final List<IconData> iconPresets = [
      Icons.menu_book,
      Icons.functions,
      Icons.translate,
      Icons.history,
      Icons.public,
      Icons.gavel,
      Icons.category,
      Icons.science,
      Icons.opacity,
      Icons.spa,
      Icons.language,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Yeni Ders Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ders Adı',
                        hintText: 'Örn: Edebiyat',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ders Rengi', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colorPresets.map((color) {
                        final isSelected = selectedColor.value == color.value;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ders İkonu', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: iconPresets.map((icon) {
                        final isSelected = selectedIcon.codePoint == icon.codePoint;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary) : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final newLesson = Lesson(
                        id: const Uuid().v4(),
                        name: name,
                        colorValue: selectedColor.value,
                        iconCodePoint: selectedIcon.codePoint,
                        subjects: [],
                      );
                      await ref.read(lessonListProvider.notifier).addLesson(newLesson);
                      setState(() {
                        _selectedLessonId = newLesson.id;
                        _selectedSubject = null;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog to Add a New Subject under selected Lesson
  void _showAddSubjectDialog() {
    if (_selectedLessonId == null) return;
    final subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Konu Ekle'),
          content: TextField(
            controller: subjectController,
            decoration: const InputDecoration(
              labelText: 'Konu Adı',
              hintText: 'Örn: Üslü Sayılar',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = subjectController.text.trim();
                if (name.isNotEmpty) {
                  await ref
                      .read(lessonListProvider.notifier)
                      .addSubject(_selectedLessonId!, name);
                  setState(() {
                    _selectedSubject = name;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  // Save/Update Mistake Handler
  Future<void> _saveMistake() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questionImagePath == null || _questionImagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen sorunun bir fotoğrafını ekleyin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditMode = widget.mistakeId != null;
      String localQuestionPath = _questionImagePath!;
      String? localSolutionPath = _solutionImagePath;

      // Copy images locally if they have changed or are new
      if (!isEditMode) {
        localQuestionPath = await FileService.instance.saveImage(_questionImagePath!);
        if (_solutionImagePath != null) {
          localSolutionPath = await FileService.instance.saveImage(_solutionImagePath!);
        }
      } else {
        final original = ref.read(mistakeListProvider).firstWhere((m) => m.id == widget.mistakeId);
        if (_questionImagePath != original.questionImagePath) {
          // New question image selected
          await FileService.instance.deleteImage(original.questionImagePath);
          localQuestionPath = await FileService.instance.saveImage(_questionImagePath!);
        }
        if (_solutionImagePath != original.solutionImagePath) {
          // New solution image selected
          if (original.solutionImagePath != null) {
            await FileService.instance.deleteImage(original.solutionImagePath);
          }
          if (_solutionImagePath != null) {
            localSolutionPath = await FileService.instance.saveImage(_solutionImagePath!);
          }
        }
      }

      // Prepare tags list
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final mistake = Mistake(
        id: isEditMode ? widget.mistakeId! : const Uuid().v4(),
        lessonId: _selectedLessonId!,
        subject: _selectedSubject!,
        sourceBook: _bookController.text.trim().isEmpty ? null : _bookController.text.trim(),
        mockExamName: _examController.text.trim().isEmpty ? null : _examController.text.trim(),
        testName: _testController.text.trim().isEmpty ? null : _testController.text.trim(),
        pageNumber: int.tryParse(_pageController.text),
        questionNumber: int.tryParse(_questionNumController.text),
        difficulty: _difficulty,
        reason: _reason,
        note: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        tags: tags,
        questionImagePath: localQuestionPath,
        solutionImagePath: localSolutionPath,
        createdAt: isEditMode
            ? ref.read(mistakeListProvider).firstWhere((m) => m.id == widget.mistakeId).createdAt
            : DateTime.now(),
        nextReviewAt: isEditMode
            ? ref.read(mistakeListProvider).firstWhere((m) => m.id == widget.mistakeId).nextReviewAt
            : DateTime.now().add(const Duration(days: 1)), // default to tomorrow
        reviewStage: isEditMode
            ? ref.read(mistakeListProvider).firstWhere((m) => m.id == widget.mistakeId).reviewStage
            : 0,
        isCompleted: isEditMode
            ? ref.read(mistakeListProvider).firstWhere((m) => m.id == widget.mistakeId).isCompleted
            : false,
        reviewAttempts: isEditMode
            ? ref.read(mistakeListProvider).firstWhere((m) => m.id == widget.mistakeId).reviewAttempts
            : [],
        correctAnswerOption: _correctAnswerOption,
      );

      if (isEditMode) {
        await ref.read(mistakeListProvider.notifier).updateMistake(mistake);
      } else {
        await ref.read(mistakeListProvider.notifier).addMistake(mistake);
      }

      // Save last selected lesson and subject in Hive settings for user convenience
      final settingsBox = Hive.box(AppConstants.settingsBoxName);
      await settingsBox.put('last_selected_lesson_id', _selectedLessonId);
      await settingsBox.put('last_selected_subject', _selectedSubject);

      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata kaydedilirken bir sorun oluştu: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(lessonListProvider);
    final theme = Theme.of(context);

    // Get subjects list for current lesson
    List<String> subjects = [];
    if (_selectedLessonId != null) {
      final lessonObj = lessons.firstWhere((l) => l.id == _selectedLessonId, orElse: () => lessons.first);
      subjects = lessonObj.subjects;
      
      // Safety guard: if the selected subject is not in the subjects list, reset it to null!
      if (_selectedSubject != null && !subjects.contains(_selectedSubject)) {
        _selectedSubject = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mistakeId != null ? 'Hata Düzenle' : 'Yeni Yanlış Soru Ekle'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveMistake,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: PHOTOS ---
                    Text('Soru Fotoğrafı *', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildPhotoBox(
                      isQuestion: true,
                      imagePath: _questionImagePath,
                      onTap: () => _showImageSourceSheet(true),
                      onDelete: () => setState(() => _questionImagePath = null),
                    ),
                    const SizedBox(height: 20),

                    Text('Çözüm Fotoğrafı (İsteğe Bağlı)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildPhotoBox(
                      isQuestion: false,
                      imagePath: _solutionImagePath,
                      onTap: () => _showImageSourceSheet(false),
                      onDelete: () => setState(() => _solutionImagePath = null),
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION 2: CATEGORY ---
                    Text('Kategorizasyon', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Lesson selection
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedLessonId,
                            hint: const Text('Ders Seçin'),
                            validator: (val) => val == null ? 'Lütfen bir ders seçin' : null,
                            decoration: const InputDecoration(labelText: 'Ders'),
                            items: lessons.map((l) {
                              return DropdownMenuItem<String>(
                                value: l.id,
                                child: Text(l.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedLessonId = val;
                                _selectedSubject = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          onPressed: _showAddLessonDialog,
                          icon: const Icon(Icons.add),
                          tooltip: 'Ders Ekle',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Subject selection
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSubject,
                            disabledHint: const Text('Önce ders seçmelisiniz'),
                            hint: const Text('Konu Seçin'),
                            validator: (val) => val == null ? 'Lütfen bir konu seçin' : null,
                            decoration: const InputDecoration(labelText: 'Konu'),
                            items: _selectedLessonId == null
                                ? null
                                : subjects.map((sub) {
                                    return DropdownMenuItem<String>(
                                      value: sub,
                                      child: Text(sub),
                                    );
                                  }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedSubject = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          onPressed: _selectedLessonId == null ? null : _showAddSubjectDialog,
                          icon: const Icon(Icons.add),
                          tooltip: 'Konu Ekle',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Correct Answer Option Selection
                    Text(
                      'Doğru Cevap Şıkkı (İsteğe Bağlı)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['A', 'B', 'C', 'D', 'E'].map((opt) {
                        final isSelected = _correctAnswerOption == opt;
                        return ChoiceChip(
                          label: SizedBox(
                            width: 30,
                            child: Center(
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          onSelected: (selected) {
                            setState(() {
                              _correctAnswerOption = selected ? opt : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION 3: METADATA ---
                    Text('Sınav & Kitap Bilgileri (İsteğe Bağlı)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bookController,
                      decoration: const InputDecoration(
                        labelText: 'Kaynak Kitap',
                        hintText: 'Örn: 345 TYT Matematik',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _examController,
                            decoration: const InputDecoration(
                              labelText: 'Deneme Sınavı Adı',
                              hintText: 'Örn: Özdebir 1',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _testController,
                            decoration: const InputDecoration(
                              labelText: 'Test Adı / No',
                              hintText: 'Örn: Test 3',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Sayfa',
                              hintText: 'Örn: 124',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _questionNumController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Soru Numarası',
                              hintText: 'Örn: 5',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION 4: EVALUATION ---
                    Text('Değerlendirme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Difficulty
                    Text('Zorluk Seviyesi', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: AppConstants.difficultyTranslations.entries.map((entry) {
                        final isSelected = _difficulty == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _difficulty = entry.key);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Mistake Reason
                    Text('Yanlış Nedeni', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: AppConstants.reasonTranslations.entries.map((entry) {
                        final isSelected = _reason == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _reason = entry.key);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION 5: NOTES & TAGS ---
                    Text('Notlar & Etiketler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Çalışma Notu',
                        hintText: 'Soru ile ilgili püf noktaları buraya yazabilirsiniz...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Etiketler (Virgülle Ayırın)',
                        hintText: 'Örn: üslü-sayı, zor-soru, 2026-tyt',
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveMistake,
                        icon: const Icon(Icons.save),
                        label: Text(widget.mistakeId != null ? 'Değişiklikleri Kaydet' : 'Hata Defterine Ekle'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoBox({
    required bool isQuestion,
    required String? imagePath,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    final actualPath = imagePath != null ? FileService.getActualPath(imagePath) : null;
    final hasImage = actualPath != null && actualPath.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? theme.colorScheme.primary.withOpacity(0.3) : theme.colorScheme.outline.withOpacity(0.5),
            style: BorderStyle.solid,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(actualPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.6),
                      ),
                      onPressed: onDelete,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isQuestion ? Icons.camera_enhance : Icons.add_photo_alternate_outlined,
                    size: 44,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isQuestion
                        ? 'Fotoğraf Çekmek veya Yüklemek için Tıklayın'
                        : 'Çözüm/İpucu Fotoğrafı Yüklemek için Tıklayın',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
