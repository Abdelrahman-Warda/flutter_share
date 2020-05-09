import 'package:flutter/material.dart';

AppBar header(context, {title = 'FlutterShare',removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: !removeBackButton,
    title: Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontFamily: title == 'FlutterShare' ? 'Signatra' : '',
        fontSize: title == 'FlutterShare' ? 50 : 22,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
