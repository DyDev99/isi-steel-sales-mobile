import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/data/home_repository.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/lead_screen.dart';
import 'package:isi_steel_sales_mobile/features/opportunity/presentation/screens/opportunity_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/glass_nav_bar.dart';

/// App shell: owns the bottom nav and hosts the five tabs.
///
/// Tabs live in a LAZY IndexedStack — each is built only when first visited,
/// then kept alive so its scroll/filters survive tab switches. Each tab
/// provides its own bloc, so state stays scoped to that feature.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = <NavTab>[
    NavTab(Icons.home_rounded, 'Home'),
    NavTab(Icons.people_alt_rounded, 'Leads'),
    NavTab(Icons.receipt_long_rounded, 'Orders'),
    NavTab(Icons.trending_up_rounded, 'Opps'),
    NavTab(Icons.person_rounded, 'Profile'),
  ];

  late final List<Widget?> _built = List<Widget?>.filled(_tabs.length, null);

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return BlocProvider(
          create: (_) => HomeCubit(const HomeRepositoryImpl())..load(),
          child: const HomeScreen(userName: 'there'),
        );
      case 1:
        return const LeadScreen();
      case 2:
        return const OrderScreen();
      case 3:
        return const OpportunityScreen();
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    _built[_index] ??= _buildTab(_index); // lazily build the visited tab

    return Scaffold(
      backgroundColor: Vibe.bg,
      body: IndexedStack(
        index: _index,
        children: List.generate(
          _tabs.length,
          (i) => _built[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: GlassNavBar(
        tabs: _tabs,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
