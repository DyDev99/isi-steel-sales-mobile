import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';

class DocumentsSection extends StatelessWidget {
  const DocumentsSection(
      {super.key, required this.documents, required this.onAddDocument});
  final List<LeadDocument> documents;
  final void Function(DocumentType type, String name) onAddDocument;

  ({IconData icon, Color color}) _style(
          DocumentType type, ColorScheme scheme, AppThemeColors colors) =>
      switch (type) {
        DocumentType.businessLicense => (
            icon: Icons.picture_as_pdf_rounded,
            color: scheme.primary
          ),
        DocumentType.taxRegistration => (
            icon: Icons.picture_as_pdf_rounded,
            color: colors.warning
          ),
        DocumentType.ownerId => (icon: Icons.badge_rounded, color: colors.info),
        DocumentType.storefrontPhoto => (
            icon: Icons.storefront_rounded,
            color: scheme.secondary
          ),
        DocumentType.warehousePhoto => (
            icon: Icons.warehouse_rounded,
            color: scheme.secondary
          ),
        DocumentType.other => (
            icon: Icons.insert_drive_file_rounded,
            color: colors.textSecondary
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
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (documents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('leads.no_documents'.tr,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          )
        else
          ...documents.map((doc) {
            final s = _style(doc.type, scheme, colors);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
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
                            style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text(_formatDate(doc.uploadedDate),
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 11)),
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
            icon: Icon(Icons.upload_file_rounded,
                size: 18, color: scheme.primary),
            label: Text('leads.upload_document'.tr,
                style: TextStyle(color: scheme.primary)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: scheme.primary),
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
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceSoft,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('leads.add_document_demo'.tr,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final option in _mockOptions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_style(option.$1, scheme, colors).icon,
                      color: _style(option.$1, scheme, colors).color),
                  title: Text(option.$2,
                      style:
                          TextStyle(color: colors.textPrimary, fontSize: 13.5)),
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
