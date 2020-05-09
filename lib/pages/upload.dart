import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/models/user.dart';
import 'package:flutter_share/pages/home.dart';
import 'package:flutter_share/widgets/progress.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload>{
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  File imageFile;
  bool isUploading = false;
  String postId = Uuid().v4();

  void handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
        source: ImageSource.camera, maxHeight: 675, maxWidth: 960);
    setState(() {
      imageFile = file;
    });
  }

  void handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxHeight: 675, maxWidth: 960);
    setState(() {
      imageFile = file;
    });
  }

  selectImage(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text('Create Post'),
            children: <Widget>[
              SimpleDialogOption(
                  child: Text('Photo with Camera'),
                  onPressed: () => handleTakePhoto()),
              SimpleDialogOption(
                  child: Text('Image from Gallery'),
                  onPressed: () => handleChooseFromGallery()),
              SimpleDialogOption(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context))
            ],
          );
        });
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: MediaQuery.of(context).size.height * .5,
          ),
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: RaisedButton(
              color: Colors.deepOrange,
              onPressed: () => selectImage(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Upload Image',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
          )
        ],
      ),
    );
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    setState(() {
      imageFile = File('${tempDir.path}/img_$postId.jpg')
        ..writeAsBytesSync(Im.encodeJpg(
            Im.decodeImage(imageFile.readAsBytesSync()),
            quality: 85));
    });
  }

  Future<String> uploadImage(File file) async {
    StorageTaskSnapshot storageSnap =
        await storageRef.child('post_$postId.jpg').putFile(file).onComplete;
    return await storageSnap.ref.getDownloadURL();
  }

  createPostInFirestore({String media, String location, String description}) {
    postsRef
        .document(widget.currentUser.id)
        .collection('userPosts')
        .document(postId)
        .setData({
      'postId': postId,
      'likes':{},
      'ownerId': widget.currentUser.id,
      'username': widget.currentUser.username,
      'mediaUrl': media,
      'description': description,
      'location': location,
      'timestamp': {},
    });
    captionController.clear();
    locationController.clear();
    setState(() {
      imageFile = null;
      isUploading = false;
    });
  }

  void handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(imageFile);
    createPostInFirestore(
      media: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
  }

  void getUserLocation() async {
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromPosition(await Geolocator().getCurrentPosition());
    locationController.text =
        placemarks[0].locality + ', ' + placemarks[0].country;
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => setState(() {
                  imageFile = null;
                })),
        title: Text('Caption Post', style: TextStyle(color: Colors.black)),
        actions: <Widget>[
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              'Post',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(''),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width * .8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: FileImage(imageFile), fit: BoxFit.cover)),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 10)),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35,
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                    hintText: 'Where was this photo taken?',
                    border: InputBorder.none),
              ),
            ),
          ),
          Container(
            width: 200,
            height: 100,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: () => getUserLocation(),
              icon: Icon(Icons.my_location, color: Colors.white),
              label: Text('Use Current Location',
                  style: TextStyle(color: Colors.white)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              color: Colors.blue,
            ),
          )
        ],
      ),
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return imageFile == null ? buildSplashScreen() : buildUploadForm();
  }
}
