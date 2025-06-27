import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/message_provider.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isInitialized = false;
  bool _isLoading = false;
  List<MessageModel> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  Future<void> _initializeMessages() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      await messageProvider.fetchMessages();
      
      if (!mounted) return;
      
      setState(() {
        _filteredMessages = messageProvider.messages;
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    }
  }

  void _updateSearchQuery(String query) {
    if (!mounted) return;
    
    setState(() {
      _searchQuery = query;
      _filteredMessages = Provider.of<MessageProvider>(context, listen: false)
          .messages
          .where((message) =>
              message.content.toLowerCase().contains(query.toLowerCase()) ||
              message.senderName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: _updateSearchQuery,
                  ),
                ),
                Expanded(
                  child: Consumer<MessageProvider>(
                    builder: (context, messageProvider, child) {
                      final messages = _searchQuery.isEmpty
                          ? messageProvider.messages
                          : _filteredMessages;

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text('No messages yet'),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(message.senderName[0]),
                            ),
                            title: Text(message.senderName),
                            subtitle: Text(message.content),
                            trailing: Text(
                              DateFormat('MMM d, h:mm a')
                                  .format(message.timestamp),
                            ),
                            onTap: () {
                              if (message.isGroupMessage) {
                                context.push('/messaging/group/${message.propertyId}');
                              } else {
                                context.push('/messaging/direct/${message.recipientId}/${message.recipientPhoneNumber}');
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('New Message'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.group),
                    title: const Text('Group Chat'),
                    subtitle: const Text('Send a message to all tenants in a property'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/messaging/group');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Direct Message'),
                    subtitle: const Text('Send a message to a specific tenant'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/messaging/direct');
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 