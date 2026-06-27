import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../core/supabase_client.dart' as supa;
import '../app_spacing.dart';
import '../app_typography.dart';
import '../services/auth_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/pressable.dart';

// ─────────────────────────────────────────────
// Show helper — call this instead of constructing directly.
// ─────────────────────────────────────────────
Future<void> showAuthSheet(BuildContext context, {bool allowCancel = false}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: allowCancel,
    enableDrag: allowCancel,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => AuthSheet(allowCancel: allowCancel),
  );
}

// ─────────────────────────────────────────────
enum _AuthMode { options, emailSignIn, emailSignUp }

// ─────────────────────────────────────────────
class AuthSheet extends StatefulWidget {
  final bool allowCancel;
  const AuthSheet({super.key, this.allowCancel = false});

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  _AuthMode _mode = _AuthMode.options;
  bool _loading = false;
  // Which social provider is mid sign-in, so only that button spins.
  // 'apple' | 'google' | null.
  String? _busyProvider;
  // Sign-in failure shown inline (a bottom SnackBar would hide behind the sheet).
  String? _authError;

  // Email form fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _passwordVisible = false;

  // Inline field errors — null means no error shown yet
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  static final _emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    // Clear per-field error as the user types or taps into the field
    _nameCtrl.addListener(() {
      if (_nameError != null) setState(() => _nameError = null);
    });
    _emailCtrl.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
    });
    _passwordCtrl.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus && _nameError != null)
        setState(() => _nameError = null);
    });
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus && _emailError != null)
        setState(() => _emailError = null);
    });
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus && _passwordError != null)
        setState(() => _passwordError = null);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────
  bool _validateSignIn() {
    String? emailErr, passErr;
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (email.isEmpty) {
      emailErr = 'Email is required';
    } else if (!_emailRegex.hasMatch(email)) {
      emailErr = 'Enter a valid email address';
    }
    if (pass.isEmpty) {
      passErr = 'Password is required';
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });
    if (emailErr != null) {
      _emailFocus.requestFocus();
      return false;
    }
    if (passErr != null) {
      _passwordFocus.requestFocus();
      return false;
    }
    return true;
  }

  bool _validateSignUp() {
    String? nameErr, emailErr, passErr;
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (name.isEmpty) {
      nameErr = 'Name is required';
    } else if (name.length < 2) {
      nameErr = 'Name must be at least 2 characters';
    }
    if (email.isEmpty) {
      emailErr = 'Email is required';
    } else if (!_emailRegex.hasMatch(email)) {
      emailErr = 'Enter a valid email address';
    }
    if (pass.isEmpty) {
      passErr = 'Password is required';
    } else if (pass.length < 6) {
      passErr = 'Password must be at least 6 characters';
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
    });
    if (nameErr != null) {
      _nameFocus.requestFocus();
      return false;
    }
    if (emailErr != null) {
      _emailFocus.requestFocus();
      return false;
    }
    if (passErr != null) {
      _passwordFocus.requestFocus();
      return false;
    }
    return true;
  }

  void _clearErrors() => setState(() {
        _nameError = _emailError = _passwordError = null;
        _authError = null;
      });

  // Inline error banner — visible inside the sheet (a bottom SnackBar would
  // render underneath the modal and never be seen).
  Widget _errorBanner() {
    if (_authError == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textDestructive.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border:
            Border.all(color: AppColors.textDestructive.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.textDestructive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _authError!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textDestructive,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────
  Future<void> _run(Future<void> Function() action, {String? provider}) async {
    if (_loading) return; // ignore taps while another sign-in is in flight
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _busyProvider = provider;
      _authError = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _authError = e.message);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      // User-initiated cancel isn't an error worth surfacing.
      if (mounted && !msg.toLowerCase().contains('cancel')) {
        setState(() => _authError = msg);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _busyProvider = null;
        });
      }
    }
  }

  Future<void> _apple() => _run(AuthService.signInWithApple, provider: 'apple');
  Future<void> _google() =>
      _run(AuthService.signInWithGoogle, provider: 'google');

  Future<void> _emailSignIn() async {
    if (!_validateSignIn()) return;
    await _run(() => AuthService.signInWithEmail(
        _emailCtrl.text.trim(), _passwordCtrl.text));
  }

  Future<void> _emailSignUp() async {
    if (!_validateSignUp()) return;
    await _run(() => AuthService.signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim()));
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Enter your email address first');
      _emailFocus.requestFocus();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loading = true);
    try {
      await supa.supabase.auth.resetPasswordForEmail(email);
      if (mounted) {
        AppToast.show(context, 'Password reset email sent',
            icon: Icons.mark_email_read_outlined);
      }
    } on AuthException catch (e) {
      if (mounted) AppToast.show(context, e.message, isError: true);
    } catch (_) {
      if (mounted)
        AppToast.show(context, 'Failed to send reset email', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final safeBottom = mq.padding.bottom;
    final keyboard = mq.viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              AppSpacing.screenH, 12, AppSpacing.screenH, safeBottom + 24),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _mode == _AuthMode.options
                ? _buildOptions()
                : _buildEmailForm(),
          ),
        ),
      ),
    );
  }

  // ── Options view ─────────────────────────────
  Widget _buildOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _handle(),
        if (widget.allowCancel) ...[
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 28),
        // Logo + wordmark
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Pollora',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Vote on things that matter',
          style:
              TextStyle(fontSize: 14, color: AppColors.textTertiary, height: 1),
        ),
        const SizedBox(height: 36),

        _errorBanner(),

        // Apple
        _SocialButton(
          label: 'Continue with Apple',
          icon: const Icon(Icons.apple_rounded, color: Colors.white, size: 20),
          backgroundColor: const Color(0xFF000000),
          textColor: Colors.white,
          loading: _busyProvider == 'apple',
          onTap: _apple,
        ),
        const SizedBox(height: 12),

        // Google
        _SocialButton(
          label: 'Continue with Google',
          icon: _GoogleIcon(),
          backgroundColor: const Color(0xFF2A2A2A),
          textColor: AppColors.textPrimary,
          loading: _busyProvider == 'google',
          onTap: _google,
        ),
        const SizedBox(height: 20),

        // Divider
        Row(children: [
          const Expanded(
              child: Divider(color: Color(0xFF2A2A2A), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textTertiary)),
          ),
          const Expanded(
              child: Divider(color: Color(0xFF2A2A2A), thickness: 1)),
        ]),
        const SizedBox(height: 20),

        // Email
        _SocialButton(
          label: 'Continue with Email',
          icon: const Icon(Icons.mail_outline_rounded,
              color: AppColors.textSecondary, size: 18),
          backgroundColor: Colors.transparent,
          textColor: AppColors.textSecondary,
          loading: false,
          border: true,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _mode = _AuthMode.emailSignIn);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _emailFocus.requestFocus();
            });
          },
        ),
        const SizedBox(height: 24),

        // ToS
        Text(
          'By continuing you agree to our Terms of Service\nand Privacy Policy.',
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Email form view ───────────────────────────
  Widget _buildEmailForm() {
    final isSignUp = _mode == _AuthMode.emailSignUp;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        const SizedBox(height: 16),

        // Back + title
        Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _mode = _AuthMode.options);
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary, size: 18),
              ),
            ),
            const SizedBox(width: 4),
            Text(isSignUp ? 'Create Account' : 'Sign In',
                style: AppTypography.screenTitle),
          ],
        ),
        const SizedBox(height: 24),

        // Name field — sign up only
        if (isSignUp) ...[
          _EmailField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            hint: 'Your name',
            nextFocus: _emailFocus,
            icon: Icons.person_outline_rounded,
            error: _nameError,
          ),
          const SizedBox(height: 12),
        ],

        _EmailField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          hint: 'Email address',
          nextFocus: _passwordFocus,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.mail_outline_rounded,
          error: _emailError,
        ),
        const SizedBox(height: 12),

        _EmailField(
          controller: _passwordCtrl,
          focusNode: _passwordFocus,
          hint: 'Password',
          obscure: !_passwordVisible,
          icon: Icons.lock_outline_rounded,
          isLast: true,
          error: _passwordError,
          suffix: GestureDetector(
            onTap: () => setState(() => _passwordVisible = !_passwordVisible),
            behavior: HitTestBehavior.opaque,
            child: Icon(
              _passwordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ),
          onSubmitted: isSignUp ? _emailSignUp : _emailSignIn,
        ),

        // Forgot password — sign in only
        if (!isSignUp) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _loading ? null : _forgotPassword,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),

        _errorBanner(),

        // Primary action button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed:
                _loading ? null : (isSignUp ? _emailSignUp : _emailSignIn),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              disabledBackgroundColor: AppColors.surfaceElevated,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text(
                    isSignUp ? 'Create Account' : 'Sign In',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Toggle sign in ↔ sign up
        Center(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _nameCtrl.clear();
              _emailCtrl.clear();
              _passwordCtrl.clear();
              _clearErrors();
              setState(() => _mode =
                  isSignUp ? _AuthMode.emailSignIn : _AuthMode.emailSignUp);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) {
                  (isSignUp ? _emailFocus : _nameFocus).requestFocus();
                }
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                        text: isSignUp
                            ? 'Already have an account? '
                            : "Don't have an account? "),
                    TextSpan(
                      text: isSignUp ? 'Sign In' : 'Sign Up',
                      style: const TextStyle(
                        color: AppColors.textAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _handle() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      );
}

