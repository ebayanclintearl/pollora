import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../models/poll.dart';
import '../providers/polls_provider.dart';
import '../providers/users_provider.dart';

class CreateScreen extends ConsumerStatefulWidget {
  /// Called after a poll is published — used by the shell to switch to the feed.
  final VoidCallback? onPublished;

  const CreateScreen({super.key, this.onPublished});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  static const int _maxOptions = 6;

  final _pageController = PageController();
  int _currentStep = 0;

  final _questionController = TextEditingController();
  final _questionFocus = FocusNode();

  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<FocusNode> _optionFocuses = [FocusNode(), FocusNode()];

  String? _coverImagePath;
  final _imagePicker = ImagePicker();

  bool _questionFilled = false;
  bool _canPublish = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _questionController.addListener(_onQuestionChanged);
    for (final c in _optionControllers) {
      c.addListener(_updatePublishState);
    }

  }

  @override
  void dispose() {
    _pageController.dispose();
    _questionController.dispose();
    _questionFocus.dispose();
    for (final c in _optionControllers) { c.dispose(); }
    for (final f in _optionFocuses) { f.dispose(); }
    super.dispose();
  }

  void _onQuestionChanged() {
    final filled = _questionController.text.trim().isNotEmpty;
    if (filled != _questionFilled) setState(() => _questionFilled = filled);
    _updatePublishState();
  }

  void _updatePublishState() {
    final q = _questionController.text.trim().isNotEmpty;
    final opts =
        _optionControllers.where((c) => c.text.trim().isNotEmpty).length;
    final can = q && opts >= 2;
    if (can != _canPublish) setState(() => _canPublish = can);
  }

  void _goToStep2() {
    if (!_questionFilled) return;
    HapticFeedback.lightImpact();
    _questionFocus.unfocus();
    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep = 1);
    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) _optionFocuses[0].requestFocus();
    });
  }

  void _goToStep1() {
    HapticFeedback.lightImpact();
    for (final f in _optionFocuses) { f.unfocus(); }
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep = 0);
    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) _questionFocus.requestFocus();
    });
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _addOption() {
    if (_optionControllers.length >= _maxOptions) return;
    final ctrl = TextEditingController()..addListener(_updatePublishState);
    final focus = FocusNode();
    setState(() {
      _optionControllers.add(ctrl);
      _optionFocuses.add(focus);
    });
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) {
        focus.requestFocus();
        HapticFeedback.selectionClick();
      }
    });
  }

  void _removeOption(int index) {
    if (index < 2) return;
    _optionControllers[index].dispose();
    _optionFocuses[index].dispose();
    setState(() {
      _optionControllers.removeAt(index);
      _optionFocuses.removeAt(index);
    });
    _updatePublishState();
  }

  Future<void> _pickCoverImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _coverImagePath = picked.path);
    }
  }

  void _removeCoverImage() {
    HapticFeedback.lightImpact();
    setState(() => _coverImagePath = null);
  }

  void _onOptionSubmitted(int index) {
    if (index < _optionControllers.length - 1) {
      _optionFocuses[index + 1].requestFocus();
    } else {
      _dismissKeyboard();
    }
  }

  // ── Publish ──────────────────────────────────
  Future<void> _publishPoll() async {
    if (!_canPublish || _publishing) return;
    _dismissKeyboard();
    setState(() => _publishing = true);
    HapticFeedback.mediumImpact();

    // Build options — only non-empty entries, preserving order.
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    final options = _optionControllers
        .where((c) => c.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) => PollOption(
              id: 'opt_${ts}_${e.key}',
              text: e.value.text.trim(),
              votes: 0,
            ))
        .toList();

    final poll = Poll(
      id: 'poll_$ts',
      author: currentUser,
      question: _questionController.text.trim(),
      options: options,
      createdAt: now,
      coverImagePath: _coverImagePath,
    );

    ref.read(pollsProvider.notifier).addPoll(poll);

    // Brief pause so the user sees the button change.
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    _resetForm();

    // Switch to feed tab.
    widget.onPublished?.call();
  }

  void _resetForm() {
    _questionController.clear();

    // Dispose any dynamically-added option fields (index ≥ 2).
    for (int i = _optionControllers.length - 1; i >= 2; i--) {
      _optionControllers[i].dispose();
      _optionFocuses[i].dispose();
      _optionControllers.removeAt(i);
      _optionFocuses.removeAt(i);
    }

    // Clear the two required fields.
    for (final c in _optionControllers) { c.clear(); }

    _pageController.jumpToPage(0);
    setState(() {
      _currentStep = 0;
      _questionFilled = false;
      _canPublish = false;
      _publishing = false;
      _coverImagePath = null;
    });
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgress(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.screenTop, AppSpacing.screenH, 0),
      child: SizedBox(
        height: AppIconSizes.touchTarget,
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _currentStep == 1
                  ? GestureDetector(
                      key: const ValueKey('back'),
                      onTap: _goToStep1,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: AppIconSizes.touchTarget,
                        height: AppIconSizes.touchTarget,
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textSecondary,
                            size: AppIconSizes.control),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('none'),
                      width: AppIconSizes.touchTarget,
                      height: AppIconSizes.touchTarget),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _currentStep == 0 ? 'Create Poll' : 'Add Options',
                  key: ValueKey(_currentStep),
                  style: AppTypography.screenTitle,
                  textAlign:
                      _currentStep == 0 ? TextAlign.start : TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: AppIconSizes.touchTarget,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _StepDot(active: _currentStep == 0),
                  const SizedBox(width: 5),
                  _StepDot(active: _currentStep == 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 16, AppSpacing.screenH, 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: _currentStep == 0 ? 0.5 : 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (_, value, __) => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 3,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation(AppColors.accentPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('YOUR QUESTION', style: AppTypography.labelSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _questionController,
            focusNode: _questionFocus,
            minLines: 3,
            maxLines: 6,
            maxLength: 120,
            textInputAction: TextInputAction.done,
            onTapOutside: (_) => _dismissKeyboard(),
            onSubmitted: (_) => _dismissKeyboard(),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
            decoration: const InputDecoration(
              hintText: 'Ask your question…',
              hintStyle: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: AppColors.textPlaceholder,
                height: 1.45,
              ),
              counterText: '',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            cursorColor: AppColors.accentPrimary,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _questionController,
              builder: (_, val, __) => Text(
                '${val.text.length} / 120',
                style: AppTypography.labelSmall,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text('COVER IMAGE', style: AppTypography.labelSmall),
          const SizedBox(height: 12),
          _CoverImagePicker(
            imagePath: _coverImagePath,
            onPick: _pickCoverImage,
            onRemove: _removeCoverImage,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Row(
            children: [
              const Text('OPTIONS', style: AppTypography.labelSmall),
              const Spacer(),
              Text(
                '${_optionControllers.length} / $_maxOptions',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, 4, AppSpacing.screenH, 24),
            children: [
              ..._buildOptionRows(),
              const SizedBox(height: 4),
              if (_optionControllers.length < _maxOptions)
                _AddOptionRow(onTap: _addOption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isStep2 = _currentStep == 1;
    final enabled = isStep2 ? _canPublish : _questionFilled;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 10, AppSpacing.screenH, 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border:
            Border(top: BorderSide(color: AppColors.borderDefault, width: 0.5)),
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled && !_publishing
              ? (isStep2 ? _publishPoll : _goToStep2)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPrimary,
            disabledBackgroundColor: AppColors.surfaceElevated,
            foregroundColor: Colors.white,
            disabledForegroundColor: AppColors.textSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _publishing
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isStep2 ? 'Publish Poll' : 'Continue',
                    key: ValueKey(_currentStep),
                    style: AppTypography.titleSmall
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
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
        focusNode: _optionFocuses[i],
        canRemove: i >= 2,
        isLast: i == _optionControllers.length - 1,
        onRemove: () => _removeOption(i),
        onSubmitted: () => _onOptionSubmitted(i),
      ));
    }
    return rows;
  }
}

// ─────────────────────────────────────────────
// Step dot
// ─────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: active ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.accentPrimary : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Option row
// ─────────────────────────────────────────────
class _OptionRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canRemove;
  final bool isLast;
  final VoidCallback onRemove;
  final VoidCallback onSubmitted;

  const _OptionRow({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.canRemove,
    required this.isLast,
    required this.onRemove,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 1,
            maxLength: 40,
            textInputAction:
                isLast ? TextInputAction.done : TextInputAction.next,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onSubmitted: (_) => onSubmitted(),
            style:
                AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: index < 2
                  ? 'Option ${index + 1}'
                  : 'Option ${index + 1} · optional',
              hintStyle: AppTypography.titleSmall
                  .copyWith(color: AppColors.textPlaceholder),
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            cursorColor: AppColors.accentPrimary,
          ),
        ),
        if (canRemove)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onRemove();
            },
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: AppIconSizes.touchTarget,
              height: 52,
              child: Icon(Icons.close_rounded,
                  size: AppIconSizes.control, color: AppColors.textSecondary),
            ),
          )
        else
          const SizedBox(width: AppIconSizes.touchTarget),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Cover image picker  (16:9, optional)
// ─────────────────────────────────────────────
class _CoverImagePicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _CoverImagePicker({
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: imagePath != null
          ? _Preview(imagePath: imagePath!, onRemove: onRemove)
          : _Placeholder(onPick: onPick),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final VoidCallback onPick;
  const _Placeholder({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.borderDefault,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentPrimaryMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.textAccent,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add cover image',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Optional · 16:9',
              style: AppTypography.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;
  const _Preview({required this.imagePath, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        // Remove button top-right
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.textSecondary, size: AppIconSizes.inline),
            ),
            const SizedBox(width: 8),
            Text('Add option',
                style: AppTypography.titleSmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
