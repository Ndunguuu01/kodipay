import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message_model.dart';
import '../config/api_config.dart';
import '../services/api.dart';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MessageProvider with ChangeNotifier {
  List<MessageModel> _groupMessages = [];
  List<MessageModel> _directMessages = [];
  List<MessageModel> _messages = [];
  String? _errorMessage;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isLoading = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  String? _lastWebSocketUrl;
  bool _isConnecting = false;
  bool _isDisposed = false;
  StreamSubscription? _webSocketSubscription;
  Timer? _heartbeatTimer;
  IO.Socket? _socket;

  List<MessageModel> get groupMessages => _groupMessages;
  List<MessageModel> get directMessages => _directMessages;
  List<MessageModel> get messages => _messages;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isConnecting => _isConnecting;

  Future<void> fetchMessages() async {
    if (_isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    developer.log('Fetching all messages...', name: 'MessageProvider');
    notifyListeners();

    // Ensure ApiConfig.token is up to date
    ApiConfig.token = await ApiService.getAuthToken();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiConfig.token != null) 'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );
      developer.log('Fetch messages response: ${response.statusCode} - ${response.body}', name: 'MessageProvider');

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = json.decode(response.body);
        _messages = messagesJson.map((json) => MessageModel.fromJson(json)).toList();
        _errorMessage = null;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Authentication required. Please log in again.';
      } else {
        _errorMessage = 'Failed to fetch messages: ${response.statusCode}';
      }
    } catch (e, stack) {
      if (!_isDisposed) {
        _errorMessage = 'Error fetching messages: $e';
        developer.log('Error fetching messages', name: 'MessageProvider', error: e, stackTrace: stack);
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchGroupMessages(String propertyId) async {
    if (_isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    developer.log('Fetching group messages for propertyId: $propertyId', name: 'MessageProvider');
    notifyListeners();

    // Ensure ApiConfig.token is up to date
    ApiConfig.token = await ApiService.getAuthToken();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/group/$propertyId'),
        headers: {
          'Content-Type': 'application/json',
          if (ApiConfig.token != null) 'Authorization': 'Bearer ${ApiConfig.token}',
        },
      );
      developer.log('Fetch group messages response: ${response.statusCode} - ${response.body}', name: 'MessageProvider');

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = json.decode(response.body);
        _groupMessages = messagesJson.map((json) => MessageModel.fromJson(json)).toList();
        _errorMessage = null;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Authentication required. Please log in again.';
      } else {
        _errorMessage = 'Failed to fetch group messages: ${response.statusCode}';
      }
    } catch (e, stack) {
      if (!_isDisposed) {
        _errorMessage = 'Error fetching group messages: $e';
        developer.log('Error fetching group messages', name: 'MessageProvider', error: e, stackTrace: stack);
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchDirectMessages(String recipientId) async {
    if (_isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    developer.log('Fetching direct messages for recipientId: $recipientId', name: 'MessageProvider');
    notifyListeners();

    try {
      final authToken = await ApiService.getAuthToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/direct/$recipientId'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );
      developer.log('Fetch direct messages response: ${response.statusCode} - ${response.body}', name: 'MessageProvider');

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = json.decode(response.body);
        _directMessages = messagesJson.map((json) => MessageModel.fromJson(json)).toList();
        _errorMessage = null;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Authentication required. Please log in again.';
      } else {
        _errorMessage = 'Failed to fetch direct messages: ${response.statusCode}';
      }
    } catch (e, stack) {
      if (!_isDisposed) {
        _errorMessage = 'Error fetching direct messages: $e';
        developer.log('Error fetching direct messages', name: 'MessageProvider', error: e, stackTrace: stack);
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _setupWebSocket(String userId) async {
    if (_isDisposed || _isConnecting) return;
    developer.log('Setting up Socket.IO for userId: $userId', name: 'MessageProvider');
    try {
      _isConnecting = true;
      notifyListeners();

      // Clean up existing connection
      await _cleanupWebSocket();

      // Refresh token before connecting
      bool refreshSuccess = await _refreshTokenIfNeeded();
      if (!refreshSuccess) {
        developer.log('Token refresh failed before WebSocket connection', name: 'MessageProvider');
        _errorMessage = 'Authentication required. Please log in again.';
        _isConnecting = false;
        notifyListeners();
        return;
      }

      // Get the current auth token
      final authToken = await ApiService.getAuthToken();
      if (authToken == null) {
        _errorMessage = 'Authentication required. Please log in again.';
        _isConnecting = false;
        notifyListeners();
        return;
      }

      final socket = IO.io(
        ApiConfig.wsUrl,
        IO.OptionBuilder()
          .setTransports(<String>['websocket'])
          .setQuery({'userId': userId, 'token': authToken})
          .disableAutoConnect()
          .build(),
      );
      _socket = socket;
      socket.connect();

      socket.onConnect((_) {
        developer.log('Socket.IO connected', name: 'MessageProvider');
        _isConnected = true;
        _reconnectAttempts = 0;
        _isConnecting = false;
        notifyListeners();
      });

      socket.on('newMessage', (data) {
        developer.log('Socket.IO newMessage: $data', name: 'MessageProvider');
        try {
          final messageModel = MessageModel.fromJson(data);
          _messages.add(messageModel);
          notifyListeners();
        } catch (e, stack) {
          developer.log('Error processing Socket.IO message', name: 'MessageProvider', error: e, stackTrace: stack);
        }
      });

      socket.onDisconnect((_) {
        developer.log('Socket.IO disconnected', name: 'MessageProvider');
        _isConnected = false;
        _isConnecting = false;
        notifyListeners();
        _scheduleReconnect();
      });

      socket.onError((error) {
        developer.log('Socket.IO error: $error', name: 'MessageProvider');
        _isConnected = false;
        _isConnecting = false;
        notifyListeners();
        _scheduleReconnect();
      });
    } catch (e, stack) {
      developer.log('Error setting up Socket.IO', name: 'MessageProvider', error: e, stackTrace: stack);
      if (!_isDisposed) {
        _isConnected = false;
        _isConnecting = false;
        notifyListeners();
        _scheduleReconnect();
      }
    }
  }

  Future<bool> _refreshTokenIfNeeded() async {
    // Access tokens are private in ApiService, so use public getters/setters
    final refreshToken = await ApiService.getRefreshToken();
    if (refreshToken == null) {
      developer.log('No refresh token available', name: 'MessageProvider');
      return false;
    }

    try {
      developer.log('Attempting to refresh token', name: 'MessageProvider');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        final newRefreshToken = data['refreshToken'];

        if (newToken != null && newRefreshToken != null) {
          await ApiService.setAuthToken(newToken);
          await ApiService.setRefreshToken(newRefreshToken);
          ApiConfig.setToken(newToken);
          developer.log('Token refreshed successfully and set for ApiService', name: 'MessageProvider');
          return true;
        }
      }

      developer.log('Token refresh failed with response: ${response.statusCode} - ${response.body}', name: 'MessageProvider');
      return false;
    } catch (e) {
      developer.log('Error during token refresh: $e', name: 'MessageProvider');
      return false;
    }
  }

  Future<void> _cleanupWebSocket() async {
    try {
      if (_socket != null) {
        _socket!.dispose();
        _socket = null;
      }
      _isConnected = false;
      _isConnecting = false;
    } catch (e) {
      developer.log('Error cleaning up Socket.IO', name: 'MessageProvider', error: e);
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed || _isConnecting) return;
    
    _reconnectAttempts++;
    final delay = min(1000 * pow(2, _reconnectAttempts), 30000);
    
    Future.delayed(Duration(milliseconds: delay.toInt()), () {
      if (!_isDisposed && !_isConnected && !_isConnecting) {
        _setupWebSocket(_lastWebSocketUrl?.split('userId=').last ?? '');
      }
    });
  }

  void joinGroupChat(String propertyId) {
    if (!_isConnecting && !_isDisposed) {
      _setupWebSocket(propertyId);
    }
  }

  void joinDirectMessage(String senderId, String recipientId) {
    if (!_isConnecting && !_isDisposed) {
      _setupWebSocket('$senderId-$recipientId');
    }
  }

  Future<void> sendGroupMessage(String propertyId, String senderId, String content) async {
    developer.log('Sending group message: propertyId=$propertyId, senderId=$senderId, content=$content', name: 'MessageProvider');
    try {
      if (propertyId.isEmpty || senderId.isEmpty || content.isEmpty) {
        developer.log('ERROR: One or more required fields are empty. propertyId: $propertyId, senderId: $senderId, content: $content', name: 'MessageProvider');
        _errorMessage = 'Cannot send message: propertyId, senderId, and content are required.';
        notifyListeners();
        return;
      }
      // Get the current auth token
      final authToken = await ApiService.getAuthToken();
      if (authToken == null) {
        _errorMessage = 'Authentication required. Please log in again.';
        notifyListeners();
        return;
      }

      final requestBody = {
        'propertyId': propertyId,
        'senderId': senderId,
        'content': content,
      };
      developer.log('Request body being sent: $requestBody', name: 'MessageProvider');
      developer.log('Request URL: ${ApiConfig.baseUrl}/messages/group', name: 'MessageProvider');
      developer.log('Auth token present: ${authToken.isNotEmpty}', name: 'MessageProvider');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/messages/group'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(requestBody),
      );
      developer.log('Send group message response: ${response.statusCode} - ${response.body}', name: 'MessageProvider');

      if (response.statusCode == 401) {
        _errorMessage = 'Authentication required. Please log in again.';
      } else if (response.statusCode != 201) {
        _errorMessage = 'Failed to send group message';
      }
      notifyListeners();
    } catch (e, stack) {
      _errorMessage = 'Error sending group message: $e';
      developer.log('Error sending group message', name: 'MessageProvider', error: e, stackTrace: stack);
      notifyListeners();
    }
  }

  Future<void> sendDirectMessage(String senderId, String recipientId, String content) async {
    developer.log('Sending direct message: senderId=$senderId, recipientId=$recipientId, content=$content', name: 'MessageProvider');
    try {
      if (senderId.isEmpty || recipientId.isEmpty || content.isEmpty) {
        developer.log('ERROR: One or more required fields are empty. senderId: $senderId, recipientId: $recipientId, content: $content', name: 'MessageProvider');
        _errorMessage = 'Cannot send message: senderId, recipientId, and content are required.';
        notifyListeners();
        return;
      }
      final authToken = await ApiService.getAuthToken();
      if (authToken == null) {
        _errorMessage = 'Authentication required. Please log in again.';
        notifyListeners();
        return;
      }
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/messages/direct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'senderId': senderId,
          'recipientId': recipientId,
          'content': content,
        }),
      );
      developer.log('Send direct message response: \\${response.statusCode} - \\${response.body}', name: 'MessageProvider');

      if (response.statusCode != 201) {
        _errorMessage = 'Failed to send direct message';
        notifyListeners();
      }
    } catch (e, stack) {
      _errorMessage = 'Error sending direct message: $e';
      developer.log('Error sending direct message', name: 'MessageProvider', error: e, stackTrace: stack);
      notifyListeners();
    }
  }

  Future<void> sendMessage(String recipientId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'recipientId': recipientId,
          'content': content,
        }),
      );

      if (response.statusCode != 201) {
        _errorMessage = 'Failed to send message';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error sending message: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupWebSocket();
    super.dispose();
  }
}
