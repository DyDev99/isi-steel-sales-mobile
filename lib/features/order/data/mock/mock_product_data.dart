import 'dart:math';

/// Deterministic generator for the demo product catalog.
///
/// Produces plain JSON-ready maps (not domain entities) — its only job is to
/// build the payload written to `assets/mock/products.json` by
/// `tool/generate_mock_products.dart`, and to act as `MockProductRemoteDataSource`'s
/// in-memory fallback if that asset is ever missing.
///
/// Composed from small single-purpose generators, mirroring how a real ERP
/// catalog is actually assembled — `ProductGenerator` crosses category leaves
/// x grade x brand into ~300 non-sellable "families" (e.g. "ISI Steel SD390
/// Rebar"), `VariantGenerator` expands each family into 20-100 sellable SKUs
/// (sizes/diameters/lengths), `WarehouseGenerator` assigns each SKU to a
/// handful of warehouses, `PricingGenerator` derives every price tier from a
/// base price, and `PromotionGenerator` decides which rows carry a
/// promotion. Swapping any one of these for a smarter version (or a real
/// SAP-fed pipeline) doesn't touch the others.
class MockProductData {
  MockProductData._();

  static Map<String, dynamic> generate({int seed = 7}) {
    final rand = Random(seed);
    final families = ProductGenerator.buildFamilies();
    final warehouses = WarehouseGenerator.warehouses;

    final products = <Map<String, dynamic>>[];
    var materialSeq = 1;

    for (final family in families) {
      final variants = VariantGenerator.buildVariants(family);
      for (final variant in variants) {
        final code = '${family.codePrefix}-${variant.sizeLabel}';
        final materialCode = 'MAT-${materialSeq.toString().padLeft(6, '0')}';
        materialSeq++;
        final assignedWarehouses = WarehouseGenerator.assignFor(warehouses, rand);

        for (final wh in assignedWarehouses) {
          final id = '$code-${wh.code}';
          final pricing = PricingGenerator.forVariant(family, variant, rand);
          final promo = PromotionGenerator.maybeApply(pricing, rand);
          final stockQty = (50 + rand.nextInt(2950)).toDouble();
          final reserved = stockQty * (rand.nextDouble() * 0.15);
          final daysAgo = rand.nextInt(60);

          products.add({
            'id': id,
            'familyId': family.familyId,
            'familyName': family.familyName,
            'code': code,
            'sku': id,
            'materialCode': materialCode,
            'barcode': _barcodeFor(id),
            'name': '${family.namePrefix} ${variant.sizeLabel}',
            'description': '${family.namePrefix} ${variant.sizeLabel}, ${family.grade} grade, '
                '${family.brand}, ${family.material}.',
            'categoryId': family.categoryId,
            'subCategory': family.grade,
            'brand': family.brand,
            'grade': family.grade,
            'material': family.material,
            'size': variant.sizeLabel,
            'diameter': variant.diameter,
            'thickness': variant.thickness,
            'length': variant.length,
            'width': variant.width,
            'height': variant.height,
            'weight': variant.weight,
            'unit': family.unit,
            'warehouseCode': wh.code,
            'territory': wh.province,
            'businessUnit': family.businessUnit,
            'imageUrl': 'https://picsum.photos/seed/${Uri.encodeComponent(code)}/400/300',
            'isMto': family.isMtoEligible && variant.mtoHint,
            'status': _statusFor(rand),
            'updatedAt': DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String(),
            'deleted': false,
            'minStock': 50.0,
            'maxStock': 3000.0,
            'stockQuantity': double.parse(stockQty.toStringAsFixed(0)),
            'reservedQuantity': double.parse(reserved.toStringAsFixed(0)),
            'pricing': {
              'costPrice': pricing.costPrice,
              'standardPrice': pricing.standardPrice,
              'wholesalePrice': pricing.wholesalePrice,
              'dealerPrice': pricing.dealerPrice,
              'vipPrice': pricing.vipPrice,
              'creditPrice': pricing.creditPrice,
              'cashPrice': pricing.cashPrice,
              'currency': 'USD',
              'promotionPrice': promo?.promotionPrice,
              'promotionType': promo?.type.name,
              'promotionLabel': promo?.label,
            },
          });
        }
      }
    }

    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'categories': CategoryGenerator.categories,
      'products': products,
    };
  }

  static String _barcodeFor(String id) {
    final hash = id.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7FFFFFFF);
    return (8800000000000 + (hash % 999999999)).toString().padLeft(13, '0');
  }

  static String _statusFor(Random rand) {
    final roll = rand.nextDouble();
    if (roll < 0.93) return 'active';
    if (roll < 0.98) return 'inactive';
    return 'discontinued';
  }
}

