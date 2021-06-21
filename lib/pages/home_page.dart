import 'dart:async';
import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_information/flutter_device_information.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:verifiable_claim_demo/local_models.dart';
import 'package:verifiable_claim_demo/utils/app_configs.dart';
import 'package:verifiable_claim_demo/utils/vc_services.dart';

import 'pages.dart';

class ScanSolver {
  static scan(context, refresher) async {
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
        if (scanObject["type"] != null && scanObject["type"] == "claim") {
          claimScanned(context, scanObject, refresher);
        } else if (scanObject["type"] != null && scanObject["type"] == "pubKey") {
          keypairScanned(context, scanObject, refresher);
        }
      } catch (err) {}
    }
  }

  static keypairScanned(context, scanObject, refresher) async {
    String? alias = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return KeyPairAliasDialog();
      },
    );

    if (alias != null) {
      await KeyPairManager.addKeyPair(
          KeyPair(
              scanObject["pubKey"]
                  .replaceAll(CryptoUtils.BEGIN_PUBLIC_KEY, "")
                  .replaceAll(CryptoUtils.END_PUBLIC_KEY, "")
                  .trim(),
              null),
          alias: alias,
          metaData: {"own": false});
      refresher();
      await navigator!.pushNamed("keypair_detail_page", arguments: KeyPairDetailPageArguments(keypairAlias: alias))
          as bool?;
      refresher();
    }
  }

  static claimScanned(context, scanObject, refresher) async {
    bool signIt = await (showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Claim Found"),
          content:
              SingleChildScrollView(child: ClaimDetailWidget(VerifiableClaimWrapper.fromReadable(scanObject["claim"]))),
          actions: [
            TextButton(
              onPressed: () {
                VerifiableClaimManager.addVerifiableClaims(
                    VerifiableClaimWrapper.fromReadable(scanObject["claim"]).verifiableClaim);
                navigator!.pop(false);
              },
              child: Text("save"),
            ),
            if (VerifiableClaimWrapper.fromReadable(scanObject["claim"]).verifiableClaim.issuer != null &&
                VerifiableClaimWrapper.fromReadable(scanObject["claim"]).verifiableClaim.signature != null)
              TextButton(
                onPressed: () {
                  MapEntry<String?, KeyPairWrapper?> ent = KeyPairManager.keyPairs!.entries.firstWhere((element) {
                    String pubK =
                        // sha256
                        //     .convert(utf8.encode(
                        element.value!.keyPair.pubKey!
                            .replaceAll(CryptoUtils.BEGIN_PUBLIC_KEY, "")
                            .replaceAll(CryptoUtils.END_PUBLIC_KEY, "")
                            .trim()
                        //     ))
                        // .toString()
                        ;
                    return pubK == VerifiableClaimWrapper.fromReadable(scanObject["claim"]).verifiableClaim.issuer;
                  },
                      orElse: () {
                        return null;
                      } as MapEntry<String?, KeyPairWrapper?> Function()?);
                  final result = VerifiableClaimWrapper.fromReadable(scanObject["claim"])
                      .verifiableClaim
                      .verifySignature(VerifiableClaimWrapper.fromReadable(scanObject["claim"]).verifiableClaim.issuer)
                      .isValid;
                  Dialogs.showAlertDialog(context,
                      hideCancel: true,
                      content: (result
                          ? ("valid signature\n" + (ent == null ? "keypair is NOT TRUSTED" : "signer: " + ent.key!))
                          : "INVALID signature"));
                },
                child: Text("verify signature"),
              ),
            TextButton(
              onPressed: () {
                navigator!.pop(true);
              },
              child: Text("sign it"),
            ),
          ],
        );
      },
    ) as FutureOr<bool>);
    if (signIt) {
      String? keyPairAlias = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return KeyPairSelector();
        },
      );
      if (keyPairAlias != null &&
          keyPairAlias.length > 0 &&
          KeyPairManager.keyPairs![keyPairAlias] != null &&
          KeyPairManager.keyPairs![keyPairAlias]!.keyPair.privKey != null) {
        final privK = RSAKeyParser().parse("-----BEGIN PRIVATE KEY-----\r" +
            KeyPairManager.keyPairs![keyPairAlias]!.keyPair.privKey! +
            "\r-----END PRIVATE KEY-----");
        final signer = Signer(RSASigner(
          RSASignDigest.SHA256,
          privateKey: privK as RSAPrivateKey?,
        ));
        final signature = signer
            .sign(
              json.encode(
                VerifiableClaimWrapper.fromReadable(scanObject["claim"]).verifiableClaim.toReadable(),
              ),
            )
            .base64;
        final scannedClaim = VerifiableClaimWrapper.fromReadable(scanObject["claim"]);
        // final signerPubK = KeyPairManager.keyPairs[keyPairAlias].keyPair.pubKey;
        final signerPubK =
            // sha256
            //     .convert(utf8.encode(
            KeyPairManager.keyPairs![keyPairAlias]!.keyPair.pubKey!
                .replaceAll(CryptoUtils.BEGIN_PUBLIC_KEY, "")
                .replaceAll(CryptoUtils.END_PUBLIC_KEY, "")
                .trim()
            //     ))
            // .toString()
            ;
        scannedClaim.verifiableClaim.signature = signature;
        scannedClaim.verifiableClaim.issuer = signerPubK;
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Claim Signed"),
              content: SingleChildScrollView(child: ClaimDetailWidget(scannedClaim)),
              actions: [
                TextButton(
                    onPressed: () {
                      VerifiableClaimManager.addVerifiableClaims(scannedClaim.verifiableClaim);
                      navigator!.pop(false);
                    },
                    child: Text("save")),
                TextButton(
                    onPressed: () {
                      Dialogs.showAlertDialog(
                        context,
                        hideCancel: true,
                        contentWidget: Container(
                          width: double.maxFinite,
                          child: QrImage(
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                            data: json.encode(
                              {
                                'type': 'claim',
                                'claim': scannedClaim.toReadable(),
                              },
                            ),
                            version: QrVersions.auto,
                          ),
                        ),
                      );
                    },
                    child: Text("show"))
              ],
            );
          },
        );
        refresher();
      }
    }
    refresher();
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  // Widget _buildDrawer() {
  //   return Column(
  //     children: [
  //       InkWell(
  //         onTap: () {},
  //         child: Container(),
  //       )
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(FlutterIcons.file_document_mco),
            onPressed: () {
              navigator!.pushNamed("claim_management_page");
            },
          ),
          IconButton(
            icon: Icon(FlutterIcons.key_variant_mco),
            onPressed: () {
              navigator!.pushNamed("key_management_page");
            },
          ),
        ],
      ),
      // drawer: Drawer(
      //   child: SafeArea(
      //     child: _buildDrawer(),
      //   ),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((_) => Colors.grey[300]),
              ),
              onPressed: () async {
                await ScanSolver.scan(context, () {
                  if (mounted) {
                    setState(() {});
                  }
                });
              },
              child: Text("Scan"),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((_) => Colors.grey[300]),
              ),
              onPressed: () async {
                await navigator!.pushNamed("creating_claim_page");
                if (mounted) {
                  setState(() {});
                }
              },
              child: Text("Create Claim"),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((_) => Colors.grey[300]),
              ),
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
              child: Text("Create KeyPair"),
            ),
          ],
        ),
      ),
    );
  }
}
