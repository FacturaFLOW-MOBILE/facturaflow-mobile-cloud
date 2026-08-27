import 'failure.dart';

/// Resultado de una operación que puede fallar sin lanzar excepciones.
///
/// Se usa en toda la capa de datos para que los ViewModels manejen el error
/// como un valor y no con `try/catch` disperso por la UI.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Valor si el resultado es correcto, `null` en caso de error.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// Fallo si el resultado es un error, `null` en caso contrario.
  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final failure) => failure,
      };

  /// Transforma el valor conservando el error.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok<R>(transform(value)),
        Err<T>(:final failure) => Err<R>(failure),
      };

  /// Reduce el resultado a un único valor.
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  String toString() => 'Err(${failure.message})';
}
