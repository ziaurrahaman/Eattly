import 'package:eattlystefan/pages/meal_planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import './drawer_list.dart';
import '../../pages/HomePage.dart';
import '../../pages/IngredientAddPage.dart';
import '../../pages/SavedRecipePage.dart';
import '../../pages/SettingsPage.dart';
import '../../pages/shopListPage.dart';
import '../../utils/text_style.dart';

class EattlyDrawer extends StatefulWidget {
  @override
  _EattlyDrawerState createState() => _EattlyDrawerState();
}

class _EattlyDrawerState extends State<EattlyDrawer> {
  var isLoggedIn = false;

  Future<void> _checkIfIsLogged() async {
    final AccessToken accessToken = await FacebookAuth.instance.isLogged;

    if (accessToken != null) {
      print("Is Loged::: ${accessToken.toJson()}");
      final userData = await FacebookAuth.instance.getUserData();

      setState(() {
        isLoggedIn = true;
      });
    }
  }

  Future<void> _logOutFacebook() async {
    await FacebookAuth.instance.logOut();

    setState(() {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    });
  }

  logoutUser() async {
    await gSignIn.signOut();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  showComparisonDialog(BuildContext context) {
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

  @override
  void initState() {
    _checkIfIsLogged();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Drawer(
        child: Container(
          decoration: BoxDecoration(
            image: new DecorationImage(
              image: new AssetImage('assets/eattly_drawer_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 80,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'EATTLY',
                  style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'EAT\'S EASY',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat'),
                ),
              ),
              SizedBox(
                height: 40,
              ),
              DrawerList(
                icon: Icons.home,
                title: "Home",
                callback: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomePage(
                                flag: 'drawer',
                              )));
                },
              ),
              DrawerList(
                icon: Icons.shopping_cart,
                title: "Shopping List",
                callback: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ShopListPage()),
                  );
                },
              ),
              DrawerList(
                callback: () {},
                icon: Icons.star,
                title: "Premium",
              ),
              DrawerList(
                callback: () {
                  Navigator.of(context)
                      .pushReplacementNamed(MealPlannerScreen.routeName);
                },
                icon: Icons.history,
                title: "Meal Planner",
              ),
              DrawerList(
                callback: () => showComparisonDialog(context),
                icon: Icons.favorite,
                title: "Compare",
              ),
              DrawerList(
                callback: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(),
                    ),
                  );
                },
                icon: Icons.settings,
                title: "Settings",
              ),
              DrawerList(
                callback: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavedRecipePage(
                        currentUser: currentUser,
                      ),
                    ),
                  );
                },
                icon: Icons.bookmark,
                title: "Saved Recipes",
              ),
              DrawerList(
                callback: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddIngredient()),
                  );
                },
                icon: Icons.ac_unit,
                title: "Add Ingredient",
              ),
              Divider(
                color: whiteColor,
                endIndent: 100.0,
              ),
              DrawerList(
                icon: Icons.logout,
                title: "Log Out",
                callback: isLoggedIn ? _logOutFacebook : logoutUser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
