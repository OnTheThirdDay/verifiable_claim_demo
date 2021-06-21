import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:verifiable_claim_demo/startup_tasks.dart';

import 'pages.dart';

class WelcomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WelcomePageState();
  }
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    StartupTasks.startupAll().then((value) {
      navigator!.pushReplacementNamed("home_page");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("loading")),
    );
  }
}
