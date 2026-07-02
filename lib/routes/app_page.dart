import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart'; // uncomment for per-page blocs
import 'package:mini_app/core/contants/app_rooutes.dart';

// TODO: import your real screens, e.g.:
// import 'package:mini_app/features/home/presentation/home_screen.dart';

/// BLoC replacement for GetX `getPages()`.
///
/// In GetX you wrote:
///   GetPage(name: Static.details, page: () => DetailsScreen(),
///           binding: DetailsBinding())
/// In BLoC the `binding` becomes a BlocProvider wrapped around that page:
///   case Static.details:
///     return MaterialPageRoute(
///       builder: (_) => BlocProvider(
///         create: (_) => DetailsBloc(),   // <- was DetailsBinding
///         child: const DetailsScreen(),
///       ),
///       settings: settings,
///     );
class AppPages {
  AppPages._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Static.homeScreen:
        return MaterialPageRoute(
          // Replace with your real HomeScreen.
          builder: (_) => const _Placeholder(title: 'Home'),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => _Placeholder(title: 'No route: ${settings.name}'),
          settings: settings,
        );
    }
  }
}

/// Temporary stand-in so the app runs before you wire real screens.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
