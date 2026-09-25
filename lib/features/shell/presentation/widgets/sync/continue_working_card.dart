import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/resumable_visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/continue_work_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/continue_work_resolver.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Floating card featuring gold accent framing, dual-bordered icon badge,
/// subtle corner watermarks, and tactile 3D action controls.
class ContinueWorkingCard extends StatelessWidget {
  const ContinueWorkingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final activeShopId =
        context.watch<ResumableVisitCubit>().state.activeShopId;
    return BlocBuilder<ContinueWorkCubit, ContinueWorkState>(
      builder: (context, state) {
        if (!state.loaded) {
          return const _ContinueWorkingCardSkeleton();
        }

        final drafts = standaloneDrafts(state.drafts, activeShopId);
        if (drafts.isEmpty) {
          return const SizedBox.shrink();
        }
        if (drafts.length > 1) {
          return _MultiDraftCard(count: drafts.length);
        }
        return _DraftCard(draft: drafts.first);
      },
    );
  }
}

class _ContinueWorkingCardSkeleton extends StatelessWidget {
  const _ContinueWorkingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final skeletonColor = scheme.onSurface.withValues(alpha: 0.12);

    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.rr(20),
                height: context.rr(20),
                decoration: BoxDecoration(
                  color: skeletonColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.rw(8)),
              Expanded(
                child: Container(
                  height: context.rh(14),
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(context.rr(4)),
                  ),
                ),
              ),
              SizedBox(width: context.rw(32)),
              Container(
                width: context.rr(20),
                height: context.rr(20),
                decoration: BoxDecoration(
                  color: skeletonColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(12)),
          Container(
            width: context.rw(120),
            height: context.rh(12),
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(context.rr(4)),
            ),
          ),
          SizedBox(height: context.rh(6)),
          Container(
            width: context.rw(190),
            height: context.rh(12),
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(context.rr(4)),
            ),
          ),
          SizedBox(height: context.rh(16)),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: context.rh(40),
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(context.rr(10)),
                  ),
                ),
              ),
              SizedBox(width: context.rw(10)),
              Expanded(
                child: Container(
                  height: context.rh(40),
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(context.rr(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});
  final Quotation draft;

  static const Color _goldBorderColor = Color(0xFFCBA135);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Dual-Bordered Icon Avatar Badge
              Container(
                padding: EdgeInsets.all(context.rr(6)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _goldBorderColor.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4.r,
                      offset: Offset(0, context.rh(2)),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: context.rsp(18),
                  color: scheme.primary,
                ),
              ),
              SizedBox(width: context.rw(10)),
              Expanded(
                child: Text(
                  'sync.continue_previous'.tr,
                  style: TextStyle(
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              _DiscardButton(draft: draft),
            ],
          ),
          SizedBox(height: context.rh(10)),
          // Traditional framed sub-container
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.rw(10), vertical: context.rh(8)),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(context.rr(8)),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'sync.quotation_n'.trParams({'id': draft.id}),
                  style: TextStyle(
                    fontSize: context.rsp(13),
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                SizedBox(height: context.rh(3)),
                Text(
                  _subtitle(draft),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.rsp(12),
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.rh(14)),
          Row(
            children: [
              Expanded(
                child: _ThreeDOutlinedButton(
                  label: 'common.submit'.tr,
                  onPressed: () => _submit(context, draft),
                ),
              ),
              SizedBox(width: context.rw(10)),
              Expanded(
                child: _ThreeDFilledButton(
                  label: 'common.continue'.tr,
                  onPressed: () => _continue(context, draft),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MultiDraftCard extends StatelessWidget {
  const _MultiDraftCard({required this.count});
  final int count;

  static const Color _goldBorderColor = Color(0xFFCBA135);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return _CardShell(
      child: InkWell(
        onTap: () => _openDraftsSheet(context),
        borderRadius: BorderRadius.circular(context.rr(12)),
        child: Row(
          children: [
            // Dual-Bordered Icon Avatar Badge
            Container(
              padding: EdgeInsets.all(context.rr(8)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: _goldBorderColor.withValues(alpha: 0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4.r,
                    offset: Offset(0, context.rh(2)),
                  ),
                ],
              ),
              child: Icon(
                Icons.history_rounded,
                size: context.rsp(20),
                color: scheme.primary,
              ),
            ),
            SizedBox(width: context.rw(12)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'sync.continue_working'.trParams({'count': count}),
                    style: TextStyle(
                      fontSize: context.rsp(14),
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: context.rh(2)),
                  Text(
                    'sync.unfinished_drafts'.tr,
                    style: TextStyle(
                      fontSize: context.rsp(12),
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: context.rsp(22),
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold Framed Tactile Card Shell with Corner Watermarks
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  static const Color _goldBorderColor = Color(0xFFCBA135);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(context.rr(18)),
        border: Border.all(
          color: _goldBorderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, context.rh(6)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.rr(17)),
        child: Stack(
          children: [
            // Top-Left Corner Decorative Circle Watermark
            Positioned(
              top: -context.rr(22),
              left: -context.rr(22),
              child: Container(
                width: context.rr(55),
                height: context.rr(55),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Bottom-Right Corner Decorative Circle Watermark
            Positioned(
              bottom: -context.rr(22),
              right: -context.rr(22),
              child: Container(
                width: context.rr(55),
                height: context.rr(55),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: EdgeInsets.all(context.rr(14)),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactile 3D Filled Action Button
class _ThreeDFilledButton extends StatelessWidget {
  const _ThreeDFilledButton({
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.rr(10)),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.35),
            blurRadius: 6.r,
            offset: Offset(0, context.rh(3)),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: themeColor,
          padding: EdgeInsets.symmetric(vertical: context.rh(10)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.rr(10)),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.rsp(12.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Tactile 3D Outlined Action Button
class _ThreeDOutlinedButton extends StatelessWidget {
  const _ThreeDOutlinedButton({
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.rr(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4.r,
            offset: Offset(0, context.rh(2)),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColor,
          backgroundColor: scheme.surface,
          side: BorderSide(
            color: themeColor.withValues(alpha: 0.8),
            width: 1.2,
          ),
          padding: EdgeInsets.symmetric(vertical: context.rh(10)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.rr(10)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.rsp(12.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DiscardButton extends StatelessWidget {
  const _DiscardButton({required this.draft});
  final Quotation draft;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _confirmDiscard(context, draft),
      borderRadius: BorderRadius.circular(context.rr(20)),
      child: Container(
        padding: EdgeInsets.all(context.rr(4)),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.appColors.textSecondary.withValues(alpha: 0.08),
        ),
        child: Icon(
          Icons.close_rounded,
          size: context.rsp(16),
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }
}

String _subtitle(Quotation q) {
  final who = q.shopName?.isNotEmpty == true
      ? q.shopName!
      : (q.leadDisplayName ?? 'orders.quotation_extra.walk_in'.tr);
  return 'sync.draft_meta'.trParams(
      {'who': who, 'count': q.lines.length, 'time': _timeAgo(q.updatedAt)});
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'common.just_now'.tr;
  if (diff.inMinutes < 60) {
    return 'common.min_ago'.trParams({'minutes': diff.inMinutes});
  }
  if (diff.inHours < 24) {
    return 'common.hours_ago'.trParams({'hours': diff.inHours});
  }
  return 'common.days_ago'.trParams({'days': diff.inDays});
}

void _continue(BuildContext context, Quotation draft) {
  Navigator.of(context).push(MaterialPageRoute(
    settings: const RouteSettings(name: QuotationDetailScreen.routeName),
    builder: (_) => QuotationDetailScreen(quotation: draft),
  ));
}

void _submit(BuildContext context, Quotation draft) {
  context.read<PendingSyncCubit>().enqueue(draft.id);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('sync.queued_for_sap'.trParams({'id': draft.id})),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _confirmDiscard(BuildContext context, Quotation draft) async {
  final cubit = context.read<ContinueWorkCubit>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('sync.discard_draft_title'.tr),
      content: Text('sync.discard_draft_body'.trParams({'id': draft.id})),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('common.keep'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'common.discard'.tr,
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.error,
            ),
          ),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await cubit.discard(draft.id);
}

void _openDraftsSheet(BuildContext context) {
  final continueCubit = context.read<ContinueWorkCubit>();
  final pendingCubit = context.read<PendingSyncCubit>();
  showModalBottomSheet<void>(
    constraints: const BoxConstraints(maxWidth: AppBottomSheet.maxWidth),
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: continueCubit),
        BlocProvider.value(value: pendingCubit),
      ],
      child: const _DraftsSheet(),
    ),
  );
}

class _DraftsSheet extends StatelessWidget {
  const _DraftsSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(context.rr(24))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20.r,
              offset: Offset(0, -context.rh(4)),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: BlocBuilder<ContinueWorkCubit, ContinueWorkState>(
            builder: (context, state) {
              if (!state.loaded) {
                return const _DraftsSheetSkeleton();
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(context.rw(16), context.rh(14),
                    context.rw(16), context.rh(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: context.rw(44),
                        height: context.rh(5),
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(context.rr(2.5)),
                        ),
                      ),
                    ),
                    SizedBox(height: context.rh(14)),
                    Text(
                      'sync.continue_working'
                          .trParams({'count': state.drafts.length}),
                      style: TextStyle(
                        fontSize: context.rsp(17),
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: context.rh(12)),
                    if (state.drafts.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: context.rh(30)),
                        child: Center(
                          child: Text(
                            'sync.no_drafts_left'.tr,
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: state.drafts.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: context.rh(10)),
                          itemBuilder: (context, i) =>
                              _DraftRow(draft: state.drafts[i]),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DraftsSheetSkeleton extends StatelessWidget {
  const _DraftsSheetSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final skeletonColor = scheme.onSurface.withValues(alpha: 0.12);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.rw(16), context.rh(14), context.rw(16), context.rh(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: context.rw(44),
              height: context.rh(5),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(context.rr(2.5)),
              ),
            ),
          ),
          SizedBox(height: context.rh(16)),
          Container(
            width: context.rw(160),
            height: context.rh(18),
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(context.rr(4)),
            ),
          ),
          SizedBox(height: context.rh(16)),
          ...List.generate(
            2,
            (index) => Container(
              margin: EdgeInsets.only(bottom: context.rh(10)),
              height: context.rh(70),
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(context.rr(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({required this.draft});
  final Quotation draft;

  static const Color _goldBorderColor = Color(0xFFCBA135);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.all(context.rr(12)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(context.rr(12)),
        border: Border.all(color: _goldBorderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6.r,
            offset: Offset(0, context.rh(3)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'sync.quotation_n'.trParams({'id': draft.id}),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: context.rsp(13.5),
              color: scheme.primary,
            ),
          ),
          SizedBox(height: context.rh(2)),
          Text(
            _subtitle(draft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: context.rsp(11.5), color: colors.textSecondary),
          ),
          SizedBox(height: context.rh(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _confirmDiscard(context, draft),
                child: Text(
                  'common.discard'.tr,
                  style: TextStyle(
                    fontSize: context.rsp(12),
                    color: colors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: context.rw(4)),
              _ThreeDOutlinedButton(
                label: 'common.submit'.tr,
                onPressed: () => _submit(context, draft),
              ),
              SizedBox(width: context.rw(8)),
              _ThreeDFilledButton(
                label: 'common.continue'.tr,
                onPressed: () {
                  Navigator.of(context).pop();
                  _continue(context, draft);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
