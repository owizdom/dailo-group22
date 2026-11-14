import 'package:equatable/equatable.dart';

/// Who is signed in right now, as reported by Firebase Authentication.
class AuthSession extends Equatable {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });

  final String uid;
  final String email;

  /// Google accounts arrive verified. Email accounts become verified after
  /// the user opens the link Firebase sends.
  final bool emailVerified;

  @override
  List<Object?> get props => [uid, email, emailVerified];
}
