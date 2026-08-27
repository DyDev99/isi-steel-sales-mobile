import 'package:flutter/material.dart';

/// Directory-level loading state used while the first customer page is read.
class CustomerLoading extends StatelessWidget {
  const CustomerLoading({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}
