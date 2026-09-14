part of '../add_customer_bottom_sheet.dart';

extension DocumentsStepExtension on _AddCustomerBottomSheetState {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
    );
  }

  Widget _buildDocumentPhotosSection(
      BpCustomerDraft draft, Map<String, String> errors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _twoCol(
          _buildPhotoTile('outlet_front', 'add_customer.photo_front',
              Icons.storefront_rounded, draft, errors),
          _buildPhotoTile('outlet_inside', 'add_customer.photo_inside',
              Icons.store_rounded, draft, errors),
        ),
        _gap(8),
        _twoCol(
          _buildPhotoTile('id_card', 'add_customer.photo_id', Icons.badge_rounded,
              draft, errors),
          _buildPhotoTile('patent_tax', 'add_customer.photo_patent',
              Icons.receipt_long_rounded, draft, errors,
              required: false),
        ),
        if (draft.taxClass == '1') ...[
          _gap(8),
          _buildPhotoTile('vat_cert', 'add_customer.photo_vat',
              Icons.verified_rounded, draft, errors),
        ],
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


  Widget _buildDocumentsStep(Map<String, String> errors) {
    final draft = _bloc.state.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDocumentPhotosSection(draft, errors),
        _gap(8),
        _text(
          _remarkCtrl,
          'add_customer.remark_hint'.tr,
          label: 'add_customer.remark'.tr,
          icon: Icons.notes_rounded,
          compact: true,
          maxLines: 2,
          onChanged: (v) => _edit((d) => d.remark = v),
        ),
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
}
