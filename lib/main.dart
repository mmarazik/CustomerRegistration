import 'package:flutter/material.dart';

import 'screens/CustomersScreen.dart';
import 'screens/CustomerRegistrationScreen.dart';
import 'screens/TakePictureScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  //Main app color palatte
  final Map<int, Color> color = {
    50: Color.fromRGBO(0, 17, 65, .1),
    100: Color.fromRGBO(0, 17, 65, .2),
    200: Color.fromRGBO(0, 17, 65, .3),
    300: Color.fromRGBO(0, 17, 65, .4),
    400: Color.fromRGBO(0, 17, 65, .5),
    500: Color.fromRGBO(0, 17, 65, .6),
    600: Color.fromRGBO(0, 17, 65, .7),
    700: Color.fromRGBO(0, 17, 65, .8),
    800: Color.fromRGBO(0, 17, 65, .9),
    900: Color.fromRGBO(0, 17, 65, 1),
  };
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'MyCustomer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: MaterialColor(0xFF001141, color),
          accentColor: Color(0xFFe6e6e6),
          canvasColor: Color(0xFFe6e6e6),
          textTheme: TextTheme(
            headline4: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001141),
            ),
            headline6: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001141),
            ),
            bodyText2: TextStyle(
              fontSize: 12,
              color: Color(0xFF001141),
            ),
            bodyText1: TextStyle(
              fontSize: 12,
              color: Color(0xFF001141),
            ),
          ),
          buttonTheme: ButtonTheme.of(context).copyWith(
              buttonColor: Color(0x651856),
              textTheme: ButtonTextTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              )),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          "/": (context) => CustomerRegistrationScreen('My Customer'),
          TakePictureScreen.routeName: (context) => TakePictureScreen(),
          CustomersScreeen.routeName: (context) => CustomersScreeen(),
        });
  }
}
