// @dart=2.9
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'pages/pages.dart';

void main() {
  runApp(
    GetMaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case "home_page":
            return CupertinoPageRoute(builder: (context) => HomePage(), settings: settings, maintainState: true);
          case "claim_management_page":
            return CupertinoPageRoute(
                builder: (context) => ClaimManagementPage(), settings: settings, maintainState: true);
          case "key_management_page":
            return CupertinoPageRoute(
                builder: (context) => KeyManagementPage(), settings: settings, maintainState: true);
          case "creating_claim_page":
            return CupertinoPageRoute(
                builder: (context) => CreatingClaimPage(), settings: settings, maintainState: true);
          case "keypair_detail_page":
            if (settings.arguments is KeyPairDetailPageArguments) {
              return CupertinoPageRoute(
                  builder: (context) => KeyPairDetailPage(settings.arguments as KeyPairDetailPageArguments),
                  settings: settings,
                  maintainState: true);
            }
            return null;
          case "claim_detail_page":
            if (settings.arguments is ClaimDetailPageArguments) {
              return CupertinoPageRoute(
                  builder: (context) => ClaimDetailPage(settings.arguments as ClaimDetailPageArguments),
                  settings: settings,
                  maintainState: true);
            }
            return null;
          default:
            return null;
        }
      },
      home: WelcomePage(),
    ),
  );
}
