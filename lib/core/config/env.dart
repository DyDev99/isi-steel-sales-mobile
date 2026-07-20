import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'SAP_API_URL_1', obfuscate: true)
  static final String sapApiUrl1 = _Env.sapApiUrl1;

  @EnviedField(varName: 'SAP_API_URL_2', obfuscate: true)
  static final String sapApiUrl2 = _Env.sapApiUrl2;

  @EnviedField(varName: 'SAP_API_URL_3', obfuscate: true)
  static final String sapApiUrl3 = _Env.sapApiUrl3;

  @EnviedField(varName: 'SAP_API_URL_4', obfuscate: true)
  static final String sapApiUrl4 = _Env.sapApiUrl4;

  @EnviedField(varName: 'DB_SALT', obfuscate: true)
  static final String dbSalt = _Env.dbSalt;

  /// Ordered list of SAP API gateways for auto-failover.
  static List<String> get sapApiUrls => [
        sapApiUrl1,
        sapApiUrl2,
        sapApiUrl3,
        sapApiUrl4,
      ];
}