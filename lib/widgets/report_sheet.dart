import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_typography.dart';
import '../providers/moderation_provider.dart';
import 'app_toast.dart';
import 'pressable.dart';

// The last entry opens a free-text field instead of submitting immediately.
const List<String> _reportReasons = [
  'Spam or misleading',
  'Harassment or bullying',
  'Hate speech or symbols',
  'Violence or threats',
  'Nudity or sexual content',
  'Something else',
];
const String _kOther = 'Something else';

/// Presents a reason picker, then files the report with the chosen reason.
/// [targetType] is 'poll' | 'comment' | 'user'; [targetLabel] is the noun
/// shown in the title (e.g. 'poll').
Future<void> showReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetLabel,
  required String targetId,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ReportSheet(
      targetType: targetType,
      targetLabel: targetLabel,
      targetId: targetId,
      hostContext: context,
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  final String targetType;
  final String targetLabel;
  final String targetId;
  final BuildContext hostContext;

  const _ReportSheet({
    required this.targetType,
    required this.targetLabel,
    required this.targetId,
    required this.hostContext,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  bool _customMode = false;
  bool _submitting = false;
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String reason) async {
    if (_submitting) return;
    _submitting = true;
    HapticFeedback.selectionClick();
    Navigator.pop(context);
    final ok = await reportContent(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: reason,
    );
    if (widget.hostContext.mounted) {
      AppToast.show(
        widget.hostContext,
        ok
            ? 'Report received — we\'ll review within 24 hours'
            : 'Couldn\'t submit report. Try again.',
        isError: !ok,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        // When the keyboard is up it covers the home indicator, so drop the
        // safe-area padding and sit snug above the keyboard instead.
        padding: EdgeInsets.only(bottom: keyboard > 0 ? 12 : bottom + 8),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _customMode ? _buildCustom() : _buildReasons(),
        ),
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.borderSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  // ── Reason list ──────────────────────────────
  Widget _buildReasons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text('Report ${widget.targetLabel}',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Why are you reporting this? Your report is anonymous.',
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ),
        ..._reportReasons.asMap().entries.map((entry) {
          final isLast = entry.key == _reportReasons.length - 1;
          final reason = entry.value;
          final isOther = reason == _kOther;
          return Column(
            children: [
              Pressable(
                pressedScale: 0.99,
                onTap: () {
                  if (isOther) {
                    setState(() => _customMode = true);
                  } else {
                    _submit(reason);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                          child:
                              Text(reason, style: AppTypography.titleSmall)),
                      if (isOther)
                        const Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.only(left: 20),
                  color: AppColors.borderSubtle,
                ),
            ],
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Free-text reason ─────────────────────────
  Widget _buildCustom() {
    final text = _customCtrl.text.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        // Back + title
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
          child: Row(
            children: [
              Pressable(
                pressedScale: 0.85,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _customMode = false);
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
              ),
              Text('Tell us more',
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            controller: _customCtrl,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.titleSmall
                .copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Describe the problem…',
              hintStyle: AppTypography.titleSmall
                  .copyWith(color: AppColors.textPlaceholder),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              counterStyle:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 11),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                borderSide:
                    const BorderSide(color: AppColors.accentPrimary, width: 1.5),
              ),
            ),
            cursorColor: AppColors.accentPrimary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: Pressable(
              pressedScale: 0.98,
              onTap: text.isEmpty ? null : () => _submit(text),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: text.isEmpty
                      ? AppColors.surfaceElevated
                      : AppColors.textDestructive,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Text(
                  'Submit report',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        text.isEmpty ? AppColors.textTertiary : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
