import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';

/// Surfaces auth failures as a dismissible inline banner. Wrap it in a
/// [BlocListener]-free spot; it listens itself and rebuilds only when the
/// failure message changes (buildWhen), so it costs nothing while idle.
class AuthMessageBanner extends StatelessWidget {
  const AuthMessageBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
          curr is AuthFailureState || prev is AuthFailureState,
      builder: (context, state) {
        if (state is! AuthFailureState) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  size: 20, color: scheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.message,
                  style:
                      TextStyle(color: scheme.onErrorContainer, fontSize: 13.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
