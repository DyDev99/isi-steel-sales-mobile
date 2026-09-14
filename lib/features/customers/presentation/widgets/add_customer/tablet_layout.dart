part of '../add_customer_bottom_sheet.dart';

extension TabletLayoutExtension on _AddCustomerBottomSheetState {
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
            onPressed: state.isBusy ? null : () => _handleTabletNext(state),
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
                      previewItem('Search Term 1', draft.searchTerm),
                      if (draft.searchTerm2.isNotEmpty)
                        previewItem('Search Term 2', draft.searchTerm2),
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

}
