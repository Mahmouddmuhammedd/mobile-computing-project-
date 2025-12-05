// lib/screens/chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  ChatScreen({required this.chatId, required this.chatName, Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final uid = auth.user?.uid ?? '';

    final messagesQuery = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // newest first (we'll reverse list)
        .limit(200);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesQuery.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text('No messages yet'));
                }

                // ListView.builder with reverse: true so newest messages appear at bottom
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final text = data['text'] ?? '';
                    final senderEmail = data['senderEmail'] ?? '';
                    final senderId = data['senderId'] ?? '';
                    final timestamp = data['timestamp'] is Timestamp ? data['timestamp'] as Timestamp : null;
                    final timeStr = _formatTimestamp(timestamp);
                    final isMe = senderId == uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(text),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (senderEmail.isNotEmpty)
                                Text(senderEmail, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              if (senderEmail.isNotEmpty) SizedBox(width: 8),
                              Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // input area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(auth),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _sendMessage(auth),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _sendMessage(AuthService auth) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final uid = auth.user?.uid ?? '';
    final email = auth.user?.email ?? '';

    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    try {
      // 1) add message with server timestamp
      await chatDoc.collection('messages').add({
        'text': text,
        'senderId': uid,
        'senderEmail': email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2) update parent chat doc with last message/time
      await chatDoc.update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _ctrl.clear();

      // scroll to bottom (because ListView is reversed)
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send error: $e')));
      }
    }
  }
}
