import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_colors.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  static const int _maxOptions = 6;

  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  XFile? _coverImage;
  bool _imageEnabled = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) c.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= _maxOptions) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (index < 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _toggleCoverImage() async {
    if (_imageEnabled) {
      setState(() {
        _imageEnabled = false;
        _coverImage = null;
      });
      return;
    }
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image != null) {
      setState(() {
        _imageEnabled = true;
        _coverImage = image;
      });
    }
  }

  Future<void> _replaceCoverImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image != null) setState(() => _coverImage = image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Create Poll',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Question input — large, no label, always visible
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _questionController,
                minLines: 1,
                maxLines: 4,
                maxLength: 120,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask your question…',
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPlaceholder,
                    height: 1.35,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: AppColors.accentPrimary,
              ),
            ),

            // Compact cover image strip — only when enabled
            if (_imageEnabled && _coverImage != null) ...[
              const SizedBox(height: 16),
              _CoverImageStrip(
                image: _coverImage!,
                onReplace: _replaceCoverImage,
                onRemove: () => setState(() {
                  _imageEnabled = false;
                  _coverImage = null;
                }),
              ),
            ],

            const SizedBox(height: 24),

            // Options section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'OPTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_optionControllers.length} / $_maxOptions',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Options — scrollable within remaining space
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  ..._buildOptionRows(),
                  const SizedBox(height: 4),
                  if (_optionControllers.length < _maxOptions)
                    _AddOptionRow(onTap: _addOption),
                ],
              ),
            ),
          ],
        ),
      ),

      // Publish + image button — always pinned above keyboard
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.borderDefault, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Image toggle
              GestureDetector(
                onTap: _toggleCoverImage,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _imageEnabled ? AppColors.accentPrimary : AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: _imageEnabled ? Colors.white : AppColors.textTertiary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Publish button
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Publish Poll',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionRows() {
    final rows = <Widget>[];
    for (int i = 0; i < _optionControllers.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      rows.add(_OptionRow(
        index: i,
        controller: _optionControllers[i],
        canRemove: i >= 2,
        onRemove: () => _removeOption(i),
      ));
    }
    return rows;
  }
}

// ─────────────────────────────────────────────
// Compact option row
// ─────────────────────────────────────────────
class _OptionRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final bool canRemove;
  final VoidCallback onRemove;

  const _OptionRow({
    required this.index,
    required this.controller,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Number badge
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Input
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: controller,
              maxLines: 1,
              maxLength: 40,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: index < 2 ? 'Option ${index + 1}' : 'Option ${index + 1} · optional',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPlaceholder,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              cursorColor: AppColors.accentPrimary,
            ),
          ),
        ),
        // Remove button (optional slots only)
        if (canRemove)
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 36,
              height: 44,
              child: Icon(Icons.close_rounded, size: 15, color: AppColors.textTertiary),
            ),
          )
        else
          const SizedBox(width: 36),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Compact cover image strip
// ─────────────────────────────────────────────
class _CoverImageStrip extends StatelessWidget {
  final XFile image;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  const _CoverImageStrip({
    required this.image,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: SizedBox(
                width: 70,
                height: 52,
                child: Image.file(File(image.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            // Labels
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cover image',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onReplace,
                    child: const Text(
                      'Replace photo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Remove
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 44,
                height: 52,
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add option row
// ─────────────────────────────────────────────
class _AddOptionRow extends StatelessWidget {
  final VoidCallback onTap;
  const _AddOptionRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.textTertiary, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Add option',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
