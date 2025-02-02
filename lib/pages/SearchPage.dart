import 'dart:developer';
import 'package:chatapp/main.dart';
import 'package:chatapp/models/ChatRoomModel.dart';
import 'package:chatapp/models/UserModel.dart';
import 'package:chatapp/pages/ChatRoomPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const SearchPage(
      {Key? key, required this.userModel, required this.firebaseUser})
      : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();

  Future<ChatRoomModel?> getChatroomModel(UserModel targetUser) async {
    ChatRoomModel? chatRoom;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .where("participants.${widget.userModel.uid}", isEqualTo: true)
        .where("participants.${targetUser.uid}", isEqualTo: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Fetch the existing one
      var docData = snapshot.docs[0].data();
      ChatRoomModel existingChatroom =
          ChatRoomModel.fromMap(docData as Map<String, dynamic>);

      chatRoom = existingChatroom;
    } else {
      // Create a new one
      ChatRoomModel newChatroom = ChatRoomModel(
        chatroomid: uuid.v1(),
        lastMessage: "",
        participants: {
          widget.userModel.uid.toString(): true,
          targetUser.uid.toString(): true,
        },
      );

      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(newChatroom.chatroomid)
          .set(newChatroom.toMap());

      chatRoom = newChatroom;

      log("New Chatroom Created!");
    }

    return chatRoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users"),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search by Email",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      setState(() {});
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              CupertinoButton(
                onPressed: () {
                  setState(() {});
                },
                color: Theme.of(context).colorScheme.secondary,
                child: Text("Search"),
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .where("email",
                          isNotEqualTo: widget.userModel
                              .email) // Ensure the logged-in user is not included
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      if (snapshot.hasData) {
                        QuerySnapshot dataSnapshot =
                            snapshot.data as QuerySnapshot;
                        List<DocumentSnapshot> docs = dataSnapshot.docs;

                        if (docs.isEmpty) {
                          return Center(child: Text("No users found"));
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> userMap =
                                docs[index].data() as Map<String, dynamic>;
                            UserModel user = UserModel.fromMap(userMap);

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                              child: ListTile(
                                onTap: () async {
                                  ChatRoomModel? chatroomModel =
                                      await getChatroomModel(user);

                                  if (chatroomModel != null) {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return ChatRoomPage(
                                            targetUser: user,
                                            userModel: widget.userModel,
                                            firebaseUser: widget.firebaseUser,
                                            chatroom: chatroomModel,
                                          );
                                        },
                                      ),
                                    );
                                  }
                                },
                                contentPadding: EdgeInsets.all(10),
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(user.profilepic!),
                                  backgroundColor: Colors.grey[500],
                                ),
                                title: Text(user.fullname!),
                                subtitle: Text(user.email!),
                                trailing: Icon(Icons.keyboard_arrow_right),
                              ),
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text("An error occurred!"));
                      } else {
                        return Center(child: Text("No users found"));
                      }
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
