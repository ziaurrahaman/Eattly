import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';

import './HomePage.dart';
import './StoryPage.dart';
import './UploadStoryPage.dart';
import '../models/Story.dart';
import '../models/User.dart';
import '../widgets/PostWidget.dart';
import '../widgets/ProgressWidget.dart';

class TimeLinePage2 extends StatefulWidget {
  final Users gCurrentUser;
  final List<Users> whoAreFollowing;

  TimeLinePage2({this.gCurrentUser, this.whoAreFollowing});

  @override
  _TimeLinePageState2 createState() => _TimeLinePageState2();
}

class _TimeLinePageState2 extends State<TimeLinePage2> {
  List<DocumentSnapshot> posts = [];
  DocumentSnapshot lastDocument;
  List<String> followingList = [];
  List<String> followersList = [];
  List<Users> usersWhoAreFollowingAndHaveStory = [];
  List<List<Story>> stories = [];
  List<Users> followersUsers = [];
  List<Users> followingUsers = [];
  ScrollController scrollController = ScrollController();
  int _perPage = 5;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool loadingProducts = false;
  bool gettingMoreProducts = false;
  bool moreProductsAvailable = true;

  Stream<QuerySnapshot> timelineData;

  @override
  void initState() {
    super.initState();

    retrieveTimeLine();
    retrieveFollowings();
    retrieveFollowers();
    scrollController.addListener(() {
      double maxScroll = scrollController.position.maxScrollExtent;
      double curretnScroll = scrollController.position.pixels;
      double delta = MediaQuery.of(context).size.height * 0.30;

      if (maxScroll - curretnScroll <= delta) {
        getMoreProduct();
      }
    });
  }

