import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/home/data/home_repository.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeInitial());

  final HomeRepository _repository;

  Future<void> load() async {
    emit(const HomeLoading());
    try {
      final summary = await _repository.fetchSummary();
      emit(HomeLoaded(summary));
    } catch (_) {
      emit(const HomeError("Couldn't load your dashboard"));
    }
  }

  Future<void> refresh() => load();
}
