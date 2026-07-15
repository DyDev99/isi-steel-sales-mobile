import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/domain/entities/coach_action.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/domain/entities/coach_status.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/blocs/app_coach_bloc.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/widgets/assistant_overlay.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/widgets/floating_assistant_button.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';

/// Mounts the coach layer over the app shell.
///
/// Drop it as the top child of `MainShell`'s `Stack`. It provides the singleton
/// [AppCoachBloc], translates shell tab-switches into coach actions (so the
/// walkthrough advances on real navigation, never a bare "Next"), keeps anchors
/// on-screen via `ensureVisible`, and renders either the assistant overlay or
/// the paused floating button — or nothing when idle/completed.
class AppCoachHost extends StatefulWidget {
  const AppCoachHost({super.key});

  @override
  State<AppCoachHost> createState() => _AppCoachHostState();
}

class _AppCoachHostState extends State<AppCoachHost> {
  final AppCoachBloc _bloc = sl<AppCoachBloc>();
  final ShellTabController _tabs = sl<ShellTabController>();
  String? _shownStepId;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_onTabChanged);
    // Guest-first onboarding means the coach must NOT run for guests browsing
    // the shell. But a first-time user who actually signs in *should* get the
    // walkthrough — so start it only when authenticated. The bloc itself
    // no-ops if the tutorial was already completed or skipped, so returning
    // signed-in users won't see it again.
    //
    // A fresh sign-in rebuilds MainShell (login clears the stack to `main`),
    // re-running this initState with the session already set — so this check
    // fires at exactly the right moment for the first login.
    if (sl<SessionManager>().isAuthenticated) {
      _bloc.add(const CoachStarted());
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    super.dispose();
  }

  /// A tab switch is a real user action — report it so the matching step can
  /// advance. Programmatic returns to Home emit [CoachAction.openHome], which no
  /// step waits for, so they're harmless.
  void _onTabChanged() {
    const map = <int, CoachAction>{
      ShellTab.home: CoachAction.openHome,
      ShellTab.customers: CoachAction.openCustomers,
      ShellTab.myVisits: CoachAction.openMyVisits,
      ShellTab.leads: CoachAction.openMyLeads,
      ShellTab.orders: CoachAction.openOrders,
    };
    final action = map[_tabs.value];
    if (action != null) _bloc.add(CoachActionTriggered(action));
  }

  /// When a step becomes active, make sure its anchor is visible: bring the
  /// shell back to Home (all anchors live there) and scroll the target into
  /// view. Guarded so it runs once per step.
  void _onStepShown(AppCoachState state) {
    final step = state.currentStep;
    if (step == null || step.id == _shownStepId) return;
    _shownStepId = step.id;

    if (step.autoNavigateHome && _tabs.value != ShellTab.home) {
      // Let the user glimpse the tab they opened before easing back Home.
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) _tabs.goTo(ShellTab.home);
      });
    }

    final id = step.targetKeyId;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = CoachKeys.contextFor(id);
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.35,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return BlocProvider<AppCoachBloc>.value(
      value: _bloc,
      child: BlocConsumer<AppCoachBloc, AppCoachState>(
        listener: (_, state) => _onStepShown(state),
        // Only rebuild the heavy overlay when something it draws changes.
        buildWhen: (a, b) =>
            a.status != b.status ||
            a.index != b.index ||
            a.completedStepIds.length != b.completedStepIds.length,
        builder: (context, state) {
          // Always occupy the shell's full Stack; the child decides what shows.
          return Positioned.fill(child: _buildLayer(state, reduceMotion));
        },
      ),
    );
  }

  Widget _buildLayer(AppCoachState state, bool reduceMotion) {
    final Key key;
    final Widget child;

    if (state.status == CoachStatus.paused) {
      key = const ValueKey('coach-paused');
      child = FloatingAssistantButton(
        onResume: () => _bloc.add(const CoachResumed()),
      );
    } else {
      final step = state.currentStep;
      if (!state.isVisible || step == null) {
        key = const ValueKey('coach-empty');
        child = const SizedBox.shrink();
      } else {
        // Deliberately NOT keyed by step.id: AssistantOverlay must stay the
        // same State instance across steps so its own rect-sync and
        // step-to-step transition logic (see didUpdateWidget) keeps working.
        // Only the three *modes* below (paused / overlay / empty) cross-fade
        // against each other.
        key = const ValueKey('coach-overlay');
        child = AssistantOverlay(
          step: step,
          stepNumber: step.order,
          totalSteps: state.steps.length,
          progress: state.progress,
          reduceMotion: reduceMotion,
          onCta: () => _bloc.add(const CoachCtaPressed()),
          onSkip: () => _bloc.add(const CoachSkipped()),
          onClose: () => _bloc.add(const CoachPaused()),
        );
      }
    }

    return AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: key, child: child),
    );
  }
}