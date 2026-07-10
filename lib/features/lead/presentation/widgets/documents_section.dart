import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';

class DocumentsSection extends StatelessWidget {
  const DocumentsSection(
      {super.key, required this.documents, required this.onAddDocument});
  final List<LeadDocument> documents;
  final void Function(DocumentType type, String name) onAddDocument;

  ({IconData icon, Color color}) _style(DocumentType type) => switch (type) {
        DocumentType.businessLicense => (
            icon: Icons.picture_as_pdf_rounded,
            color: Vibe.violet
          ),
        DocumentType.taxRegistration => (
            icon: Icons.picture_as_pdf_rounded,
            color: Vibe.amber
          ),
        DocumentType.ownerId => (icon: Icons.badge_rounded, color: Vibe.mint),
        DocumentType.storefrontPhoto => (
            icon: Icons.storefront_rounded,
            color: Vibe.pink
          ),
        DocumentType.warehousePhoto => (
            icon: Icons.warehouse_rounded,
            color: Vibe.pink
          ),
        DocumentType.other => (
            icon: Icons.insert_drive_file_rounded,
            color: Vibe.muted
          ),
      };

  static const _mockOptions = <(DocumentType, String)>[
    (DocumentType.businessLicense, 'Business License.pdf'),
    (DocumentType.taxRegistration, 'Tax Registration.pdf'),
    (DocumentType.ownerId, 'Owner ID.pdf'),
    (DocumentType.storefrontPhoto, 'Storefront Photo.jpg'),
    (DocumentType.warehousePhoto, 'Warehouse Photo.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (documents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No documents yet',
                style: TextStyle(color: Vibe.muted, fontSize: 12.5)),
          )
        else
          ...documents.map((doc) {
            final s = _style(doc.type);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Vibe.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Vibe.stroke),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(s.icon, size: 17, color: s.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Vibe.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text(_formatDate(doc.uploadedDate),
                            style: const TextStyle(
                                color: Vibe.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddSheet(context),
            icon: const Icon(Icons.upload_file_rounded,
                size: 18, color: Vibe.violet),
            label: const Text('Upload document',
                style: TextStyle(color: Vibe.violet)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Vibe.violet),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Vibe.bgSoft,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add a document (demo)',
                  style: TextStyle(
                      color: Vibe.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final option in _mockOptions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_style(option.$1).icon,
                      color: _style(option.$1).color),
                  title: Text(option.$2,
                      style: const TextStyle(color: Vibe.text, fontSize: 13.5)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onAddDocument(option.$1, option.$2);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
