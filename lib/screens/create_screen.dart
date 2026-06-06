import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
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

  final _questionController = TextEditingController();
  final _questionFocus = FocusNode();

  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<FocusNode> _optionFocuses = [
    FocusNode(),
    FocusNode(),
  ];

  bool _canPublish = false;

  @override
  void initState() {
    super.initState();
    _questionController.addListener(_updatePublishState);
    for (final c in _optionControllers) {
      c.addListener(_updatePublishState);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _questionFocus.dispose();
    for (final c in _optionControllers) c.dispose();
    for (final f in _optionFocuses) f.dispose();
    super.dispose();
  }

  void _updatePublishState() {
    final q = _questionController.text.trim().isNotEmpty;
    final opts = _optionControllers.where((c) => c.text.trim().isNotEmpty).length;
    final can = q && opts >= 2;
    if (can != _canPublish) setState(() => _canPublish = can);
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
      // Move to the next existing option
      _optionFocuses[index + 1].requestFocus();
    } else if (_optionControllers.length < _maxOptions) {
      // Auto-add a new option and focus it
      _addOption();
    } else {
      // Max reached — dismiss keyboard
      _optionFocuses[index].unfocus();
    }
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
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, AppSpacing.screenTop,
                  AppSpacing.screenH, AppSpacing.screenTop),
              child: const SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Create Poll', style: AppTypography.screenTitle),
                ),
              ),
            ),

            // ── Question input ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: TextField(
                controller: _questionController,
                focusNode: _questionFocus,
                minLines: 1,
                maxLines: 4,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  if (_optionFocuses.isNotEmpty) {
                    _optionFocuses[0].requestFocus();
                  }
                },
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                cursorColor: AppColors.accentPrimary,
              ),
            ),

            const SizedBox(height: 24),

            // ── Options label ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Row(
                children: [
                  const Text('OPTIONS', style: AppTypography.labelSmall),
                  const Spacer(),
                  Text(
                    '${_optionControllers.length} / $_maxOptions',
                    style: AppTypography.labelSmall.copyWith(letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Options list ──
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH, 0, AppSpacing.screenH, 24),
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

      // ── Publish button ──
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.borderDefault, width: 0.5),
            ),
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _canPublish
                  ? () => HapticFeedback.mediumImpact()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                disabledBackgroundColor: AppColors.surfaceElevated,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.textTertiary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Text(
                'Publish Poll',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        canAddMore: _optionControllers.length < _maxOptions,
        onRemove: () => _removeOption(i),
        onSubmitted: () => _onOptionSubmitted(i),
      ));
    }
    return rows;
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
  final bool canAddMore;
  final VoidCallback onRemove;
  final VoidCallback onSubmitted;

  const _OptionRow({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.canRemove,
    required this.isLast,
    required this.canAddMore,
    required this.onRemove,
    required this.onSubmitted,
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
            borderRadius: BorderRadius.circular(AppRadius.sm),
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
        const SizedBox(width: 8),

        // Input — theme provides fill, 12dp radius, focused accent border
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 1,
            maxLength: 40,
            textInputAction: isLast && !canAddMore
                ? TextInputAction.done
                : TextInputAction.next,
            onSubmitted: (_) => onSubmitted(),
            style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: index < 2
                  ? 'Option ${index + 1}'
                  : 'Option ${index + 1} · optional',
              hintStyle: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPlaceholder),
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            cursorColor: AppColors.accentPrimary,
          ),
        ),

        // Remove / spacer
        if (canRemove)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onRemove();
            },
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 52,
              child: Icon(Icons.close_rounded, size: 18,
                  color: AppColors.textTertiary),
            ),
          )
        else
          const SizedBox(width: 44),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
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
                  color: AppColors.textTertiary, size: 16),
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
