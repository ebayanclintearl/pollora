import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import '../services/auth_service.dart';
import '../widgets/app_toast.dart';

// ─────────────────────────────────────────────
// Show helper — call this instead of constructing directly.
// ─────────────────────────────────────────────
Future<void> showAuthSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => const AuthSheet(),
  );
}

// ─────────────────────────────────────────────
enum _AuthMode { options, emailSignIn, emailSignUp }

// ─────────────────────────────────────────────
class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key});

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  _AuthMode _mode = _AuthMode.options;
  bool _loading = false;

  // Email form fields
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _passwordFocus = FocusNode();
  bool _passwordVisible = false;

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

  // ── Actions ──────────────────────────────────
  Future<void> _run(Future<void> Function() action) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loading = true);
    try {
      await action();
      // Pop the sheet — _AppEntry rebuilds with isAuthenticated == true.
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) AppToast.show(context, e.message, isError: true);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        AppToast.show(context, msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apple()  => _run(AuthService.signInWithApple);
  Future<void> _google() => _run(AuthService.signInWithGoogle);

  Future<void> _emailSignIn() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      AppToast.show(context, 'Enter email and password', isError: true);
      return;
    }
    await _run(() => AuthService.signInWithEmail(email, password));
  }

  Future<void> _emailSignUp() async {
    final name     = _nameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      AppToast.show(context, 'Fill in all fields', isError: true);
      return;
    }
    if (password.length < 6) {
      AppToast.show(context, 'Password must be at least 6 characters', isError: true);
      return;
    }
    await _run(() => AuthService.signUpWithEmail(
          email: email, password: password, name: name));
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            AppSpacing.screenH, 12, AppSpacing.screenH, bottom + 24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: _mode == _AuthMode.options
              ? _buildOptions()
              : _buildEmailForm(),
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
          style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
              height: 1),
        ),
        const SizedBox(height: 36),

        // Apple
        _SocialButton(
          label: 'Continue with Apple',
          icon: const Icon(Icons.apple_rounded,
              color: Colors.white, size: 20),
          backgroundColor: const Color(0xFF000000),
          textColor: Colors.white,
          loading: _loading,
          onTap: _apple,
        ),
        const SizedBox(height: 12),

        // Google
        _SocialButton(
          label: 'Continue with Google',
          icon: _GoogleIcon(),
          backgroundColor: const Color(0xFF2A2A2A),
          textColor: AppColors.textPrimary,
          loading: _loading,
          onTap: _google,
        ),
        const SizedBox(height: 20),

        // Divider
        Row(children: [
          const Expanded(child: Divider(color: Color(0xFF2A2A2A), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textTertiary)),
          ),
          const Expanded(child: Divider(color: Color(0xFF2A2A2A), thickness: 1)),
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
        ),
        const SizedBox(height: 12),

        _EmailField(
          controller: _passwordCtrl,
          focusNode: _passwordFocus,
          hint: 'Password',
          obscure: !_passwordVisible,
          icon: Icons.lock_outline_rounded,
          isLast: true,
          suffix: GestureDetector(
            onTap: () =>
                setState(() => _passwordVisible = !_passwordVisible),
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
        const SizedBox(height: 24),

        // Primary action button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading
                ? null
                : (isSignUp ? _emailSignUp : _emailSignIn),
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
              setState(() => _mode = isSignUp
                  ? _AuthMode.emailSignIn
                  : _AuthMode.emailSignUp);
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
    return GestureDetector(
      onTap: loading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: border
              ? Border.all(color: const Color(0xFF3A3A3A))
              : null,
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.textSecondary)),
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
// Google "G" icon (painted, no image asset needed)
// ─────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    void arc(double start, double sweep, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 0.72), start, sweep, false, paint);
    }

    // Blue
    arc(-0.26, 1.8, const Color(0xFF4285F4));
    // Green
    arc(1.54, 0.73, const Color(0xFF34A853));
    // Yellow
    arc(2.27, 0.52, const Color(0xFFFBBC05));
    // Red
    arc(-1.05, 0.79, const Color(0xFFEA4335));

    // Right arm of G
    final paint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r * 0.72, c.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
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
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscure,
      textInputAction:
          isLast ? TextInputAction.done : TextInputAction.next,
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          onSubmitted?.call();
        }
      },
      style: AppTypography.titleSmall
          .copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.titleSmall
            .copyWith(color: AppColors.textPlaceholder),
        prefixIcon: Icon(icon,
            size: 18, color: AppColors.textTertiary),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 44),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide:
              const BorderSide(color: AppColors.accentPrimaryBorder, width: 1.5),
        ),
      ),
      cursorColor: AppColors.accentPrimary,
    );
  }
}
