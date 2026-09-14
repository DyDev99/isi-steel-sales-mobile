part of '../add_customer_bottom_sheet.dart';

extension ContactStepExtension on _AddCustomerBottomSheetState {
  // ===========================================================================
  // STEP 3 — Contact
  // ===========================================================================
  Widget _buildContactStep(Map<String, String> errors) {
    final draft = _bloc.state.draft;

    final telephoneSwitchCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildIconBox(Icons.phone_outlined, size: 28, iconSize: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _cardLabel('add_customer.telephone'.tr, required: true, fontSize: 11),
                Text(
                  'add_customer.same_as_mobile'.tr,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: draft.telephoneSameAsMobile,
              activeTrackColor: Theme.of(context).colorScheme.primary,
              onChanged: (v) => _edit((d) => d.telephoneSameAsMobile = v),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _twoCol(
          _text(
            _contactNameCtrl,
            'add_customer.contact_name_hint'.tr,
            label: 'add_customer.contact_name'.tr,
            icon: Icons.person_rounded,
            required: true,
            compact: true,
            error: errors['contactPersonName'],
            onChanged: (v) => _edit((d) => d.contactPersonName = v),
          ),
          _dropdown(
            label: 'add_customer.role'.tr,
            icon: Icons.work_outline_rounded,
            required: true,
            compact: true,
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
        ),
        _gap(8),
        _phone(
          _mobileCtrl,
          'add_customer.phone_hint'.tr,
          label: 'add_customer.mobile_phone'.tr,
          icon: Icons.phone_android_rounded,
          required: true,
          compact: true,
          error: errors['mobilePhone'],
          onChanged: (v) => _edit((d) => d.mobilePhone = v),
        ),
        _gap(8),
        _twoCol(
          telephoneSwitchCard,
          _dropdown(
            label: 'add_customer.language'.tr,
            icon: Icons.language_rounded,
            compact: true,
            value: draft.language.isEmpty
                ? SapBpConst.defaultLanguage
                : draft.language,
            options: SapMasterData.language,
            showCode: false,
            onChanged: (v) => _edit((d) => d.language = v!),
          ),
        ),
        if (!draft.telephoneSameAsMobile) ...[
          _gap(8),
          _phone(
            _telCtrl,
            'add_customer.phone_hint'.tr,
            label: 'add_customer.telephone'.tr,
            icon: Icons.call_outlined,
            required: true,
            compact: true,
            error: errors['telephone'],
            onChanged: (v) => _edit((d) => d.telephone = v),
          ),
        ],
      ],
    );
  }

}
