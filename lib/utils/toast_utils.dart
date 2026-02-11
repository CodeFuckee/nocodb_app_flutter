import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class ToastUtils {
  static const MethodChannel _channel = MethodChannel('com.example.mobile_portainer_flutter/channel');

  static void show(String message) {
    if (Platform.isAndroid) {
      _channel.invokeMethod('showToast', message);
    } else {
      // For other platforms, we might still want to use SnackBar, 
      // but since this is a static helper, passing context is needed for SnackBar.
      // However, Fluttertoast also supports iOS and Web.
      // Let's use Fluttertoast for all platforms for consistency if appropriate,
      // or just handle Android as requested.
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}
