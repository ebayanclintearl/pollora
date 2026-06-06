import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
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

  bool _questionFilled = false;
  bool _canPublish = false;

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
    for (final c in _optionControllers) {
      c.dispose();
    }
    for (final f in _optionFocuses) {
      f.dispose();
    }
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
    for (final f in _optionFocuses) {
      f.unfocus();
    }
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

  void _onOptionSubmitted(int index) {
    if (index < _optionControllers.length - 1) {
      _optionFocuses[index + 1].requestFocus();
    } else {
      _dismissKeyboard();
    }
  }

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
            // Back button — only on step 2
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
            // Title
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
            // Step dots
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
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Options label
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
        // Options
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
          onPressed: _currentStep == 0
              ? (_questionFilled ? _goToStep2 : null)
              : (_canPublish ? () => HapticFeedback.mediumImpact() : null),
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
            child: Text(
              _currentStep == 0 ? 'Continue' : 'Publish Poll',
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
