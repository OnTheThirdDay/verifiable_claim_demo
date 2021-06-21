import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:verifiable_claim_demo/local_models.dart';
import 'package:verifiable_claim_demo/pages/pages.dart';

class CreatingClaimPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CreatingClaimPageState();
  }
}

class CreatingClaimPageState extends State<CreatingClaimPage> {
  TextEditingController? controller;
  late Uuid uuid;
  String? id;
  String? selectedKeyPairAlias;
  final formKey = GlobalKey<FormState>();

  @override
  initState() {
    controller = TextEditingController(text: '');
    uuid = Uuid();
    id = uuid.v4();
    selectedKeyPairAlias = "";
    super.initState();
  }

  @override
  dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Claim"),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        child: Text(
                          id!,
                          // overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        id = uuid.v4();
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: Icon(
                        FlutterIcons.dice_faw5s,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.only(right: 10),
                      child: Text("owner key pair"),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedKeyPairAlias,
                        items: [
                              DropdownMenuItem(
                                child: Text(""),
                                value: "",
                              )
                            ] +
                            KeyPairManager.keyPairs!.keys
                                .toList()
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    child: Text(
                                      e!,
                                    ),
                                    value: e,
                                  ),
                                )
                                .toList(),
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
              Expanded(
                child: Container(
                  child: TextFormField(
                    // expands: true,
                    maxLines: null,
                    scrollPadding: EdgeInsets.all(5),
                    controller: controller,
                    validator: (value) {
                      if (value == null || value.length <= 0) {
                        return 'cannot be empty';
                      }
                      return null;
                    },
                    decoration: InputDecoration(labelText: "claim", alignLabelWithHint: true),
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  if (formKey.currentState!.validate()) {
                    String vcAlias = await VerifiableClaimManager.addVerifiableClaims(
                      VerifiableClaim(
                        id,
                        (!KeyPairManager.keyPairs!.containsKey(selectedKeyPairAlias) ||
                                KeyPairManager.keyPairs![selectedKeyPairAlias] == null)
                            ? null
                            : sha256
                                .convert(utf8.encode(KeyPairManager.keyPairs![selectedKeyPairAlias]!.keyPair.pubKey!
                                    .replaceAll(CryptoUtils.BEGIN_PUBLIC_KEY, "")
                                    .replaceAll(CryptoUtils.END_PUBLIC_KEY, "")
                                    .trim()))
                                .toString(),
                        controller!.text,
                      ),
                    );
                    if (vcAlias != null) {
                      var result = await navigator!.pushNamed(
                        "claim_detail_page",
                        arguments: ClaimDetailPageArguments(claimUniqId: vcAlias),
                      );
                      navigator!.pop(result);
                    }
                  }
                },
                child: Text("generate"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
