import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/message_provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:intl/intl.dart';
import 'package:kodipay/models/message_model.dart';

class GroupChatScreen extends StatefulWidget {
  final String propertyId;

  const GroupChatScreen({super.key, required this.propertyId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);

    // Fetch property details
    final property = propertyProvider.getPropertyById(widget.propertyId);
    if (property == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property not found')),
      );
      return;
    }

    // Fetch group messages
    messageProvider.fetchGroupMessages(widget.propertyId, context).then((_) {
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

    // Join the group chat room
    messageProvider.joinGroupChat(widget.propertyId);
  }

  void _sendMessage() {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      messageProvider.sendGroupMessage(
        widget.propertyId,
        authProvider.auth!.id,
        content,
      );
      // Optimistically add the message
      messageProvider.groupMessages.add(
        MessageModel(
          id: DateTime.now().toString(),
          senderId: authProvider.auth!.id,
          senderPhoneNumber: authProvider.auth!.phoneNumber,
          content: content,
          timestamp: DateTime.now(),
          isGroupMessage: true,
          propertyId: widget.propertyId,
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
    final propertyProvider = Provider.of<PropertyProvider>(context);

    final property = propertyProvider.getPropertyById(widget.propertyId);
    if (property == null) {
      return const Scaffold(
        body: Center(child: Text('Property not found')),
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
            Text(property.name),
            Text(
              'Group Chat',
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
                : messageProvider.groupMessages.isEmpty
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
                        itemCount: messageProvider.groupMessages.length,
                        itemBuilder: (context, index) {
                          final message = messageProvider.groupMessages[index];
                          final isMe = message.senderId == authProvider.auth!.id;
                          final showDate = index == 0 ||
                              !_isSameDay(
                                message.timestamp,
                                messageProvider.groupMessages[index - 1].timestamp,
                              );

                          return Column(
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    _formatDate(message.timestamp),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ),
                              Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFF90CAF9) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                              isMe ? 'You' : message.senderPhoneNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                          color: isMe ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message.content,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                              DateFormat('HH:mm').format(message.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMe ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
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
                  onPressed: _sendMessage,
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