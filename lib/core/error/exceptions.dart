import 'package:equatable/equatable.dart';

class CacheException extends Equatable implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  List<Object> get props => [message];
}

class NoteDataException extends Equatable implements Exception {
  final String message;

  const NoteDataException(this.message);

  @override
  List<Object> get props => [message];
}

class ServerException extends Equatable implements Exception {
  final String message;

  const ServerException(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkException extends Equatable implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  List<Object> get props => [message];
}

class MLKitException extends Equatable implements Exception {
  final String message;

  const MLKitException(this.message);

  @override
  List<Object> get props => [message];
}

class GeminiAPIException extends Equatable implements Exception {
  final String message;

  const GeminiAPIException(this.message);

  @override
  List<Object> get props => [message];
}
