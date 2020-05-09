import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/models/user.dart';
import 'package:flutter_share/pages/edit_profile.dart';
import 'package:flutter_share/widgets/header.dart';
import 'package:flutter_share/widgets/post.dart';
import 'package:flutter_share/widgets/post_tile.dart';
import 'package:flutter_share/widgets/progress.dart';
import 'package:flutter_share/pages/home.dart';
import 'package:flutter_svg/svg.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String currentUserId = currentUser?.id;
  String postOrientation = 'grid';
  bool isFollowing = false;
  bool isLoading = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  getFollowers() {
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments()
        .then((snapshot) {
      setState(() {
        followerCount = snapshot.documents.length;
      });
    });
  }
  getFollowing() {
    followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments()
        .then((snapshot) {
      setState(() {
        followingCount = snapshot.documents.length;
      });
    });
  }

  checkIfFollowing() {
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      setState(() {
        isFollowing = doc.exists;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: TextStyle(
                color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w400),
          ),
        )
      ],
    );
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250,
          height: 27,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.blue,
            border: Border.all(color: isFollowing ? Colors.grey : Colors.blue),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  handleUnfollow() {
    setState(() {
      isFollowing = false;
    });
    //make auth user unfollow that user 'update his followers collection'
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //remove that user from auth user followings 'update your following collection'
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //delete activity feed item for that user
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleFollow() {
    setState(() {
      isFollowing = true;
    });
    //make auth user follow that user 'update his followers collection'
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({});
    //put that user in auth user followings 'update your following collection'
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});
    //add activity feed item for that user to notify about new follower 'you'
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUserId,
      'userProfileImg': currentUser.photoUrl,
      'timestamp': timestamp,
    });
  }

  buildProfileButton() {
    if (currentUserId == widget.profileId)
      return buildButton(
          text: 'Edit Profile',
          function: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfile(
                  currentUserId: currentUserId,
                ),
              )));
    else if (isFollowing)
      return buildButton(text: 'Unfollow', function: () => handleUnfollow());
    return buildButton(text: 'Follow', function: () => handleFollow());
  }

  FutureBuilder buildProfileHeader() {
    return FutureBuilder(
        future: usersRef.document(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return circularProgress();
          User user = User.fromDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(user.photoUrl),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildCountColumn('posts', postCount),
                              buildCountColumn('followers', followerCount),
                              buildCountColumn('following', followingCount),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[buildProfileButton()],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    user.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    user.bio,
                  ),
                ),
              ],
            ),
          );
        });
  }

  setPostOrientation(String orientation) {
    setState(() {
      this.postOrientation = orientation;
    });
  }

  Row buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
            icon: Icon(Icons.grid_on),
            color: postOrientation == 'grid'
                ? Theme.of(context).primaryColor
                : Colors.grey,
            onPressed: () => setPostOrientation('grid')),
        IconButton(
            icon: Icon(Icons.list),
            color: postOrientation == 'list'
                ? Theme.of(context).primaryColor
                : Colors.grey,
            onPressed: () => setPostOrientation('list')),
      ],
    );
  }

  Widget buildProfilePosts() {
    if (isLoading)
      return circularProgress();
    else if (posts.isEmpty)
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: MediaQuery.of(context).size.height * .3,
            ),
            Text(
              'No Posts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
            )
          ],
        ),
      );
    else if (postOrientation == 'grid') {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(
          child: PostTile(post),
        ));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        children: gridTiles,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
      );
    }
    return Column(
      children: posts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: 'Profile'),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(height: 0),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
