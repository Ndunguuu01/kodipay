class ApiConfig {
  static const String baseUrl = 'http://192.168.100.71:5000/api';
  static const String wsUrl = 'ws://192.168.100.71:5000';
  static String? token;

  static void setToken(String? newToken) {
    token = newToken;
  }

  static void clearToken() {
    token = null;
  }
}
