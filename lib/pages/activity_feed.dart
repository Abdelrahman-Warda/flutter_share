import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/pages/home.dart';
import 'package:flutter_share/pages/post_screen.dart';
import 'package:flutter_share/pages/profile.dart';
import 'package:flutter_share/widgets/header.dart';
import 'package:flutter_share/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();
    List<ActivityFeedItem> feedItems = [];
    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });
    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).accentColor,
      appBar: header(context, title: 'Activity Feed'),
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }
            return ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    this.username,
    this.userId,
    this.postId,
    this.type,
    this.mediaUrl,
    this.userProfileImg,
    this.commentData,
    this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      postId: doc['postId'],
      type: doc['type'],
      mediaUrl: doc['mediaUrl'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
    );
  }
  configureMediaPreview(BuildContext context) {
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PostScreen(
                      postId: postId,
                      userId: userId,
                    ))),
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(mediaUrl),
                      fit: BoxFit.cover)),
            ),
          ),
        ),
      );
    } else
      mediaPreview = Text('');
    if (type == 'like')
      activityItemText = 'liked your post';
    else if (type == 'follow')
      activityItemText = 'is following you';
    else if (type == 'comment')
      activityItemText = 'replied: $commentData';
    else
      activityItemText = 'Error: unknown type $type';
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                        text: username,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' $activityItemText')
                  ]),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

  showProfile(BuildContext context, {String profileId}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Profile(
                  profileId: profileId,
                )));
  }