import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

ImagePicker picker = ImagePicker();

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[100],
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Timeline',
                style: TextStyle(
                    fontSize: 30,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  Get.bottomSheet(TweetForm());
                },
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.black,
                ),
                iconSize: 30,
              ),
            ],
          ),
        ),
      ),
      body: Container(
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
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('tweets')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                return ListView.builder(
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              child: CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(
                                  message['profile-image'],
                                ),
                              ),
                            ),
                            title: Text(
                              message['accName'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(message['message']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.network(
                              message['image-url'],
                              width: 300,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class TweetForm extends StatefulWidget {
  @override
  _TweetFormState createState() => _TweetFormState();
}

class _TweetFormState extends State<TweetForm> {
  PlatformFile? pickedFile;
  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc', 'png'],
    );

    if (result == null) return;
    setState(() {
      pickedFile = result.files.first;
    });
  }

  Widget buildProgress() {
    return StreamBuilder<TaskSnapshot>(
      stream: uploadTask?.snapshotEvents,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          double progress = data.bytesTransferred / data.totalBytes;
          return SizedBox(
            height: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.black,
                    color: Colors.black),
                Center(
                  child: Text(
                    '${(progress * 100).toStringAsFixed(2)} %',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 50,
            ),
          );
        }
      },
    );
  }

  UploadTask? uploadTask;
  Future uploadFile() async {
    kIsWeb == true
        ? uploadTask = FirebaseStorage.instance
            .ref('files/${pickedFile!.name}')
            .putData(pickedFile!.bytes!)
        : uploadTask = FirebaseStorage.instance
            .ref('files/${pickedFile!.name}')
            .putFile(File(pickedFile!.path!));
  }

  final _formKey = GlobalKey<FormState>();
  late String _tweetMessage; // Declare _tweetMessage here

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.white,
        ),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Tweet...',
                      suffixIcon: IconButton(
                        onPressed: () async {
                          uploadFile();
                          final snapshot =
                              await uploadTask!.whenComplete(() {});
                          final urlDownload =
                              await snapshot.ref.getDownloadURL();
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            FirebaseFirestore.instance
                                .collection('tweets')
                                .add({
                              'message': _tweetMessage,
                              'accName': FirebaseAuth
                                      .instance.currentUser?.displayName ??
                                  "",
                              'time': DateTime.now().toString(),
                              'image-url': urlDownload,
                              'profile-image':
                                  FirebaseAuth.instance.currentUser!.photoURL,
                            });
                            Get.back();
                          }
                        },
                        icon: Icon(Icons.send),
                      ),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a tweet message';
                      }
                      return null;
                    },
                    onSaved: (value) => _tweetMessage = value!,
                  ),
                  SizedBox(height: 20),
                  if (pickedFile != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        color: Colors.grey,
                        child: Center(
                          child: kIsWeb == true
                              ? Image.memory(
                                  pickedFile!.bytes!,
                                  width: 300,
                                  height: 300,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(
                                    pickedFile!.path!,
                                  ),
                                  width: 300,
                                  height: 300,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  if (pickedFile == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 90),
                      child: IconButton(
                        icon: Icon(Icons.image),
                        iconSize: 100,
                        onPressed: () {
                          selectFile();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
