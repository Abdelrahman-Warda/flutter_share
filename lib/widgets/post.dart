import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/models/user.dart';
import 'package:flutter_share/pages/activity_feed.dart';
import 'package:flutter_share/pages/comments.dart';
import 'package:flutter_share/pages/home.dart';
import 'package:flutter_share/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }
  int getLikeCount(likes) {
    if (likes == null) return 0;
    int count = 0;

    likes.values.forEach((val) {
      if (val == true) count++;
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
      postId: this.postId,
      ownerId: this.ownerId,
      username: this.username,
      location: this.location,
      description: this.description,
      mediaUrl: this.mediaUrl,
      likes: this.likes,
      likeCount: getLikeCount(this.likes));
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  bool showHeart = false;
  bool isLiked;
  int likeCount;
  Map likes;

  _PostState(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes,
      this.likeCount});

  deletePost() {
    // delete the post itself
    postsRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) doc.reference.delete();
    });

    // delete uploaded image
    storageRef.child('post_$postId.jpg').delete();

    //delete all activityfeed notifications
    activityFeedRef
        .document(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .getDocuments()
        .then((snapshot) {
      snapshot.documents.forEach((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    });

    //delete all comments
    commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments()
        .then((snapshot) {
      snapshot.documents.forEach((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    });
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text('Remove this post?'),
            children: <Widget>[
              SimpleDialogOption(
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
              ),
              SimpleDialogOption(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return circularProgress();
        User user = User.fromDocument(snapshot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Text(location),
          trailing: (currentUserId == ownerId)
              ? IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => handleDeletePost(context))
              : Text(''),
        );
      },
    );
  }

  removeLikeFromActivityFeed() {
    if (currentUserId != ownerId)
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) doc.reference.delete();
      });
  }

  addLikeToActivityFeed() {
    if (currentUserId != ownerId)
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
      });
  }

  handleLikePost() {
    if (isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
        showHeart = false;
      });
    } else if (!isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(
        Duration(milliseconds: 450),
        () => setState(
          () {
            showHeart = false;
          },
        ),
      );
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: () => handleLikePost(),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CachedNetworkImage(
            imageUrl: mediaUrl,
          ),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticInOut,
                  cycles: 0,
                  builder: (anim) => Transform.scale(
                    scale: anim.value,
                    child: Icon(Icons.favorite, size: 80, color: Colors.red),
                  ),
                )
              : Text('')
        ],
      ),
    );
  }

  buildPostFooter(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40, left: 20)),
            GestureDetector(
              onTap: () => handleLikePost(),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20)),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Comments(
                            postId: postId,
                            ownerId: ownerId,
                            mediaUrl: mediaUrl,
                          ))),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$likeCount likes',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$username',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(padding: EdgeInsets.only(left: 4)),
            Expanded(
              child: Text(description),
            )
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(context),
      ],
    );
  }
}
