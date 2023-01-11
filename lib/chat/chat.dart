import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class Chat1 extends StatefulWidget {
  const Chat1({super.key});

  @override
  State<Chat1> createState() => _Chat1State();
}

class _Chat1State extends State<Chat1> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.brown[100],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: ChatScreen()),
      ),
    );
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late String messageText;
  late String username;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          username = user.displayName!;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(35),
            bottomRight: Radius.circular(35),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // List of messages
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('messages')
                    .orderBy('time')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final messages = snapshot.data!.docs.reversed;
                  List<Widget> messageWidgets = [];
                  for (var message in messages) {
                    final messageText = message.get('text');
                    final messageSender = message.get('sender');
                    final currentUser = username;

                    final messageWidget = MessageBubble(
                      sender: messageSender,
                      text: messageText,
                      isMe: currentUser == messageSender,
                    );
                    messageWidgets.add(messageWidget);
                  }
                  return Expanded(
                    child: ListView(
                      physics: ScrollPhysics(),
                      shrinkWrap: true,
                      primary: true,
                      reverse: true,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      children: messageWidgets,
                    ),
                  );
                },
              ),
              // Send message form
              Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: TextFormField(
                    onChanged: (value) => messageText = value,
                    decoration: InputDecoration(
                      hintText: 'Enter a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _firestore.collection('messages').add({
                            'text': messageText,
                            'sender': username,
                            'time': Timestamp.now(),
                            'message-id':
                                _firestore.collection('messages').doc().id,
                          });
                          // Clear the text field
                          _formKey.currentState!.reset();
                        },
                        icon: Icon(Icons.send),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;
  MessageBubble(
      {super.key,
      required this.sender,
      required this.text,
      required this.isMe,
      this.id,
      this.message});

  final String sender;
  final String text;
  final bool isMe;
  final String? id;
  final MessageBubble? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          GestureDetector(
            onLongPress: () {
              if (isMe) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Message'),
                    content:
                        Text('Are you sure you want to delete this message?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (isMe) {
                            final messagesRef = FirebaseFirestore.instance
                                .collectionGroup('messages')
                                .where('message-id',
                                    isEqualTo: message
                                        ?.id); // Use the 'message-id' field to filter the query

                            // Delete the message document
                            messagesRef.get().then((snapshot) {
                              if (snapshot.docs.isNotEmpty) {
                                snapshot.docs[0].reference.delete();
                              }
                            });
                          }
                          Navigator.pop(context);
                        },
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Material(
              borderRadius: BorderRadius.only(
                topLeft: isMe ? Radius.circular(30) : Radius.zero,
                topRight: isMe ? Radius.zero : Radius.circular(30),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              elevation: 5,
              color: isMe
                  ? Color.fromARGB(169, 102, 103, 104)
                  : Color.fromARGB(144, 0, 0, 0),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isMe ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