/// Category taxonomy — Steel/Structural/Flat/Pipe (as originally specified)
/// plus Hardware and Construction.
class CategoryGenerator {
  CategoryGenerator._();

  static final List<Map<String, dynamic>> categories = [
    {'id': 'cat_steel', 'parentId': null, 'name': 'Steel', 'sortOrder': 0},
    {'id': 'cat_steel_rebar', 'parentId': 'cat_steel', 'name': 'Rebar', 'sortOrder': 0},
    {'id': 'cat_steel_wire_rod', 'parentId': 'cat_steel', 'name': 'Wire Rod', 'sortOrder': 1},
    {'id': 'cat_steel_billet', 'parentId': 'cat_steel', 'name': 'Billet', 'sortOrder': 2},
    {'id': 'cat_structural', 'parentId': null, 'name': 'Structural Steel', 'sortOrder': 1},
    {'id': 'cat_structural_hbeam', 'parentId': 'cat_structural', 'name': 'H Beam', 'sortOrder': 0},
    {'id': 'cat_structural_ibeam', 'parentId': 'cat_structural', 'name': 'I Beam', 'sortOrder': 1},
    {'id': 'cat_structural_cchannel', 'parentId': 'cat_structural', 'name': 'C Channel', 'sortOrder': 2},
    {'id': 'cat_structural_anglebar', 'parentId': 'cat_structural', 'name': 'Angle Bar', 'sortOrder': 3},
    {'id': 'cat_flat', 'parentId': null, 'name': 'Flat Steel', 'sortOrder': 2},
    {'id': 'cat_flat_plate', 'parentId': 'cat_flat', 'name': 'Plate', 'sortOrder': 0},
    {'id': 'cat_flat_coil', 'parentId': 'cat_flat', 'name': 'Coil', 'sortOrder': 1},
    {'id': 'cat_flat_sheet', 'parentId': 'cat_flat', 'name': 'Sheet', 'sortOrder': 2},
    {'id': 'cat_pipe', 'parentId': null, 'name': 'Pipe', 'sortOrder': 3},
    {'id': 'cat_pipe_gi', 'parentId': 'cat_pipe', 'name': 'GI Pipe', 'sortOrder': 0},
    {'id': 'cat_pipe_black', 'parentId': 'cat_pipe', 'name': 'Black Pipe', 'sortOrder': 1},
    {'id': 'cat_pipe_stainless', 'parentId': 'cat_pipe', 'name': 'Stainless Pipe', 'sortOrder': 2},
    {'id': 'cat_hardware', 'parentId': null, 'name': 'Hardware', 'sortOrder': 4},
    {'id': 'cat_hardware_nuts', 'parentId': 'cat_hardware', 'name': 'Nuts', 'sortOrder': 0},
    {'id': 'cat_hardware_bolts', 'parentId': 'cat_hardware', 'name': 'Bolts', 'sortOrder': 1},
    {'id': 'cat_hardware_washers', 'parentId': 'cat_hardware', 'name': 'Washers', 'sortOrder': 2},
    {'id': 'cat_construction', 'parentId': null, 'name': 'Construction', 'sortOrder': 5},
    {'id': 'cat_construction_cement', 'parentId': 'cat_construction', 'name': 'Cement', 'sortOrder': 0},
    {'id': 'cat_construction_nails', 'parentId': 'cat_construction', 'name': 'Nails', 'sortOrder': 1},
    {'id': 'cat_construction_wire_mesh', 'parentId': 'cat_construction', 'name': 'Wire Mesh', 'sortOrder': 2},
  ];
}

/// A non-sellable "product family" (category leaf x grade x brand) — never
/// persisted on its own, just the grouping [Product.familyId] rows share.
class ProductFamily {
  const ProductFamily({
    required this.familyId,
    required this.familyName,
    required this.codePrefix,
    required this.categoryId,
    required this.leafKey,
    required this.namePrefix,
    required this.grade,
    required this.brand,
    required this.material,
    required this.unit,
    required this.businessUnit,
    required this.basePrice,
    required this.isMtoEligible,
  });

