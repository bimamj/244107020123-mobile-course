sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Remote / HTTP problems.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Authentication problems (bad credentials, expired session, ...).
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Business-rule validation errors raised by use cases.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Requested resource does not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
