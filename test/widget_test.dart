// Real widget smoke test (replaces the default counter boilerplate, which
// referenced a counter UI this app never had and would always fail).
//
// Exercises a self-contained presentational widget end-to-end: it renders the
// category chips and reports the tapped category id back through its callback.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/widgets/category_chip_list.dart';

void main() {
  testWidgets('CategoryChipList renders labels and reports the tapped id', (tester) async {
    String? tapped = 'unset';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryChipList(
            categories: const [
              CategoryChipViewModel(id: null, label: 'All', selected: true),
              CategoryChipViewModel(id: 'cat-pipe', label: 'Pipe', selected: false),
            ],
            onSelect: (id) => tapped = id,
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Pipe'), findsOneWidget);

    await tester.tap(find.text('Pipe'));
    await tester.pumpAndSettle();

    expect(tapped, 'cat-pipe');
  });
}
