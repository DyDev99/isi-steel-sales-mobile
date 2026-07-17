import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_state.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_board_section.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_pipeline_actions.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_search_bar.dart';

/// The lead pipeline, grouped into one board section per [PipelineStage].
///
/// **Presentation-layer redesign only.** Every bloc event, sheet, navigation
/// path and permission check is the one that was already here — that behaviour
/// now lives in [LeadPipelineActions]; what changed is the axis.
///
/// The board used to be three vertical columns that scrolled sideways as a
/// unit, so a rep had to scroll horizontally to discover the Won column existed
/// at all, and no stage's total was visible until they found it. Now the page
/// scrolls vertically — every stage header (count + total) is reachable by a
/// normal downward scroll — and each stage's cards scroll horizontally within
/// their own section.
///
/// **Known regression:** the old columns supported drag-and-drop between stages
/// (`PipelineColumn` → `LeadMoved` / `LeadReordered`). Horizontal strips nested
/// in a vertical scroll cannot carry that gesture without conflicting drag
/// axes, so moving a lead is now the card's "Move stage" action — same
/// `LeadMoved` event, same validation. `LeadReordered` consequently has no UI
/// trigger in this layout; the event and its bloc handler are untouched.
class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key, this.initialStage = PipelineStage.leads});

  /// Which stage to bring into view first. Kept for API compatibility: the
  /// customer detail screen opens this screen at Opportunities.
  final PipelineStage initialStage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: BlocConsumer<PipelineBloc, PipelineState>(
          listenWhen: (prev, curr) =>
              curr is PipelineLoaded && curr.blockedMoveMessage != null,
          listener: (context, state) {
            if (state is PipelineLoaded && state.blockedMoveMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.blockedMoveMessage!)),
              );
            }
          },
          builder: (context, state) => switch (state) {
            PipelineLoaded() =>
              _BoardBody(state: state, initialStage: initialStage),
            PipelineError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context
                    .read<PipelineBloc>()
                    .add(const PipelineLoadRequested()),
              ),
            _ => Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.secondary),
              ),
          },
        ),
      ),
    );
  }
}

class _BoardBody extends StatefulWidget {
  const _BoardBody({required this.state, required this.initialStage});

  final PipelineLoaded state;
  final PipelineStage initialStage;

  @override
  State<_BoardBody> createState() => _BoardBodyState();
}

class _BoardBodyState extends State<_BoardBody> {
  final ScrollController _pageController = ScrollController();

  late final LeadPipelineActions _actions =
      LeadPipelineActions(isAdmin: sl<SessionManager>().can(UserRole.admin));

  /// One-time scroll so [PipelineScreen.initialStage] is on screen at first
  /// paint, preserving the old board's auto-scroll behaviour on the new axis.
  bool _initialScrollDone = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Stages the filter says are visible, in pipeline order. Honouring
  /// `visibleStages` is what lets the existing "filter by stage" control double
  /// as a single-board view.
  List<PipelineStage> get _visibleStages => PipelineStage.values
      .where(widget.state.filter.visibleStages.contains)
      .toList();

  void _openFilter(BuildContext context) => _actions.openFilterSheet(
        context,
        filter: widget.state.filter,
        allLeads: widget.state.allLeads,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final stages = _visibleStages;
    final hasFilters = !widget.state.filter.isEmpty;

    _scheduleInitialScroll(stages);

    return Column(
      children: [
        // Search · filter · add — the screen's only top bar. Sorting is applied
        // from inside the filter sheet (it dispatches SortChanged on apply), so
        // removing the separate header did not remove the capability.
        LeadSearchBar(
          initialValue: widget.state.filter.search,
          hasActiveFilters: hasFilters,
          onChanged: (q) => context.read<PipelineBloc>().add(SearchChanged(q)),
          onFilterTap: () => _openFilter(context),
          onAddLead: () => _actions.addLead(context),
        ),
        Expanded(
          child: RefreshIndicator(
            color: scheme.secondary,
            backgroundColor: colors.surfaceSoft,
            onRefresh: () async =>
                context.read<PipelineBloc>().add(const PipelineLoadRequested()),
            child: ListView.separated(
              controller: _pageController,
              // Keeps pull-to-refresh working even when the boards don't fill
              // the viewport.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: stages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final stage = stages[i];
                return LeadBoardSection(
                  key: ValueKey(stage),
                  stage: stage,
                  leads: widget.state.columns[stage] ?? const [],
                  isAdmin: _actions.isAdmin,
                  onCardTap: (lead) => _actions.openDetail(context, lead),
                  onCardAction: (lead, action) =>
                      _actions.handle(context, lead, action),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Brings [PipelineScreen.initialStage] into view once, after first layout.
  ///
  /// Uses an offset estimate rather than a measurement: sections have adaptive
  /// height, and being approximately right on one frame beats blocking paint to
  /// measure. Clamped to the real extent so it can never overscroll.
  void _scheduleInitialScroll(List<PipelineStage> stages) {
    if (_initialScrollDone) return;
    final index = stages.indexOf(widget.initialStage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialScrollDone) return;
      _initialScrollDone = true;
      if (index <= 0 || !_pageController.hasClients) return;
      const approxSectionHeight = 200.0;
      _pageController.jumpTo(
        (index * approxSectionHeight)
            .clamp(0.0, _pageController.position.maxScrollExtent),
      );
    });
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.textSecondary, size: 40),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text('Try again',
                style: TextStyle(
                    color: scheme.secondary, fontWeight: FontWeight.w700)),
          ),
          SizedBox.shrink()
        ],
      ),
    );
  }
}
