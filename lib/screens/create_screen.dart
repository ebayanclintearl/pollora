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

  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  XFile? _pickedImage;
  bool _imageEnabled = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= _maxOptions) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (index < 2) return; // first two are required
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image != null) setState(() => _pickedImage = image);
  }

  void _removeImage() => setState(() => _pickedImage = null);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, top + 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Create Poll',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ask a question and add options',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Form Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poll question
                  _FieldLabel(label: 'Poll question'),
                  const SizedBox(height: 8),
                  _InputField(
                    placeholder: 'What should we watch tonight?',
                    minLines: 2,
                    maxLength: 120,
                  ),
                  const SizedBox(height: 20),

                  // Cover image toggle + picker
                  _ImageToggleRow(
                    enabled: _imageEnabled,
                    onChanged: (val) {
                      setState(() {
                        _imageEnabled = val;
                        if (!val) _pickedImage = null;
                      });
                    },
                  ),
                  if (_imageEnabled) ...[
                    const SizedBox(height: 12),
                    _ImagePickerField(
                      image: _pickedImage,
                      onPick: _pickImage,
                      onRemove: _removeImage,
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Options
                  ..._buildOptionFields(),

                  const SizedBox(height: 12),

                  // Add option row — hidden at max
                  if (_optionControllers.length < _maxOptions)
                    _AddOptionRow(onTap: _addOption),

                  const SizedBox(height: 12),

                  // Helper text
                  Text(
                    _optionControllers.length >= _maxOptions
                        ? 'Maximum $_maxOptions options reached'
                        : 'Minimum 2 options · Maximum $_maxOptions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Publish Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Publish Poll',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptionFields() {
    final widgets = <Widget>[];
    for (int i = 0; i < _optionControllers.length; i++) {
      final isOptional = i >= 2;
      final canRemove = i >= 2;
      final label = isOptional ? 'Option ${i + 1} (optional)' : 'Option ${i + 1}';
      final isLast = i == _optionControllers.length - 1;

      // Label row with optional remove button
      widgets.add(
        Row(
          children: [
            Expanded(child: _FieldLabel(label: label, isOptional: isOptional)),
            if (canRemove)
              GestureDetector(
                onTap: () => _removeOption(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 8));
      widgets.add(_InputField(
        placeholder: 'Enter an option',
        controller: _optionControllers[i],
        maxLength: 40,
      ));
      if (!isLast) widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isOptional;

  const _FieldLabel({required this.label, this.isOptional = false});

  @override
  Widget build(BuildContext context) {
    if (!isOptional) {
      return Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
      );
    }

    // "Option X (optional)" — split label for styling
    final parts = label.split(' (optional)');
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: parts[0],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const TextSpan(
            text: ' (optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String placeholder;
  final int minLines;
  final TextEditingController? controller;
  final int? maxLength;

  const _InputField({
    required this.placeholder,
    this.minLines = 1,
    this.controller,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines > 1 ? 4 : 1,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPlaceholder,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          // hide Flutter's built-in counter
          counterText: '',
        ),
        cursorColor: AppColors.accentPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Image Toggle Row
// ─────────────────────────────────────────────
class _ImageToggleRow extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ImageToggleRow({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: enabled ? AppColors.accentPrimary : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image_outlined,
              color: enabled ? Colors.white : AppColors.textTertiary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.accentPrimary,
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.surfaceElevated,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Image Picker Field
// ─────────────────────────────────────────────
class _ImagePickerField extends StatelessWidget {
  final XFile? image;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerField({
    required this.image,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: image == null
            ? _EmptyImageState(onPick: onPick)
            : _FilledImageState(image: image!, onRemove: onRemove),
      ),
    );
  }
}

class _EmptyImageState extends StatelessWidget {
  final VoidCallback onPick;
  const _EmptyImageState({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: AppColors.surfaceInput,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.image_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add photo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '16 : 9 aspect ratio',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledImageState extends StatelessWidget {
  final XFile image;
  final VoidCallback onRemove;
  const _FilledImageState({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(image.path), fit: BoxFit.cover),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
class _AddOptionRow extends StatelessWidget {
  final VoidCallback onTap;

  const _AddOptionRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.accentPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add option',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
