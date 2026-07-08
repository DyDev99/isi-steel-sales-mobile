
// Custom UI Component: Combined Grid Container representing Size, Quality, Mesh Size, and Length
import 'package:flutter/material.dart';

class SizeAndQualityContainerRow extends StatelessWidget {
  const SizeAndQualityContainerRow({
    required this.selectedSize,
    required this.selectedQuality,
    required this.selectedMeshSize,
    required this.selectedLength,
    required this.onSizeChanged,
    required this.onQualityChanged,
    required this.onMeshSizeChanged,
    required this.onLengthChanged,
  });

  final String selectedSize;
  final String selectedQuality;
  final String selectedMeshSize;
  final String selectedLength;
  
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<String> onMeshSizeChanged;
  final ValueChanged<String> onLengthChanged;

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.bold, 
            color: Color(0xFF1E293B),
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42, // Set fixed standard constraint to match perfectly
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true, // Forces text components to center vertically without padding shift
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F2C7F)),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155), fontFamily: 'Roboto'),
              items: items.map<DropdownMenuItem<String>>((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val));
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
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Size',
                  value: selectedSize,
                  items: ['0.35 mm', '0.40 mm', '0.45 mm', '0.50 mm'],
                  onChanged: onSizeChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdownField(
                  label: 'Quality',
                  value: selectedQuality,
                  items: ['Standard', 'Premium Zacs', 'High-Strength'],
                  onChanged: onQualityChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Mesh Size',
                  value: selectedMeshSize,
                  items: ['50x50 mm', '100x100 mm', '150x150 mm', '200x200 mm'],
                  onChanged: onMeshSizeChanged,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDropdownField(
                  label: 'Length',
                  value: selectedLength,
                  items: ['1.2 m', '2.4 m', '3.0 m', '6.0 m'],
                  onChanged: onLengthChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
