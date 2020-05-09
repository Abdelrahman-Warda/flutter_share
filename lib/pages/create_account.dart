import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_share/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String username;
  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, title: 'Set up your profile',removeBackButton: true),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: Text(
                    'Create a username',
                    style: TextStyle(fontSize: 25),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    autovalidate: true,
                    child: TextFormField(
                      validator: (val) {
                        if (val.trim().length < 3 || val.isEmpty)
                          return 'Username is too short';
                        else if (val.trim().length > 12)
                          return 'Username is too long';
                        else
                          return null;
                      },
                      onSaved: (val) => username = val,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'username',
                        labelStyle: TextStyle(fontSize: 15),
                        hintText: 'Must be at least 3 characters',
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final form = _formKey.currentState;
                    if (form.validate()) {
                      form.save();
                      SnackBar snackbar =
                          SnackBar(content: Text('Welcome $username!'));
                      _scaffoldKey.currentState.showSnackBar(snackbar);
                      Timer(Duration(milliseconds: 1500),
                          () => Navigator.pop(context, username));
                    }
                  },
                  child: Container(
                    height: 50,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        'Submit',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
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
