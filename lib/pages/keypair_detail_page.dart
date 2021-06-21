import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:verifiable_claim_demo/local_models.dart';

import 'pages.dart';

class KeyPairDetailPageArguments {
  final Key? key;
  final String? keypairAlias;

  KeyPairDetailPageArguments({this.key, this.keypairAlias});
}

class KeyPairDetailPage extends StatefulWidget {
  final KeyPairDetailPageArguments args;

  KeyPairDetailPage(this.args) : super(key: args.key);

  @override
  State<StatefulWidget> createState() {
    return _KeyPairDetailPageState();
  }
}

class _KeyPairDetailPageState extends State<KeyPairDetailPage> {
  String? keypairAlias;
  final formKey = GlobalKey<FormState>();
  TextEditingController? controller;

  @override
  void initState() {
    super.initState();
    keypairAlias = widget.args.keypairAlias;
    controller = TextEditingController(text: keypairAlias ?? '');
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Key Pair Detail"),
        actions: [
          IconButton(
            icon: Icon(FlutterIcons.delete_ant),
            onPressed: () async {
              bool result = KeyPairManager.deleteKeyPair(keypairAlias);
              if (result) {
                navigator!.pop(true);
              } else {}
            },
          ),
        ],
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 5, bottom: 10, left: 10, right: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          maxLines: 1,
                          expands: false,
                          decoration: InputDecoration(labelText: "alias", hintText: "leave blank to use public key"),
                          validator: (value) {
                            if (controller!.text == keypairAlias) {
                              return null;
                            }
                            if (controller!.text == null ||
                                controller!.text.length <= 0 ||
                                (KeyPairManager.keyPairs!.containsKey(controller!.text) &&
                                    KeyPairManager.keyPairs![controller!.text] != null)) {
                              return 'alias already exists';
                            }
                            return null;
                          },
                        ),
                      ),
                      TextButton(
                        child: Text("save"),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (formKey.currentState!.validate()) {
                            bool result = KeyPairManager.renameKeyPair(keypairAlias, controller!.text);
                            if (result) {
                              keypairAlias = controller!.text;
                            } else {
                              controller!.text = keypairAlias!;
                            }
                            if (mounted) {
                              setState(() {});
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Text("public key:"),
                Container(
                  child: QrImage(
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    data: json.encode(
                      {
                        'type': 'pubKey',
                        'pubKey': KeyPairManager.keyPairs![keypairAlias]!.keyPair.pubKey,
                      },
                    ),
                    version: QrVersions.auto,
                  ),
                ),
                if (KeyPairManager.keyPairs![keypairAlias]!.keyPair.privKey != null) Text("private key:"),
                if (KeyPairManager.keyPairs![keypairAlias]!.keyPair.privKey != null)
                  Container(
                    child: QrImage(
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      data: json.encode(
                        {
                          'type': 'privKey',
                          'privKey': KeyPairManager.keyPairs![keypairAlias]!.keyPair.privKey,
                        },
                      ),
                      version: QrVersions.auto,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
