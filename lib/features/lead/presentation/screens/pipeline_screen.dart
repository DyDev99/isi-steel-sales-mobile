import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/storage/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/aurora_background.dart';
// Add this line back right here:
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/lead_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_state.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/lead_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_card.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_form_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/move_stage_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/pipeline_column.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/pipeline_filter_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/send_to_hq_sheet.dart';

class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key, this.initialStage = PipelineStage.leads});
  final PipelineStage initialStage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: BlocConsumer<PipelineBloc, PipelineState>(
              listenWhen: (prev, curr) =>
                  curr is PipelineLoaded && curr.blockedMoveMessage != null,
              listener: (context, state) {
                if (state is PipelineLoaded &&
                    state.blockedMoveMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.blockedMoveMessage!)),
                  );
                }
              },
              builder: (context, state) => switch (state) {
                PipelineLoaded() =>
                  _Board(state: state, initialStage: initialStage),
                PipelineError(:final message) => _ErrorView(
                    message: message,
                    onRetry: () => context
                        .read<PipelineBloc>()
                        .add(const PipelineLoadRequested()),
                  ),
                _ => Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary)),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Board extends StatefulWidget {
  const _Board({required this.state, required this.initialStage});
  final PipelineLoaded state;
  final PipelineStage initialStage;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _boardController = ScrollController();

  /// One-time auto-scroll to the [initialStage] column on first layout.
  bool _initialScrollDone = false;

  @override
  void dispose() {
    _searchController.dispose();
    _boardController.dispose();
    super.dispose();
  }

  bool get _isAdmin => sl<SessionManager>().can(UserRole.admin);

  void _openDetail(BuildContext context, Lead lead) {
    final pipelineBloc = context.read<PipelineBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: pipelineBloc),
            BlocProvider(create: (_) => sl<LeadDetailCubit>()..load(lead.id)),
          ],
          child: LeadDetailScreen(leadId: lead.id),
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, Lead lead, LeadCardAction action) async {
    final bloc = context.read<PipelineBloc>();
    switch (action) {
      case LeadCardAction.view:
        _openDetail(context, lead);
      case LeadCardAction.edit:
        final updated =
            await showLeadFormSheet(context: context, existing: lead);
        if (updated != null) bloc.add(LeadUpdated(updated));
      case LeadCardAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: context.appColors.surfaceSoft,
            title: Text('Delete lead?',
                style: TextStyle(color: context.appColors.textPrimary)),
            content: Text('This removes ${lead.companyName} from the pipeline.',
                style: TextStyle(color: context.appColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) bloc.add(LeadDeleted(lead.id));
      case LeadCardAction.move:
        final result = await showMoveStageSheet(
            context: context, lead: lead, isAdmin: _isAdmin);
        if (result != null) {
          bloc.add(LeadMoved(
            leadId: lead.id,
            toStage: result.toStage,
            opportunityInfo: result.opportunityInfo,
            wonInfo: result.wonInfo,
          ));
        }
      case LeadCardAction.sendToHq:
        final updated = await showSendToHqSheet(context: context, lead: lead);
        if (updated != null) bloc.add(LeadUpdated(updated));
    }
  }

  Future<void> _handleDrop(
      BuildContext context, Lead dragged, PipelineStage toStage) async {
    if (dragged.stage == toStage) return;
    final result = await resolveStageMove(
        context: context, lead: dragged, toStage: toStage);
    if (result == null || !context.mounted) return;
    context.read<PipelineBloc>().add(LeadMoved(
          leadId: dragged.id,
          toStage: result.toStage,
          opportunityInfo: result.opportunityInfo,
          wonInfo: result.wonInfo,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final territories =
        widget.state.allLeads.map((l) => l.territory).toSet().toList()..sort();
    final reps = widget.state.allLeads
        .map((l) => l.assignedRepName)
        .toSet()
        .toList()
      ..sort();

    return RefreshIndicator(
      color: scheme.secondary,
      backgroundColor: colors.surfaceSoft,
      onRefresh: () async =>
          context.read<PipelineBloc>().add(const PipelineLoadRequested()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EXACT REPLICA OF THE DESIGN IMAGE ROW LAYOUT ---
            Transform.translate(
              offset: Offset(0, -4.h),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  children: [
                    // 1. Search Bar Input Container
                    Expanded(
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: colors.border),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: colors.textSecondary, size: 22.w),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (q) => context
                                    .read<PipelineBloc>()
                                    .add(SearchChanged(q)),
                                decoration: InputDecoration(
                                  hintText: "Search company or owner...",
                                  hintStyle: TextStyle(
                                      color: colors.textHint, fontSize: 14.sp),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(
                                    fontSize: 14.sp, color: colors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // 2. Action Filtering Button Container
                    GestureDetector(
                      onTap: () => showPipelineFilterSheet(
                        context: context,
                        filter: widget.state.filter,
                        territories: territories,
                        reps: reps,
                        onApply: (f) {
                          final bloc = context.read<PipelineBloc>();
                          bloc.add(FilterChanged(
                            territory: () => f.territory,
                            assignedRepName: () => f.assignedRepName,
                            priority: () => f.priority,
                            visibleStages: f.visibleStages,
                          ));
                          bloc.add(SortChanged(f.sortBy));
                        },
                      ),
                      child: Container(
                        width: 48.h,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: !widget.state.filter.isEmpty
                                ? scheme.primary
                                : colors.border,
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: colors.textPrimary,
                          size: 20.w,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // 3. Shaped Blue Add Action Button Container
                    GestureDetector(
                      onTap: () async {
                        final created =
                            await showLeadFormSheet(context: context);
                        if (created != null && context.mounted) {
                          context
                              .read<PipelineBloc>()
                              .add(LeadCreated(created));
                        }
                      },
                      child: Container(
                        width: 48.h,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.r),
                            topRight: Radius.circular(16.r),
                            bottomLeft: Radius.circular(20.r),
                            bottomRight: Radius.circular(16.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child:
                            Icon(Icons.add, color: scheme.onPrimary, size: 22.w),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Three boards on one screen (Leads | Opportunities | Won) in a
            // horizontally scrollable row; each column scrolls vertically on
            // its own and is never mixed into a single list.
            _scrollableBoard(context),
          ],
        ),
      ),
    );
  }

  // One accent colour per board, resolved from the active theme.
  Color _accentFor(
          PipelineStage stage, ColorScheme scheme, AppThemeColors colors) =>
      switch (stage) {
        PipelineStage.leads => scheme.primary,
        PipelineStage.opportunities => colors.success,
        PipelineStage.won => colors.info,
      };

  /// The pipeline as a horizontally scrollable row of three boards
  /// (Leads | Opportunities | Won). Each column is a fixed width so roughly
  /// two fit on screen and the third scrolls into view; the row auto-scrolls
  /// to the [initialStage] board on first layout.
  Widget _scrollableBoard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final columns = widget.state.columns;
    const order = PipelineStage.values;

    // Fill the viewport under the search bar; each column scrolls internally.
    final available = MediaQuery.sizeOf(context).height - 260.h;
    final boardHeight = available < 340.h ? 340.h : available;

    // Sized so ~2 columns are visible at once, the rest reachable by scroll.
    final gap = 12.w;
    final colWidth = (MediaQuery.sizeOf(context).width - 32.w - gap) / 2;

    if (!_initialScrollDone) {
      final index = order.indexOf(widget.initialStage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _initialScrollDone) return;
        _initialScrollDone = true;
        if (index > 0 && _boardController.hasClients) {
          final target = index * (colWidth + gap);
          _boardController.jumpTo(
              target.clamp(0.0, _boardController.position.maxScrollExtent));
        }
      });
    }

    return SizedBox(
      height: boardHeight,
      child: ListView.separated(
        controller: _boardController,
        scrollDirection: Axis.horizontal,
        itemCount: order.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemBuilder: (context, i) {
          final stage = order[i];
          return SizedBox(
            width: colWidth,
            child: _column(
              context: context,
              stage: stage,
              title: stage.label,
              accent: _accentFor(stage, scheme, colors),
              leads: columns[stage] ?? const [],
            ),
          );
        },
      ),
    );
  }

  /// Builds one board column, wiring the same tap / action / drag-and-drop
  /// handlers the board has always used.
  PipelineColumn _column({
    required BuildContext context,
    required PipelineStage stage,
    required String title,
    required Color accent,
    required List<Lead> leads,
  }) {
    return PipelineColumn(
      stage: stage,
      title: title,
      accent: accent,
      leads: leads,
      onCardTap: (lead) => _openDetail(context, lead),
      onCardAction: (lead, action) => _handleAction(context, lead, action),
      onDroppedOnColumn: (dragged) => _handleDrop(context, dragged, stage),
      onDroppedOnCard: (dragged, index) {
        if (dragged.stage == stage) {
          final oldIndex = (widget.state.columns[stage] ?? const [])
              .indexWhere((l) => l.id == dragged.id);
          if (oldIndex != -1) {
            context.read<PipelineBloc>().add(LeadReordered(
                stage: stage, oldIndex: oldIndex, newIndex: index));
          }
        } else {
          _handleDrop(context, dragged, stage);
        }
      },
    );
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
        ],
      ),
    );
  }
}
