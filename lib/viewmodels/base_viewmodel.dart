import 'package:flutter/foundation.dart';

import '../services/service_exception.dart';

// Shared loading/error handling for every ViewModel
class BaseViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  bool get loading => _loading;

  // Message of the last failed "run", or null.
  String? get error => _error;

  // Runs action with loading = true
  // Returns false when failed
  // Error message is stored in "error
  @protected
  Future<bool> run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on ServiceException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Something went wrong. $e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // A page can be closed while a request is still running.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
