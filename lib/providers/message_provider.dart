import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:kodipay/services/api.dart';
import 'package:kodipay/models/message_model.dart';

class MessageProvider with ChangeNotifier {
  List<MessageModel> _groupMessages = [];
  List<MessageModel> _directMessages = [];
  bool _isLoading = false;
  String? _errorMessage;
  late IO.Socket _socket;

  List<MessageModel> get groupMessages => _groupMessages;
  List<MessageModel> get directMessages => _directMessages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  MessageProvider() {
    _initializeSocket();
  }

  void _initializeSocket() {
    _socket = IO.io(ApiService.baseUrl.replaceAll('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to WebSocket server');
    });

    _socket.on('groupMessage', (data) {
      print('Received group message: $data');
      if (data == null || !data.containsKey('content')) {
        print('Error: Invalid group message data');
        return;
      }
      _groupMessages.add(MessageModel(
        id: DateTime.now().toString(), // Temporary ID for real-time messages
        senderId: data['sender'],
        senderPhoneNumber: 'Unknown', // Will be populated when fetching history
        content: data['content'],
        timestamp: DateTime.parse(data['timestamp']),
        isGroupMessage: true,
        propertyId: data['propertyId'],
      ));
      notifyListeners();
    });

    _socket.on('directMessage', (data) {
      print('Received direct message: $data');
      if (data == null || !data.containsKey('content')) {
        print('Error: Invalid direct message data');
        return;
      }
      _directMessages.add(MessageModel(
        id: DateTime.now().toString(), // Temporary ID for real-time messages
        senderId: data['sender'],
        senderPhoneNumber: 'Unknown', // Will be populated when fetching history
        recipientId: data['recipientId'],
        content: data['content'],
        timestamp: DateTime.parse(data['timestamp']),
        isGroupMessage: false,
      ));
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      print('Disconnected from WebSocket server');
    });
  }

  // Join a group chat
  void joinGroupChat(String propertyId) {
    _socket.emit('joinGroupChat', propertyId);
  }

  // Join a direct message conversation
  void joinDirectMessage(String senderId, String recipientId) {
    _socket.emit('joinDirectMessage', {
      'senderId': senderId,
      'recipientId': recipientId,
    });
  }

  // Send a group message
  void sendGroupMessage(String propertyId, String senderId, String content) {
    _socket.emit('sendGroupMessage', {
      'propertyId': propertyId,
      'senderId': senderId,
      'content': content,
    });
  }

  // Send a direct message
  Future<void> sendDirectMessage({required String senderId, required String recipientId, required String content,}) async {
    _socket.emit('sendDirectMessage', {
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
    });
  }

  // Fetch group chat messages
  Future<void> fetchGroupMessages(String propertyId, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/messages/group/$propertyId', context: context);
      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = jsonDecode(response.body);
        _groupMessages = messagesJson.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to fetch group messages: ${response.statusCode}';
        print(_errorMessage); // Log the error
      }
    } catch (e) {
      _errorMessage = 'Error fetching group messages: $e';
      print(_errorMessage); // Log the error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch direct messages
  Future<void> fetchDirectMessages(String recipientId, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/messages/direct/$recipientId', context: context);
      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = jsonDecode(response.body);
        _directMessages = messagesJson.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        _errorMessage = 'Failed to fetch direct messages: ${response.statusCode}';
        print(_errorMessage); // Log the error
      }
    } catch (e) {
      _errorMessage = 'Error fetching direct messages: $e';
      print(_errorMessage); // Log the error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }
}
