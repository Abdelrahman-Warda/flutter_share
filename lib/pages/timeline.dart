import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/models/user.dart';
import 'package:flutter_share/pages/search.dart';
import 'package:flutter_share/widgets/header.dart';
import 'package:flutter_share/widgets/post.dart';
import 'package:flutter_share/widgets/progress.dart';
import 'home.dart';

class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];
  
  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  buildUsersToFollow() {
    return StreamBuilder(
        stream: usersRef
            .orderBy('timestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return circularProgress();
          List<UserResult> userResults = [];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromDocument(doc);
            final bool isAuthUser = (currentUser.id == user.id);
            if (isAuthUser) return;

            final bool isFollowingUser = followingList.contains(user.id);
            if (isFollowingUser) return;

            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          });
          return Container(
            color: Theme.of(context).accentColor.withOpacity(0.2),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.person_add,
                        color: Theme.of(context).primaryColor,
                        size: 30,
                      ),
                      SizedBox(
                        width: 30,
                      ),
                      Text(
                        'Users to Follow',
                        style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 30),
                      )
                    ],
                  ),
                ),
                Column(children: userResults)
              ],
            ),
          );
        });
  }

  buildTimeline() {
    if (posts == null)
      return circularProgress();
    else if (posts.isEmpty) return buildUsersToFollow();
    return ListView(
      children: posts,
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