  final String familyId;
  final String familyName;
  final String codePrefix;
  final String categoryId;
  final String leafKey;
  final String namePrefix;
  final String grade;
  final String brand;
  final String material;
  final String unit;
  final String businessUnit;
  final double basePrice;
  final bool isMtoEligible;
}

class _LeafSpec {
  const _LeafSpec({
    required this.key,
    required this.categoryId,
    required this.namePrefix,
    required this.grades,
    required this.material,
    required this.unit,
    required this.businessUnit,
    required this.basePrice,
    this.isMtoEligible = false,
  });

  final String key;
  final String categoryId;
  final String namePrefix;
  final List<String> grades;
  final String material;
  final String unit;
  final String businessUnit;
  final double basePrice;
  final bool isMtoEligible;
}

/// Crosses each category leaf's grade list with every brand to produce the
/// demo's ~300 base product families.
class ProductGenerator {
  ProductGenerator._();

  static const brands = ['ISI Steel', 'KIC Group', 'Mesan Steel', 'Cambo Steel', 'Angkor Metal', 'Sena Metal'];

  static const _leaves = <_LeafSpec>[
    _LeafSpec(key: 'rebar', categoryId: 'cat_steel_rebar', namePrefix: 'Rebar',
        grades: ['SD295', 'SD390', 'SD490'], material: 'Carbon Steel', unit: 'PCS',
        businessUnit: 'Construction Steel', basePrice: 6.5, isMtoEligible: true),
    _LeafSpec(key: 'wireRod', categoryId: 'cat_steel_wire_rod', namePrefix: 'Wire Rod',
        grades: ['SAE1006', 'SAE1008', 'SAE1010'], material: 'Low Carbon Steel', unit: 'COIL',
        businessUnit: 'Construction Steel', basePrice: 5.5),
    _LeafSpec(key: 'billet', categoryId: 'cat_steel_billet', namePrefix: 'Billet',
        grades: ['Q235', 'Q275', '5SP'], material: 'Carbon Steel', unit: 'PCS',
        businessUnit: 'Construction Steel', basePrice: 380, isMtoEligible: true),
    _LeafSpec(key: 'hbeam', categoryId: 'cat_structural_hbeam', namePrefix: 'H Beam',
        grades: ['SS400', 'Q235', 'A572'], material: 'Structural Steel', unit: 'PCS',
        businessUnit: 'Structural Steel', basePrice: 320, isMtoEligible: true),
    _LeafSpec(key: 'ibeam', categoryId: 'cat_structural_ibeam', namePrefix: 'I Beam',
        grades: ['SS400', 'Q235', 'A572'], material: 'Structural Steel', unit: 'PCS',
        businessUnit: 'Structural Steel', basePrice: 300),
    _LeafSpec(key: 'cchannel', categoryId: 'cat_structural_cchannel', namePrefix: 'C Channel',
        grades: ['SS400', 'Q235', 'A36'], material: 'Structural Steel', unit: 'PCS',
        businessUnit: 'Structural Steel', basePrice: 70),
    _LeafSpec(key: 'anglebar', categoryId: 'cat_structural_anglebar', namePrefix: 'Angle Bar',
        grades: ['SS400', 'Q235', 'A36'], material: 'Structural Steel', unit: 'PCS',
        businessUnit: 'Structural Steel', basePrice: 20),
    _LeafSpec(key: 'plate', categoryId: 'cat_flat_plate', namePrefix: 'Steel Plate',
        grades: ['MS', 'SS400', 'A36'], material: 'Carbon Steel', unit: 'SHEET',
        businessUnit: 'Flat Products', basePrice: 45, isMtoEligible: true),
    _LeafSpec(key: 'coil', categoryId: 'cat_flat_coil', namePrefix: 'Hot Rolled Coil',
        grades: ['SPHC', 'SS400', 'DX51D'], material: 'Carbon Steel', unit: 'MT',
        businessUnit: 'Flat Products', basePrice: 620),
    _LeafSpec(key: 'sheet', categoryId: 'cat_flat_sheet', namePrefix: 'Steel Sheet',
        grades: ['SPCC', 'SS400', 'Galvanized'], material: 'Carbon Steel', unit: 'SHEET',
        businessUnit: 'Flat Products', basePrice: 14),
    _LeafSpec(key: 'giPipe', categoryId: 'cat_pipe_gi', namePrefix: 'GI Pipe',
        grades: ['SCH40', 'SCH80', 'Class B'], material: 'Galvanized Steel', unit: 'PCS',
        businessUnit: 'Pipe & Tube', basePrice: 9),
    _LeafSpec(key: 'blackPipe', categoryId: 'cat_pipe_black', namePrefix: 'Black Pipe',
        grades: ['SCH40', 'SCH80', 'Class B'], material: 'Carbon Steel', unit: 'PCS',
        businessUnit: 'Pipe & Tube', basePrice: 7),
    _LeafSpec(key: 'stainlessPipe', categoryId: 'cat_pipe_stainless', namePrefix: 'Stainless Pipe',
        grades: ['304', '316', '201'], material: 'Stainless Steel', unit: 'PCS',
        businessUnit: 'Pipe & Tube', basePrice: 28, isMtoEligible: true),
    _LeafSpec(key: 'bolts', categoryId: 'cat_hardware_bolts', namePrefix: 'Hex Bolt',
        grades: ['Grade 8.8', 'Grade 10.9', 'Stainless A2'], material: 'Alloy Steel', unit: 'BOX',
        businessUnit: 'Hardware', basePrice: 0.15),
    _LeafSpec(key: 'nuts', categoryId: 'cat_hardware_nuts', namePrefix: 'Hex Nut',
        grades: ['Grade 8.8', 'Grade 10.9', 'Stainless A2'], material: 'Alloy Steel', unit: 'BOX',
        businessUnit: 'Hardware', basePrice: 0.08),
    _LeafSpec(key: 'washers', categoryId: 'cat_hardware_washers', namePrefix: 'Washer',
        grades: ['Flat', 'Spring', 'Stainless'], material: 'Steel', unit: 'BOX',
        businessUnit: 'Hardware', basePrice: 0.03),
    _LeafSpec(key: 'cement', categoryId: 'cat_construction_cement', namePrefix: 'Cement',
        grades: ['OPC', 'PPC', 'Rapid Hardening'], material: 'Portland Cement', unit: 'BAG',
        businessUnit: 'Construction Materials', basePrice: 5.2),
    _LeafSpec(key: 'nails', categoryId: 'cat_construction_nails', namePrefix: 'Nail',
        grades: ['Common', 'Concrete', 'Roofing'], material: 'Steel Wire', unit: 'BOX',
        businessUnit: 'Construction Materials', basePrice: 1.1),
    _LeafSpec(key: 'wireMesh', categoryId: 'cat_construction_wire_mesh', namePrefix: 'Wire Mesh',
        grades: ['Welded', 'Chain Link', 'Hexagonal'], material: 'Galvanized Wire', unit: 'ROLL',
        businessUnit: 'Construction Materials', basePrice: 32),
  ];

