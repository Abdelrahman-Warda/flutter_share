const functions = require("firebase-functions");
const admin = require("firebase-admin")
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

exports.onCreateFollower = functions
    .firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async (snapshot, context) => {
        console.log("Follower Created", snapshot.data());

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        // create followed user"s posts ref
        const followedUserPostsRef = admin
            .firestore()
            .collection("posts")
            .doc(userId)
            .collection("userPosts");

        // create following user"s timeline ref
        const timelinePostsRef = admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts");

        // get followed user"s posts
        const querySnapshot = await followedUserPostsRef.get();

        // add each followed user post to following user"s timeline
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                timelinePostsRef.doc(postId).set(postData);
            }
        });
    })


exports.onDeleteFollower = functions
    .firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onDelete(async (snapshot, context) => {
        console.log("Follower Deleted", snapshot.id);

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        // create unfollowing user"s timeline ref
        const timelinePostsRef = admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts")
            .where("ownerId", "==", userId);

        // get unfollowed user"s posts
        const querySnapshot = await timelinePostsRef.get();

        // remove each unfollowed user post from following user"s timeline
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });
    })

exports.onCreatePost = functions
    .firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onCreate(async (snapshot, context) => {
        console.log("Post Created", snapshot.data());

        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        // get all followers of new post owner
        const userFollowersRef = admin
            .firestore()
            .collection("followers")
            .doc(userId)
            .collection("userFollowers");

        const querySnapshot = await userFollowersRef.get();

        // add new post to each follower's timeline
        querySnapshot.forEach((doc) => {
            const followerId = doc.id;

            admin
                .firestore
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .set(postCreated);
        })
    })

exports.onUpdatePost = functions
    .firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onUpdate(async (change, context) => {
        console.log("Post Updated", change.after.data());

        const postUpdated = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        // get all followers of updated post owner
        const userFollowersRef = admin
            .firestore()
            .collection("followers")
            .doc(userId)
            .collection("userFollowers");

        const querySnapshot = await userFollowersRef.get();

        // ypdate post to each follower's timeline
        querySnapshot.forEach((doc) => {
            const followerId = doc.id;

            admin
                .firestore
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then((doc) => {
                    if (doc.exists) {
                        doc.ref.update(postUpdated)
                    }
                })
        })
    })

exports.onDeletePost = functions
    .firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onDelete(async (snapshot, context) => {
        console.log("Post Deleted");

        const userId = context.params.userId;
        const postId = context.params.postId;

        // get all followers of new post owner
        const userFollowersRef = admin
            .firestore()
            .collection("followers")
            .doc(userId)
            .collection("userFollowers");

        const querySnapshot = await userFollowersRef.get();

        // Delete post from each follower's timeline
        querySnapshot.forEach((doc) => {
            const followerId = doc.id;

            admin
                .firestore
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then((doc) => {
                    if (doc.exists) {
                        doc.ref.delete();
                    }
                })
        })
    })


exports.onCreateActivityFeedItem = functions.firestore
    .document('/feed/{userId}/feedItems/{activityFeedItem}')
    .onCreate(async (snapshot, context) => {
        console.log('Activity Feed Item Created', snapshot.data());

        // get user connected to feed
        const userId = context.params.userId;

        const userRef = admin.firestore().doc(`users/${userId}`);
        const doc = await userRef.get();

        // once we have the user check if they have a notification token tthen send notification if token is found
        const androidNotificationToken = doc.data().androidNotificationToken;
        if (androidNotificationToken) {
            sendNotification(androidNotificationToken, createdActivityFeedItem);
        } else
            console.log('No token for user, cannot send notification');

        // create message body according to type
        function sendNotification(androidNotificationToken, activityFeedItem) {
            let body;

            switch (activityFeedItem.type) {
                case "comment":
                    body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData}`;
                    break;
                case "like":
                    body = `${activityFeedItem.username} liked your post`;
                    break;
                case "follow":
                    body = `${activityFeedItem.username} started following you`;
                    break;
                default:
                    break;
            }
            // create message for push notification
            const message = {
                notification: { body },
                token: androidNotificationToken,
                data: { recipient: userId },
            };

            // message with admin.messaging()
            admin.messaging.send(message)
                .then(response => {
                    // response is a message ID string
                    console.log("successfully sent message", response);
                })
                .catch(error => {
                    console.log("Error sending message", error);
                })

        }
    })