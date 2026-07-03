import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.parentId,
  });

  final String id;
  final String? parentId;
  final String name;
  final int sortOrder;

  bool get isTopLevel => parentId == null;

  @override
  List<Object?> get props => [id, parentId, name, sortOrder];
}
