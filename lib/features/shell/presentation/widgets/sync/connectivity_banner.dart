import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_cubit.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// A calm, always-visible-when-offline banner. Reassures rather than alarms:
/// work is safe locally. Observe-only — it never navigates. Renders nothing
/// while online (the reconnect *snackbar* handles the online transition).
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) {
        if (status == ConnectivityStatus.online) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Vibe.slate,
            borderRadius: BorderRadius.circular(14),
            boxShadow: Vibe.cardShadow,
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You’re offline — everything is saved on this device.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
