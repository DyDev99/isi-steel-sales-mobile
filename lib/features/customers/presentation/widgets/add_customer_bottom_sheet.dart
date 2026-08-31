import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:phone_form_field/phone_form_field.dart';

import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/logging/debug_trace.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/add_customer_bloc.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/domain/entities/geo_address.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/domain/usecases/resolve_geo_address.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/presentation/widgets/geo_location_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/order_location_service.dart';
import 'package:isi_steel_sales_mobile/core/camera/image_capture_service.dart';

/// Console tracer, sharing the registration channel so the form's own steps
/// interleave with the bloc's and the HTTP calls' in one readable sequence.
const _trace = DebugTrace('registration');

class AddCustomerBottomSheet extends StatelessWidget {
  final bool isTablet;
  final bool isFullScreen;

  const AddCustomerBottomSheet({
    super.key,
    this.isTablet = false,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) => BlocProvider<AddCustomerBloc>(
        create: (_) => sl<AddCustomerBloc>()..add(const OpenServerDraft()),
        child: _AddCustomerForm(
          isTablet: isTablet,
          isFullScreen: isFullScreen,
        ),
      );
}

class _AddCustomerForm extends StatefulWidget {
  const _AddCustomerForm({
    required this.isTablet,
    required this.isFullScreen,
  });
  final bool isTablet;
  final bool isFullScreen;

  @override
  State<_AddCustomerForm> createState() => _AddCustomerBottomSheetState();
}

class _AddCustomerBottomSheetState extends State<_AddCustomerForm> {
  // Simulator-only fallback used while developing the Cambodia sales app.
  // Release builds must always store the real device position.
  static const _developmentCambodiaLatitude = 11.5564;
  static const _developmentCambodiaLongitude = 104.9282;

  // ---------------------------------------------------------------------------
  // Controllers exist ONLY for text input. Every value lives on the draft;
  // the controllers write through to it on change.
  // ---------------------------------------------------------------------------
  final _nameEnCtrl = TextEditingController();
  final _nameKhCtrl = TextEditingController();
  final _name2Ctrl = TextEditingController();
  final _searchTermCtrl = TextEditingController();
  final _coNameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _houseNoCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _vatTinCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  final _mobileCtrl = PhoneController(
      initialValue: const PhoneNumber(isoCode: IsoCode.KH, nsn: ''));
  final _telCtrl = PhoneController(
      initialValue: const PhoneNumber(isoCode: IsoCode.KH, nsn: ''));

  /// Lets "Next" tell the address block to reveal its own field errors.
  ///
  /// `validateStep` decides whether the step may advance, but it returns error
  /// keys the geo selector never sees — it owns its four fields and their
  /// messages. Without this handle the rep taps Next, nothing happens, and no
  /// field says why.
  final _geoController = GeoLocationSelectorController();

  /// The address-step error keys the selector renders itself. Postal code is
  /// included: the selector owns that field too, including the manual-entry
  /// case for the communes with no code on record.
  static const _geoErrorKeys = {'city', 'district', 'commune', 'postalCode'};

  bool _capturingGps = false;
  bool _showMoreIdentity = false;
  bool _showAdvancedTerms = false;

