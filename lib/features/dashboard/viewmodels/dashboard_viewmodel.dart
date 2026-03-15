import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> refresh() async {
    setLoading(true);
    setError(null);
    try {
      // Logic to refresh dashboard data would go here
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}
