// Custom UI Component: sequential product-attribute filter row
// (Size -> Length -> Mesh Size -> Quality) plus Unit/Quantity selector for
// the item about to be added to the cart.
//
// Filter order (matches the numbering used across the Quotation Builder):
//   1. Category      -> CategoryQuickFilterRow (outside this widget)
//   2. Size
//   3. Length
//   4. Mesh Size
//   5. Quality
//
// Each dropdown includes an 'All' sentinel so a step can be skipped without
// blocking the ones after it - selecting Size alone still narrows the list,
// selecting Size + Length narrows it further, etc. ("live narrowing").
import 'package:flutter/material.dart';

/// Sentinel value meaning "this filter step is not applied".
const String kAnyAttributeValue = 'All';

class SizeAndQualityContainerRow extends StatelessWidget {
  const SizeAndQualityContainerRow({
    super.key,
    required this.selectedSize,
    required this.selectedQuality,
    required this.selectedMeshSize,
    required this.selectedLength,
    required this.selectedUnit, // 'Pc' or 'Ton'
    required this.quantity,
    required this.sizeOptions,
    required this.lengthOptions,
    required this.meshSizeOptions,
    required this.qualityOptions,
    required this.onSizeChanged,
    required this.onQualityChanged,
    required this.onMeshSizeChanged,
    required this.onLengthChanged,
    required this.onUnitChanged,
    required this.onQuantityChanged,
  });

  final String selectedSize;
  final String selectedQuality;
  final String selectedMeshSize;
  final String selectedLength;
  final String selectedUnit;
  final int quantity;

  /// Option lists come from whatever's actually in the catalog (see
  /// `QuotationBuilderScreen`'s `_distinct...Options` helpers) - each should
  /// already start with `kAnyAttributeValue` for the "All" choice.
  final List<String> sizeOptions;
  final List<String> lengthOptions;
  final List<String> meshSizeOptions;
  final List<String> qualityOptions;

  final ValueChanged<String> onSizeChanged;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<String> onMeshSizeChanged;
  final ValueChanged<String> onLengthChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<int> onQuantityChanged;

  Widget _buildDropdownField({
    required int step,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    // Defensive: if a stale/unknown value is passed in (e.g. state carried
    // over from a different product line), fall back to "All" instead of
    // throwing when DropdownButton can't find a matching item.
    final safeValue = items.contains(value) ? value : kAnyAttributeValue;
    final isFiltered = safeValue != kAnyAttributeValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepBadge(step: step, active: isFiltered),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isFiltered
                    ? const Color(0xFF0F2C7F)
                    : const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF0F2C7F)),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155)),
              items: items.map<DropdownMenuItem<String>>((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val == kAnyAttributeValue ? 'All' : val),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Size (filter 2) & Length (filter 3)
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  step: 2,
                  label: 'Size',
                  value: selectedSize,
                  items: sizeOptions,
                  onChanged: onSizeChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdownField(
                  step: 3,
                  label: 'Length',
                  value: selectedLength,
                  items: lengthOptions,
                  onChanged: onLengthChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Mesh Size (filter 4) & Quality (filter 5)
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  step: 4,
                  label: 'Mesh Size',
                  value: selectedMeshSize,
                  items: meshSizeOptions,
                  onChanged: onMeshSizeChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdownField(
                  step: 5,
                  label: 'Quality',
                  value: selectedQuality,
                  items: qualityOptions,
                  onChanged: onQualityChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider to separate filter specs from the transactional selectors
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 14),

          // Row 3: Unit Selection (Pc/Ton) & Quantity Counter Selector
          // (not part of the filter sequence - applies to the item being
          // added to the cart once the user has found it via the filters).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: ['Pc', 'Ton'].map((unit) {
                        final isSelected = selectedUnit == unit;
                        return GestureDetector(
                          onTap: () => onUnitChanged(unit),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 65,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F2C7F)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1
                              ? () => onQuantityChanged(quantity - 1)
                              : null,
                          icon: const Icon(Icons.remove_rounded, size: 18),
                          color: const Color(0xFF0F2C7F),
                          disabledColor: const Color(0xFFCBD5E1),
                        ),
                        Container(
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(minWidth: 40),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onQuantityChanged(quantity + 1),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          color: const Color(0xFF0F2C7F),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small numbered circle showing which step in the filter sequence this
/// dropdown represents (2-5; step 1 is the category row above this widget).
/// Fills in violet once that step has an actual (non-"All") value selected.
class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.step, required this.active});
  final int step;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF0F2C7F) : Colors.white,
        border: Border.all(
            color: active ? const Color(0xFF0F2C7F) : const Color(0xFFCBD5E1)),
      ),
      child: Text(
        '$step',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: active ? Colors.white : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
