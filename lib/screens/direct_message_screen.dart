import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/message_provider.dart';
import 'package:kodipay/providers/tenant_provider.dart';
import 'package:kodipay/models/tenant_model.dart';
import 'package:kodipay/models/message_model.dart';
import 'package:intl/intl.dart';

class DirectMessageScreen extends StatefulWidget {
  final String recipientId;
  final String recipientPhoneNumber;

  const DirectMessageScreen({
    super.key,
    required this.recipientId,
    required this.recipientPhoneNumber,
  });

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  TenantModel? _tenant;

  @override
  void initState() {
    super.initState();
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);

    // Fetch tenant details
    _tenant = tenantProvider.tenants.firstWhere(
      (t) => t.id == widget.recipientId,
      orElse: () => TenantModel(
        id: '',
        phoneNumber: '',
        firstName: '',
        lastName: '',
        email: '',
        status: '',
        paymentStatus: '',
        propertyId: '',
      ),
    );

    // Fetch direct messages
    messageProvider.fetchDirectMessages(widget.recipientId, context).then((_) {
      if (messageProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageProvider.errorMessage!)),
        );
      }
      // Scroll to bottom after messages are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    // Join the direct message room
    messageProvider.joinDirectMessage(authProvider.auth!.id, widget.recipientId);
  }

  Future<void> _sendMessage(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    messageProvider.sendDirectMessage(
      senderId: authProvider.auth!.id,
      recipientId: widget.recipientId,
      content: content,
    );

    // Optimistically add the message to the list
    messageProvider.directMessages.add(
      MessageModel(
        id: DateTime.now().toString(),
        senderId: authProvider.auth!.id,
        senderPhoneNumber: authProvider.auth!.phoneNumber,
        recipientId: widget.recipientId,
        recipientPhoneNumber: widget.recipientPhoneNumber,
        content: content,
        timestamp: DateTime.now(),
        isGroupMessage: false,
      ),
    );
    setState(() {});

    _messageController.clear();
    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final messageProvider = Provider.of<MessageProvider>(context);

    if (_tenant == null) {
      return const Scaffold(
        body: Center(child: Text('Tenant not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tenant!.fullName),
            Text(
              _tenant!.phoneNumber,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: Column(
        children: [
          Expanded(
            child: messageProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : messageProvider.directMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messageProvider.directMessages.length,
                        itemBuilder: (context, index) {
                          final message = messageProvider.directMessages[index];
                          final isMe = message.senderId == authProvider.auth!.id;
                          final showDate = index == 0 ||
                              !_isSameDay(
                                message.timestamp,
                                messageProvider.directMessages[index - 1].timestamp,
                              );

                          return Column(
                            crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: Text(
                                      _formatDate(message.timestamp),
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue[200] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe ? 'You' : _tenant!.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isMe ? Colors.blue[900] : Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(message.content),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        DateFormat('HH:mm').format(message.timestamp),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          if (messageProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                messageProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: const Color(0xFF90CAF9),
                  onPressed: () async => await _sendMessage(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }
}