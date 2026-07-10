import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/quotation_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/off_visit_reason.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/quotation_repository.dart';

const _validityDays = 14;

/// Composes [QuotationLocalDataSource] (`quotations` table) with
/// [ProductLocalDataSource] to rehydrate full [CartItem] lines — same shape
/// `CartRepositoryImpl` uses for its own rows.
class QuotationRepositoryImpl implements QuotationRepository {
  QuotationRepositoryImpl(
      {required QuotationLocalDataSource local,
      required ProductLocalDataSource productLocal})
      : _local = local,
        _productLocal = productLocal;

  final QuotationLocalDataSource _local;
  final ProductLocalDataSource _productLocal;

  final StreamController<List<Quotation>> _controller =
      StreamController<List<Quotation>>.broadcast();

  @override
  ResultFuture<Quotation> saveQuotation({
    required List<CartItem> items,
    String? customerId,
    String? shopName,
    String? leadId,
    String? leadDisplayName,
    OffVisitReason? offVisitReason,
    double? gpsLat,
    double? gpsLng,
  }) async {
    try {
      if (items.isEmpty) {
        return const Failed(CacheFailure(message: 'Quotation has no items.'));
      }
      final now = DateTime.now();
      final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineSubtotal);
      final discount = items.fold<double>(0, (sum, i) => sum + i.lineDiscount);
      final tax = (subtotal - discount) * 0.10;
      final total = subtotal - discount + tax;

      final quotation = Quotation(
        id: _newId('QT'),
        customerId: customerId,
        shopName: shopName,
        leadId: leadId,
        leadDisplayName: leadDisplayName,
        lines: items,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        status: QuotationStatus.saved,
        offVisitReason: offVisitReason,
        gpsLatitude: gpsLat,
        gpsLongitude: gpsLng,
        sapDraftStatus: 'Draft Saved to SAP',
        validUntil: now.add(const Duration(days: _validityDays)),
        createdAt: now,
        updatedAt: now,
      );

      await _local.insertQuotation(_toRow(quotation));
      unawaited(_broadcast());
      return Success(quotation);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<Quotation> updateQuotation(Quotation existing,
      {required List<CartItem> items}) async {
    try {
      if (items.isEmpty) {
        return const Failed(CacheFailure(message: 'Quotation has no items.'));
      }
      final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineSubtotal);
      final discount = items.fold<double>(0, (sum, i) => sum + i.lineDiscount);
      final tax = (subtotal - discount) * 0.10;
      final total = subtotal - discount + tax;

      final updated = Quotation(
        id: existing.id,
        customerId: existing.customerId,
        shopName: existing.shopName,
        leadId: existing.leadId,
        leadDisplayName: existing.leadDisplayName,
        lines: items,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        status: existing.status,
        offVisitReason: existing.offVisitReason,
        gpsLatitude: existing.gpsLatitude,
        gpsLongitude: existing.gpsLongitude,
        sapDraftStatus: existing.sapDraftStatus,
        validUntil: existing.validUntil,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      await _local.updateQuotation(_toRow(updated));
      unawaited(_broadcast());
      return Success(updated);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<Quotation> markConverted(String quotationId) async {
    try {
      final row = await _local.getById(quotationId);
      if (row == null) {
        return const Failed(CacheFailure(message: 'Quotation not found.'));
      }
      final quotation = await _fromRow(row);
      final converted = Quotation(
        id: quotation.id,
        customerId: quotation.customerId,
        shopName: quotation.shopName,
        leadId: quotation.leadId,
        leadDisplayName: quotation.leadDisplayName,
        lines: quotation.lines,
        subtotal: quotation.subtotal,
        discount: quotation.discount,
        tax: quotation.tax,
        total: quotation.total,
        status: QuotationStatus.converted,
        offVisitReason: quotation.offVisitReason,
        gpsLatitude: quotation.gpsLatitude,
        gpsLongitude: quotation.gpsLongitude,
        sapDraftStatus: quotation.sapDraftStatus,
        validUntil: quotation.validUntil,
        createdAt: quotation.createdAt,
        updatedAt: DateTime.now(),
      );
      await _local.updateQuotation(_toRow(converted));
      unawaited(_broadcast());
      return Success(converted);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<Quotation?> getQuotationById(String id) async {
    try {
      final row = await _local.getById(id);
      return Success(row == null ? null : await _fromRow(row));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> deleteQuotation(String id) async {
    try {
      await _local.deleteQuotation(id);
      await _broadcast();
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  Stream<List<Quotation>> watchQuotations() async* {
    yield await _loadAll();
    yield* _controller.stream;
  }

  Future<void> _broadcast() async {
    if (!_controller.hasListener) return;
    try {
      _controller.add(await _loadAll());
    } on CacheException {
      // Keep the last good list on a transient read error.
    }
  }

  Future<List<Quotation>> _loadAll() async {
    final rows = await _local.fetchAll();
    return Future.wait(rows.map(_fromRow));
  }

  DataMap _toRow(Quotation q) => {
        'id': q.id,
        'customer_id': q.customerId,
        'shop_name': q.shopName,
        'lead_id': q.leadId,
        'lead_display_name': q.leadDisplayName,
        'lines_json': _encodeLines(q.lines),
        'subtotal': q.subtotal,
        'discount': q.discount,
        'tax': q.tax,
        'total': q.total,
        'status': q.status.name,
        'off_visit_reason': q.offVisitReason?.name,
        'gps_lat': q.gpsLatitude,
        'gps_lng': q.gpsLongitude,
        'sap_draft_status': q.sapDraftStatus,
        'valid_until': q.validUntil.toIso8601String(),
        'created_at': q.createdAt.toIso8601String(),
        'updated_at': q.updatedAt.toIso8601String(),
      };

  Future<Quotation> _fromRow(DataMap row) async {
    return Quotation(
      id: row['id'] as String,
      customerId: row['customer_id'] as String?,
      shopName: row['shop_name'] as String?,
      leadId: row['lead_id'] as String?,
      leadDisplayName: row['lead_display_name'] as String?,
      lines: await _decodeLines(row['lines_json'] as String,
          customerId: row['customer_id'] as String?,
          leadId: row['lead_id'] as String?),
      subtotal: (row['subtotal'] as num).toDouble(),
      discount: (row['discount'] as num).toDouble(),
      tax: (row['tax'] as num).toDouble(),
      total: (row['total'] as num).toDouble(),
      status: QuotationStatus.values.firstWhere((s) => s.name == row['status']),
      offVisitReason: row['off_visit_reason'] == null
          ? null
          : OffVisitReason.values
              .firstWhere((r) => r.name == row['off_visit_reason']),
      gpsLatitude: (row['gps_lat'] as num?)?.toDouble(),
      gpsLongitude: (row['gps_lng'] as num?)?.toDouble(),
      sapDraftStatus: row['sap_draft_status'] as String,
      validUntil: DateTime.parse(row['valid_until'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  String _encodeLines(List<CartItem> items) => jsonEncode(items
      .map((i) => {
            'productId': i.product.id,
            'quantity': i.quantity,
            'unit': i.unit,
            'discountPercent': i.discountPercent,
          })
      .toList());

  Future<List<CartItem>> _decodeLines(String json,
      {String? customerId, String? leadId}) async {
    final rawItems = (jsonDecode(json) as List).cast<DataMap>();
    final items = <CartItem>[];
    for (final raw in rawItems) {
      final product = await _productLocal.getById(raw['productId'] as String);
      if (product == null) continue;
      items.add(CartItem(
        id: '${raw['productId']}-${items.length}',
        product: product,
        quantity: (raw['quantity'] as num).toDouble(),
        unit: raw['unit'] as String,
        discountPercent: (raw['discountPercent'] as num).toDouble(),
        leadId: leadId,
        customerId: customerId,
      ));
    }
    return items;
  }

  static String _newId(String prefix) =>
      '$prefix-${(DateTime.now().microsecondsSinceEpoch + Random().nextInt(99999)) % 1000000}';
}
