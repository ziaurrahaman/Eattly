import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eattlystefan/models/ingredient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import 'package:uuid/uuid.dart';

import './HomePage.dart';
import '../models/User.dart';
import '../models/recipe.dart';
import '../widgets/add_recipe/add_ingredients_field.dart';
import '../widgets/add_recipe/recipe_dropdown_form_field.dart';
import '../widgets/add_recipe/recipe_form_field.dart';

class UpdateRecipeScreen extends StatefulWidget {
  final String postId;
  final String ownerId;
  final Map likes;
  final String profileName;
  final String description;
  final String name;
  final String prepare;
  final String ingredients;
  final String url;
  final Timestamp timestamp;
  final bool isShared;
  final String sharedBy;
  final Timestamp whenShared;
  final String sharedByImageUrl;
  final String sharedById;

  final List<Ingredient> nIngredients;
  String directions;
  String cost;
  String portions;
  dynamic timeNeeded;
  String category;

  UpdateRecipeScreen(
      {this.postId,
      this.ownerId,
      this.likes,
      this.profileName,
      this.description,
      this.name,
      this.prepare,
      this.ingredients,
      this.url,
      this.timestamp,
      this.isShared,
      this.sharedBy,
      this.whenShared,
      this.sharedByImageUrl,
      this.sharedById,
      this.nIngredients,
      this.directions,
      this.cost,
      this.portions,
      this.timeNeeded,
      this.category});

  @override
  _UpdateRecipeScreenState createState() => _UpdateRecipeScreenState();
}

class _UpdateRecipeScreenState extends State<UpdateRecipeScreen> {
  final _formKey = new GlobalKey<FormState>();

  final _descriptionFocusNode = FocusNode();
  final _ingredientsFocusNode = FocusNode();
  final _costToPrepareFocusNode = FocusNode();
  final _portionsFocusNode = FocusNode();
  final _timeNeededFocusNode = FocusNode();
  final _categoryFocusNode = FocusNode();
  final _previousIngredientsFocusNode = FocusNode();
  final _imagePicker = ImagePicker();
  final _postId = Uuid().v4();

  bool isOnChangedCalled = false;

  Recipe _recipe;

  File _imageFile;
  List<String> followersList = [];

  // File file;

  Future<String> uploadPhoto(mImageFile) async {
    final mStorageUploadTask =
        storageReference.child("post_$_postId.jpg").putFile(mImageFile);
    final storageTaskSnapshot = await mStorageUploadTask;
    final downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  void captureImageWithCamera() async {
    Navigator.pop(context);
    final imageFile = await _imagePicker.getImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );

    setState(() {
      _imageFile = File(imageFile.path);
    });
  }

  void pickImageFromGallery() async {
    Navigator.pop(context);
    final imageFile = await _imagePicker.getImage(
      source: ImageSource.gallery,
      maxHeight: 680,
      maxWidth: 970,
      imageQuality: 60,
    );
    setState(() {
      _imageFile = File(imageFile.path);
    });
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _ingredientsFocusNode.dispose();
    _costToPrepareFocusNode.dispose();
    _portionsFocusNode.dispose();
    _timeNeededFocusNode.dispose();
    _categoryFocusNode.dispose();
    _previousIngredientsFocusNode.dispose();
    super.dispose();
  }

  Future<void> updatePostInfoToFireStore(
    Recipe recipe,
    Users user,
    CollectionReference postsReference,
  ) async {
    var ingredients = '';

    if (widget.nIngredients.length == 0) {
      ingredients = recipe.ingredients;
    }
    await timelineReference
        .doc(user.id)
        .collection("timelinePosts")
        .doc(widget.postId)
        .update(
      {
        "description": recipe.description,
        "name": recipe.name,
        "prepare": recipe.directions,
        "ingredients": ingredients,
        "n_ingredients": jsonEncode(recipe.nIngredients),
        "cost": recipe.cost,
        "portion": recipe.portions,
        "neededTime": recipe.timeNeeded,
        "category": recipe.category,
      },
    );

    await postsReference
        .doc(user.id)
        .collection("usersPosts")
        .doc(widget.postId)
        .update(
      {
        "description": recipe.description,
        "name": recipe.name,
        "prepare": recipe.directions,
        "ingredients": ingredients,
        "n_ingredients": jsonEncode(recipe.nIngredients),
        "cost": recipe.cost,
        "portion": recipe.portions,
        "neededTime": recipe.timeNeeded,
        "category": recipe.category,
      },
    );

    for (final follower in followersList) {
      if (follower != currentUser.id) {
        await timelineReference
            .doc(follower)
            .collection("timelinePosts")
            .doc(widget.postId)
            .update(
          {
            "description": recipe.description,
            "name": recipe.name,
            "prepare": recipe.directions,
            "ingredients": ingredients,
            "n_ingredients": jsonEncode(recipe.nIngredients),
            "cost": recipe.cost,
            "portion": recipe.portions,
            "neededTime": recipe.timeNeeded,
            "category": recipe.category,
          },
        );
      }
    }
    // showToast();
  }

  retrieveFollowers() async {
    final querySnapshot = await followersReference
        .doc(currentUser.id)
        .collection("userFollowers")
        .get();

    setState(() {
      followersList =
          querySnapshot.docs.map((document) => document.id).toList();
    });
  }