  static List<ProductFamily> buildFamilies() {
    final families = <ProductFamily>[];
    for (final leaf in _leaves) {
      for (final grade in leaf.grades) {
        for (final brand in brands) {
          final gradeSlug = grade.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
          final brandSlug = brand.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
          families.add(ProductFamily(
            familyId: 'fam_${leaf.key}_${gradeSlug}_$brandSlug',
            familyName: '$brand $grade ${leaf.namePrefix}',
            codePrefix: '${leaf.key.toUpperCase()}-$gradeSlug-$brandSlug',
            categoryId: leaf.categoryId,
            leafKey: leaf.key,
            namePrefix: '$grade ${leaf.namePrefix}',
            grade: grade,
            brand: brand,
            material: leaf.material,
            unit: leaf.unit,
            businessUnit: leaf.businessUnit,
            basePrice: leaf.basePrice,
            isMtoEligible: leaf.isMtoEligible,
          ));
        }
      }
    }
    return families;
  }
}

class VariantSpec {
  const VariantSpec({
    required this.sizeLabel,
    required this.diameter,
    required this.thickness,
    required this.length,
    required this.width,
    required this.height,
    required this.weight,
    this.mtoHint = false,
  });

  final String sizeLabel;
  final double diameter;
  final double thickness;
  final double length;
  final double width;
  final double height;
  final double weight;
  final bool mtoHint;
}

/// Expands one family into its 20-100 sellable size/length SKUs. Dimensions
/// are grade-independent (a 12mm SD295 rebar is the same shape as a 12mm
/// SD390 one), so this only needs to branch on [ProductFamily.leafKey].
class VariantGenerator {
  VariantGenerator._();

