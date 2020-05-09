import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/pages/home.dart';
import 'package:flutter_share/widgets/header.dart';
import 'package:flutter_share/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String mediaUrl;
  Comments({this.postId, this.ownerId, this.mediaUrl});
  @override
  CommentsState createState() => CommentsState();
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();

  StreamBuilder buildComments() {
    return StreamBuilder(
        stream: commentsRef
            .document(widget.postId)
            .collection('comments')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return circularProgress();
          List<Comment> comments = [];
          snapshot.data.documents.forEach((doc) {
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(
            children: comments,
          );
        });
  }

  void addComment() {
    commentsRef.document(widget.postId).collection('comments').add({
      'username': currentUser.username,
      'comment': commentController.text,
      'timestamp': timestamp,
      'avatarUrl': currentUser.photoUrl,
      'userId': currentUser.id
    });
    if (widget.ownerId != currentUser.id)
      activityFeedRef.document(widget.ownerId).collection('feedItems').add({
        'type': 'comment',
        'commentData': commentController.text,
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': widget.postId,
        'mediaUrl': widget.mediaUrl,
        'timestamp': timestamp,
      });
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: 'Comments'),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: 'Write a comment...'),
            ),
            trailing: OutlineButton(
              onPressed: () => addComment(),
              borderSide: BorderSide.none,
              child: Text('Post'),
            ),
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;
  Comment({
    this.username,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider()
      ],
    );
  }
}