  @override
  void dispose() {
    for (final c in [
      _nameEnCtrl,
      _nameKhCtrl,
      _name2Ctrl,
      _searchTermCtrl,
      _coNameCtrl,
      _streetCtrl,
      _houseNoCtrl,
      _contactNameCtrl,
      _vatTinCtrl,
      _remarkCtrl,
    ]) {
      c.dispose();
    }
    _mobileCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  double _fontSize(double base) =>
      widget.isTablet ? base * 1.25 : context.rsp(base);

  double _spacing(double base) =>
      widget.isTablet ? base * 1.2 : context.rh(base);

  bool get _isTabletLayout =>
      widget.isTablet ||
      context.responsive(compact: false, medium: true, expanded: true);

  int _tabletStage =
      0; // 0: Identity+Address, 1: Contact+Terms, 2: Documents+Notes, 3: Preview

  AddCustomerBloc get _bloc => context.read<AddCustomerBloc>();

  /// Guards the "resumed your draft" notice so it shows once when the form
  /// opens, not again on every subsequent field flush — the listener also
  /// fires whenever `serverFields` changes.
  bool _resumeNoticeShown = false;

  /// Single mutation entry point. Everything the rep touches goes through here.
  void _edit(void Function(BpCustomerDraft d) mutate) =>
      _bloc.add(DraftChanged(mutate));

  void _syncTextControllers(BpCustomerDraft draft) {
    // A draft response is authoritative (the server may normalise a code or
    // prefill a default), so copy its text values into the visible controls.
    _nameEnCtrl.text = draft.nameEn;
    _nameKhCtrl.text = draft.nameKh;
    _name2Ctrl.text = draft.name2;
    _searchTermCtrl.text = draft.searchTerm;
    _coNameCtrl.text = draft.coName;
    _streetCtrl.text = draft.street;
    _houseNoCtrl.text = draft.houseNumber;
    _contactNameCtrl.text = draft.contactPersonName;
    _vatTinCtrl.text = draft.vatTin;
    _remarkCtrl.text = draft.remark;
  }

  // ===========================================================================
  // Build
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<AddCustomerBloc, AddCustomerState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.serverFields != curr.serverFields ||
          prev.errors != curr.errors,
      listener: (context, state) {
        if (state.status == AddCustomerStatus.editing &&
            state.serverDraftId != null) {
          _syncTextControllers(state.draft);

          // Say why the form came back filled in. Without this the rep sees
          // their own earlier typing and cannot tell whether it is stale data
          // from someone else's record.
          if (state.resumedDraft && !_resumeNoticeShown) {
            _resumeNoticeShown = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('add_customer.draft_resumed'.tr)),
            );
          }
        }
        // Next was blocked on a field the selector owns — tell it to show why.
        if (state.currentStep == BpFormStep.address &&
            state.errors.keys.any(_geoErrorKeys.contains)) {
          _geoController.validate();
        }
        if (state.errors.isNotEmpty && _isTabletLayout) {
          if (state.currentStep == BpFormStep.identity ||
              state.currentStep == BpFormStep.address) {
            setState(() => _tabletStage = 0);
          } else if (state.currentStep == BpFormStep.contact ||
              state.currentStep == BpFormStep.salesTerms) {
            setState(() => _tabletStage = 1);
          } else if (state.currentStep == BpFormStep.documents) {
            setState(() => _tabletStage = 2);
          }
        }
        if (state.status == AddCustomerStatus.success) {
          // The customer is saved either way. An evidence slot that did not
          // reach the server is reported here rather than as a failure,
          // because the registration itself succeeded — but staying silent
          // would leave the rep believing photographs were filed that are not.
          final unsent = state.unsentDocuments.length;
          final message = switch (state) {
            _ when state.queuedOffline => 'add_customer.queued_offline'.tr,
            _ when unsent > 0 => 'add_customer.documents_partially_sent'
                .trParams({'count': unsent}),
            _ => 'add_customer.success'.tr,
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: unsent > 0 && !state.queuedOffline
                  ? context.appColors.warning
                  : null,
              duration: unsent > 0
                  ? const Duration(seconds: 6)
                  : const Duration(seconds: 4),
              content: Text(message),
            ),
          );
          Navigator.pop(context, true);
        } else if (state.status == AddCustomerStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.error,
              content:
                  Text(state.errorMessage ?? 'add_customer.error.submit'.tr),
            ),
          );
        }
      },
      builder: (context, state) {
        final content = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: widget.isFullScreen
                ? null
                : BorderRadius.vertical(
                    top: Radius.circular(widget.isTablet ? 24 : context.rr(28)),
                  ),
          ),
          padding: EdgeInsets.fromLTRB(
            widget.isTablet ? 36 : context.rw(16),
            widget.isTablet ? 24 : context.rh(16),
            widget.isTablet ? 36 : context.rw(16),
            widget.isTablet
                ? 32
                : context.deviceInsets.sheetBottomInset(extra: context.rh(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isFullScreen) ...[
                Center(
                  child: Container(
                    width: widget.isTablet ? 60 : context.rw(42),
                    height: widget.isTablet ? 6 : context.rh(5),
                    decoration: BoxDecoration(
                      color: context.appColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: _spacing(12)),
              ],
              if (_isTabletLayout)
                _buildTabletFormHeader(state)
              else
                _buildFormHeader(state),
              SizedBox(height: _spacing(16)),
              if (_isTabletLayout)
                _buildTabletStepProgress(state)
              else
                _buildStepProgress(state),
              SizedBox(height: _spacing(16)),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: state.status == AddCustomerStatus.submitting ||
                            state.status == AddCustomerStatus.opening
                        ? Center(
                            key: const ValueKey('submitting_loader'),
                            child: Padding(
                              padding: EdgeInsets.all(_spacing(40)),
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          )
                        : _isTabletLayout
                            ? KeyedSubtree(
                                key: ValueKey('tablet_stage_$_tabletStage'),
                                child: _buildTabletStageBody(state),
                              )
                            : KeyedSubtree(
                                key: ValueKey(state.currentStep),
                                child: _buildStepBody(
                                    state.currentStep, state.errors),
                              ),
                  ),
                ),
              ),
              SizedBox(height: _spacing(20)),
              if (_isTabletLayout)
                _buildTabletNavigationButtons(state)
              else
                _buildNavigationButtons(state),
            ],
          ),
        );

        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height,
            child: content,
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Tablet Header & Progress
  // ===========================================================================
  Widget _buildTabletFormHeader(AddCustomerState state) {
    final stageTitles = [
      (
        title:
            '${'add_customer.steps.identity'.tr} & ${'add_customer.steps.address'.tr}',
        subtitle: 'add_customer.subtitle'.tr,
      ),
      (
        title:
            '${'add_customer.steps.contact'.tr} & ${'add_customer.steps.sales_terms'.tr}',
        subtitle:
            'Configure contact details, commercial pricing & tax classification',
      ),
      (
        title: 'add_customer.steps.documents'.tr,
        subtitle: 'Upload required verification photos and internal remarks',
      ),
      (
        title: '${'add_customer.review'.tr} & ${'add_customer.send_to_hq'.tr}',
        subtitle:
            'Verify all registered customer information before final submission',
      ),
    ];
    final current = stageTitles[_tabletStage.clamp(0, 3)];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  current.title,
                  key: ValueKey(current.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: _fontSize(22),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                current.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: _fontSize(13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.appColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appColors.border),
          ),
          child: Text(
            'Step ${_tabletStage + 1} / 4',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: _fontSize(13),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletStepProgress(AddCustomerState state) {
    final stages = [
      '1. General & Location',
      '2. Contact & Terms',
      '3. Documents & Notes',
      '4. Preview & Submit',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stages.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: i < _tabletStage ? () => _goToTabletStage(i) : null,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _tabletStage
                              ? Theme.of(context).colorScheme.primary
                              : i < _tabletStage
                                  ? context.appColors.success
                                  : context.appColors.border,
                        ),
                        child: i < _tabletStage
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: i == _tabletStage
                                      ? Colors.white
                                      : context.appColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stages[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _fontSize(12.5),
                            fontWeight: i == _tabletStage
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: i == _tabletStage
                                ? Theme.of(context).colorScheme.primary
                                : i < _tabletStage
                                    ? context.appColors.textPrimary
                                    : context.appColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i < stages.length - 1)
              Container(
                width: 16,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i < _tabletStage
                    ? context.appColors.success
                    : context.appColors.border,
              ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Tablet Stages Body (2-Step Columns & Preview)
  // ===========================================================================
  Widget _buildTabletStageBody(AddCustomerState state) {
    return switch (_tabletStage) {
      0 => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSectionCard(
                title: 'add_customer.steps.identity'.tr,
                subtitle: 'Who is the customer (BP header & names)',
                icon: Icons.person_outline_rounded,
                child: _buildIdentityStep(state.errors),
              ),
            ),
            SizedBox(width: _spacing(24)),
            Expanded(
              child: _buildSectionCard(
                title: 'add_customer.steps.address'.tr,
                subtitle: 'Where are they located (Address & GPS)',
                icon: Icons.location_on_outlined,
                child: _buildAddressStep(state.errors),
              ),
            ),
          ],
        ),
      1 => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSectionCard(
                title: 'add_customer.steps.contact'.tr,
                subtitle: 'How do we reach them (Phones & Contact person)',
                icon: Icons.phone_outlined,
                child: _buildContactStep(state.errors),
              ),
            ),
            SizedBox(width: _spacing(24)),
            Expanded(
              child: _buildSectionCard(
                title: 'add_customer.steps.sales_terms'.tr,
                subtitle: 'Commercial setup (Pricing, Payment & Tax)',
                icon: Icons.receipt_long_outlined,
                child: _buildSalesTermsStep(state.errors),
              ),
            ),
          ],
        ),
      2 => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSectionCard(
                title: 'add_customer.steps.documents'.tr,
                subtitle: 'Verification documents & business license photos',
                icon: Icons.attach_file_rounded,
                child: _buildDocumentPhotosSection(state.draft, state.errors),
              ),
            ),
            SizedBox(width: _spacing(24)),
            Expanded(
              child: _buildSectionCard(
                title: 'add_customer.remark'.tr,
                subtitle: 'Internal notes & instructions for Sales HQ',
                icon: Icons.description_outlined,
                child: _buildRemarksSection(state.draft),
              ),
            ),
          ],
        ),
      3 => _buildTabletPreviewScreen(state.draft),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(widget.isTablet ? 24 : context.rw(16)),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(18)),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.primary, size: _fontSize(20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: _fontSize(16),
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: _fontSize(12),
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _goToTabletStage(int stage) {
    setState(() => _tabletStage = stage);
    switch (stage) {
      case 0:
        _bloc.add(const GoToStep(BpFormStep.identity));
        break;
      case 1:
        _bloc.add(const GoToStep(BpFormStep.contact));
        break;
      case 2:
        _bloc.add(const GoToStep(BpFormStep.documents));
        break;
      case 3:
        break;
    }
  }

  void _editFromPreview(int targetStage, BpFormStep step) {
    setState(() => _tabletStage = targetStage);
    _bloc.add(GoToStep(step));
  }

  void _handleTabletNext(AddCustomerState state) {
    if (state.serverDraftId == null) {
      _bloc.add(const OpenServerDraft());
      return;
    }

    if (_tabletStage == 0) {
      final idErrors = state.draft.validateStep(BpFormStep.identity);
      final addrErrors = state.draft.validateStep(BpFormStep.address);
      if (idErrors.isNotEmpty) {
        _bloc.add(const GoToStep(BpFormStep.identity));
        _bloc.add(const NextStep());
        return;
      }
      if (addrErrors.isNotEmpty) {
        _bloc.add(const GoToStep(BpFormStep.address));
        _bloc.add(const NextStep());
        return;
      }
      _goToTabletStage(1);
    } else if (_tabletStage == 1) {
      final contactErrors = state.draft.validateStep(BpFormStep.contact);
      final termsErrors = state.draft.validateStep(BpFormStep.salesTerms);
      if (contactErrors.isNotEmpty) {
        _bloc.add(const GoToStep(BpFormStep.contact));
        _bloc.add(const NextStep());
        return;
      }
      if (termsErrors.isNotEmpty) {
        _bloc.add(const GoToStep(BpFormStep.salesTerms));
        _bloc.add(const NextStep());
        return;
      }
      _goToTabletStage(2);
    } else if (_tabletStage == 2) {
      final docErrors = state.draft.validateStep(BpFormStep.documents);
      if (docErrors.isNotEmpty) {
        _bloc.add(const GoToStep(BpFormStep.documents));
        _bloc.add(const NextStep());
        return;
      }
      _goToTabletStage(3);
    } else if (_tabletStage == 3) {
      _bloc.add(const SubmitToHQ());
    }
  }

  Widget _buildTabletNavigationButtons(AddCustomerState state) {
    final isFirst = _tabletStage == 0;
    final isLast = _tabletStage == 3;
    final needsCredit =
        SapMasterData.paymentTermNeedsCreditApproval(state.draft.paymentTerm);

    const btnPadding = EdgeInsets.symmetric(vertical: 20);

    return Row(
      children: [
        if (!isFirst) ...[
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: btnPadding,
                side: BorderSide(color: context.appColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (_tabletStage == 3) {
                  _goToTabletStage(2);
                } else if (_tabletStage == 2) {
                  _goToTabletStage(1);
                } else if (_tabletStage == 1) {
                  _goToTabletStage(0);
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(
                _tabletStage == 3 ? 'Back to Edit' : 'Previous',
                style: TextStyle(
                  fontSize: _fontSize(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: btnPadding,
              backgroundColor: isLast
                  ? context.appColors.success
                  : Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: state.status == AddCustomerStatus.submitting ||
                    state.status == AddCustomerStatus.opening
                ? null
                : () => _handleTabletNext(state),
            icon: Icon(
              isLast ? Icons.check_circle_outline : Icons.arrow_forward,
              color: Colors.white,
            ),
            label: Text(
              isLast
                  ? (needsCredit
                      ? 'add_customer.send_for_credit_approval'.tr
                      : 'add_customer.send_to_hq'.tr)
                  : (_tabletStage == 2
                      ? 'Preview & Review'
                      : 'add_customer.next_step'.tr),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: _fontSize(15),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Phone Header + progress
  // ===========================================================================
  Widget _buildFormHeader(AddCustomerState state) {
    final title = state.currentStep.titleKey.tr;

    final stepText = 'add_customer.step_indicator'
        .tr
        .replaceAll('{current}', '${state.currentStep.number}')
        .replaceAll('{total}', '${BpFormStep.values.length}');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  title,
                  key: ValueKey(title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: _fontSize(22),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'add_customer.subtitle'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: _fontSize(13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 20 : context.rw(12),
            vertical: widget.isTablet ? 10 : context.rh(6),
          ),
          decoration: BoxDecoration(
            color: context.appColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appColors.border),
          ),
          child: Text(
            stepText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: _fontSize(13),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  /// Five dots are harder to read than three — a bar tells the rep how much
  /// is left at a glance, and lets them tap back to a completed step.
  Widget _buildStepProgress(AddCustomerState state) {
    return Row(
      children: [
        for (final step in BpFormStep.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: step.index < state.currentStep.index
                  ? () => _bloc.add(GoToStep(step))
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: step.index <= state.currentStep.index
                      ? Theme.of(context).colorScheme.secondary
                      : context.appColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (step != BpFormStep.values.last) const SizedBox(width: 6),
        ],
      ],
    );
  }

  // ===========================================================================
  // Step router — mirrors BpFormStep exactly
  // ===========================================================================
  Widget _buildStepBody(BpFormStep step, Map<String, String> errors) {
    return switch (step) {
      BpFormStep.identity => _buildIdentityStep(errors),
      BpFormStep.address => _buildAddressStep(errors),
      BpFormStep.contact => _buildContactStep(errors),
      BpFormStep.salesTerms => _buildSalesTermsStep(errors),
      BpFormStep.documents => _buildDocumentsStep(errors),
    };
  }

  // ===========================================================================
  // STEP 1 — Identity
  // ===========================================================================
  Widget _buildIdentityStep(Map<String, String> errors) {
    final draft = _bloc.state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('add_customer.grouping'.tr, required: true),
        _dropdown(
          value: draft.grouping,
          options: SapMasterData.grouping,
          error: errors['grouping'],
          onChanged: (v) => _edit((d) => d.grouping = v!),
        ),
        _gap(),

        _label('add_customer.title_field'.tr, required: true),
        _dropdown(
          value: draft.title,
          options: SapMasterData.title,
          error: errors['title'],
          onChanged: (v) => _edit((d) => d.title = v!),
        ),
        _gap(),

        _label('add_customer.name_en'.tr, required: true),
        _text(
          _nameEnCtrl,
          'add_customer.name_en_hint'.tr,
          error: errors['nameEn'],
          maxLength: 40, // SAP NAME1 limit
          onChanged: (v) => _edit((d) => d.nameEn = v),
        ),
        _gap(),

        _label('add_customer.name_kh'.tr, required: true),
        _text(
          _nameKhCtrl,
          'add_customer.name_kh_hint'.tr,
          error: errors['nameKh'],
          onChanged: (v) => _edit((d) => d.nameKh = v),
        ),
        _gap(),

        _moreToggle(
          expanded: _showMoreIdentity,
          onTap: () => setState(() => _showMoreIdentity = !_showMoreIdentity),
        ),
        if (_showMoreIdentity) ...[
          _gap(),
          _label('add_customer.name2'.tr),
          _text(_name2Ctrl, 'add_customer.name2_hint'.tr,
              onChanged: (v) => _edit((d) => d.name2 = v)),
          _gap(),
          _label('add_customer.search_term'.tr),
          _text(_searchTermCtrl,
              draft.searchTerm.isEmpty ? '—' : draft.searchTerm,
              onChanged: (v) => _edit((d) => d.searchTerm = v)),
          _gap(),
          _label('add_customer.co_name'.tr),
          _text(_coNameCtrl, 'add_customer.co_name_hint'.tr,
              onChanged: (v) => _edit((d) => d.coName = v)),
        ],
        _gap(),

        // Replaces the old rep-typed customer code field.
        _infoChip(
          Icons.qr_code_2_rounded,
          'add_customer.code_assigned_by_sap'.tr,
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 2 — Address & Location
  // ===========================================================================
  Widget _buildAddressStep(Map<String, String> errors) {
    final draft = _bloc.state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('add_customer.street'.tr),
                  _text(_streetCtrl, 'add_customer.street_hint'.tr,
                      onChanged: (v) => _edit((d) => d.street = v)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('add_customer.house_no'.tr),
                  _text(_houseNoCtrl, '217',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _edit((d) => d.houseNumber = v)),
                ],
              ),
            ),
          ],
        ),
        _gap(),
        GeoLocationSelector(
          controller: _geoController,
          initialAddress: draft.geoAddress,
          initialCodes: ResolveGeoAddressParams(
            provinceCode: draft.cityCode,
            districtCode: draft.districtCode,
            communeCode: draft.communeCode,
            villageCode: draft.villageCode,
            postalCode: draft.postalCode,
          ),
          requirement: GeoAddressRequirement.standard,
          spacing: _spacing(16),
          onChanged: (address) => _edit((d) {
            d.geoAddress = address;
            d.cityCode = address.province?.code;
            d.districtCode = address.district?.code;
            d.communeCode = address.commune?.code;
            d.villageCode = address.village?.code;
            d.postalCode = address.postalCode ?? '';
          }),
        ),
        _gap(),
        Row(
          children: [
            Expanded(
              child: _infoChip(Icons.flag_outlined, 'KH - Cambodia'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _infoChip(Icons.public, 'R01 - Central Area'),
            ),
          ],
        ),
        _gap(),
        _label('add_customer.gps'.tr, required: true),
        _actionTile(
          label: draft.geoFix == null
              ? 'add_customer.gps_save'.tr
              : 'add_customer.gps_verified'.tr,
          sub: _capturingGps
              ? 'add_customer.gps_capturing'.tr
              : draft.geoFix?.display ?? 'add_customer.gps_hint'.tr,
          icon: Icons.location_on_rounded,
          completed: draft.geoFix != null,
          onTap: () => unawaited(_captureGps()),
        ),
        if (errors['geo'] != null)
          _errorText('add_customer.${errors['geo']}'.tr),
      ],
    );
  }

  Future<void> _captureGps() async {
    if (_capturingGps) return;
    setState(() => _capturingGps = true);

    ({double lat, double lng})? fix;
    try {
      fix = await sl<OrderLocationService>().captureOnce();
    } catch (error) {
      _trace.fail('gps', 'capture failed', {'error': error.runtimeType});
    }
    if (!mounted) return;
    setState(() => _capturingGps = false);

    var capturedFix = fix;
    final originalFix = capturedFix;
    final hasCambodiaFix = originalFix == null
        ? false
        : _isCambodiaCoordinate(originalFix.lat, originalFix.lng);
    if (kDebugMode && !hasCambodiaFix) {
      _trace.warn('gps', 'development fallback — fix absent or outside KH');
      capturedFix = (
        lat: _developmentCambodiaLatitude,
        lng: _developmentCambodiaLongitude,
      );
    }
    if (capturedFix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('add_customer.gps_failed'.tr)),
      );
      return;
    }

    // Full precision — SAP stores 11.531871600000001, not 11.53187.
    final latitude = capturedFix.lat;
    final longitude = capturedFix.lng;
    // A shop's position is customer data: whether a fix was captured is
    // traceable, the coordinates themselves are not (FS-SEC-2).
    _trace.ok('gps', 'fix saved to draft', {
      'inKH': DebugTrace.yesNo(_isCambodiaCoordinate(latitude, longitude)),
    });
    _edit((d) => d.geoFix = GeoFix(
          latitude: latitude,
          longitude: longitude,
          accuracyMeters: null,
          capturedAt: DateTime.now(),
        ));
  }

  bool _isCambodiaCoordinate(double latitude, double longitude) =>
      latitude >= 9.9 &&
      latitude <= 14.7 &&
      longitude >= 102.3 &&
      longitude <= 107.7;

  // ===========================================================================
  // STEP 3 — Contact
  // ===========================================================================
  Widget _buildContactStep(Map<String, String> errors) {
    final draft = _bloc.state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('add_customer.mobile_phone'.tr, required: true),
        _phone(
          _mobileCtrl,
          'add_customer.phone_hint'.tr,
          onChanged: (v) => _edit((d) => d.mobilePhone = v),
        ),
        _gap(),

        // SAP marks Telephone AND Mobile mandatory. The switch stops the rep
        // typing the same number twice, which is what they will do anyway.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
                child: _label('add_customer.telephone'.tr, required: true)),
            Switch.adaptive(
              value: draft.telephoneSameAsMobile,
              onChanged: (v) => _edit((d) => d.telephoneSameAsMobile = v),
            ),
          ],
        ),
        Text(
          'add_customer.same_as_mobile'.tr,
          style: TextStyle(
            fontSize: _fontSize(12),
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        if (!draft.telephoneSameAsMobile) ...[
          SizedBox(height: _spacing(8)),
          _phone(
            _telCtrl,
            'add_customer.phone_hint'.tr,
            error: errors['telephone'],
            onChanged: (v) => _edit((d) => d.telephone = v),
          ),
        ],
        _gap(),

        _label('add_customer.contact_name'.tr, required: true),
        _text(
          _contactNameCtrl,
          'add_customer.contact_name_hint'.tr,
          error: errors['contactPersonName'],
          onChanged: (v) => _edit((d) => d.contactPersonName = v),
        ),
        _gap(),

        _label('add_customer.role'.tr, required: true),
        _dropdown(
          value: draft.contactPersonRole,
          options: const [
            SapOption('owner', 'Owner'),
            SapOption('manager', 'Manager'),
            SapOption('buyer', 'Buyer'),
            SapOption('accountant', 'Accountant'),
          ],
          hint: 'add_customer.pick_one'.tr,
          error: errors['contactPersonRole'],
          showCode: false,
          onChanged: (v) => _edit((d) => d.contactPersonRole = v),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 4 — Sales & Billing terms
  // ===========================================================================
  Widget _buildSalesTermsStep(Map<String, String> errors) {
    final draft = _bloc.state.draft;
    // The ERP's own catalogues, falling back per-dropdown to the built-in lists
    // when they have not been loaded. The built-in lists are materially shorter
    // than SAP's — payment terms 4 vs 28, customer groups 5 vs 8 — so a rep
    // picking from them can choose a code the push will be rejected for.
    final refs = _bloc.state.references;
    final needsCredit =
        SapMasterData.paymentTermNeedsCreditApproval(draft.paymentTerm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('add_customer.customer_group'.tr, required: true),
        _dropdown(
          value: draft.customerGroup,
          options: refs.customerGroup,
          hint: 'add_customer.pick_one'.tr,
          error: errors['customerGroup'],
          onChanged: (v) => _edit((d) => d.customerGroup = v),
        ),
        if (draft.priceGroup != null) ...[
          const SizedBox(height: 6),
          _infoChip(
              Icons.sell_outlined,
              'add_customer.price_group_auto'
                  .tr
                  .replaceAll('{code}', draft.priceGroup!)),
        ],
        _gap(),
        _label('add_customer.payment_term'.tr, required: true),
        _dropdown(
          value: draft.paymentTerm,
          options: refs.paymentTerm,
          error: errors['paymentTerm'],
          onChanged: (v) => _edit((d) => d.paymentTerm = v),
        ),
        if (needsCredit) ...[
          SizedBox(height: _spacing(10)),
          _creditNotice(),
        ],
        _gap(),
        _label('add_customer.tax_class'.tr, required: true),
        _segmented(
          value: draft.taxClass,
          options: SapMasterData.taxClass,
          onChanged: (v) => _edit((d) => d.taxClass = v),
        ),
        if (draft.taxClass == '1') ...[
          _gap(),
          _label('add_customer.vat_tin'.tr, required: true),
          _text(
            _vatTinCtrl,
            'add_customer.vat_tin_hint'.tr,
            error: errors['vatTin'],
            onChanged: (v) => _edit((d) => d.vatTin = v),
          ),
        ],
        _gap(),
        _moreToggle(
          expanded: _showAdvancedTerms,
          labelCollapsed: 'add_customer.adjust_defaults'.tr,
          onTap: () => setState(() => _showAdvancedTerms = !_showAdvancedTerms),
        ),
        if (_showAdvancedTerms) ...[
          _gap(),
          _label('add_customer.sales_org'.tr, required: true),
          _dropdown(
            value: draft.salesOrg,
            options: refs.salesOrg,
            hint: 'add_customer.pick_one'.tr,
            error: errors['salesOrg'],
            onChanged: (v) => _edit((d) => d.salesOrg = v),
          ),
          _gap(),
          _label('add_customer.sales_office'.tr, required: true),
          _dropdown(
            value: draft.salesOffice,
            options: refs.salesOffice,
            hint: 'add_customer.pick_one'.tr,
            error: errors['salesOffice'],
            onChanged: (v) => _edit((d) => d.salesOffice = v),
          ),
          _gap(),
          _label('add_customer.sales_group'.tr, required: true),
          _dropdown(
            value: draft.salesGroupCode,
            options: refs.salesGroup,
            hint: 'add_customer.pick_one'.tr,
            error: errors['salesGroup'],
            onChanged: (v) => _edit((d) => d.salesGroupCode = v),
          ),
          _gap(),
          _label('add_customer.distribution_channel'.tr, required: true),
          _dropdown(
            value: draft.distributionChannel,
            options: refs.distributionChannel,
            error: errors['distributionChannel'],
            onChanged: (v) => _edit((d) => d.distributionChannel = v),
          ),
          _gap(),
          _label('add_customer.division'.tr, required: true),
          _dropdown(
            value: draft.divisionCode,
            options: refs.division,
            error: errors['division'],
            onChanged: (v) => _edit((d) => d.divisionCode = v),
          ),
          _gap(),
          _label('add_customer.delivery_priority'.tr, required: true),
          _dropdown(
            value: draft.deliveryPriority,
            options: SapMasterData.deliveryPriority,
            error: errors['deliveryPriority'],
            onChanged: (v) => _edit((d) => d.deliveryPriority = v),
          ),
          _gap(),
          _label('add_customer.shipping_condition'.tr, required: true),
          _dropdown(
            value: draft.shippingCondition,
            options: refs.shippingCondition,
            error: errors['shippingCondition'],
            onChanged: (v) => _edit((d) => d.shippingCondition = v),
          ),
          _gap(),
          _label('add_customer.currency'.tr, required: true),
          _dropdown(
            value: draft.currency,
            options: SapMasterData.currency,
            onChanged: (v) => _edit((d) => d.currency = v!),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // STEP 5 — Documents & review
  // ===========================================================================
  Widget _buildPhotoTile(
    String kind,
    String labelKey,
    IconData icon,
    BpCustomerDraft draft,
    Map<String, String> errors, {
    bool required = true,
  }) {
    final attached = draft.hasAttachment(kind);
    return Padding(
      padding: EdgeInsets.only(bottom: _spacing(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actionTile(
            label: labelKey.tr + (required ? ' *' : ''),
            sub: attached
                ? 'add_customer.photo_attached'.tr
                : 'add_customer.photo_tap'.tr,
            icon: icon,
            completed: attached,
            onTap: () => unawaited(_capturePhoto(kind)),
          ),
          if (errors[kind] != null)
            _errorText('add_customer.error.photo_required'.tr),
        ],
      ),
    );
  }

  Widget _buildDocumentPhotosSection(
      BpCustomerDraft draft, Map<String, String> errors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('add_customer.photos'.tr, required: true),
        _buildPhotoTile('outlet_front', 'add_customer.photo_front',
            Icons.storefront_rounded, draft, errors),
        _buildPhotoTile('outlet_inside', 'add_customer.photo_inside',
            Icons.store_rounded, draft, errors),
        _buildPhotoTile('id_card', 'add_customer.photo_id', Icons.badge_rounded,
            draft, errors),
        _buildPhotoTile('patent_tax', 'add_customer.photo_patent',
            Icons.receipt_long_rounded, draft, errors,
            required: false),
        if (draft.taxClass == '1')
          _buildPhotoTile('vat_cert', 'add_customer.photo_vat',
              Icons.verified_rounded, draft, errors),
      ],
    );
  }

  Widget _buildRemarksSection(BpCustomerDraft draft) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('add_customer.remark'.tr),
        _text(
          _remarkCtrl,
          'add_customer.remark_hint'.tr,
          maxLines: 4,
          onChanged: (v) => _edit((d) => d.remark = v),
        ),
        SizedBox(height: _spacing(16)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'add_customer.credit_notice'.tr,
                  style: TextStyle(
                    fontSize: _fontSize(12),
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletPreviewScreen(BpCustomerDraft draft) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final needsCredit =
        SapMasterData.paymentTermNeedsCreditApproval(draft.paymentTerm);

    Widget previewItem(String label, String value, {bool isCode = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: _fontSize(12),
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: TextStyle(
                  fontSize: _fontSize(13),
                  fontWeight: isCode ? FontWeight.w700 : FontWeight.w500,
                  color: colors.textPrimary,
                  fontFamily: isCode ? 'monospace' : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget previewCard({
      required String title,
      required IconData icon,
      required VoidCallback onEdit,
      required List<Widget> children,
    }) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: scheme.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: _fontSize(15),
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label:
                      Text('Edit', style: TextStyle(fontSize: _fontSize(12))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );
    }

    final formattedAddress = [
      if (draft.street.isNotEmpty || draft.houseNumber.isNotEmpty)
        '${draft.houseNumber} ${draft.street}'.trim(),
      if (draft.geoAddress != null && draft.geoAddress != GeoAddress.empty)
        draft.geoAddress!
            .format(LocalizationService.instance.currentLanguageCode)
      else ...[
        if (draft.communeCode != null) draft.communeCode!,
        if (draft.districtCode != null) draft.districtCode!,
        if (draft.cityCode != null) draft.cityCode!,
      ],
      if (draft.postalCode.isNotEmpty) 'Postal: ${draft.postalCode}',
    ].where((s) => s.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlight Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.08),
                scheme.secondary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.nameEn.isNotEmpty ? draft.nameEn : 'New Customer',
                      style: TextStyle(
                        fontSize: _fontSize(18),
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (draft.nameKh.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        draft.nameKh,
                        style: TextStyle(
                          fontSize: _fontSize(14),
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: needsCredit
                      ? Colors.amber.withValues(alpha: 0.15)
                      : colors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: needsCredit ? Colors.amber : colors.success,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      needsCredit ? Icons.schedule : Icons.check_circle,
                      size: 16,
                      color:
                          needsCredit ? Colors.amber.shade900 : colors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      needsCredit
                          ? 'Credit Approval Required'
                          : 'Ready for SAP HQ',
                      style: TextStyle(
                        fontSize: _fontSize(12),
                        fontWeight: FontWeight.w800,
                        color: needsCredit
                            ? Colors.amber.shade900
                            : colors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _spacing(20)),

        // 2-Column Grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  previewCard(
                    title: 'add_customer.steps.identity'.tr,
                    icon: Icons.person_outline_rounded,
                    onEdit: () => _editFromPreview(0, BpFormStep.identity),
                    children: [
                      previewItem('Account Group', draft.grouping,
                          isCode: true),
                      previewItem(
                          'Title', draft.title.isNotEmpty ? draft.title : '—'),
                      previewItem('Name (EN)', draft.nameEn),
                      if (draft.name2.isNotEmpty)
                        previewItem('Trade Name (Name 2)', draft.name2),
                      previewItem('Name (KH)', draft.nameKh),
                      previewItem('Search Term', draft.searchTerm),
                      if (draft.coName.isNotEmpty)
                        previewItem('c/o Name', draft.coName),
                    ],
                  ),
                  SizedBox(height: _spacing(20)),
                  previewCard(
                    title: 'add_customer.steps.contact'.tr,
                    icon: Icons.phone_outlined,
                    onEdit: () => _editFromPreview(1, BpFormStep.contact),
                    children: [
                      previewItem('Mobile Phone', draft.mobilePhone),
                      previewItem(
                          'Telephone',
                          draft.telephoneSameAsMobile
                              ? 'Same as mobile'
                              : draft.telephone),
                      previewItem('Contact Person', draft.contactPersonName),
                      previewItem(
                          'Contact Role', draft.contactPersonRole ?? '—'),
                      previewItem('Language', draft.language),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: _spacing(20)),
            Expanded(
              child: Column(
                children: [
                  previewCard(
                    title: 'add_customer.steps.address'.tr,
                    icon: Icons.location_on_outlined,
                    onEdit: () => _editFromPreview(0, BpFormStep.address),
                    children: [
                      previewItem('Full Address', formattedAddress),
                      if (draft.geoFix != null)
                        previewItem(
                          'GPS Coordinates',
                          '${draft.geoFix!.latitude.toStringAsFixed(5)}, ${draft.geoFix!.longitude.toStringAsFixed(5)}',
                          isCode: true,
                        ),
                    ],
                  ),
                  SizedBox(height: _spacing(20)),
                  previewCard(
                    title: 'add_customer.steps.sales_terms'.tr,
                    icon: Icons.receipt_long_outlined,
                    onEdit: () => _editFromPreview(1, BpFormStep.salesTerms),
                    children: [
                      previewItem('Distribution Channel',
                          draft.distributionChannel ?? '—'),
                      previewItem('Division', draft.divisionCode ?? '—'),
                      previewItem('Customer Group', draft.customerGroup ?? '—'),
                      previewItem('Price Group', draft.priceGroup ?? '—'),
                      previewItem(
                          'Delivery Priority', draft.deliveryPriority ?? '—'),
                      previewItem(
                          'Shipping Condition', draft.shippingCondition ?? '—'),
                      previewItem('Payment Terms', draft.paymentTerm ?? '—'),
                      previewItem(
                          'Tax Class',
                          draft.taxClass == '1'
                              ? '1 - Taxable'
                              : '0 - Non-taxable'),
                      if (draft.taxClass == '1')
                        previewItem('VAT / TIN', draft.vatTin, isCode: true),
                    ],
                  ),
                  SizedBox(height: _spacing(20)),
                  previewCard(
                    title: 'add_customer.steps.documents'.tr,
                    icon: Icons.folder_shared_outlined,
                    onEdit: () => _editFromPreview(2, BpFormStep.documents),
                    children: [
                      previewItem('Attachments',
                          '${draft.attachments.length} attached (${draft.attachments.map((a) => a.kind).join(', ')})'),
                      if (draft.remark.isNotEmpty)
                        previewItem('Remarks', draft.remark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsStep(Map<String, String> errors) {
    final draft = _bloc.state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDocumentPhotosSection(draft, errors),
        _gap(),
        _label('add_customer.remark'.tr),
        _text(_remarkCtrl, 'add_customer.remark_hint'.tr,
            maxLines: 3, onChanged: (v) => _edit((d) => d.remark = v)),
        _gap(),
        _buildReviewSummary(draft),
      ],
    );
  }

  Future<void> _capturePhoto(String kind) async {
    // Camera only — the point is on-site evidence, not a gallery pick.
    // Compress to <=1600px / ~300KB before queueing; reps are on 3G.
    //
    // Resolved from the locator rather than constructed here, so the simulator
    // gets the stand-in and a device gets the lens without this screen knowing
    // which (`docs/feature/camera/README.md`).
    final XFile? photo = await sl<ImageCaptureService>().capture(
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (photo == null || !mounted) return;
    _bloc.add(AttachmentAdded(BpAttachment(kind: kind, localPath: photo.path)));
  }

  /// Collapsed recap with an edit pencil per step, so a typo does not mean
  /// walking back through five screens.
  Widget _buildReviewSummary(BpCustomerDraft draft) {
    Widget row(BpFormStep step, String value) => Padding(
          padding: EdgeInsets.symmetric(vertical: _spacing(6)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.titleKey.tr,
                      style: TextStyle(
                        fontSize: _fontSize(12),
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      value.isEmpty ? '—' : value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _fontSize(14),
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: _fontSize(18)),
                onPressed: () => _bloc.add(GoToStep(step)),
              ),
            ],
          ),
        );

    return Container(
      padding: EdgeInsets.all(widget.isTablet ? 20 : context.rw(14)),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'add_customer.review'.tr,
            style: TextStyle(
              fontSize: _fontSize(15),
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          row(BpFormStep.identity, '${draft.nameEn}\n${draft.nameKh}'),
          row(
            BpFormStep.address,
            [
              if (draft.street.isNotEmpty || draft.houseNumber.isNotEmpty)
                '${draft.houseNumber} ${draft.street}'.trim(),
              if (draft.geoAddress != null &&
                  draft.geoAddress != GeoAddress.empty)
                draft.geoAddress!
                    .format(LocalizationService.instance.currentLanguageCode)
              else ...[
                if (draft.districtCode != null) draft.districtCode!,
                if (draft.cityCode != null) draft.cityCode!,
              ],
              if (draft.postalCode.isNotEmpty) draft.postalCode,
            ].where((s) => s.isNotEmpty).join(', '),
          ),
          row(BpFormStep.contact, draft.mobilePhone),
          row(BpFormStep.salesTerms,
              '${draft.customerGroup ?? '—'} · ${draft.paymentTerm ?? '—'}'),
        ],
      ),
    );
  }

  // ===========================================================================
  // Navigation
  // ===========================================================================
  Widget _buildNavigationButtons(AddCustomerState state) {
    final isFirst = state.isFirstStep;
    final isLast = state.isLastStep;
    final needsCredit =
        SapMasterData.paymentTermNeedsCreditApproval(state.draft.paymentTerm);

    final btnPadding = widget.isTablet
        ? const EdgeInsets.symmetric(vertical: 22)
        : EdgeInsets.symmetric(vertical: context.rh(16));

    return Row(
      children: [
        if (!isFirst) ...[
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: btnPadding,
                side: BorderSide(color: context.appColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _bloc.add(const PreviousStep()),
              child: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
                size: _fontSize(22),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: btnPadding,
              backgroundColor: isLast
                  ? context.appColors.success
                  : Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: state.status == AddCustomerStatus.submitting ||
                    state.status == AddCustomerStatus.opening
                ? null
                : () => _bloc.add(state.serverDraftId == null
                    ? const OpenServerDraft()
                    : isLast
                        ? const SubmitToHQ()
                        : const NextStep()),
            child: Text(
              isLast
                  ? (needsCredit
                      ? 'add_customer.send_for_credit_approval'.tr
                      : 'add_customer.send_to_hq'.tr)
                  : 'add_customer.next_step'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLast
                    ? Colors.white
                    : Theme.of(context).colorScheme.surface,
                fontSize: _fontSize(15),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Shared field widgets — same look as before, now error-aware
  // ===========================================================================
  Widget _gap() => SizedBox(height: _spacing(18));

  Widget _label(String label, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: _fontSize(15),
              fontWeight: FontWeight.w700,
            ),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: _fontSize(15),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
      );

  Widget _errorText(String msg) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(
          msg,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: _fontSize(12),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  InputDecoration _decoration(String hint,
      {String? error, bool readOnly = false}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c),
        );

    return InputDecoration(
      hintText: hint,
      counterText: '',
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        fontSize: _fontSize(15),
      ),
      filled: true,
      fillColor: readOnly
          ? context.appColors.border.withValues(alpha: 0.2)
          : context.appColors.surfaceSoft,
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 20 : context.rw(14),
        vertical: widget.isTablet ? 20 : context.rh(14),
      ),
      enabledBorder: border(
        error != null
            ? Theme.of(context).colorScheme.error
            : context.appColors.border,
      ),
      focusedBorder: border(Theme.of(context).colorScheme.onSurface),
      errorBorder: border(Theme.of(context).colorScheme.error),
      focusedErrorBorder: border(Theme.of(context).colorScheme.error),
    );
  }

  Widget _text(
    TextEditingController controller,
    String hint, {
    String? error,
    int? maxLength,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: onChanged,
          inputFormatters: maxLength != null
              ? [LengthLimitingTextInputFormatter(maxLength)]
              : null,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: _fontSize(15),
          ),
          decoration: _decoration(hint, error: error),
        ),
        if (error != null) _errorText('add_customer.$error'.tr),
      ],
    );
  }

  Widget _phone(
    PhoneController controller,
    String hint, {
    String? error,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhoneFormField(
          controller: controller,
          onChanged: (p) => onChanged(p.international),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: _fontSize(15),
          ),
          countryButtonStyle: CountryButtonStyle(
            showFlag: true,
            showIsoCode: false,
            showDialCode: true,
            showDropdownIcon: true,
            textStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: _fontSize(15),
            ),
          ),
          validator: PhoneValidator.compose([
            PhoneValidator.required(context,
                errorText: 'add_customer.error.required'.tr),
            PhoneValidator.validMobile(context,
                errorText: 'add_customer.error.invalid_phone'.tr),
          ]),
          decoration: _decoration(hint, error: error),
        ),
        if (error != null) _errorText('add_customer.$error'.tr),
      ],
    );
  }

  Widget _dropdown({
    required String? value,
    required List<SapOption> options,
    required ValueChanged<String?> onChanged,
    String? hint,
    String? error,
    bool isDisabled = false,
    // Names only, by default.
    //
    // A rep picks "Battambang", not "0003". The code is a key SAP needs on the
    // wire, not something a person in a shop should have to read past —
    // prefixing every option with it made a 28-entry payment-term list read as
    // a wall of identifiers. The code is still what gets submitted; only the
    // label changes.
    bool showCode = false,
  }) {
    // The stored value is not guaranteed to be in the list.
    //
    // `DropdownButton` asserts that exactly one item matches its value, so an
    // unmatched code crashes the whole form — which is what a resumed draft
    // still carrying `T00` did after the payment terms were corrected against
    // the live catalogue. It also happens whenever SAP retires a code the app
    // has already stored.
    //
    // The value is kept and shown rather than silently dropped: blanking it
    // would leave the draft holding a code the rep can neither see nor
    // correct, and submit would carry it to SAP regardless. Surfacing it as
    // unrecognised lets them pick a real one.
    final resolved = [...options];
    final hasValue = value != null && value.isNotEmpty;
    if (hasValue && !resolved.any((o) => o.code == value)) {
      resolved.insert(
        0,
        SapOption(
            value, 'add_customer.unrecognised_code'.trParams({'code': value})),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 20 : context.rw(14),
            vertical: widget.isTablet ? 12 : context.rh(6),
          ),
          decoration: BoxDecoration(
            color: isDisabled
                ? context.appColors.border.withValues(alpha: 0.2)
                : context.appColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null
                  ? Theme.of(context).colorScheme.error
                  : context.appColors.border,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              // Empty string is not a selection; passing it would assert for
              // the same reason an unknown code does.
              value: hasValue ? value : null,
              isExpanded: true,
              hint: Text(
                hint ?? '',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                  fontSize: _fontSize(15),
                ),
              ),
              dropdownColor: context.appColors.surfaceSoft,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: _fontSize(24),
              ),
              items: isDisabled
                  ? null
                  : resolved
                      .map((o) => DropdownMenuItem<String>(
                            value: o.code,
                            child: Text(
                              showCode ? o.display : o.labelEn,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: _fontSize(15),
                              ),
                            ),
                          ))
                      .toList(),
              onChanged: isDisabled ? null : onChanged,
            ),
          ),
        ),
        if (error != null) _errorText('add_customer.$error'.tr),
      ],
    );
  }

  /// Two-option choices read better as a segmented control than a dropdown.
  Widget _segmented({
    required String? value,
    required List<SapOption> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        for (final o in options) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: context.rh(14)),
                decoration: BoxDecoration(
                  color: value == o.code
                      ? Theme.of(context).colorScheme.secondary
                      : context.appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appColors.border),
                ),
                child: Text(
                  o.labelEn,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: value == o.code
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: _fontSize(14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          if (o != options.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.rw(12),
          vertical: context.rh(10),
        ),
        decoration: BoxDecoration(
          color: context.appColors.border.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: _fontSize(16),
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _moreToggle({
    required bool expanded,
    required VoidCallback onTap,
    String? labelCollapsed,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: _fontSize(20),
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                expanded
                    ? 'add_customer.show_less'.tr
                    : (labelCollapsed ?? 'add_customer.more_details'.tr),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: _fontSize(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

  /// Moved here from the photos step — it belongs next to Payment Term,
  /// which is the field that actually triggers credit review.
  Widget _creditNotice() => Container(
        padding: EdgeInsets.all(widget.isTablet ? 20 : context.rw(14)),
        decoration: BoxDecoration(
          color: context.appColors.warningAlt.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.appColors.warningAlt.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined,
                color: context.appColors.warningAlt, size: _fontSize(22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'add_customer.credit_notice'.tr,
                style: TextStyle(
                  color: context.appColors.warningAlt,
                  fontSize: _fontSize(13),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _actionTile({
    required String label,
    required String sub,
    required IconData icon,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(widget.isTablet ? 22 : context.rw(14)),
        decoration: BoxDecoration(
          color: completed
              ? context.appColors.success.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: completed
                ? context.appColors.success
                : context.appColors.border,
            width: completed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: _fontSize(22),
              color: completed
                  ? context.appColors.success
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: _fontSize(15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontSize: _fontSize(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.add_a_photo_rounded,
              color: completed
                  ? context.appColors.success
                  : Theme.of(context).colorScheme.onSurface,
              size: _fontSize(22),
            ),
          ],
        ),
      ),
    );
  }
}
