import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/domain/entities/coach_action.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/domain/entities/coach_status.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/blocs/app_coach_bloc.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_anchor_registry.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/widgets/assistant_overlay.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';

/// Mounts the coach layer over the app shell.
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
    if (sl<SessionManager>().isAuthenticated) {
      _bloc.add(const CoachStarted());
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    super.dispose();
  }

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

  void _onStepShown(AppCoachState state) {
    final step = state.currentStep;
    if (step == null || step.id == _shownStepId) return;
    _shownStepId = step.id;

    if (step.autoNavigateHome && _tabs.value != ShellTab.home) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) _tabs.goTo(ShellTab.home);
      });
    }

    final id = step.targetKeyId;
    if (id == null) return;
    final registry = CoachAnchorScope.maybeOf(context);
    if (registry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = registry.contextFor(id);
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
        buildWhen: (a, b) =>
            a.status != b.status ||
            a.index != b.index ||
            a.completedStepIds.length != b.completedStepIds.length ||
            a.isVisible != b.isVisible,
        builder: (context, state) {
          // Immediately unmount layer if completed or invisible (and not paused)
          if (state.status == CoachStatus.completed ||
              (!state.isVisible && state.status != CoachStatus.paused)) {
            return const SizedBox.shrink();
          }

          return _buildLayer(state, reduceMotion);
        },
      ),
    );
  }

  Widget _buildLayer(AppCoachState state, bool reduceMotion) {
    final Key key;
    final Widget child;

    if (state.status == CoachStatus.paused) {
      key = const ValueKey('coach-paused');
      child = Align(
        alignment: Alignment.bottomRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
            child: GestureDetector(
              onTap: () => _bloc.add(const CoachResumed()),
              child: SizedBox(
                width: 120,
                height: 120,
                child: Lottie.asset(
                  "assets/lotties/Live chatbot.json",
                  fit: BoxFit.contain,
                  animate: !reduceMotion,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      final step = state.currentStep;
      if (!state.isVisible || step == null) {
        key = const ValueKey('coach-empty');
        child = const SizedBox.shrink();
      } else {
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
