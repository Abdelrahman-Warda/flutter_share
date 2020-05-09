import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/models/user.dart';
import 'package:flutter_share/pages/activity_feed.dart';
import 'package:flutter_share/pages/create_account.dart';
import 'package:flutter_share/pages/profile.dart';
import 'package:flutter_share/pages/search.dart';
import 'package:flutter_share/pages/timeline.dart';
import 'package:flutter_share/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final CollectionReference usersRef = Firestore.instance.collection('users');
final CollectionReference postsRef = Firestore.instance.collection('posts');
final CollectionReference commentsRef =
    Firestore.instance.collection('comments');
final CollectionReference activityFeedRef =
    Firestore.instance.collection('feed');
final CollectionReference followersRef =
    Firestore.instance.collection('followers');
final CollectionReference followingRef =
    Firestore.instance.collection('following');
final CollectionReference timelineRef =
    Firestore.instance.collection('timeline');
final StorageReference storageRef = FirebaseStorage.instance.ref();
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  final bool isOpenningApp;
  Home({this.isOpenningApp = true});
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    // get permissions if on iOS
    if (Platform.isIOS) {
      _firebaseMessaging.requestNotificationPermissions(
          IosNotificationSettings(alert: true, badge: true, sound: true));
      _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
        // print('Settings registered: $settings');
      });
    }
    _firebaseMessaging.getToken().then((token) {
      // print('Firebase MEssaging Token: $token\n');
      usersRef
          .document(user.id)
          .updateData({'androidNotificationToken': token});
    });

    _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        // print('on message: $message\n');
        // get intended recipient and message body and displaying notification
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];

        if (recipientId == user.id) {
          // print('Notification shown!');
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        // print('Notification not shown');
      },
    );
  }

  void handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      final GoogleSignInAccount user = googleSignIn.currentUser;
      DocumentSnapshot doc = await usersRef.document(user.id).get();
      if (!doc.exists) {
        final username = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => CreateAccount()));

        await usersRef.document(user.id).setData({
          'id': user.id,
          'username': username,
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoUrl,
          'bio': '',
          'timestamp': timestamp,
        });
        //make new user their own follower 'to see their own posts'
        await followersRef
            .document(user.id)
            .collection('userFollowers')
            .document(user.id)
            .setData({});

        doc = await usersRef.document(user.id).get();
      }
      currentUser = User.fromDocument(doc);
    }
    setState(() => isAuth = account != null);
    if (isAuth) configurePushNotifications();
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen((account) => handleSignIn(account))
        // .onError((error) => print('Error signing in: $error'))
        ;
    if (widget.isOpenningApp == true)
      googleSignIn
              .signInSilently(suppressErrors: false)
              .then((account) => handleSignIn(account))
          // .catchError((error) => print('Error signing in: $error'))
          ;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(
            profileId: currentUser.id,
          ),
        ],
        controller: pageController,
        onPageChanged: ((pageIndex) =>
            setState(() => this.pageIndex = pageIndex)),
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        activeColor: Theme.of(context).primaryColor,
        onTap: ((selectedIndex) => pageController.animateToPage(
              selectedIndex,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOutExpo,
            )),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 35)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle))
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'FlutterShare',
              style: TextStyle(
                  fontFamily: "Signatra", fontSize: 90, color: Colors.white),
            ),
            GestureDetector(
              onTap: () => googleSignIn.signIn(),
              child: Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: AssetImage('assets/images/google_signin_button.png'),
                  fit: BoxFit.cover,
                )),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
