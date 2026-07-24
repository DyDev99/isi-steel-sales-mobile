import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:isi_steel_sales_mobile/features/order/domain/entities/data_domain.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/customization/customization_state.dart';

class CustomizationCubit extends Cubit<CustomizationState> {
  final ImagePicker _picker;

  CustomizationCubit({ImagePicker? picker})
      : _picker = picker ?? ImagePicker(),
        super(const CustomizationDataState());

  CustomizationDataState get _currentState =>
      state is CustomizationDataState ? (state as CustomizationDataState) : const CustomizationDataState();

  Future<void> captureOrPickDrawing(ImageSource source) async {
    final previous = _currentState;
    try {
      emit(const CustomizationLoading());
      // image_picker requests the camera/photo permission itself and downscales
      // the capture via [imageQuality]/[maxWidth]/[maxHeight], so no separate
      // permission or compression package is needed.
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (file == null) {
        emit(previous);
        return;
      }

      final storedPath = await _storeDrawing(file.path);
      if (storedPath != null) {
        emit(previous.copyWith(drawingImagePath: storedPath));
      } else {
        emit(const CustomizationError('Failed to save drawing file.'));
      }
    } catch (e) {
      emit(CustomizationError('Error capturing drawing: ${e.toString()}'));
    }
  }

  void removeDrawing() {
    if (_currentState.drawingImagePath != null) {
      final file = File(_currentState.drawingImagePath!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
    emit(_currentState.copyWith(drawingImagePath: null));
  }

  void updateMeasurements({
    double? lengthMm,
    double? widthMm,
    double? heightMm,
    double? thicknessMm,
    double? diameterMm,
  }) {
    final current = _currentState.measurements;
    final updated = CustomizationMeasurement(
      lengthMm: lengthMm ?? current.lengthMm,
      widthMm: widthMm ?? current.widthMm,
      heightMm: heightMm ?? current.heightMm,
      thicknessMm: thicknessMm ?? current.thicknessMm,
      diameterMm: diameterMm ?? current.diameterMm,
    );
    emit(_currentState.copyWith(measurements: updated));
  }

  /// Seeds the measurements once (used to prefill the form from the base
  /// product's spec without marking every field dirty).
  void seedMeasurements(CustomizationMeasurement measurements) {
    emit(_currentState.copyWith(measurements: measurements));
  }

  void updateNotes(String notes) {
    emit(_currentState.copyWith(notes: notes));
  }

  void updateAppearance(String appearance) {
    emit(_currentState.copyWith(appearance: appearance));
  }

  void updateUnit(String unit) {
    emit(_currentState.copyWith(selectedUnit: unit));
  }

  void updateQuantity(double qty) {
    emit(_currentState.copyWith(quantity: qty));
  }

  /// Copies the picked (already-downscaled) image into the app's private
  /// `drawing_cache` directory so it survives the temp file being reclaimed.
  Future<String?> _storeDrawing(String rawPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetFolder = Directory(p.join(appDir.path, 'drawing_cache'));
      if (!targetFolder.existsSync()) {
        targetFolder.createSync(recursive: true);
      }

      final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = p.join(targetFolder.path, fileName);

      await File(rawPath).copy(targetPath);
      return targetPath;
    } catch (_) {
      return null;
    }
  }
}