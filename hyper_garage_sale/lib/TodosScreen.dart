import 'package:flutter/material.dart';
import 'dart:io';
import 'globals.dart' as globals;


//widget that shows next screen to user
class TodosScreen extends StatefulWidget {

  const TodosScreen({Key key}) : super(key: key);

  @override
  _TodosScreenState createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {

  @override 
  Widget build(BuildContext context) {

    return _myListView(context);      
  }


  Widget _myListView(BuildContext context) {

    List<Widget> list = new List<Widget>();
    int count = 0;

    for (var i = 0; i < globals.itemList.length; i++) {
      //check every 4th iteration
      //check whether it's not out of bounds
      if (i % 4 == 0 && i + 3 < globals.itemList.length) {
        count += 1;
        String currPicture = globals.itemList[i];
        String currentInfo = globals.itemList.sublist(i + 1, i + 4).join();

        print("Current picture path: " + currPicture);
        print("Current picture info: " + currentInfo);


        list.add(new ListTile(title: Text(currentInfo)));
        list.add(new Container( child: Image.file(File(currPicture))));
        //remove listtile from element, just add the current info 
      }
    }
    
    
    if (count > globals.itemCount) {
      globals.itemCount = count;
      //print("item count has increased!");
      /*runApp(new MaterialApp(
        home: new InitializeNotifications()),
      );*/
      
    }
  


    return Scaffold(
      body:
        ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            
            final elem = list[index];
            return ListTile(
              title: elem,
            );
          },
        ),  
    ); 
  }
}