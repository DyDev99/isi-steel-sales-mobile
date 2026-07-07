import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/mock/visit_history_mock_data.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/visit_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/visit_history_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/visit_history_card.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/visit_history_empty_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/visit_history_error_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/visit_history_skeleton.dart';

enum _ViewState { loading, loaded, empty, error }

/// "My Visits" history list — UI flow only, backed by static mock data.
/// Simulates a network fetch on open (loading → loaded) and exposes a
/// debug-only menu to preview the empty/error states without a real backend.
class MyVisitsHistoryScreen extends StatefulWidget {
  const MyVisitsHistoryScreen({super.key});

  static const routeName = 'my-visits-history';

  @override
  State<MyVisitsHistoryScreen> createState() => _MyVisitsHistoryScreenState();
}

class _MyVisitsHistoryScreenState extends State<MyVisitsHistoryScreen> {
  _ViewState _state = _ViewState.loading;
  List<VisitRecord> _visits = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _ViewState.loading);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final visits = buildMockVisitHistory();
    setState(() {
      _visits = visits;
      _state = visits.isEmpty ? _ViewState.empty : _ViewState.loaded;
    });
  }

  void _openDetail(VisitRecord visit) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: VisitHistoryDetailScreen.routeName),
      builder: (_) => VisitHistoryDetailScreen(visit: visit),
    ));
  }

  void _setDebugPreview(_ViewState state) {
    setState(() {
      _state = state;
      if (state == _ViewState.loaded) _visits = buildMockVisitHistory();
      if (state == _ViewState.empty) _visits = const [];
    });
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: Text('my_visits.history.title'.tr,
            style: const TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
        actions: kDebugMode
            ? [
                PopupMenuButton<_ViewState>(
                  tooltip: 'my_visits.history.preview_state'.tr,
                  icon: const Icon(Icons.bug_report_rounded, color: Vibe.muted),
                  onSelected: _setDebugPreview,
                  itemBuilder: (_) => [
                    PopupMenuItem(value: _ViewState.loading, child: Text('my_visits.history.state_loading'.tr)),
                    PopupMenuItem(value: _ViewState.loaded, child: Text('my_visits.history.state_loaded'.tr)),
                    PopupMenuItem(value: _ViewState.empty, child: Text('my_visits.history.state_empty'.tr)),
                    PopupMenuItem(value: _ViewState.error, child: Text('my_visits.history.state_error'.tr)),
                  ],
                ),
              ]
            : null,
      ),
      body: switch (_state) {
        _ViewState.loading => const VisitHistoryListSkeleton(),
        _ViewState.error => VisitHistoryErrorState(onRetry: _load),
        _ViewState.empty => const VisitHistoryEmptyState(),
        _ViewState.loaded => RefreshIndicator(
            color: Vibe.violet,
            backgroundColor: Vibe.bgSoft,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                Text(
                  'my_visits.history.subtitle'.tr.replaceAll('{count}', '${_visits.length}'),
                  style: const TextStyle(color: Vibe.muted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final visit in _visits) VisitHistoryCard(visit: visit, onTap: () => _openDetail(visit)),
              ],
            ),
          ),
      },
    );
  }
}
