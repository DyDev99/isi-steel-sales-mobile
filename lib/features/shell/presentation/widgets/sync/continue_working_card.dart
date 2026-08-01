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
                width: 20.r,
                height: 20.r,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 32.w),
              Container(
                width: 20.r,
                height: 20.r,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: 120.w,
            height: 12.h,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            width: 190.w,
            height: 12.h,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(10.r),
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
                padding: EdgeInsets.all(6.r),
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
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 18.sp,
                  color: scheme.primary,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'sync.continue_previous'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              _DiscardButton(draft: draft),
            ],
          ),
          SizedBox(height: 10.h),
          // Traditional framed sub-container
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(8.r),
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
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _subtitle(draft),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _ThreeDOutlinedButton(
                  label: 'common.submit'.tr,
                  onPressed: () => _submit(context, draft),
                ),
              ),
              SizedBox(width: 10.w),
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
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          children: [
            // Dual-Bordered Icon Avatar Badge
            Container(
              padding: EdgeInsets.all(8.r),
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
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.history_rounded,
                size: 20.sp,
                color: scheme.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'sync.continue_working'.trParams({'count': count}),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'sync.unfinished_drafts'.tr,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22.sp,
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
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: _goldBorderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17.r),
        child: Stack(
          children: [
            // Top-Left Corner Decorative Circle Watermark
            Positioned(
              top: -22.r,
              left: -22.r,
              child: Container(
                width: 55.r,
                height: 55.r,
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
              bottom: -22.r,
              right: -22.r,
              child: Container(
                width: 55.r,
                height: 55.r,
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
              padding: EdgeInsets.all(14.r),
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
    this.color,
  });
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.35),
            blurRadius: 6.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: themeColor,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
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
    this.color,
  });
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
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
          padding: EdgeInsets.symmetric(vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
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
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.appColors.textSecondary.withValues(alpha: 0.08),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 16.sp,
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20.r,
              offset: Offset(0, -4.h),
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
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2.5.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'sync.continue_working'
                          .trParams({'count': state.drafts.length}),
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (state.drafts.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.h),
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
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
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
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: 160.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 16.h),
          ...List.generate(
            2,
            (index) => Container(
              margin: EdgeInsets.only(bottom: 10.h),
              height: 70.h,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(14.r),
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
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _goldBorderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6.r,
            offset: Offset(0, 3.h),
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
              fontSize: 13.5.sp,
              color: scheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            _subtitle(draft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5.sp, color: colors.textSecondary),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _confirmDiscard(context, draft),
                child: Text(
                  'common.discard'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              _ThreeDOutlinedButton(
                label: 'common.submit'.tr,
                onPressed: () => _submit(context, draft),
              ),
              SizedBox(width: 8.w),
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
