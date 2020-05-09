import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/models/user.dart';
import 'package:flutter_share/pages/home.dart';
import 'package:flutter_share/widgets/progress.dart';
import 'package:flutter_svg/svg.dart';
import 'activity_feed.dart';
class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin<Search>{
  TextEditingController searchController;
  Future<QuerySnapshot> searchResultsFuture;

  @override
  void initState() {
    searchController = new TextEditingController();
    super.initState();
  }

  void handleSearch(String query) {
    setState(() {
      searchResultsFuture =
          usersRef.where('displayName', isGreaterThan: query).getDocuments();
    });
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        onFieldSubmitted: handleSearch,
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search for a user...',
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => searchController.clear());
            },
          ),
        ),
      ),
    );
  }

  Container buildNoContent() {
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: MediaQuery.of(context).size.height * .5,
            ),
            Text(
              'Find Users',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 60,
              ),
            )
          ],
        ),
      ),
    );
  }

  FutureBuilder buildSearchResults() {
    return FutureBuilder(
        future: searchResultsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return circularProgress();
          List<UserResult> searchResults = [];
          snapshot.data.documents.forEach((doc) {
            searchResults.add(UserResult(User.fromDocument(doc)));
          });
          return ListView(
            children: searchResults,
          );
        });
  }
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(.8),
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: ()=> showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(user.displayName,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              subtitle: Text(user.username,style: TextStyle(color: Colors.white),),
            ),
          ),
          Divider(
            height: 2,
            color: Colors.white54,
          )
        ],
      ),
    );
  }
}
