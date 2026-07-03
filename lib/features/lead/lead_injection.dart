import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/features/lead/data/repositories/lead_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/add_lead_activity.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/add_lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/add_lead_note.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/create_lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/delete_lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/fetch_lead_activity.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/fetch_leads.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/fetch_pipeline_summary.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/get_lead_by_id.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/move_lead_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/reorder_leads.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/update_lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/lead_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';

/// Registers everything the sales-pipeline (lead) feature needs.
///
/// The repository is a singleton (not a factory) because the in-memory mock
/// backend holds mutable state that must survive across the board and
/// detail screens for the lifetime of the app session. Usecases are thin,
/// stateless wrappers around the repository (see domain/usecases/lead_usecase.dart)
/// so they're cheap lazy singletons too.
void registerLeadFeature(GetIt sl) {
  sl.registerLazySingleton<LeadRepository>(() => LeadRepositoryImpl());

  // ── Usecases ──────────────────────────────────────────────────────
  sl.registerLazySingleton(() => FetchLeads(sl()));
  sl.registerLazySingleton(() => GetLeadById(sl()));
  sl.registerLazySingleton(() => CreateLead(sl()));
  sl.registerLazySingleton(() => UpdateLead(sl()));
  sl.registerLazySingleton(() => DeleteLead(sl()));
  sl.registerLazySingleton(() => MoveLeadStage(sl()));
  sl.registerLazySingleton(() => ReorderLeads(sl()));
  sl.registerLazySingleton(() => FetchPipelineSummary(sl()));
  sl.registerLazySingleton(() => FetchLeadActivity(sl()));
  sl.registerLazySingleton(() => AddLeadActivity(sl()));
  sl.registerLazySingleton(() => AddLeadDocument(sl()));
  sl.registerLazySingleton(() => AddLeadNote(sl()));
  sl.registerLazySingleton(() => FetchNotifications(sl()));

  // ── Presentation ──────────────────────────────────────────────────
  sl.registerFactory(() => PipelineBloc(
        fetchLeads: sl(),
        fetchPipelineSummary: sl(),
        moveLeadStage: sl(),
        reorderLeads: sl(),
        deleteLead: sl(),
        createLead: sl(),
        updateLead: sl(),
        sessionManager: sl(),
      ));
  sl.registerFactory(() => LeadDetailCubit(
        getLeadById: sl(),
        fetchLeadActivity: sl(),
        addLeadNote: sl(),
        addLeadDocument: sl(),
        addLeadActivity: sl(),
      ));
}
