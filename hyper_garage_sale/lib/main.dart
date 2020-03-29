import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'globals.dart' as globals;
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const LatLng SOURCE_LOCATION = LatLng(37.310805, -121.979503);
const double CAMERA_ZOOM = 16;
const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 30;

/*we start our project in the TakePictureScreen class*/
Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  

    runApp( 
      MaterialApp(
        theme: ThemeData.dark(),
        home: TakePictureScreen(
          camera: firstCamera,
        ),
        routes: <String, WidgetBuilder> {
          "/TodosScreen" : (BuildContext context) => new TodosScreen(),
        },
      ),
    );
}

    // A screen that takes in a list of cameras and the Directory to store images.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}



class TakePictureScreenState extends State<TakePictureScreen> {
  // Add two variables to the state class to store the CameraController and
  // the Future.
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  DateTime currentTime = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  String _title;
  String _price;
  String _description;
  Completer<GoogleMapController> _mapController = Completer();
  LocationData currentLocation;
  Location location;


  

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();

    location = new Location();
    location.onLocationChanged().listen((LocationData cLoc) {
      currentLocation = cLoc;
      print("current location: " + cLoc.toString());
      updatePinOnMap();
    });

    setInitialLocation();
  }

  void setInitialLocation() async {
    currentLocation = await location.getLocation();
  }

   /*we have new camera position every time location changes,
      so that we can update our location view on maps as it changes*/
    void updatePinOnMap() async {

      CameraPosition cPos = CameraPosition(
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING,
        target: LatLng(currentLocation.latitude, currentLocation.longitude),
      );

      //over here, we update our camera position with the current location
      final GoogleMapController _updatesController = await _mapController.future;
      _updatesController.animateCamera(CameraUpdate.newCameraPosition(cPos));

  }


  

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }


  @override
  /*Builds the home screen with FormUI as what the user sees,
  FormUI creates 3 text fields with validators that check and save the 
  text that is entered by the user. Below the form UI, I establish two 
  a row with camera buttons that allow a picture to be taken*/

  Widget build(BuildContext context) {
      return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ListViews',
          theme: ThemeData(
            primarySwatch: Colors.teal,
          ),
          home: Scaffold(
            appBar: AppBar(title: Text('HyperGarageSale')),
            body: new SingleChildScrollView(
              child: new Container(
                margin: new EdgeInsets.all(15.0),
                child: new Form(
                  key: _formKey,
                  autovalidate: _autoValidate,
                  child: FormUI(),
                ),
              ),
            ),
          ),
      );
  }

    Widget FormUI() {

      CameraPosition initialCameraPosition = CameraPosition(
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING,
        target: SOURCE_LOCATION,
      );

      //we check whether current location is null. if it isn't. we update the 
      //initial camera position's latitude and longitude
      if (currentLocation != null) {
        initialCameraPosition = CameraPosition(
          target: LatLng(currentLocation.latitude, currentLocation.longitude),
          zoom: CAMERA_ZOOM,
          tilt: CAMERA_TILT,
          bearing: CAMERA_BEARING,
        );
      }


      return new Column (
        children: <Widget> [

          //onSaved saves the name entered 
          new TextFormField(
            decoration: const InputDecoration(labelText: 'Title'),
            keyboardType: TextInputType.text,
            validator: validateTitle,
            
            onSaved: (String val) {
              _title = val;
              globals.itemList.add("\n\n\n" + "Selling " + _title + "\n");
          
            }
          ),

          new TextFormField(
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.text,
            validator: validatePrice,

            onSaved: (String val) {
              _price = val;
              globals.itemList.add("Price: " + _price + "\n");
            }  
          ),

          new TextFormField(
            decoration: const InputDecoration(labelText: 'Description'),
            keyboardType: TextInputType.text,
            validator: validateDesc,

             onSaved: (String val) {
              _description = val; 
              globals.itemList.add("Description: " + _description + "\n");  
           
            }
          ),
          new SizedBox(
            height: 10.0,
          ),
          new RaisedButton(

            //navigate to new page from here using navigator.push new route()
            onPressed: _validateInputs, 
            child: new Text('Post'),
          ),

          new Row(

                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: <Widget>[

                  FloatingActionButton(
                    heroTag: "btn1",
                    child: Icon(Icons.camera_alt),
                    onPressed: () async {

                      try {
                        // Ensure that the camera is initialized.
                        await _initializeControllerFuture;

                        // Construct the path where the image should be saved using the
                        // pattern package.
                        final path = join(
                          // Store the picture in the temp directory.
                          // Find the temp directory using the `path_provider` plugin.
                          (await getTemporaryDirectory()).path,
                          '${DateTime.now()}.png',
                        );

                        //Takes picture with camera and logs where it's saved 
                        await _controller.takePicture(path);
                        addItemstoSP(path);

                        // If the picture was taken, display it on a new screen.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DisplayPictureScreen(imagePath: path),
                          ),
                        );    
                      } catch (e) {
                        // If an error occurs, log the error to the console.
                        print(e);
                      }

                    }, 
                  ),

                  FloatingActionButton(
                    heroTag: "btn2",
                    child: Icon(Icons.camera_alt),
                    onPressed: () async {

                      try {
                        // Ensure that the camera is initialized.
                        await _initializeControllerFuture;

                        // Construct the path where the image should be saved using the
                        // pattern package.
                        final path = join(
                          // Store the picture in the temp directory.
                          // Find the temp directory using the `path_provider` plugin.
                          (await getTemporaryDirectory()).path,
                          '${DateTime.now()}.png',
                        );
                        
                        await _controller.takePicture(path);
                        addItemstoSP(path);

                        // If the picture was taken, display it on a new screen.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DisplayPictureScreen(imagePath: path),
                          ),
                        );
                      } catch (e) {
                        // If an error occurs, log the error to the console.
                        print(e);
                      }
                    }
                  ),
                ],
          ),

          //add some padding between widgets
          new Padding(
            padding: const EdgeInsets.all(10),

          ),

          /*add row below form fields for google maps current location*/
          new Row(
             mainAxisAlignment: MainAxisAlignment.center,
                 children: <Widget>[

                   SizedBox(
                     width: 300,
                     height: 200,
                     child:
                      GoogleMap(
                        initialCameraPosition: initialCameraPosition,
                        onMapCreated: (GoogleMapController controller) {
                            _mapController.complete((controller));
                        }
                      ),   
                   ),
                 ],
          ),

      ],
    );
  }






  String validateTitle(String value) { 
    if (value.length < 1)
        return 'Text box must have something in it';
      else   
        return null;
  }

  
  String validatePrice(String value) { 
    if (value.length < 1)
        return 'Text box must have something in it';
      else
        return null;
  }

  
  String validateDesc(String value) { 
    if (value.length < 1)
        return 'Text box must have something in it';
      else
        return null;
  }

  /*this function validates inputs entered in the forms and then saves them 
  if they're valid. It is called when the user clicks on "Post", which then navigates
  the user to a new screen where the picture and info is represented*/
  void _validateInputs() {
    currentTime = DateTime.now();
    //if data valid, then save and go to next screen
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      _navigateToNewScreen(context);

    
      
    } else {
      //if data not valid then start the autovalidation
      setState(() {
        _autoValidate = true;
      });
    
    }
  }

    _navigateToNewScreen(BuildContext context) async {
      //_validateInputs();
      Navigator.of(context).pushNamed("/TodosScreen");
    }


  void addItemstoSP(String path) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    globals.itemList.add(path);
    prefs.setStringList('$currentTime', globals.itemList);
    print(prefs.getStringList('$currentTime'));
  }

}




/*TodosScreen is a class where all the info from the form fields entered by the 
user and the picture taken are represented as different elements in a ListView.
It also enables notfications for whenever a new post is created*/

class TodosScreen extends StatefulWidget {

  const TodosScreen({Key key}) : super(key: key);

  @override
  _TodosScreenState createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {


  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  initState() {
    super.initState();
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project   
     // If you have skipped STEP 3 then change app_icon to @mipmap/ic_launcher
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon'); 

    var initializationSettingsIOS = new IOSInitializationSettings();
    
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
     onSelectNotification: onSelectNotification);
  }



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
      
      print("item count has increased!"); 
      _showNotificationWithDefaultSound();
    }
  
    //return Scaffold();

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

  Future onSelectNotification(String payload) async {
    showDialog(
      context: context,
      builder: (_) {
        return new AlertDialog(
          title: Text("PayLoad"),
          content: Text("Payload : $payload"),
        );
      },
    );
  }

  Future _showNotificationWithDefaultSound() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'New Post!',
      'A new posting has been added.',
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

}




                

/*class for displaying the picture taken to the user*/
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}


