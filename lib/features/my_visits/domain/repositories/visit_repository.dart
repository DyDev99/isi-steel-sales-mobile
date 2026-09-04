import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_in_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_out_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_collection.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_note.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_order_line.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_return.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_stock_update.dart';

abstract interface class VisitRepository {
  ResultFuture<CheckInRecord> checkIn(CheckInRecord record);
  ResultFuture<CheckOutRecord> checkOut(CheckOutRecord record);

  ResultFuture<void> addOrderLine(VisitOrderLine line);
  ResultFuture<void> addStockUpdate(VisitStockUpdate update);
  ResultFuture<void> addReturn(VisitReturn returnItem);
  ResultFuture<void> addCollection(VisitCollection collection);
  ResultFuture<void> addNote(VisitNote note);
  ResultFuture<void> addPhoto(VisitPhoto photo);

  ResultFuture<List<VisitOrderLine>> fetchOrderLines(String stopId);
  ResultFuture<List<VisitStockUpdate>> fetchStockUpdates(String stopId);
  ResultFuture<List<VisitReturn>> fetchReturns(String stopId);
  ResultFuture<List<VisitCollection>> fetchCollections(String stopId);
  ResultFuture<List<VisitNote>> fetchNotes(String stopId);
  ResultFuture<List<VisitPhoto>> fetchPhotos(String stopId);
}
