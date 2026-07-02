// Add this to app_routes.dart or a new file like navigator_key.dart
import 'package:flutter/widgets.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
/// Route name constants. Plain strings — no framework dependency, so this
/// file is identical whether you use GetX or BLoC.
class Static {
  Static._();

  static const String splash = '/';
  static const String login = '/login';
  static const String main = '/main'; // MainShell (bottom-nav container)
  static const String home = '/home';
  static const String lead = '/lead';
  static const String order = '/order';
  static const String opportunity = '/opportunity';
}