  getMoreProduct() async {
    print('called');
    if (moreProductsAvailable == false) {
      return;
    }

    if (gettingMoreProducts == true) {
      return;
    }
    gettingMoreProducts = true;
    Query q = timelineReference
        .doc(widget.gCurrentUser.id)
        .collection("timelinePosts")
        .orderBy("timestamp", descending: true)
        .startAfter([lastDocument.data()['timestamp']]).limit(_perPage);

    QuerySnapshot querySnapshot = await q.get();

    if (querySnapshot.docs.length < _perPage) {
      moreProductsAvailable = false;
    }
    lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];
    posts.addAll(querySnapshot.docs);
    setState(() {
      gettingMoreProducts = false;
    });
  }

  retrieveTimeLine() async {
    //retrieve TimeLine post
    Query q = timelineReference
        .doc(widget.gCurrentUser.id)
        .collection("timelinePosts")
        .orderBy("timestamp", descending: true)
        .limit(_perPage);

    setState(() {
      loadingProducts = true;
    });

    QuerySnapshot querySnapshot = await q.get();

    posts = querySnapshot.docs;
    lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];

    setState(() {
      loadingProducts = false;
    });

    //get all users who have stories and also follow the user
    await getStoriesOfAllUserWhoAreFollowingTheCurrentUSer().then((value) {
      usersWhoAreFollowingAndHaveStory = [];
      for (int i = 0; i < widget.whoAreFollowing.length; i++) {
        for (int j = 0; j < value.length; j++) {
          if (widget.whoAreFollowing[i].id == value[j][0].ownerId) {
            setState(() {
              usersWhoAreFollowingAndHaveStory.add(widget.whoAreFollowing[i]);
            });
          }
        }
      }
      print('storyLength:${usersWhoAreFollowingAndHaveStory.length}');
    });
  }

  Future<List<List<Story>>> retrieveStories() async {
    final querySnapshot = await storyReference.get();
    querySnapshot.docs.forEach((element) async {
      final querySnapshotForStory =
          await storyReference.doc(element.id).collection('userStories').get();
      final storiesOfAUser = querySnapshotForStory.docs
          .map((document) => Story.fromDocument(document))
          .toList();

      stories.add(storiesOfAUser);
    });
    return stories;
  }

  Future<List<List<Story>>>
      getStoriesOfAllUserWhoAreFollowingTheCurrentUSer() async {
    List<List<Story>> storiesOfAllUserWhoAreFollowingTheCurrentUser = [];
    for (final userWhoIsFollowing in widget.whoAreFollowing) {
      List<Story> stories = await getStories(userWhoIsFollowing.id);
      if (!storiesOfAllUserWhoAreFollowingTheCurrentUser.contains(stories) &&
          stories.length > 0) {
        setState(() {
          storiesOfAllUserWhoAreFollowingTheCurrentUser.add(stories);
        });
      }
    }
    for (final storiesOfAllUserWhoAreFollowingTheCurrentUser
        in storiesOfAllUserWhoAreFollowingTheCurrentUser) {
      print(
          'allStories: ${storiesOfAllUserWhoAreFollowingTheCurrentUser.length}');
    }

    setState(() {
      stories = storiesOfAllUserWhoAreFollowingTheCurrentUser;
    });

    return storiesOfAllUserWhoAreFollowingTheCurrentUser;
  }

  Future<List<Story>> getStories(String userId) async {
    List<Story> selectedUserStories = [];
    var abc = await storyReference.doc(userId).collection("userStories").get();
    abc.docs.forEach((element) {
      var story = Story.fromDocument(element);

      print('aboutStory:${story.aboutStory}');
      var presentDate = DateTime.now();
      var difference = presentDate.difference(story.timestamp.toDate()).inDays;
      if (element.data != null) {
        if (!selectedUserStories.contains(story) && difference <= 1) {
          selectedUserStories.add(story);
        }
      }
    });
    return selectedUserStories;
  }

  retrieveFollowings() async {
    final querySnapshot = await followingReference
        .doc(currentUser.id)
        .collection("userFollowing")
        .get()
        .then((value) async {
      setState(() {
        followingList = value.docs.map((document) => document.id).toList();
      });

      List<Users> users = [];
      for (final following in followingList) {
        final documentSnapshot = await usersReference.doc(following).get();
        if (documentSnapshot.data != null) {
          final user = Users.fromDocument(documentSnapshot);
          if (!users.contains(user)) {
            users.add(user);
          }
        }
      }
      followingUsers = users;
    });
  }

  retrieveFollowers() async {
    final querySnapshot = await followersReference
        .doc(currentUser.id)
        .collection("userFollowers")
        .get()
        .then((value) async {
      setState(() {
        followersList = value.docs.map((document) => document.id).toList();
      });

      List<Users> users = [];
      for (final follower in followersList) {
        final documentSnapshot = await usersReference.doc(follower).get();
        if (documentSnapshot.data != null) {
          final user = Users.fromDocument(documentSnapshot);
          if (!users.contains(user)) {
            users.add(user);
          }
        }
      }
      followersUsers = users;
    });
  }

  getUsersWhomCurrentUserIsFollowing() async {
    List<Users> users = [];
    var followings = await retrieveFollowings();
    for (final following in followings) {
      final documentSnapshot = await usersReference.doc(following).get();
      if (documentSnapshot.data != null) {
        final user = Users.fromDocument(documentSnapshot);
        if (!users.contains(user)) {
          users.add(user);
        }
      }
    }
    return users;
  }

  showComparisonDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          content: Text(
            'New features are coming soon.',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        );
      },
    );
  }

  Widget createUserTimeLine() {
    if (posts == null) {
      return circularProgress();
    } else {
      return SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 140,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        height: 140,
                        width: 75,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 70,
                                  width: 80,
                                  color: Colors.white,
                                ),
                                Container(
                                    height: 60,
                                    width: 80,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => UploadStoryPage(
                                              gCurrentUser: widget.gCurrentUser,
                                            ),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(currentUser.url),
                                        radius: 50,
                                      ),
                                    )),
                                Positioned(
                                  height: 25,
                                  top: 45,
                                  right: 0,
                                  child: Container(
                                      height: 24,
                                      width: 24,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          color: Colors.blue),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (ctx) => UploadStoryPage(
                                                gCurrentUser:
                                                    widget.gCurrentUser,
                                              ),
                                            ),
                                          );
                                        },
                                      )),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text('MyStory')
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                        height: 140,
                        child: StreamBuilder(
                            stream: storyReference.snapshots(),
                            builder: (context, snapshot) {
                              List<Users> allStoriesFromSnapshot = [];

                              if (snapshot.hasData) {
                                snapshot.data.documents.forEach((document) {
                                  var user = Users.fromDocument(document);
                                  print('snapshotUserId: ${user.email}');
                                  if (!allStoriesFromSnapshot.contains(user)) {
                                    allStoriesFromSnapshot.add(user);
                                  }
                                });
                              }
                              return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) => Container(
                                      margin: EdgeInsets.all(8),
                                      height: 140,
                                      width: 60,
                                      child: GestureDetector(
                                          onTap: () async {
                                            showProgressDialog(
                                                loadingText:
                                                    'Story is loading...',
                                                context: context);
                                            var selectedUserId =
                                                usersWhoAreFollowingAndHaveStory[
                                                        index]
                                                    .id;
                                            print(
                                                'selectedUserId: $selectedUserId');
                                            List<Story> storiesOfSelectedUser =
                                                await getStories(
                                                    selectedUserId);
                                            List<List<Story>>
                                                storiesOfAllUsersFollowing =
                                                await getStoriesOfAllUserWhoAreFollowingTheCurrentUSer();
                                            dismissProgressDialog();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (BuildContext context) =>
                                                        StoryPage(
                                                  stories:
                                                      storiesOfAllUsersFollowing,
                                                  selectedUserStories:
                                                      storiesOfSelectedUser,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    usersWhoAreFollowingAndHaveStory[
                                                            index]
                                                        .url),
                                                radius: 30,
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                usersWhoAreFollowingAndHaveStory[
                                                        index]
                                                    .profileName,
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              )
                                            ],
                                          ))),
                                  shrinkWrap: true,
                                  itemCount:
                                      usersWhoAreFollowingAndHaveStory.length);
                            }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              child: (loadingProducts == true)
                  ? Container(
                      child: Center(
                        child: Text('Loading...'),
                      ),
                    )
                  : (posts.length == 0)
                      ? Center(
                          child: Text('No products to show'),
                        )
                      : ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            var post = Post.fromDocument(posts[index]);
                            return post;
                          },
                          itemCount: posts.length,
                          shrinkWrap: true,
                        ),
            )
          ],
        ),
      );
    }
  }

  ///Added drawer
  @override
  Widget build(context) {
    return Scaffold(
      key: _scaffoldKey,
      body: RefreshIndicator(
        onRefresh: () => retrieveTimeLine(),
        child: createUserTimeLine(),
      ),
    );
  }
}