// ─────────────────────────────────────────────
// Social button
// ─────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;
  final bool loading;
  final bool border;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.loading,
    required this.onTap,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? null : onTap,
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: border ? Border.all(color: const Color(0xFF3A3A3A)) : null,
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textSecondary)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      )),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Google "G" icon — official logo on a white tile (brand-compliant)
// ─────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/google_logo.png',
        width: 22,
        height: 22,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Email text field
// ─────────────────────────────────────────────
class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final FocusNode? nextFocus;
  final TextInputType keyboardType;
  final IconData icon;
  final bool obscure;
  final bool isLast;
  final Widget? suffix;
  final VoidCallback? onSubmitted;
  final String? error;

  const _EmailField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.nextFocus,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.isLast = false,
    this.suffix,
    this.onSubmitted,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscure,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onSubmitted: (_) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              onSubmitted?.call();
            }
          },
          style:
              AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.titleSmall
                .copyWith(color: AppColors.textPlaceholder),
            prefixIcon: Icon(icon,
                size: 18,
                color: hasError
                    ? AppColors.textDestructive
                    : AppColors.textTertiary),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12), child: suffix)
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 44),
            filled: true,
            fillColor: hasError
                ? AppColors.textDestructive.withValues(alpha: 0.08)
                : AppColors.surfaceElevated,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: hasError
                  ? const BorderSide(
                      color: AppColors.textDestructive, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: hasError
                  ? const BorderSide(
                      color: AppColors.textDestructive, width: 1.5)
                  : const BorderSide(
                      color: AppColors.accentPrimaryBorder, width: 1.5),
            ),
          ),
          cursorColor: AppColors.accentPrimary,
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 13, color: AppColors.textDestructive),
              const SizedBox(width: 5),
              Text(
                error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDestructive,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