  static List<VariantSpec> buildVariants(ProductFamily family) {
    return switch (family.leafKey) {
      'rebar' => _rebar(),
      'wireRod' => _wireRod(),
      'billet' => _billet(),
      'hbeam' => _beam('H'),
      'ibeam' => _beam('I'),
      'cchannel' => _cchannel(),
      'anglebar' => _angleBar(),
      'plate' => _plate(),
      'coil' => _coil(),
      'sheet' => _sheet(),
      'giPipe' || 'blackPipe' => _pipe(),
      'stainlessPipe' => _pipe(lengths: const [4, 6]),
      'bolts' => _bolt(),
      'nuts' => _nut(),
      'washers' => _washer(),
      'cement' => _cement(),
      'nails' => _nail(),
      'wireMesh' => _wireMesh(),
      _ => const [],
    };
  }

  static List<VariantSpec> _rebar() => [
        for (final d in [6, 8, 10, 12, 16, 19, 22, 25, 28, 32])
          for (final len in [6, 9, 12])
            VariantSpec(
              sizeLabel: '${d}mm-${len}M',
              diameter: d.toDouble(),
              thickness: 0,
              length: len.toDouble(),
              width: d.toDouble(),
              height: d.toDouble(),
              weight: d * d * 0.00617 * len,
              mtoHint: len == 12 && d >= 28,
            ),
      ];

  static List<VariantSpec> _wireRod() => [
        for (final d in [5.5, 6, 6.5, 7, 8, 9, 10, 12])
          for (final coilKg in [500, 1000, 2000])
            VariantSpec(
              sizeLabel: '${d}mm-${coilKg}KG',
              diameter: d.toDouble(),
              thickness: 0,
              length: 0,
              width: d.toDouble(),
              height: d.toDouble(),
              weight: coilKg.toDouble(),
            ),
      ];

  static List<VariantSpec> _billet() => [
        for (final size in [100, 120, 130, 150, 180, 200])
          for (final len in [6, 9, 12, 15])
            VariantSpec(
              sizeLabel: '${size}x$size-${len}M',
              diameter: 0,
              thickness: 0,
              length: len.toDouble(),
              width: size.toDouble(),
              height: size.toDouble(),
              weight: size * size * 0.00785 * len / 1000,
              mtoHint: true,
            ),
      ];

  static List<VariantSpec> _beam(String type) => [
        for (final size in ['100x100', '150x150', '200x200', '250x250', '300x300', '350x350', '400x400'])
          for (final len in [6, 9, 12])
            VariantSpec(
              sizeLabel: '$size-${len}M',
              diameter: 0,
              thickness: 0,
              length: len.toDouble(),
              width: double.parse(size.split('x')[0]),
              height: double.parse(size.split('x')[1]),
              weight: double.parse(size.split('x')[0]) * (type == 'H' ? 0.4 : 0.35) * len,
              mtoHint: len == 12,
            ),
      ];

  static List<VariantSpec> _cchannel() => [
        for (final size in ['75x40', '100x50', '125x65', '150x75', '200x80'])
          for (final len in [6, 9, 12])
            VariantSpec(
              sizeLabel: '$size-${len}M',
              diameter: 0,
              thickness: 0,
              length: len.toDouble(),
              width: double.parse(size.split('x')[0]),
              height: double.parse(size.split('x')[1]),
              weight: double.parse(size.split('x')[0]) * 0.15 * len,
            ),
      ];

  static List<VariantSpec> _angleBar() => [
        for (final size in ['25x25', '30x30', '40x40', '50x50', '63x63', '75x75', '90x90', '100x100'])
          for (final t in [3, 4, 5, 6])
            for (final len in [6, 9])
              VariantSpec(
                sizeLabel: '$size-T$t-${len}M',
                diameter: 0,
                thickness: t.toDouble(),
                length: len.toDouble(),
                width: double.parse(size.split('x')[0]),
                height: t.toDouble(),
                weight: double.parse(size.split('x')[0]) * t * 0.0154 * len,
              ),
      ];

  static List<VariantSpec> _plate() => [
        for (final t in [3, 4, 5, 6, 8, 10, 12, 16, 20, 25])
          for (final size in ['4x8ft', '5x10ft', '6x12ft', '1500x6000mm', '2000x6000mm'])
            VariantSpec(
              sizeLabel: '${t}mm-$size',
              diameter: 0,
              thickness: t.toDouble(),
              length: 0,
              width: 0,
              height: t.toDouble(),
              weight: t * 7.85 * 3,
              mtoHint: t >= 20,
            ),
      ];

