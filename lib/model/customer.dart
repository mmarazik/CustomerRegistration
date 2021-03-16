import 'package:flutter/material.dart';

class Customer {
  final int id;
  final String platformIMEI;
  final String firstName;
  final String lastName;
  final DateTime dob;
  final String passport;
  final String email;
  final String imagePath;
  final String deviceName;
  final String lat;
  final String lng;

  Customer(
      {@required this.id,
      @required this.platformIMEI,
      @required this.firstName,
      @required this.lastName,
      @required this.dob,
      @required this.passport,
      @required this.email,
      @required this.imagePath,
      @required this.deviceName,
      @required this.lat,
      @required this.lng});
}
