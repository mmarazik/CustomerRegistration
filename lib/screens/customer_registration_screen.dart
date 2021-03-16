import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:flutter/services.dart';
import 'package:imei_plugin/imei_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:path/path.dart' as p;

import 'customers_screen.dart';
import 'take_picture_screen.dart';
import '../helpers/database_helper.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  final String title;

  CustomerRegistrationScreen(this.title);
  @override
  _CustoomerRegistrationScreenState createState() =>
      _CustoomerRegistrationScreenState();
}

class _CustoomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  //Globl form key
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  //Regex for fields validation (Name and IMEI and email)
  static final validNameCharacters = RegExp(r'^[A-Za-z\u0600-\u06FF\s-]+$');
  static final validIMEI = RegExp(r'^\d{15}');
  static final validPassportNumber = RegExp(r'^[A-Za-z1-9-]+$');
  static final validEmail = RegExp(
      r"^(?!(?:(?:\x22?\x5C[\x00-\x7E]\x22?)|(?:\x22?[^\x5C\x22]\x22?)){255,})(?!(?:(?:\x22?\x5C[\x00-\x7E]\x22?)|(?:\x22?[^\x5C\x22]\x22?)){65,}@)(?:(?:[\x21\x23-\x27\x2A\x2B\x2D\x2F-\x39\x3D\x3F\x5E-\x7E]+)|(?:\x22(?:[\x01-\x08\x0B\x0C\x0E-\x1F\x21\x23-\x5B\x5D-\x7F]|(?:\x5C[\x00-\x7F]))*\x22))(?:\.(?:(?:[\x21\x23-\x27\x2A\x2B\x2D\x2F-\x39\x3D\x3F\x5E-\x7E]+)|(?:\x22(?:[\x01-\x08\x0B\x0C\x0E-\x1F\x21\x23-\x5B\x5D-\x7F]|(?:\x5C[\x00-\x7F]))*\x22)))*@(?:(?:(?!.*[^.]{64,})(?:(?:(?:xn--)?[a-z0-9]+(?:-[a-z0-9]+)*\.){1,126}){1,}(?:(?:[a-z][a-z0-9]*)|(?:(?:xn--)[a-z0-9]+))(?:-[a-z0-9]+)*)|(?:\[(?:(?:IPv6:(?:(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){7})|(?:(?!(?:.*[a-f0-9][:\]]){7,})(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,5})?::(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,5})?)))|(?:(?:IPv6:(?:(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){5}:)|(?:(?!(?:.*[a-f0-9]:){5,})(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,3})?::(?:[a-f0-9]{1,4}(?::[a-f0-9]{1,4}){0,3}:)?)))?(?:(?:25[0-5])|(?:2[0-4][0-9])|(?:1[0-9]{2})|(?:[1-9]?[0-9]))(?:\.(?:(?:25[0-5])|(?:2[0-4][0-9])|(?:1[0-9]{2})|(?:[1-9]?[0-9]))){3}))\]))$");

  //Local variables for storing form data
  String _platformImei = "";
  String _firstName = "";
  String _lastName = "";
  String _passport = "";
  String _email = "";
  DateTime _dob;
  XFile _imageFile;
  Position _currentPosition;

  TextEditingController _imeiController;
  String _sdCardPath;

  //helper variable to indicate if form is saved to display error message for invalid date of birth
  bool _isFormSaved = false;

  Future<int> _insertDBRow() async {
    String deviceName = "Other";
    if (Platform.isAndroid) {
      deviceName = "Android";
    } else if (Platform.isIOS) {
      deviceName = "iOS";
    }

    String imageFilePath = _imageFile.path;
    print("Current Image File Path is ");
    print(imageFilePath);

    if (Platform.isAndroid && _sdCardPath != null) {
      try {
        //save image to SD card
        String newFilePath = p.join(_sdCardPath, _imageFile.name);
        File file = File(_imageFile.path);
        File newFile = await file.copy(newFilePath);
        file.delete();
        imageFilePath = newFile.path;
        print("Copied file to new location");
        print(imageFilePath);
      } catch (error) {
        //error copying file so we will save the record with old path
        print(error.toString());
      }
    }

    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelper.columnIMEI: _platformImei,
      DatabaseHelper.columnFirstName: _firstName,
      DatabaseHelper.columnLastName: _lastName,
      DatabaseHelper.columnDob: _dob.toString(),
      DatabaseHelper.columnPassportNumber: _passport,
      DatabaseHelper.columnEmail: _email,
      DatabaseHelper.columnImagePath: imageFilePath,
      DatabaseHelper.columnDeviceName: deviceName,
      DatabaseHelper.columnLat:
          (_currentPosition != null ? _currentPosition.latitude : 0),
      DatabaseHelper.columnLng:
          (_currentPosition != null ? _currentPosition.longitude : 0),
    };
    int id;
    try {
      id = await dbHelper.insert(row);
    } catch (error) {
      print("Databse failed to insert");
      print(error.toString());
      return -1;
    }
    return id;
  }

  void _onSubmit() async {
    final isValid = _formKey.currentState.validate();
    FocusScope.of(context).unfocus();

    if (_dob == null) {
      setState(() {
        _dob = null;
        _isFormSaved = true;
      });
      return;
    }

    if (_imageFile == null) {
      setState(() {
        _isFormSaved = true;
      });
      return;
    }

    if (!isValid) {
      return;
    }
    _formKey.currentState.save();

    print("Before getting location");
    _currentPosition = await _determinePosition().catchError((e) {
      print("error on getting location");
      _currentPosition = null;
    });
    if (_currentPosition != null) {
      print(_currentPosition.latitude.toString());
      print(_currentPosition.longitude.toString());
    }

    //save to DB
    int id = await _insertDBRow();
    if (id == -1) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: (() {
            Text("Error");
          }()),
          content: Text("Failed to insert to DB!"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: (() {
            Text("Success");
          }()),
          content: Text(
              "Successfully inserted record with id '" + id.toString() + "'"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      _formKey.currentState.reset();
      setState(() {
        _dob = null;
        _isFormSaved = false;
        _imageFile = null;
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    int month1 = currentDate.month;
    int month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _dob == null ? DateTime.now() : _dob,
      firstDate: DateTime(1920, 1, 1),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Birth Daate',
      fieldHintText: 'month/day/year',
      fieldLabelText: 'Enter Birth Date (mm/dd/yy)',
      errorFormatText: 'Please enter a valid date in the format mm/dd/yyyy',
      errorInvalidText: 'Valid Birth date range is from 1/1/1920 till today',
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _dob = pickedDate;
      });
    });
  }

  Future<void> _initPlatformState() async {
    String platformImei = "";
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformImei =
          await ImeiPlugin.getImei(shouldShowRequestPermissionRationale: false);
      print(platformImei);
    } on PlatformException {
      platformImei = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    _imeiController.text = platformImei;
    setState(() {
      _platformImei = platformImei;
    });
  }

  Future<void> _initExternalStorage() async {
    _sdCardPath = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);
  }

  @override
  void initState() {
    super.initState();
    _imeiController = new TextEditingController();
    if (Platform.isAndroid) {
      _initPlatformState();
      _initExternalStorage();
    }
  }

  @override
  Widget build(BuildContext context) {
    DateFormat formatter = new DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        brightness: Brightness.light,
        actions: [
          DropdownButton(
            underline: Container(),
            icon: Icon(Icons.more_vert,
                color: Theme.of(context).primaryIconTheme.color),
            items: [
              DropdownMenuItem(
                child: Container(
                  width: 80,
                  height: 20,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(15)),
                  child: Text('Show All Customers',
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                  // child: Row(
                  //   children: <Widget>[
                  //     Icon(Icons.language),
                  //     SizedBox(width: 8),
                  //     Text(S.of(context).menuOtherLang),
                  //   ],
                  // ),
                ),
                value: 'show_customers',
              ),
            ],
            onChanged: (itemIdentifier) {
              if (itemIdentifier == "show_customers") {
                Navigator.pushNamed(context, CustomersScreeen.routeName);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Customer Registrataion",
                style: Theme.of(context).textTheme.headline4,
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                key: ValueKey("imei"),
                controller: _imeiController,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  labelText: 'IMEI',
                  labelStyle: Theme.of(context).textTheme.bodyText1,
                ),
                validator: (value) {
                  value = value.trim();
                  if (value.isEmpty) {
                    return 'IMEI is required';
                  } else if (!validIMEI.hasMatch(value)) {
                    return 'IMEI must be 15 digits';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  _platformImei = newValue.trim();
                },
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                key: ValueKey("first_name"),
                autocorrect: false,
                textCapitalization: TextCapitalization.words,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  labelText: 'First Name',
                  labelStyle: Theme.of(context).textTheme.bodyText1,
                ),
                validator: (value) {
                  value = value.trim();
                  if (value.isEmpty) {
                    return 'First Name is Required';
                  } else if (!validNameCharacters.hasMatch(value)) {
                    return 'First Name must contain characters and spaces only';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  _firstName = newValue.trim();
                },
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                key: ValueKey("last_name"),
                autocorrect: false,
                textCapitalization: TextCapitalization.words,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  labelText: 'Last Name',
                  labelStyle: Theme.of(context).textTheme.bodyText1,
                ),
                validator: (value) {
                  value = value.trim();
                  if (value.isEmpty) {
                    return 'Last Name is Required';
                  } else if (!validNameCharacters.hasMatch(value)) {
                    return 'Last Name must contain characters and spaces only';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  _lastName = newValue.trim();
                },
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Date of Birth",
                              style: Theme.of(context).textTheme.bodyText1),
                          Text(
                            _dob == null
                                ? _isFormSaved
                                    ? 'Birth Date is Required'
                                    : ""
                                : formatter.format(_dob),
                            style: _dob == null
                                ? TextStyle(color: Theme.of(context).errorColor)
                                : null,
                          ),
                          IconButton(
                              icon: Icon(Icons.date_range),
                              color: Theme.of(context).primaryColor,
                              onPressed: _presentDatePicker),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              if (_dob != null && _calculateAge(_dob) >= 18)
                TextFormField(
                  key: ValueKey("passport"),
                  autocorrect: false,
                  textCapitalization: TextCapitalization.words,
                  enableSuggestions: false,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    labelText: 'Passport Number',
                    labelStyle: Theme.of(context).textTheme.bodyText1,
                  ),
                  validator: (value) {
                    value = value.trim();
                    if (value.isEmpty) {
                      if (_dob != null && _calculateAge(_dob) >= 18) {
                        return 'Passport Number is Required';
                      }
                      return null;
                    } else if (!validPassportNumber.hasMatch(value)) {
                      return 'Passport Number must contain characters and numbers only';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    _passport = newValue.trim();
                  },
                ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                key: ValueKey("email"),
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                enableSuggestions: false,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  labelText: 'Email',
                  labelStyle: Theme.of(context).textTheme.bodyText1,
                ),
                validator: (value) {
                  value = value.trim();
                  if (value.isNotEmpty && !validEmail.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  _email = newValue.trim();
                },
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_imageFile == null)
                            _isFormSaved
                                ? Text("Photo is required",
                                    style: TextStyle(
                                        color: Theme.of(context).errorColor))
                                : Text("Please take your picture!",
                                    style:
                                        Theme.of(context).textTheme.bodyText1),
                          if (_imageFile != null)
                            Image.file(
                              File(_imageFile.path),
                              height: 200,
                              width: 200,
                              fit: BoxFit.fitWidth,
                            ),
                          ElevatedButton(
                            onPressed: () async {
                              if (_imageFile != null) {
                                print("Will Delete old file");
                                print(_imageFile.path);
                                File f = File(_imageFile.path);
                                f.delete();
                                _imageFile = null;
                              }
                              final image = await Navigator.pushNamed(
                                  context, TakePictureScreen.routeName);
                              if (image != null) {
                                setState(() {
                                  _imageFile = image;
                                });
                                print(_imageFile.name);
                              }
                            },
                            child: Text("Take Picture"),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  _onSubmit();
                },
                // color: Theme.of(context).primaryColor,
                child: Text("Save", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
