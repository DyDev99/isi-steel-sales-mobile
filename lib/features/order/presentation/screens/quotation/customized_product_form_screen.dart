import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:isi_steel_sales_mobile/features/order/domain/entities/data_domain.dart'
    show CustomizationMeasurement;
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/product_customization_spec.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/customization/customization_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/customization/customization_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/drawing_upload_component.dart';

/// Category-aware product customization. Which measurement fields appear
/// (length / width / height / thickness / diameter) is driven by the base
/// product's category via [ProductCustomizationSpec]; every product can also
/// override its surface appearance/finish and attach a technical drawing.
class CustomizedProductFormScreen extends StatelessWidget {
  final Product baseProduct;
  final String? leadId;
  final String? customerId;

  const CustomizedProductFormScreen({
    super.key,
    required this.baseProduct,
    this.leadId,
    this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomizationCubit()
        ..updateUnit(baseProduct.unit)
        ..seedMeasurements(_prefill(baseProduct)),
      child: _CustomizedProductFormView(
        baseProduct: baseProduct,
        leadId: leadId,
        customerId: customerId,
      ),
    );
  }

  static CustomizationMeasurement _prefill(Product product) {
    var m = const CustomizationMeasurement();
    for (final field in ProductCustomizationSpec.fieldsFor(product)) {
      final value = ProductCustomizationSpec.prefillMm(product, field);
      if (value != null) {
        m = ProductCustomizationSpec.withField(m, field, value);
      }
    }
    return m;
  }
}

class _CustomizedProductFormView extends StatefulWidget {
  final Product baseProduct;
  final String? leadId;
  final String? customerId;

  const _CustomizedProductFormView({
    required this.baseProduct,
    this.leadId,
    this.customerId,
  });

  @override
  State<_CustomizedProductFormView> createState() =>
      __CustomizedProductFormViewState();
}

class __CustomizedProductFormViewState
    extends State<_CustomizedProductFormView> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _appearanceController = TextEditingController();

  late final List<CustomizationField> _fields;
  late final Map<CustomizationField, TextEditingController> _numericControllers;

  @override
  void initState() {
    super.initState();
    _fields = ProductCustomizationSpec.fieldsFor(widget.baseProduct);
    final seeded = CustomizedProductFormScreen._prefill(widget.baseProduct);
    _numericControllers = {
      for (final field in _fields)
        if (field != CustomizationField.appearance)
          field: TextEditingController(
            text: _formatPrefill(
                ProductCustomizationSpec.measurementValue(seeded, field)),
          ),
    };
  }

  static String _formatPrefill(double? value) {
    if (value == null || value == 0) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _appearanceController.dispose();
    for (final c in _numericControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submitForm(CustomizationDataState customization) {
    context.read<CartCubit>().addCustomProduct(
          widget.baseProduct,
          quantity: customization.quantity,
          unit: customization.selectedUnit,
          measurements: customization.measurements.isEmpty
              ? null
              : customization.measurements,
          appearance: customization.appearance.trim().isEmpty
              ? null
              : customization.appearance.trim(),
          drawingImagePath: customization.drawingImagePath,
          customizationDescription:
              customization.notes.trim().isEmpty ? null : customization.notes,
          leadId: widget.leadId,
          customerId: widget.customerId,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customized product added to quotation!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Product ✏️'),
        centerTitle: false,
      ),
      body: BlocConsumer<CustomizationCubit, CustomizationState>(
        listener: (context, state) {
          if (state is CustomizationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<CustomizationCubit>();
          final dataState = state is CustomizationDataState
              ? state
              : const CustomizationDataState();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBaseProductHeader(theme, colorScheme),
                        const SizedBox(height: 20),

                        _SectionTitle(title: '1. TECHNICAL DRAWING / SKETCH'),
                        const SizedBox(height: 8),
                        DrawingUploadComponent(
                          imagePath: dataState.drawingImagePath,
                          onPickImage: (src) => cubit.captureOrPickDrawing(src),
                          onRemoveImage: () => cubit.removeDrawing(),
                        ),
                        const SizedBox(height: 24),

                        _SectionTitle(
                            title: '2. SPECIFICATIONS FOR '
                                '${widget.baseProduct.subCategory.toUpperCase()}'),
                        const SizedBox(height: 12),
                        _buildMeasurementFields(cubit),

                        if (_hasAppearance) ...[
                          const SizedBox(height: 20),
                          _SectionTitle(title: '3. APPEARANCE / FINISH'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _appearanceController,
                            onChanged: cubit.updateAppearance,
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Galvanized, Powder-coated black, Raw/mill finish...',
                              prefixIcon: const Icon(Icons.palette_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        _SectionTitle(
                            title:
                                '${_hasAppearance ? '4' : '3'}. ADDITIONAL INSTRUCTIONS'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          onChanged: cubit.updateNotes,
                          decoration: InputDecoration(
                            hintText:
                                'Specify steel grade, bending angles, or special instructions...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border:
                      Border(top: BorderSide(color: colorScheme.outlineVariant)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _submitForm(dataState),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          label: const Text('Add Customized Item',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool get _hasAppearance => _fields.contains(CustomizationField.appearance);

  Widget _buildMeasurementFields(CustomizationCubit cubit) {
    final numericFields = _fields
        .where((f) => f != CustomizationField.appearance)
        .toList();

    // Two-per-row grid.
    final rows = <Widget>[];
    for (var i = 0; i < numericFields.length; i += 2) {
      final left = numericFields[i];
      final right =
          i + 1 < numericFields.length ? numericFields[i + 1] : null;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: _measurementField(left, cubit)),
            const SizedBox(width: 12),
            Expanded(
              child: right == null
                  ? const SizedBox.shrink()
                  : _measurementField(right, cubit),
            ),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }

  Widget _measurementField(CustomizationField field, CustomizationCubit cubit) {
    return _MeasurementField(
      label: _fieldLabel(field),
      controller: _numericControllers[field]!,
      onChanged: (v) {
        final parsed = double.tryParse(v);
        switch (field) {
          case CustomizationField.length:
            cubit.updateMeasurements(lengthMm: parsed);
          case CustomizationField.width:
            cubit.updateMeasurements(widthMm: parsed);
          case CustomizationField.height:
            cubit.updateMeasurements(heightMm: parsed);
          case CustomizationField.thickness:
            cubit.updateMeasurements(thicknessMm: parsed);
          case CustomizationField.diameter:
            cubit.updateMeasurements(diameterMm: parsed);
          case CustomizationField.appearance:
            break;
        }
      },
    );
  }

  String _fieldLabel(CustomizationField field) => switch (field) {
        CustomizationField.length => 'Length (mm)',
        CustomizationField.width => 'Width (mm)',
        CustomizationField.height => 'Height (mm)',
        CustomizationField.thickness => 'Thickness (mm)',
        CustomizationField.diameter => 'Diameter Ø (mm)',
        CustomizationField.appearance => 'Appearance',
      };

  Widget _buildBaseProductHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.baseProduct.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Code: ${widget.baseProduct.code} • Base Unit: ${widget.baseProduct.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _MeasurementField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
