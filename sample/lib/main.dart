import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Listener',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MessageList(),
    );
  }
}

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    listenForSms();
  }

  Future<void> requestPermissions() async {
    await Permission.sms.request();
    await Permission.storage.request();
  }

  void listenForSms() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        storeMessageInFirebase(message);
      },
      listenInBackground: false,
    );
  }

  void storeMessageInFirebase(SmsMessage msg) async {
    await FirebaseFirestore.instance.collection('messages').add({
      'address': msg.address,
      'body': msg.body,
      'timestamp': DateTime.fromMillisecondsSinceEpoch(msg.date!).toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('messages').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var message = snapshot.data!.docs[index];
              return ListTile(
                title: Text(message['address']),
                subtitle: Text(message['body']),
                trailing: Text(message['timestamp']),
              );
            },
          );
        },
      ),
    );
  }
}