  static List<VariantSpec> _coil() => [
        for (var t = 0.3; t <= 3.0; t += 0.3)
          for (final width in [1000, 1219, 1250, 1500])
            VariantSpec(
              sizeLabel: '${t.toStringAsFixed(1)}mm-${width}W',
              diameter: 0,
              thickness: double.parse(t.toStringAsFixed(1)),
              length: 0,
              width: width.toDouble(),
              height: double.parse(t.toStringAsFixed(1)),
              weight: t * width * 7.85 / 1000,
            ),
      ];

  static List<VariantSpec> _sheet() => [
        for (var t = 0.3; t <= 3.0; t += 0.3)
          for (final size in ['4x8ft', '5x10ft', '4x10ft'])
            VariantSpec(
              sizeLabel: '${t.toStringAsFixed(1)}mm-$size',
              diameter: 0,
              thickness: double.parse(t.toStringAsFixed(1)),
              length: 0,
              width: 0,
              height: double.parse(t.toStringAsFixed(1)),
              weight: t * 6.5,
            ),
      ];

  static List<VariantSpec> _pipe({List<int> lengths = const [4, 6, 12]}) => [
        for (final size in ['1/2"', '3/4"', '1"', '1.25"', '1.5"', '2"', '2.5"', '3"', '4"'])
          for (final len in lengths)
            VariantSpec(
              sizeLabel: '${size.replaceAll('"', 'IN')}-${len}M',
              diameter: 0,
              thickness: 0,
              length: len.toDouble(),
              width: 0,
              height: 0,
              weight: len * 1.2,
            ),
      ];

  static List<VariantSpec> _bolt() => [
        for (final size in ['M6', 'M8', 'M10', 'M12', 'M16', 'M20', 'M24'])
          for (final len in [20, 30, 40, 50, 60, 80, 100])
            VariantSpec(
              sizeLabel: '$size-${len}mm',
              diameter: double.parse(size.substring(1)),
              thickness: 0,
              length: len.toDouble(),
              width: 0,
              height: 0,
              weight: double.parse(size.substring(1)) * len * 0.0006,
            ),
      ];

  static List<VariantSpec> _nut() => [
        for (final size in ['M6', 'M8', 'M10', 'M12', 'M16', 'M20', 'M24'])
          VariantSpec(
            sizeLabel: size,
            diameter: double.parse(size.substring(1)),
            thickness: 0,
            length: 0,
            width: 0,
            height: 0,
            weight: double.parse(size.substring(1)) * 0.004,
          ),
      ];

  static List<VariantSpec> _washer() => [
        for (final size in ['M6', 'M8', 'M10', 'M12', 'M16', 'M20', 'M24'])
          VariantSpec(
            sizeLabel: size,
            diameter: double.parse(size.substring(1)),
            thickness: 0,
            length: 0,
            width: 0,
            height: 0,
            weight: double.parse(size.substring(1)) * 0.001,
          ),
      ];

  static List<VariantSpec> _cement() => [
        for (final bagKg in [25, 40, 50])
          VariantSpec(
            sizeLabel: '${bagKg}kg',
            diameter: 0,
            thickness: 0,
            length: 0,
            width: 0,
            height: 0,
            weight: bagKg.toDouble(),
          ),
      ];

  static List<VariantSpec> _nail() => [
        for (final len in [25, 38, 50, 63, 75, 100])
          VariantSpec(
            sizeLabel: '${len}mm',
            diameter: 0,
            thickness: 0,
            length: len.toDouble(),
            width: 0,
            height: 0,
            weight: len * 0.006,
          ),
      ];

  static List<VariantSpec> _wireMesh() => [
        for (final gauge in [8, 10, 12, 14])
          for (final roll in ['1x30m', '1.2x30m', '1.5x30m'])
            VariantSpec(
              sizeLabel: 'G$gauge-$roll',
              diameter: gauge.toDouble(),
              thickness: 0,
              length: 30,
              width: double.parse(roll.split('x')[0]),
              height: 0,
              weight: gauge * 3.5,
            ),
      ];
}

class Warehouse {
  const Warehouse(this.code, this.province);
  final String code;
  final String province;
}

