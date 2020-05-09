import 'package:flutter/material.dart';
import 'package:flutter_share/pages/post_screen.dart';
import 'package:flutter_share/widgets/custom_image.dart';
import 'package:flutter_share/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile(this.post);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostScreen(
            postId: post.postId,
            userId: post.ownerId,
          ),
        ),
      ),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
