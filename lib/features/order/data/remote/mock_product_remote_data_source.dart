import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/order/data/mock/mock_product_data.dart';
import 'package:isi_steel_sales_mobile/features/order/data/models/category_model.dart';
import 'package:isi_steel_sales_mobile/features/order/data/models/product_model.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/product_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/remote_sync_page.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_pricing.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_scope.dart';

/// Simulates an SAP catalog feed: loads the generated
/// `assets/mock/products.json` once (falling back to generating it in-memory
/// if the asset is ever missing), then serves scoped/paged initial syncs and
/// deterministic delta syncs from it — never the network, since this is a
/// demo stand-in, but shaped exactly like a real paginated REST source would
/// be so swapping in a Dio-backed implementation later is mechanical.
class MockProductRemoteDataSource implements ProductRemoteDataSource {
  MockProductRemoteDataSource();

  List<ProductModel>? _products;
  List<CategoryModel>? _categories;

  Future<void> _ensureLoaded() async {
    if (_products != null) return;
    try {
      final raw = await rootBundle.loadString('assets/mock/products.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final productsJson = decoded['products'] as List;
      final categoriesJson = decoded['categories'] as List;
      _products = productsJson
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _categories = categoriesJson
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final generated = MockProductData.generate();
      _products = (generated['products'] as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _categories = (generated['categories'] as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  bool _inScope(ProductModel p, SyncScope scope) =>
      scope.matchesWarehouse(p.warehouseCode) || p.territory == scope.territory;

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      await _ensureLoaded();
      return _categories!;
    } catch (e) {
      throw ServerException(message: 'Failed to load categories: $e');
    }
  }

  @override
  Future<RemoteSyncPage> fetchInitial({
    required SyncScope scope,
    required int page,
    required int pageSize,
  }) async {
    try {
      await _ensureLoaded();
      final scoped = _products!.where((p) => _inScope(p, scope)).toList();
      final start = page * pageSize;
      if (start >= scoped.length) {
        return const RemoteSyncPage(items: [], hasMore: false);
      }
      final end = min(start + pageSize, scoped.length);
      return RemoteSyncPage(
          items: scoped.sublist(start, end), hasMore: end < scoped.length);
    } catch (e) {
      throw ServerException(message: 'Initial sync failed: $e');
    }
  }

  @override
  Future<RemoteDeltaPage> fetchDelta(
      {required SyncScope scope, required DateTime since}) async {
    try {
      await _ensureLoaded();
      final scoped = _products!.where((p) => _inScope(p, scope)).toList();
      if (scoped.isEmpty) {
        return const RemoteDeltaPage(upserted: [], deletedIds: []);
      }

      // Deterministic per-call-time delta: reseeding on `since` means the
      // exact same call repeated for the same timestamp is reproducible,
      // while later calls (later `since`) surface a different slice — this
      // is what makes the delta path genuinely exercised in a demo, not
      // just a no-op after the first sync.
      final rand = Random(since.millisecondsSinceEpoch ~/ 1000);
      final changedCount = max(1, (scoped.length * 0.05).round());
      final deletedCount = max(0, (scoped.length * 0.01).round());
      scoped.shuffle(rand);

      final deleted = scoped.take(deletedCount).map((p) => p.id).toList();
      final changed = scoped.skip(deletedCount).take(changedCount).map((p) {
        final priceJitter = 0.9 + rand.nextDouble() * 0.2;
        final stockJitter = rand.nextInt(500);
        final standard = double.parse(
            (p.pricing.standardPrice * priceJitter).toStringAsFixed(2));
        return ProductModel(
          id: p.id,
          familyId: p.familyId,
          familyName: p.familyName,
          code: p.code,
          sku: p.sku,
          materialCode: p.materialCode,
          barcode: p.barcode,
          name: p.name,
          description: p.description,
          categoryId: p.categoryId,
          subCategory: p.subCategory,
          brand: p.brand,
          grade: p.grade,
          material: p.material,
          size: p.size,
          diameter: p.diameter,
          thickness: p.thickness,
          length: p.length,
          width: p.width,
          height: p.height,
          weight: p.weight,
          unit: p.unit,
          warehouseCode: p.warehouseCode,
          territory: p.territory,
          businessUnit: p.businessUnit,
          imageUrl: p.imageUrl,
          isMto: p.isMto,
          status: p.status,
          updatedAt: DateTime.now(),
          pricing: ProductPricing(
            costPrice: p.pricing.costPrice,
            standardPrice: standard,
            wholesalePrice: double.parse((standard * 0.92).toStringAsFixed(2)),
            dealerPrice: double.parse((standard * 0.85).toStringAsFixed(2)),
            vipPrice: double.parse((standard * 0.80).toStringAsFixed(2)),
            creditPrice: double.parse((standard * 1.03).toStringAsFixed(2)),
            cashPrice: double.parse((standard * 0.97).toStringAsFixed(2)),
            currency: p.pricing.currency,
            promotionPrice: p.pricing.promotionPrice,
            promotionType: p.pricing.promotionType,
            promotionLabel: p.pricing.promotionLabel,
          ),
          stockQuantity: (p.stockQuantity + stockJitter).toDouble(),
          reservedQuantity: p.reservedQuantity,
          minStock: p.minStock,
          maxStock: p.maxStock,
        );
      }).toList();

      return RemoteDeltaPage(upserted: changed, deletedIds: deleted);
    } catch (e) {
      throw ServerException(message: 'Delta sync failed: $e');
    }
  }
}
