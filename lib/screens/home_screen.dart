import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;
    final chatsCol = FirebaseFirestore.instance.collection('chats');
    final presenceRef = FirebaseDatabase.instance.ref('presence');

    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        actions: [
          IconButton(onPressed: ()=>auth.signOut(), icon: Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          ListTile(title: Text(user?.email ?? '')),
          
          StreamBuilder<DatabaseEvent>(
            stream: presenceRef.onValue,
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.snapshot.value == null) {
                return SizedBox.shrink();
              }
              final map = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
              final onlineCount = map.values.where((v) {
                try { return (v is Map && v['online'] == true); } catch (_) { return false; }
              }).length;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: Colors.green),
                    SizedBox(width: 8),
                    Text('$onlineCount users online'),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatsCol.orderBy('lastMessageTime', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text('No chats yet. Tap + to create one.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Chat';
                    final lastMsg = data['lastMessage'] ?? '';
                    final lastTime = data['lastMessageTime'];
                    String timeStr = '';
                    if (lastTime is Timestamp) {
                      final dt = lastTime.toDate();
                      timeStr = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
                    }
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(lastMsg.isNotEmpty ? '$lastMsg • $timeStr' : 'No messages'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(chatId: d.id, chatName: name),
                      )),
                    );
                  }
                );
              }
            )
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nameController = TextEditingController();
          final res = await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('New Chat'),
              content: TextField(controller: nameController, decoration: InputDecoration(labelText:'Chat name')),
              actions: [
                TextButton(onPressed: ()=>Navigator.pop(context), child: Text('Cancel')),
                TextButton(onPressed: ()=>Navigator.pop(context, nameController.text.trim()), child: Text('Create')),
              ],
            )
          );

          if (res != null && res.isNotEmpty) {
            try {
              final docRef = await chatsCol.add({
                'name': res,
                'createdAt': FieldValue.serverTimestamp(),
                'lastMessage': '',
                'lastMessageTime': FieldValue.serverTimestamp(),
              });

              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChatScreen(chatId: docRef.id, chatName: res),
              ));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create chat error: $e')));
            }
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
