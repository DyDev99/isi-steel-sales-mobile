// Rebuilt Modern UX/UI Discount Component with full layout stability
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscountSection extends StatefulWidget {
  const DiscountSection({
    super.key,
    required this.selectedDiscount,
    required this.onDiscountSelected,
  });

  final int selectedDiscount;
  final ValueChanged<int> onDiscountSelected;

  @override
  State<DiscountSection> createState() => _DiscountSectionState();
}

class _DiscountSectionState extends State<DiscountSection> {
  final List<int> _presets = [0, 5,10, 15, 20];
  final TextEditingController _customController = TextEditingController();
  bool _isCustomActive = false;

  @override
  void initState() {
    super.initState();
    if (!_presets.contains(widget.selectedDiscount)) {
      _isCustomActive = true;
      _customController.text = widget.selectedDiscount.toString();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _handlePresetTap(int percent) {
    setState(() {
      _isCustomActive = false;
      _customController.clear();
    });
    widget.onDiscountSelected(percent);
  }

  void _handleCustomTap() {
    setState(() {
      _isCustomActive = true;
    });
    final customVal = int.tryParse(_customController.text) ?? 0;
    widget.onDiscountSelected(customVal);
  }

  void _onCustomValuesChanged(String value) {
    final parsed = int.tryParse(value) ?? 0;
    if (parsed > 100) {
      _customController.text = '100';
      _customController.selection = TextSelection.fromPosition(const TextPosition(offset: 3));
      widget.onDiscountSelected(100);
    } else {
      widget.onDiscountSelected(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discount', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B), fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._presets.map((percent) {
              final isSelected = !_isCustomActive && widget.selectedDiscount == percent;
              return InkWell(
                onTap: () => _handlePresetTap(percent),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F2C7F) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isSelected ? const Color(0xFF0F2C7F) : const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        percent == 0 ? '0% (None)' : '$percent%',
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            InkWell(
              onTap: _handleCustomTap,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: _isCustomActive ? const Color(0xFF0F2C7F) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _isCustomActive ? const Color(0xFF0F2C7F) : const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isCustomActive) ...[
                      const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      'Custom',
                      style: TextStyle(
                        color: _isCustomActive ? Colors.white : const Color(0xFF334155),
                        fontWeight: _isCustomActive ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_isCustomActive) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 140,
            height: 42, // Uniform alignment with inputs
            child: TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onChanged: _onCustomValuesChanged,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                hintText: 'Enter value',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
                suffixText: '%',
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2C7F)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0F2C7F), width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}