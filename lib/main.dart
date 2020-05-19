import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todo/note.model.dart';
import 'package:todo/page_state_bloc.dart';

void main() async {                                                              //main function
  WidgetsFlutterBinding.ensureInitialized();
  final Directory directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  Hive.registerAdapter(NoteAdapter());
  runApp(MyApp());
}


class MyApp extends StatefulWidget{                                             //My App class
  @override
  MyAppState createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp>{                                          //My App class state
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title:'TO-DO ',
      home:ToDo(),
    );
  }
  @override
  void dispose(){
    Hive.close();
    super.dispose();
  }
}

class ToDo extends StatefulWidget{
  @override
  ToDoState createState()
  {
    return ToDoState();
  }
}

class ToDoState extends State<ToDo> {

  final DateFormat dateFormat = DateFormat('dd MMMM yyyy');                     //Date Format Used through the App

  final PageStateBloc mainBloc = PageStateBloc();                               //Bloc_pattern style Bloc to control state of Home Page (Main Page) with varying dates
  final PageStateBloc todoBloc = PageStateBloc();                               //Bloc_pattern style Bloc to control state of ToDoList with adding/removing/editing of notes

  DateTime date = DateTime.now();                                               //Current date

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: date,                                                        //Home page opens for Current date
      stream: mainBloc.getStream,                                               //stream of mainBloc
      builder: (BuildContext context,AsyncSnapshot snapshot){
        date=snapshot.data;                                                     //Changing the date based on the new date received from the stream
        return showToDoList();
      },
    );
  }
  showToDoList(){
    return FutureBuilder(
        future: Hive.openBox(dateFormat.format(date).toString()),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Scaffold();                                                //Empty Scaffold is Hive Box doesn't Open
            }
            else {
              return Scaffold(                                                  //Home Page if Hive Box opens successfully
                appBar: AppBar(
                  title: Text('${dateFormat.format(date).toString()}   , ${DateFormat('EEEE').format(date).toString()}',style: TextStyle(fontSize: 20),),
                ),
                floatingActionButton: bottomButtonsMainPage(),
                body:todoList(),
              );
            }
          }
          else{                                                                 //Returning a dummy Scaffold with buttons and appbar but without body to
            return Scaffold(                                                    //prevent flickering of Home page during Hive Box open await time
              appBar: AppBar(
                title: Text('${dateFormat.format(date).toString()}   , ${DateFormat('EEEE').format(date).toString()}',style: TextStyle(fontSize: 20),),
              ),
              floatingActionButton: bottomButtonsMainPage(),
            );
          }
        });
  }
  bottomButtonsMainPage(){                                                      //Column of buttons Used in Home Page
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Transform.scale(
          scale: 0.6,
          child:FloatingActionButton(                                           //Help Button
              backgroundColor: Colors.blueAccent,
              onPressed: (){
                showHelp();
              },
              child:Icon(
                Icons.help,
                size:50,
                color: Colors.white,
              )
          ),
        ),
        Text(''),
        FloatingActionButton(                                                   //Calender View Button
            backgroundColor: Colors.blueAccent,
            onPressed: (){
              showCalender(context);
            },
            child:Icon(
              Icons.calendar_today,
              size: 40,
              color: Colors.white,
            )
        ),
        Text(''),
        FloatingActionButton(                                                   //Button for adding new Notes/Tasks
            backgroundColor: Colors.blueAccent,
            onPressed: (){
              addItemDialog();
            },
            child:Icon(
              Icons.add,
              size: 40,
              color: Colors.white,
            )
        ),
      ],
    );
  }
  Future<Null> showCalender(BuildContext context) async {                       //function to display calender/datePicker
    final DateTime selectedDate = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null && selectedDate != date)
    {
      mainBloc.getSink.add(selectedDate);                                       //Adding date to sink of mainBloc if new date is picked from the Calender
    }
  }

  todoList() {
    return StreamBuilder(
      initialData: Hive.box(dateFormat.format(date).toString()),
      stream: todoBloc.getStream,                                               //stream of todoList Bloc
      builder: (BuildContext context,AsyncSnapshot snapshot){
        if(snapshot.data.isEmpty){
          return emptyPage();                                                   //returning empty page if no notes are present for the date
        }
        else{
          return listViewBuilder(snapshot.data);                                //returning listView with list of Notes for that date
        }
      },
    );
  }
  emptyPage(){                                                                  //empty page widget
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Card(
          elevation: 0,
          color: Colors.white24,
          child: Text(
            'No Tasks Scheduled For This Date',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 30,
                fontStyle: FontStyle.italic,
                color: Colors.grey
            ),
          ),
        ),
      ),
    );
  }
  listViewBuilder(Box box) {                                                    //list view of notes from a specific box (a specific date)
    return ListView.builder(
        itemCount:box.length,
        itemBuilder: (context,index){
          final note = box.getAt(index);
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            color: index%2==0 ? Colors.lightGreenAccent:Colors.lightBlueAccent,
            child: FlatButton(
              child:Padding(
                padding: EdgeInsets.all(10.0),
                child:Text(
                  note.title,
                  style: TextStyle(fontStyle: FontStyle.normal,fontSize: 25.0,color: Colors.black87,decoration: note.finished?TextDecoration.lineThrough:TextDecoration.none),
                ),
              ),
              onPressed: (){                                                    //displaying options when a note is clicked
                showDialog(
                    context: context,
                    builder: (BuildContext context){
                      return AlertDialog(
                        content:Container(
                          height: 250,
                          child:Column(                                         //column of options
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              SizedBox(                                         //delete option
                                width: 200,
                                height: 50,
                                child:RaisedButton(
                                  child:Text(
                                    "Delete",
                                    style: TextStyle(fontSize: 30.0),
                                  ),
                                  onPressed: (){
                                    remItem(index,box);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              SizedBox(                                         //edit option
                                width: 200,
                                height: 50,
                                child: RaisedButton(
                                  child:Text(
                                    "Edit",
                                    style: TextStyle(fontSize: 30.0),
                                  ),
                                  onPressed: (){
                                    Navigator.pop(context);
                                    editItemDialog(index,note.title,box);
                                  },
                                ),
                              ),
                              SizedBox(                                         //strike-out option
                                  width: 200,
                                  height: 50,
                                child: RaisedButton(
                                    child:Text(
                                      "Completed",
                                      style: TextStyle(fontSize: 30.0),
                                    ),
                                    onPressed: (){
                                      completeItem(index, note.title,box);
                                      Navigator.pop(context);
                                    },
                                )
                              ),
                            ],
                          ),
                        )
                      );
                    }
                );
              },
            ),
          );
        }
    );
  }
  addItemDialog(){                                                              //function to display dialog box for adding new Note
    TextEditingController myController = new TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            content: TextField(
              obscureText: false,
              controller: myController ,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter Task",
              ),
            ),
            title: Text("Enter New Task To Add"),
            actions: <Widget>[
              FlatButton(
                child:Text("Add Task"),
                onPressed: (){
                  if(myController.text!="") {                                   //preventing addition of empty notes
                    addItem(Note(myController.text,false),Hive.box(dateFormat.format(date).toString()));
                  }
                  myController.text="";
                  Navigator.pop(context);
                },
              )
            ],
          );
        }
    );
  }
  editItemDialog(int index,String str,Box box){                                 //function to display dialog box for editing an existing note
    TextEditingController myContr = TextEditingController(text:str);
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            content: TextField(
              obscureText: false,
              controller: myContr,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            title: Text("Make The Changes"),
            actions: <Widget>[
              FlatButton(
                child:Text("Save"),
                onPressed: (){
                  editItem(index,myContr.text,box);
                  myContr.text="";
                  Navigator.pop(context);
                },
              )
            ],
          );
        }
    );
  }
  showHelp(){                                                                   //function to display help Images

    showHelpPic('images/help3.jpg', 'Calender View', 'Done ');
    showHelpPic('images/help2.jpg', 'Clickable Note', 'Next ->');
    showHelpPic('images/help1.jpg', 'App Layout', 'Next ->');

  }
  showHelpPic(String picName,String titleContent,String buttonName){
    return showDialog (
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title:Text(titleContent),
            content: Image.asset(
              picName,
            ),
            actions: <Widget>[
              FlatButton(
                child:Text(buttonName),
                onPressed: (){
                  Navigator.pop(context);
                },
              )
            ],
          );
        }
    );
  }
  addItem(Note note,Box box){
    box.add(note);                                                              //adding new note to the box
    Fluttertoast.showToast(msg: 'New Note Added Successfully',toastLength: Toast.LENGTH_SHORT);
    todoBloc.getSink.add(box);                                                  //adding the changed box to the sink of todoList Bloc to rebuild the widget
  }
  remItem(int index,Box box){
    box.deleteAt(index);                                                        //deleting a note from a specific index of the box
    Fluttertoast.showToast(msg: 'Note Removed Successfully',toastLength: Toast.LENGTH_SHORT);
    todoBloc.getSink.add(box);                                                  //adding the changed box to the sink of todoList Bloc to rebuild the widget
  }
  editItem(int index,String newstr,Box box){
    box.putAt(index, Note(newstr,false));                                       //inserting the edited note at the same index
    Fluttertoast.showToast(msg: 'Made Changes Successfully',toastLength: Toast.LENGTH_SHORT);
    todoBloc.getSink.add(box);                                                  //adding the changed box to the sink of todoList Bloc to rebuild the widget
  }
  completeItem(int index,String content,Box box){
    box.putAt(index,Note(content,true));                                        //setting strike-out flag to True
    Fluttertoast.showToast(msg: 'Note Striked Out',toastLength: Toast.LENGTH_SHORT);
    todoBloc.getSink.add(box);                                                  //adding the changed box to the sink of todoList Bloc to rebuild the widget
  }
}