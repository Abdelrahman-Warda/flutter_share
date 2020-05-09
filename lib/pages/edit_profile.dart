import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:flutter_share/models/user.dart';
import 'package:flutter_share/pages/home.dart';
import 'package:flutter_share/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  User user;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool _displayNameValid = true;
  bool _bioValid = true;

  void getUser() async {
    setState(() => isLoading = true);
    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Column buildUserNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Display Name',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: 'Update Display Name',
            errorText: _displayNameValid ? null : 'Display Name is too short',
          ),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Bio',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: 'Update Bio',
            errorText: _bioValid ? null : 'Bio is too long',
          ),
        )
      ],
    );
  }

  void updateProfileData() {
    setState(() {
      _displayNameValid = !(displayNameController.text.trim().length < 3 ||
          displayNameController.text.isEmpty);
      _bioValid = !(bioController.text.trim().length > 100);
    });
    if (_displayNameValid && _bioValid) {
      usersRef.document(widget.currentUserId).updateData({
        'displayName': displayNameController.text,
        'bio': bioController.text,
      });
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text('Profile updated!')));
    }
  }

  void logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home(isOpenningApp: false,)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.done,
              size: 30,
              color: Colors.green,
            ),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                          top: 16,
                          bottom: 8,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey,
                          backgroundImage: CachedNetworkImageProvider(
                            user.photoUrl,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            buildUserNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: () => updateProfileData(),
                        child: Text(
                          'Update Profile',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: FlatButton.icon(
                          onPressed: () => logout(),
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                          label: Text(
                            'Logout',
                            style: TextStyle(color: Colors.red, fontSize: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
