import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'package:verifiable_claim_demo/local_models.dart';

import 'pages.dart';

class ClaimManagementPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ClaimManagementPageState();
  }
}

class _ClaimManagementPageState extends State<ClaimManagementPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Claim Management"),
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
                  if (scanObject["type"] != null && scanObject["type"] == "claim") {
                    await ScanSolver.claimScanned(context, scanObject, () {
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
              await navigator!.pushNamed("creating_claim_page");
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      // drawer: Drawer(
      //   child: SafeArea(
      //     child: _buildDrawer(),
      //   ),
      // ),
      body: VerifiableClaimManager.verifiableClaims!.entries.length == 0
          ? Center(
              child: Text("No Verifiable Claims"),
            )
          : GridView.builder(
              itemCount: VerifiableClaimManager.verifiableClaims!.entries.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    await navigator!.pushNamed(
                      "claim_detail_page",
                      arguments: ClaimDetailPageArguments(
                          claimUniqId: VerifiableClaimManager.verifiableClaims!.entries.toList()[index].key),
                    );
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: Container(
                    color: (VerifiableClaimManager.verifiableClaims!.entries
                                    .toList()[index]
                                    .value!
                                    .verifiableClaim
                                    .signature !=
                                null &&
                            VerifiableClaimManager.verifiableClaims!.entries
                                    .toList()[index]
                                    .value!
                                    .verifiableClaim
                                    .signature!
                                    .length >
                                0)
                        ? Colors.green[200]
                        : Colors.grey[200],
                    padding: EdgeInsets.all(5),
                    margin: EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Text(VerifiableClaimManager.verifiableClaims!.entries
                            .toList()[index]
                            .value!
                            .verifiableClaim
                            .id
                            .toString()),
                        Expanded(
                          child: Text(
                            VerifiableClaimManager.verifiableClaims!.entries
                                .toList()[index]
                                .value!
                                .verifiableClaim
                                .claim!,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // QrImage(
                          //   errorCorrectionLevel: QrErrorCorrectLevel.M,
                          //   data: json.encode(
                          //     VerifiableClaimManager.verifiableClaims.entries.toList()[index].value.toReadable(),
                          //   ),
                          //   version: QrVersions.auto,
                          // ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
    );
  }
}
