import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'package:verifiable_claim_demo/local_models.dart';

import 'pages.dart';

class KeyPairSelector extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _KeyPairSelectorState();
  }
}

class _KeyPairSelectorState extends State<KeyPairSelector> {
  String? selectedKeyPairAlias;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "sign the claim",
      ),
      actions: <Widget>[
        TextButton(
          child: Text("confirm"),
          onPressed: () {
            navigator!.pop(selectedKeyPairAlias);
          },
        ),
        TextButton(
          child: Text("cancel"),
          onPressed: () {
            navigator!.pop(null);
          },
        ),
      ],
      content: Container(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.only(right: 10),
              child: Text("key pair"),
            ),
            Expanded(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedKeyPairAlias,
                items: KeyPairManager.keyPairs!.entries.fold(
                    [],
                    (oldArray, element) {
                      if (element.value!.keyPair.privKey != null && element.value!.keyPair.privKey!.length > 0) {
                        oldArray.add(DropdownMenuItem(
                          child: Text(
                            element.key!,
                            overflow: TextOverflow.visible,
                          ),
                          value: element.key,
                        ));
                      }
                      return oldArray;
                    } as List<DropdownMenuItem<String>>? Function(
                        List<DropdownMenuItem<String>>?, MapEntry<String?, KeyPairWrapper?>)),
                onChanged: (value) {
                  selectedKeyPairAlias = value;
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClaimDetailWidget extends StatefulWidget {
  final VerifiableClaimWrapper? v;
  const ClaimDetailWidget(this.v);

  @override
  State<StatefulWidget> createState() {
    return _ClaimDetailWidgetState();
  }
}

class _ClaimDetailWidgetState extends State<ClaimDetailWidget> {
  bool ownerPubKeyShowBase64 = false;
  bool issuerShowBase64 = false;
  bool signatureShowBase64 = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisAlignment: MainAxisAlignment.start,
        // mainAxisSize: MainAxisSize.max,
        children: [
          // if (VerifiableClaimManager.verifiableClaims[widget.args.claimUniqId]?.verifiableClaim?.id != null)
          Container(
            padding: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("id: "),
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text(widget.v!.verifiableClaim.id ?? ""),
                  ),
                ),
              ],
            ),
          ),
          // if (VerifiableClaimManager.verifiableClaims[widget.args.claimUniqId]?.verifiableClaim?.claim != null)
          Container(
            padding: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("claim: "),
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text(widget.v!.verifiableClaim.claim ?? ""),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text("ownerPubKey: "),
                    if (widget.v!.verifiableClaim.ownerPubKey != null)
                      ElevatedButton(
                          child: Text(!ownerPubKeyShowBase64 ? "Base64" : "QR Code"),
                          onPressed: () {
                            ownerPubKeyShowBase64 = !ownerPubKeyShowBase64;
                            if (mounted) {
                              setState(() {});
                            }
                          }),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: (ownerPubKeyShowBase64 || widget.v!.verifiableClaim.ownerPubKey == null)
                        ? Text(widget.v!.verifiableClaim.ownerPubKey ?? "")
                        : QrImage(
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                            data: json.encode(
                              {
                                'type': 'pubKey',
                                'pubKey': widget.v!.verifiableClaim.ownerPubKey,
                              },
                            ),
                            version: QrVersions.auto,
                          ),
                  ),
                ),
              ],
            ),
          ),
          // if (VerifiableClaimManager.verifiableClaims[widget.args.claimUniqId]?.verifiableClaim?.issuer != null)
          Container(
            padding: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text("issuer: "),
                    if (widget.v!.verifiableClaim.issuer != null)
                      ElevatedButton(
                          child: Text(!issuerShowBase64 ? "Base64" : "QR Code"),
                          onPressed: () {
                            issuerShowBase64 = !issuerShowBase64;
                            if (mounted) {
                              setState(() {});
                            }
                          }),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: (issuerShowBase64 || widget.v!.verifiableClaim.issuer == null)
                        ? Text(widget.v!.verifiableClaim.issuer ?? "")
                        : QrImage(
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                            data: json.encode(
                              {
                                'type': 'issuer',
                                'issuer': widget.v!.verifiableClaim.issuer,
                              },
                            ),
                            version: QrVersions.auto,
                          ),
                  ),
                ),
              ],
            ),
          ),
          // if (VerifiableClaimManager.verifiableClaims[widget.args.claimUniqId]?.verifiableClaim?.signature != null)
          Container(
            padding: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text("signature: "),
                    if (widget.v!.verifiableClaim.signature != null)
                      ElevatedButton(
                          child: Text(!signatureShowBase64 ? "Base64" : "QR Code"),
                          onPressed: () {
                            signatureShowBase64 = !signatureShowBase64;
                            if (mounted) {
                              setState(() {});
                            }
                          }),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: (signatureShowBase64 || widget.v!.verifiableClaim.signature == null)
                        ? Text(widget.v!.verifiableClaim.signature ?? "")
                        : QrImage(
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                            data: json.encode(
                              {
                                'type': 'signature',
                                'signature': widget.v!.verifiableClaim.signature,
                              },
                            ),
                            version: QrVersions.auto,
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Container(
          //   child: QrImage(
          // errorCorrectionLevel: QrErrorCorrectLevel.M,
          //     data: json.encode(
          //       {
          //         'type': 'claim',
          //         'claim': VerifiableClaimManager.verifiableClaims[widget.args.claimUniqId].toReadable(),
          //       },
          //     ),
          //     version: QrVersions.auto,
          //   ),
          // ),
        ],
      ),
    );
  }
}

