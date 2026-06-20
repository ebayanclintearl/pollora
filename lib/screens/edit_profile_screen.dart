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
import '../providers/auth_provider.dart' as auth_prov;
import '../providers/users_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameFocus = FocusNode();
  final _handleFocus = FocusNode();
  final _bioFocus = FocusNode();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _bioCtrl;

  bool _saving = false;
  bool _initialized = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _handleCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
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

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // close the source sheet
    final xfile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (xfile == null) return;
    setState(() => _pickedImage = File(xfile.path));
  }

  void _showImageSourceSheet() {
    final bottom = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceModal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A4A),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _SourceRow(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Library',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const Divider(height: 1, color: Color(0xFF303030)),
            _SourceRow(
              icon: Icons.camera_alt_outlined,
              label: 'Take Photo',
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_nameCtrl.text.trim().isEmpty) {
      AppToast.show(context, 'Name cannot be empty', isError: true);
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      await ref.read(currentProfileProvider.notifier).saveProfile(
            name: _nameCtrl.text.trim(),
            handle: _handleCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            avatarFile: _pickedImage,
          );
      if (!mounted) return;
      AppToast.show(context, 'Profile updated',
          icon: Icons.check_circle_outline_rounded);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('5 MB')
          ? 'Image must be under 5 MB'
          : e.toString().contains('handle_taken')
              ? 'That handle is already taken'
              : 'Failed to save — please try again';
      AppToast.show(context, msg, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final user = ref.watch(currentUserProvider);
    final authUser = ref.watch(auth_prov.currentUserProvider);
    final userId = authUser?.id ?? user?.id ?? '';

    // Pre-fill once loaded (won't overwrite in-progress edits).
    if (!_initialized && user != null) {
      _nameCtrl.text = user.name;
      _handleCtrl.text = user.handle;
      _bioCtrl.text = user.bio ?? '';
      _initialized = true;
    }

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
                  AppSpacing.screenH, top + 8, AppSpacing.screenH, 2),
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
                        ProfileAvatar(
                          userId: userId,
                          displayName: user?.name,
                          avatarUrl: user?.avatarUrl,
                          localFile: _pickedImage,
                          radius: 44,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceSheet,
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

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                )),
          ],
        ),
      ),
    );
  }
}
