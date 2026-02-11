import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nocodb_app_flutter/utils/toast_utils.dart';

class NotifyUtils {
  static void showNotify(BuildContext context, String message) {
    if (Platform.isAndroid) {
      ToastUtils.show(message);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
