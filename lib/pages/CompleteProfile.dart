import 'dart:developer';
import 'package:chatapp/models/UIHelper.dart';
import 'package:chatapp/models/UserModel.dart';
import 'package:chatapp/pages/HomePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CompleteProfile extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const CompleteProfile(
      {super.key, required this.userModel, required this.firebaseUser});

  @override
  _CompleteProfileState createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<CompleteProfile> {
  TextEditingController fullNameController = TextEditingController();

  void checkValues() {
    String fullname = fullNameController.text.trim();

    if (fullname == "") {
      print("Please fill all the fields");
      UIHelper.showAlertDialog(
          context, "Incomplete Data", "Please fill all the fields.");
    } else {
      log("Uploading data..");
      uploadData();
    }
  }

  void uploadData() async {
    UIHelper.showLoadingDialog(context, "Uploading data..");

    String? fullname = fullNameController.text.trim();

    widget.userModel.fullname = fullname;
    widget.userModel.profilepic = ''; // No profile picture field to update

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userModel.uid)
        .set(widget.userModel.toMap())
        .then((value) {
      log("Data uploaded!");
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) {
          return HomePage(
              userModel: widget.userModel, firebaseUser: widget.firebaseUser);
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("Complete Profile"),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: ListView(
            children: [
              SizedBox(
                height: 20,
              ),
              // Removed CircleAvatar and image picker logic
              Icon(
                Icons.person,
                size: 120, // Icon size can be adjusted
              ),
              SizedBox(
                height: 20,
              ),
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                ),
              ),
              SizedBox(
                height: 20,
              ),
              CupertinoButton(
                onPressed: () {
                  checkValues();
                },
                color: Theme.of(context).colorScheme.secondary,
                child: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