/// Warehouse network + which SKUs stock where — every SKU is assigned to a
/// small subset (1-3), not all warehouses, matching how real plants only
/// carry a slice of the catalog and keeping the demo dataset in the
/// spec'd 10k-30k row range instead of exploding by full warehouse count.
class WarehouseGenerator {
  WarehouseGenerator._();

  static final List<Warehouse> warehouses = [
    const Warehouse('WH-PP01', 'Phnom Penh'),
    const Warehouse('WH-PP02', 'Phnom Penh'),
    const Warehouse('WH-SR01', 'Siem Reap'),
    const Warehouse('WH-BTB01', 'Battambang'),
    const Warehouse('WH-KPC01', 'Kampong Cham'),
    const Warehouse('WH-SHV01', 'Sihanoukville'),
    const Warehouse('WH-KAN01', 'Kandal'),
    const Warehouse('WH-KAM01', 'Kampot'),
  ];

  static List<Warehouse> assignFor(List<Warehouse> all, Random rand) {
    final count = 1 + rand.nextInt(3);
    final shuffled = List<Warehouse>.from(all)..shuffle(rand);
    return shuffled.take(count).toList();
  }
}

class VariantPricing {
  const VariantPricing({
    required this.costPrice,
    required this.standardPrice,
    required this.wholesalePrice,
    required this.dealerPrice,
    required this.vipPrice,
    required this.creditPrice,
    required this.cashPrice,
  });

  final double costPrice;
  final double standardPrice;
  final double wholesalePrice;
  final double dealerPrice;
  final double vipPrice;
  final double creditPrice;
  final double cashPrice;
}

/// Derives every price tier from one base price. Standard carries the
/// nominal margin over cost; the other tiers are consistent discounts/
/// markups off standard, matching how real customer price groups work.
class PricingGenerator {
  PricingGenerator._();

  static VariantPricing forVariant(ProductFamily family, VariantSpec variant, Random rand) {
    final sizeFactor = 1 + (variant.diameter + variant.thickness) * 0.02 + variant.length * 0.05;
    final jitter = 0.95 + rand.nextDouble() * 0.10;
    final standard = double.parse((family.basePrice * sizeFactor * jitter).toStringAsFixed(2));
    final cost = double.parse((standard * 0.72).toStringAsFixed(2));

    return VariantPricing(
      costPrice: cost,
      standardPrice: standard,
      wholesalePrice: double.parse((standard * 0.92).toStringAsFixed(2)),
      dealerPrice: double.parse((standard * 0.85).toStringAsFixed(2)),
      vipPrice: double.parse((standard * 0.80).toStringAsFixed(2)),
      creditPrice: double.parse((standard * 1.03).toStringAsFixed(2)),
      cashPrice: double.parse((standard * 0.97).toStringAsFixed(2)),
    );
  }
}

class AppliedPromotion {
  const AppliedPromotion({required this.type, required this.label, required this.promotionPrice});
  final PromotionType type;
  final String label;
  final double promotionPrice;
}

enum PromotionType { percentDiscount, buyXGetY, clearance, monthly }

/// Decides which rows carry a promotion (~15%) and what it looks like.
class PromotionGenerator {
  PromotionGenerator._();

  static AppliedPromotion? maybeApply(VariantPricing pricing, Random rand) {
    if (rand.nextDouble() > 0.15) return null;

    final type = PromotionType.values[rand.nextInt(PromotionType.values.length)];
    return switch (type) {
      PromotionType.percentDiscount => AppliedPromotion(
          type: type,
          label: '${(5 + rand.nextInt(16))}% Off',
          promotionPrice: double.parse((pricing.standardPrice * (0.95 - rand.nextInt(16) / 100)).toStringAsFixed(2)),
        ),
      PromotionType.buyXGetY => AppliedPromotion(
          type: type,
          label: 'Buy 10 Get 1',
          promotionPrice: double.parse((pricing.standardPrice * 0.91).toStringAsFixed(2)),
        ),
      PromotionType.clearance => AppliedPromotion(
          type: type,
          label: 'Clearance Sale',
          promotionPrice: double.parse((pricing.standardPrice * 0.75).toStringAsFixed(2)),
        ),
      PromotionType.monthly => AppliedPromotion(
          type: type,
          label: 'Monthly Promotion',
          promotionPrice: double.parse((pricing.standardPrice * 0.90).toStringAsFixed(2)),
        ),
    };
  }
}
