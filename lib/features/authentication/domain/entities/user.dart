import 'package:equatable/equatable.dart';

/// A signed-in corporate user. Pure domain object — no JSON, no framework.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.company,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String fullName;
  final String? company;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, email, fullName, company, avatarUrl];
}
