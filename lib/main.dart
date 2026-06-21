import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_sheet.dart';
import 'screens/splash_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/create_screen.dart';
import 'screens/my_polls_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/poll_detail_screen.dart';
import 'screens/follow_list_screen.dart';
import 'widgets/pressable.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: PolloraApp()));
}

class PolloraApp extends StatelessWidget {
  const PolloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pollora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AppEntry(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/user-profile':
            final user = settings.arguments as AppUser;
            return MaterialPageRoute(
                builder: (_) => UserProfileScreen(user: user));
          case '/poll-detail':
            final pollId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => PollDetailScreen(pollId: pollId));
          case '/follow-list':
            final mode = settings.arguments as FollowListMode;
            return MaterialPageRoute(
                builder: (_) => FollowListScreen(mode: mode));
          default:
            return null;
        }
      },
    );
  }
}

// ─────────────────────────────────────────────
// App entry: Splash → Auth gate → Shell
// ─────────────────────────────────────────────
class _AppEntry extends ConsumerStatefulWidget {
  const _AppEntry();
  @override
  ConsumerState<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<_AppEntry> {
  bool _splashDone = false;
  bool _sheetShown = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () => setState(() => _splashDone = true),
      );
    }

    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      // Show the dark background and open the auth sheet once.
      if (!_sheetShown) {
        _sheetShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await showAuthSheet(context);
          // Sheet dismissed means auth succeeded — Riverpod will
          // rebuild this widget with isAuthenticated == true.
          if (mounted) setState(() => _sheetShown = false);
        });
      }
      return const _UnauthBackground();
    }

    // Reset so the sheet can re-appear after sign-out.
    _sheetShown = false;
    return const MainShell();
  }
}

/// Feed visible behind the auth sheet — blurred + darkened.
class _UnauthBackground extends StatelessWidget {
  const _UnauthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // App content rendered but fully non-interactive.
        const IgnorePointer(child: MainShell()),

        // Blur layer.
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Incremented when user taps the Feed tab while already on it.
  final _feedReselectNotifier = ValueNotifier<int>(0);
  // Incremented after a poll is published — feed switches to Latest + scrolls top.
  final _feedPublishedNotifier = ValueNotifier<int>(0);

  // Tracks whether Create screen has unsaved content.
  final _createHasContent = ValueNotifier<bool>(false);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      FeedScreen(
        reselectNotifier: _feedReselectNotifier,
        publishedNotifier: _feedPublishedNotifier,
      ),
      CreateScreen(
        onPublished: _onPollPublished,
        hasContentNotifier: _createHasContent,
      ),
      const MyPollsScreen(),
    ];
  }

  @override
  void dispose() {
    _feedReselectNotifier.dispose();
    _feedPublishedNotifier.dispose();
    _createHasContent.dispose();
    super.dispose();
  }

  void _onPollPublished() {
    _createHasContent.value = false;
    setState(() => _currentIndex = 0);
    _feedPublishedNotifier.value++;
  }

  void _onNavTap(int i) {
    if (i == _currentIndex) {
      // Re-tap on Feed → scroll to top.
      if (i == 0) {
        HapticFeedback.selectionClick();
        _feedReselectNotifier.value++;
      }
      return;
    }
    // Leaving Create with unsaved content → confirm discard.
    if (_currentIndex == 1 && _createHasContent.value) {
      _showDiscardDialog(i);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = i);
  }

  void _showDiscardDialog(int targetIndex) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Discard draft?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Your poll draft will be lost.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep editing',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createHasContent.value = false;
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = targetIndex);
            },
            child: const Text('Discard',
                style: TextStyle(color: Color(0xFFFF5C7A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _PolloraBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

class _PolloraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PolloraBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        border: Border(
          top: BorderSide(
              color: AppColors.borderDefault.withValues(alpha: 0.6),
              width: 0.5),
        ),
      ),
      child: SizedBox(
        height: 58 + bottom,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Row(
            children: [
              _NavTab(
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Feed',
                onTap: onTap,
              ),
              _CreateFAB(onTap: () => onTap(1), isActive: currentIndex == 1),
              _NavTab(
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatefulWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavTab({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  late final Animation<double> _popScale;

  bool get _isActive => widget.index == widget.currentIndex;

  @override
  void initState() {
    super.initState();
    // One-shot "pop" the icon does the moment this tab becomes active.
    _pop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 58,
      ),
    ]).animate(_pop);
  }

  @override
  void didUpdateWidget(covariant _NavTab old) {
    super.didUpdateWidget(old);
    final wasActive = old.index == old.currentIndex;
    if (!wasActive && _isActive) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive;

    return Expanded(
      child: Semantics(
        label: widget.label,
        selected: isActive,
        button: true,
        child: Pressable(
          onTap: () => widget.onTap(widget.index),
          pressedScale: 0.86,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _popScale,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: Tween(begin: 0.7, end: 1.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isActive ? widget.activeIcon : widget.icon,
                    key: ValueKey(isActive),
                    size: 24,
                    color:
                        isActive ? AppColors.navActive : AppColors.navInactive,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.navActive : AppColors.navInactive,
                  height: 1,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateFAB extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;

  const _CreateFAB({required this.onTap, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Create poll',
      button: true,
      selected: isActive,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.84,
        child: SizedBox(
          width: 72,
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              scale: isActive ? 1.08 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  shape: BoxShape.circle,
                  // Soft accent glow blooms when Create is the active tab.
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPrimary
                          .withValues(alpha: isActive ? 0.55 : 0.0),
                      blurRadius: isActive ? 18 : 0,
                      spreadRadius: isActive ? 1 : 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