class ClaimDetailPageArguments {
  final String? claimUniqId;

  ClaimDetailPageArguments({this.claimUniqId});
}

class ClaimDetailPage extends StatefulWidget {
  final ClaimDetailPageArguments? args;

  ClaimDetailPage(this.args) : super();

  @override
  State<StatefulWidget> createState() {
    return _ClaimDetailPageState();
  }
}

class _ClaimDetailPageState extends State<ClaimDetailPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: '');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Claim Detail"),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: () async {
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
                        'claim': VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]!.toReadable(),
                      },
                    ),
                    version: QrVersions.auto,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(FlutterIcons.delete_ant),
            onPressed: () async {
              bool result = VerifiableClaimManager.deleteVerifiableClaim(widget.args!.claimUniqId);
              if (result) {
                navigator!.pop(true);
              } else {}
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisAlignment: MainAxisAlignment.start,
          // mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ClaimDetailWidget(VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]),
              ),
            ),
            if (VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]?.verifiableClaim.signature != null)
              Container(
                // padding: EdgeInsets.all(5),
                child: TextButton(
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
                      return pubK ==
                          VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]!.verifiableClaim.issuer;
                    },
                        orElse: () {
                          return null;
                        } as MapEntry<String?, KeyPairWrapper?> Function()?);
                    final result = VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]!.verifiableClaim
                        .verifySignature(
                            VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]!.verifiableClaim.issuer)
                        .isValid;
                    Dialogs.showAlertDialog(context,
                        hideCancel: true,
                        content: (result
                            ? ("valid signature\n" + (ent == null ? "keypair is NOT TRUSTED" : "signer: " + ent.key!))
                            : "INVALID signature"));
                  },
                  child: Text("verify signature"),
                ),
              ),
            Container(
              // padding: EdgeInsets.all(5),
              child: TextButton(
                  onPressed: () async {
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
                              VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]!.verifiableClaim
                                  .toReadable(),
                            ),
                          )
                          .base64;
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
                      VerifiableClaimManager.updateVerifiableClaimSignature(
                          widget.args!.claimUniqId, signerPubK, signature);
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  },
                  child: Text(
                      (VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]?.verifiableClaim.signature !=
                                  null
                              ? "re"
                              : "") +
                          "sign by myself")),
            ),
            Container(
              // padding: EdgeInsets.all(5),
              child: TextButton(
                  onPressed: () async {
                    await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Scan QR Code"),
                          content: Container(
                            width: double.maxFinite,
                            child: QrImage(
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                              data: json.encode(
                                {
                                  'type': 'claim',
                                  'claim':
                                      VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]!.toReadable(),
                                },
                              ),
                              version: QrVersions.auto,
                            ),
                          ),
                          actions: [
                            TextButton(
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
                                    if (scanObject["type"] != null && scanObject["type"] == "claim") {
                                      if (json.encode(
                                            (((VerifiableClaimWrapper.fromReadable(scanObject["claim"]).verifiableClaim)..issuer = null)
                                                  ..signature = null)
                                                .toReadable(),
                                          ) ==
                                          json.encode(
                                            (((VerifiableClaimWrapper.fromReadable(VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]!.toReadable()).verifiableClaim)..issuer = null)
                                                  ..signature = null)
                                                .toReadable(),
                                          )) {
                                        final result = VerifiableClaimWrapper.fromReadable(scanObject["claim"])
                                            .verifiableClaim
                                            .verifySignature(VerifiableClaimWrapper.fromReadable(scanObject["claim"])
                                                .verifiableClaim
                                                .issuer)
                                            .isValid;
                                        if (result == true) {
                                          VerifiableClaimManager.updateVerifiableClaimSignature(
                                              widget.args!.claimUniqId,
                                              VerifiableClaimWrapper.fromReadable(scanObject["claim"])
                                                  .verifiableClaim
                                                  .issuer,
                                              VerifiableClaimWrapper.fromReadable(scanObject["claim"])
                                                  .verifiableClaim
                                                  .signature);
                                          navigator!.pop(true);
                                          Dialogs.showAlertDialog(context,
                                              hideCancel: true, content: "signature updated");
                                        } else {
                                          Dialogs.showAlertDialog(context, content: "INVALID signature");
                                        }
                                      } else {
                                        Dialogs.showAlertDialog(context, content: "Third party tampered the claim");
                                      }
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    } else {}
                                  } catch (err) {}
                                } else {}
                              },
                              child: Text("receive signed claim"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text(
                      (VerifiableClaimManager.verifiableClaims![widget.args!.claimUniqId]?.verifiableClaim.signature !=
                                  null
                              ? "re"
                              : "") +
                          "sign by trusted third party")),
            ),
          ],
        ),
      ),
    );
  }
}
