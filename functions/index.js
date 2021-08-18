const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();




exports.onCreateActivityFeedItem = functions.firestore
.document('/feed/{userId}/feedItems/{activityFeedItem}')
.onCreate(async (snapshot, context) =>
{
    const userId = context.params.userId;
    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();


    const androidNotificationToken = doc.data().androidNotificationToken;
    const createActivityFeedItem = snapshot.data();

    if(androidNotificationToken)
    {
        sendNotification(androidNotificationToken, createActivityFeedItem);
    }
    else
    {
        console.log("No token for user, can not send notification.")
    }

    function sendNotification(androidNotificationToken, activityFeedItem)
    {
        let body;

        switch (activityFeedItem.type)
        {
            case "comment":
                body = `${activityFeedItem.profileName} commented: ${activityFeedItem.commentData}`;
                break;

            case "like":
                body = `${activityFeedItem.profileName} liked your post`;
                break;

            case "follow":
                body = `${activityFeedItem.profileName} started following you`;
                break;

            default:
            break;
        }

        const message =
        {
            notification: { body },
            token: androidNotificationToken,
            data: { recipient: userId },
        };

        admin.messaging().send(message)
        .then(response =>
        {
            console.log("Successfully sent message", response);
        })
        .catch(error =>
        {
            console.log("Error sending message", error);
        })

    }
});




exports.onCreateFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onCreate(async (snapshot, context) => {

    console.log("Follower Created", snapshot.id);

    const userId = context.params.userId;

    const followerId = context.params.followerId;

    const followedUserPostsRef = admin
      .firestore()
      .collection("posts")
      .doc(userId)
      .collection("usersPosts");

    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts");

    const querySnapshot = await followedUserPostsRef.get();

    querySnapshot.forEach(doc => {
      if (doc.exists) {
        const postId = doc.id;
        const postData = doc.data();
        timelinePostsRef.doc(postId).set(postData);
      }
    });
  });





  exports.onDeleteFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onDelete(async (snapshot, context) => {

    console.log("Follower Deleted", snapshot.id);

    const userId = context.params.userId;

    const followerId = context.params.followerId;

    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts")
      .where("ownerId", "==", userId);

    const querySnapshot = await timelinePostsRef.get();
    querySnapshot.forEach(doc => {
      if (doc.exists)
      {
        doc.ref.delete();
      }
    });
  });





exports.onCreatePost = functions.firestore
  .document("/posts/{userId}/usersPosts/{postId}")
  .onCreate(async (snapshot, context) => {

    const postCreated = snapshot.data();

    const userId = context.params.userId;

    const postId = context.params.postId;

    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();

    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .set(postCreated);
    });
  });





exports.onUpdatePost = functions.firestore
  .document("/posts/{userId}/usersPosts/{postId}")
  .onUpdate(async (change, context) => {
    const postUpdated = change.after.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();

    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .get()
        .then(doc => {
          if (doc.exists) {
            doc.ref.update(postUpdated);
          }
        });
    });
  });





exports.onDeletePost = functions.firestore
  .document("/posts/{userId}/usersPosts/{postId}")
  .onDelete(async (snapshot, context) => {
    const userId = context.params.userId;
    const postId = context.params.postId;

    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();

    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .get()
        .then(doc => {
          if (doc.exists) {
            doc.ref.delete();
          }
        });
    });
  });


exports.sendNotification = functions.firestore
    .document('messages/{groupId1}/{groupId2}/{message}')
    .onCreate((snap, context) => {
      console.log('----------------start function--------------------')

      const doc = snap.data()
      console.log(doc)

      const idFrom = doc.idFrom
      const idTo = doc.idTo
      const contentMessage = doc.content

      // Get push token user to (receive)
      admin
        .firestore()
        .collection('users')
        .where('id', '==', idTo)
        .get()
        .then(querySnapshot => {
          querySnapshot.forEach(userTo => {
            console.log(`Found user to: ${userTo.data().profileName}`)
            if (userTo.data().androidNotificationToken || userTo.data().chattingWith !== idFrom) {
              // Get info user from (sent)
              admin
                .firestore()
                .collection('users')
                .where('id', '==', idFrom)
                .get()
                .then(querySnapshot2 => {
                  querySnapshot2.forEach(userFrom => {
                    console.log(`Found user from: ${userFrom.data().profileName}`)
                    const payload = {
                      notification: {
                        title: `You have a message from "${userFrom.data().profileName}"`,
                        body: contentMessage,
                        badge: '1',
                        sound: 'default'
                      }
                    }
                    // Let push to the target device
                    admin
                      .messaging()
                      .sendToDevice(userTo.data().androidNotificationToken, payload)
                      .then(response => {
                        console.log('Successfully sent message:', response)
                      })
                      .catch(error => {
                        console.log('Error sending message:', error)
                      })
                  })
                })
            } else {
              console.log('Can not find pushToken target user')
            }
          })
        })
      return null
    })