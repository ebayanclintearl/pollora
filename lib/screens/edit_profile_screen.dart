import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_icon_sizes.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../widgets/app_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameFocus    = FocusNode();
  final _handleFocus  = FocusNode();
  final _bioFocus     = FocusNode();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _bioCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: 'Clint');
    _handleCtrl = TextEditingController(text: '@clintearl');
    _bioCtrl    = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _bioCtrl.dispose();
    _nameFocus.dispose();
    _handleFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_nameCtrl.text.trim().isEmpty) {
      AppToast.show(context, 'Name cannot be empty', isError: true);
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _saving = false);
    AppToast.show(context, 'Profile updated',
        icon: Icons.check_circle_outline_rounded);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // ── Header ──────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  top + AppSpacing.screenTop,
                  AppSpacing.screenH,
                  AppSpacing.x3),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: AppIconSizes.touchTarget,
                      height: AppIconSizes.touchTarget,
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textSecondary,
                          size: AppIconSizes.control),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Edit Profile',
                        style: AppTypography.screenTitle),
                  ),
                  // Save button
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: AppIconSizes.touchTarget,
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppColors.textAccent),
                                ),
                              )
                            : Text(
                                'Save',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH, 8, AppSpacing.screenH, 40),
                children: [
                  // ── Avatar ──────────────────────
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF8B6914),
                          ),
                          child: const Center(
                            child: Text(
                              'C',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => AppToast.show(
                                context, 'Photo upload coming soon',
                                icon: Icons.photo_camera_outlined),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentPrimary,
                                border: Border.all(
                                    color: AppColors.background, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Fields ──────────────────────
                  _FieldLabel('Name'),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    hint: 'Your name',
                    maxLength: 40,
                    nextFocus: _handleFocus,
                  ),
                  const SizedBox(height: 20),

                  _FieldLabel('Handle'),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _handleCtrl,
                    focusNode: _handleFocus,
                    hint: '@yourhandle',
                    maxLength: 30,
                    nextFocus: _bioFocus,
                  ),
                  const SizedBox(height: 20),

                  _FieldLabel('Bio'),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _bioCtrl,
                    focusNode: _bioFocus,
                    hint: 'Write a short bio…',
                    maxLength: 150,
                    maxLines: 4,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTypography.labelSmall);
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final int maxLength;
  final int maxLines;
  final bool isLast;
  final FocusNode? nextFocus;

  const _Field({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.maxLength,
    this.maxLines = 1,
    this.isLast = false,
    this.nextFocus,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLength: maxLength,
      maxLines: maxLines,
      textInputAction:
          isLast ? TextInputAction.done : TextInputAction.next,
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      style: AppTypography.titleSmall
          .copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.titleSmall
            .copyWith(color: AppColors.textPlaceholder),
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide:
              BorderSide(color: AppColors.accentPrimaryBorder, width: 1.5),
        ),
      ),
      cursorColor: AppColors.accentPrimary,
    );
  }
}
