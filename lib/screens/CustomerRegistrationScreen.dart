import 'package:flutter/material.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  final String title;

  CustomerRegistrationScreen(this.title);
  @override
  _CustoomerRegistrationScreenState createState() =>
      _CustoomerRegistrationScreenState();
}

class _CustoomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Registration Foorm will appear here',
            ),
          ],
        ),
      ),
    );
  }
}
