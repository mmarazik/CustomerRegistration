import 'dart:io';
import 'package:flutter/material.dart';

class ImageDialog extends StatelessWidget {
  final String _imagePath;

  ImageDialog(this._imagePath);
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: FileImage(File(_imagePath)), fit: BoxFit.cover)),
      ),
    );
  }
}