  void showToast() {
    Fluttertoast.showToast(
      msg: 'Recipe has been updated successfully',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  @override
  void initState() {
    retrieveFollowers();
    // TODO: implement initState
    _recipe = Recipe(nIngredients: widget.nIngredients);
    var nIngredients = widget.nIngredients;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[900],
        title: Text('Edit Recipe'),
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Color(0xF3F3F3F3),
                  ),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        image: DecorationImage(
                          image: NetworkImage(widget.url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                RecipeFormField(
                  initialValue: widget.name,
                  hintText: 'eg. Fried Rice',
                  labelText: 'Name',
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_descriptionFocusNode);
                  },
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                  onSaved: (val) => setState(() {
                    _recipe.name = val;
                  }),
                ),
                RecipeFormField(
                  initialValue: widget.description,
                  maxLines: 2,
                  labelText: 'Description',
                  hintText: 'Enter Description',
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_ingredientsFocusNode);
                  },
                  focusNode: _descriptionFocusNode,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                  onSaved: (val) => setState(() {
                    _recipe.description = val;
                  }),
                ),
                (widget.nIngredients.length == 0)
                    ? RecipeFormField(
                        initialValue: widget.ingredients,
                        maxLines: 2,
                        labelText: 'Ingredients',
                        hintText: 'Enter Ingredients',
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_ingredientsFocusNode);
                        },
                        focusNode: _previousIngredientsFocusNode,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Ingredients is required';
                          }
                          return null;
                        },
                        onSaved: (val) => setState(() {
                          _recipe.ingredients = val;
                        }),
                      )
                    : AddIngredientsField(
                        ingredients: _recipe.nIngredients,
                        focusNode: _ingredientsFocusNode,
                      ),
                RecipeFormField(
                  initialValue: widget.directions,
                  maxLines: 3,
                  labelText: 'Directions',
                  hintText: 'Enter Directions',
                  validator: (val) {
                    if (val.isEmpty) {
                      return 'Directions is required';
                    }
                    return null;
                  },
                  onSaved: (val) => setState(() {
                    _recipe.directions = val;
                  }),
                  onFieldSubmitted: (_) {
                    FocusScope.of(context)
                        .requestFocus(_costToPrepareFocusNode);
                  },
                ),
                Row(
                  children: [
                    Flexible(
                      child: RecipeFormField(
                        initialValue: widget.cost,
                        keyboardType: TextInputType.number,
                        labelText: 'Cost To Prepare',
                        hintText: 'eg. \$\$\$',
                        validator: (val) {
                          if (val.isEmpty) {
                            return 'Cost is required';
                          } else if (double.tryParse(val) == null) {
                            return 'Cost must be a number';
                          } else {
                            return null;
                          }
                        },
                        focusNode: _costToPrepareFocusNode,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_portionsFocusNode);
                        },
                        onSaved: (val) => setState(() {
                          _recipe.cost = val;
                        }),
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: RecipeFormField(
                        initialValue: widget.portions,
                        keyboardType: TextInputType.number,
                        labelText: 'Portions',
                        hintText: 'eg. 2',
                        focusNode: _portionsFocusNode,
                        validator: (val) {
                          if (val.isEmpty) {
                            return 'Portions is required';
                          } else if (int.tryParse(val) == null) {
                            return 'Portion must be a number';
                          } else {
                            return null;
                          }
                        },
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_timeNeededFocusNode);
                        },
                        onSaved: (val) => setState(() {
                          _recipe.portions = val;
                        }),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Flexible(
                      child: RecipeFormField(
                        initialValue: widget.timeNeeded.toString(),
                        keyboardType: TextInputType.number,
                        labelText: 'Time Needed',
                        hintText: 'eg. 15',
                        suffixText: 'min',
                        validator: (val) {
                          if (val.isEmpty) {
                            return 'Time needed is required';
                          } else if (int.tryParse(val) == null) {
                            return 'Time needed must be a number';
                          } else {
                            return null;
                          }
                        },
                        focusNode: _timeNeededFocusNode,
                        onSaved: (val) => setState(() {
                          _recipe.timeNeeded = int.parse(val);
                        }),
                      ),
                    ),
                    SizedBox(width: 10),
                    (widget.nIngredients.length == 0)
                        ? Flexible(
                            child: RecipeFormField(
                              initialValue: widget.category,
                              keyboardType: TextInputType.number,
                              labelText: 'Category',
                              hintText: 'eg. Vegan/NonVegan',
                              suffixText: 'min',
                              validator: (val) {
                                if (val.isEmpty) {
                                  return 'Category is required';
                                } else {
                                  return null;
                                }
                              },
                              focusNode: _categoryFocusNode,
                              onSaved: (val) => setState(() {
                                _recipe.category = val;
                              }),
                            ),
                          )
                        : Flexible(
                            child: RecipeDropdownFormField(
                              onSaved: (val) => setState(() {
                                if (isOnChangedCalled == false) {
                                  _recipe.category = widget.category;
                                }
                              }),
                              initialValue: widget.category,
                              value: widget.category,
                              labelText: 'Category',
                              items: ['Vegan', 'Non-vegan'],
                              hintText: 'eg. vegan',
                              onChanged: (value) => setState(() {
                                isOnChangedCalled = true;
                                _recipe.category = value;
                              }),
                            ),
                          ),
                  ],
                ),
                SizedBox(height: 20),
                ButtonTheme(
                  minWidth: 10,
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Theme.of(context).primaryColor,
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        showProgressDialog(
                            loadingText: 'Recipe is updating...',
                            context: context);
                        _formKey.currentState.save();

                        await updatePostInfoToFireStore(
                          _recipe,
                          currentUser,
                          postsReference,
                        );
                        dismissProgressDialog();
                        Navigator.of(context).pop();

                        showToast();
                        setState(() {
                          _recipe = Recipe();
                        });

                        _formKey.currentState.reset();
                      }
                    },
                    child: Text(
                      'Save Recipe',
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
