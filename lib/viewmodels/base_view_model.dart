import 'package:flutter/foundation.dart';

import '../core/failure.dart';
import '../core/result.dart';

/// Estado de carga que la vista observa para decidir qué pintar.
enum ViewState { idle, busy, error }

/// Base de todos los ViewModels.
///
/// Centraliza el estado de carga, el mensaje de error y protege contra el
/// error clásico de `notifyListeners()` después de `dispose()`.
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  bool _disposed = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isBusy => _state == ViewState.busy;
  bool get hasError => _state == ViewState.error;
  bool get isDisposed => _disposed;

  void setBusy() {
    _state = ViewState.busy;
    _errorMessage = null;
    notifyListeners();
  }

  void setIdle() {
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _state = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Limpia el mensaje de error sin tocar el resto del estado.
  void clearError() {
    if (_errorMessage == null && _state != ViewState.error) return;
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Ejecuta una operación de repositorio manejando `busy` y `error`.
  ///
  /// Devuelve el mismo [Result] para que la vista decida si navega o no.
  @protected
  Future<Result<T>> runGuarded<T>(
    Future<Result<T>> Function() action, {
    bool notifyOnSuccess = true,
  }) async {
    setBusy();
    late Result<T> result;
    try {
      result = await action();
    } on Object catch (error) {
      final failure = NetworkFailure('Ocurrió un error inesperado: $error');
      setError(failure.message);
      return Err<T>(failure);
    }
    if (_disposed) return result;
    switch (result) {
      case Ok<T>():
        if (notifyOnSuccess) {
          setIdle();
        } else {
          _state = ViewState.idle;
          _errorMessage = null;
        }
      case Err<T>(:final failure):
        setError(failure.message);
    }
    return result;
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
