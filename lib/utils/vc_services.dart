import 'dart:convert';

import 'package:verifiable_claim_demo/utils/app_configs.dart';
import 'package:verifiable_claim_demo/utils/http_request.dart';

class VCServices {
  static Future<Map<dynamic, dynamic>> getAndroidLatest() {
    return Request.httpGet(AppConfigs.androidUpdateLink, {}).then((response) {
      Map resultMap = jsonDecode(response.body);
      return resultMap;
    });
  }
}
