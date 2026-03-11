import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class MLKitFailure extends Failure {
  const MLKitFailure(String message) : super(message);
}

class GeminiAPIFailure extends Failure {
  const GeminiAPIFailure(String message) : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}
