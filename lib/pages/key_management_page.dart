import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'package:verifiable_claim_demo/local_models.dart';

import 'pages.dart';

class KeyPairAliasDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _KeyPairAliasDialogState();
  }
}

class _KeyPairAliasDialogState extends State<KeyPairAliasDialog> {
  TextEditingController? controller;
  final formKey = GlobalKey<FormState>();
  @override
  initState() {
    super.initState();
    controller = TextEditingController(text: '');
  }

  @override
  dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("generate key"),
      content: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.always,
        child: TextFormField(
          controller: controller,
          validator: (value) {
            if (KeyPairManager.keyPairs!.containsKey(value) && KeyPairManager.keyPairs![value] != null) {
              return 'alias already exists';
            }
            return null;
          },
          decoration: InputDecoration(labelText: "alias", hintText: "leave blank to use public key"),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              navigator!.pop(controller!.text);
            }
          },
          child: Text("confirm"),
        ),
        TextButton(
          onPressed: () {
            navigator!.pop(null);
          },
          child: Text("cancel"),
        )
      ],
    );
  }
}

class KeyManagementPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _KeyManagementPageState();
  }
}

class _KeyManagementPageState extends State<KeyManagementPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Key Management"),
        actions: [
          IconButton(
            icon: Icon(FlutterIcons.qrcode_scan_mco),
            onPressed: () async {
              String scanResult = await QRCodeReader()
                  .setAutoFocusIntervalInMs(200) // default 5000
                  .setForceAutoFocus(true) // default false
                  .setTorchEnabled(true) // default false
                  .setHandlePermissions(true) // default true
                  .setExecuteAfterPermissionGranted(true) // default true
                  .scan();
              if (scanResult != null) {
                try {
                  Map scanObject = json.decode(scanResult);
                  if (scanObject["type"] != null && scanObject["type"] == "pubKey") {
                    await ScanSolver.keypairScanned(context, scanObject, () {
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  }
                } catch (err) {}
              }
            },
          ),
          IconButton(
            icon: Icon(FlutterIcons.add_mdi),
            onPressed: () async {
              String? alias = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return KeyPairAliasDialog();
                },
              );
              if (alias != null) {
                Dialogs.showLoading(context);
                KeyPair keyPair =
                    await (compute<KeyPair?, dynamic>(KeyPairManager.generateKeyPair, null) as FutureOr<KeyPair>);
                await KeyPairManager.addKeyPair(keyPair, alias: alias, metaData: {"own": true});
                Dialogs.hideLoading();
                if (mounted) {
                  setState(() {});
                }
                await navigator!.pushNamed("keypair_detail_page",
                    arguments: KeyPairDetailPageArguments(keypairAlias: alias)) as bool?;
                if (mounted) {
                  setState(() {});
                }
              }
            },
          ),
        ],
      ),
      body: KeyPairManager.keyPairs!.entries.length == 0
          ? Center(
              child: Text("No Key Pairs"),
            )
          : GridView.builder(
              itemCount: KeyPairManager.keyPairs!.entries.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    await navigator!.pushNamed("keypair_detail_page",
                        arguments: KeyPairDetailPageArguments(
                            keypairAlias: KeyPairManager.keyPairs!.entries.toList()[index].key)) as bool?;
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: Container(
                    // color: (KeyPairManager.keyPairs.entries.toList()[index].value.metaData["own"] == true)
                    color: (KeyPairManager.keyPairs!.entries.toList()[index].value!.keyPair.privKey != null &&
                            KeyPairManager.keyPairs!.entries.toList()[index].value!.keyPair.privKey!.length > 0)
                        ? Colors.green[200]
                        : Colors.grey[200],
                    padding: EdgeInsets.all(5),
                    margin: EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Text(KeyPairManager.keyPairs!.entries.toList()[index].key.toString()),
                        Expanded(
                          child: QrImage(
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                            data: json.encode(
                              {
                                'type': 'pubKey',
                                'pubKey': KeyPairManager.keyPairs!.entries.toList()[index].value!.keyPair.pubKey,
                              },
                            ),
                            version: QrVersions.auto,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
    );
  }
}
