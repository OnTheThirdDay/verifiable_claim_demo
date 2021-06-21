import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:verifiable_claim_demo/local_storage.dart';

class LocalModel {}

class KeyPairManager {
  static bool? dirty;
  static Map<String?, KeyPairWrapper?>? _allKeyPairs;

  static Map<String?, KeyPairWrapper?>? get keyPairs {
    _loadKeyPairs();
    return _allKeyPairs;
  }

  static void _loadKeyPairs() {
    if (_allKeyPairs == null) {
      if (LocalStorage.contains("keyPairs")) {
        _allKeyPairs = {};
        LocalStorage.extract("keyPairs").entries.forEach((e) {
          _allKeyPairs![e.key] = KeyPairWrapper.fromReadable(e.value);
        });
      } else {
        _allKeyPairs = {};
      }
    }
  }

  static void _saveKeyPairs() {
    _loadKeyPairs();
    Map<String?, Map> keyPairsToSave = {};
    _allKeyPairs!.entries.forEach((e) {
      keyPairsToSave[e.key] = e.value!.toReadable();
    });
    LocalStorage.enter("keyPairs", keyPairsToSave);
  }

  static void loadLocalKeyPairs() {
    _loadKeyPairs();
  }

  static Future<bool> addKeyPair(KeyPair keyPair, {String? alias, required Map metaData}) async {
    _loadKeyPairs();
    metaData["pubKeySHA256"] = sha256
        .convert(utf8.encode(keyPair.pubKey!
            .replaceAll(CryptoUtils.BEGIN_PUBLIC_KEY, "")
            .replaceAll(CryptoUtils.END_PUBLIC_KEY, "")
            .trim()))
        .toString();
    if (alias != null && alias.length > 0 && (!_allKeyPairs!.containsKey(alias) || _allKeyPairs![alias] == null)) {
      _allKeyPairs![alias] = KeyPairWrapper(keyPair, metaData);
    } else {
      String kAlias = DateTime.now().toString() + md5.convert(utf8.encode(keyPair.pubKey!)).toString().substring(0, 8);
      while (!(kAlias != null &&
          kAlias.length > 0 &&
          (!_allKeyPairs!.containsKey(kAlias) || _allKeyPairs![kAlias] == null))) {
        await Future.delayed(Duration(milliseconds: 200));
        kAlias = DateTime.now().toString() +
            keyPair.pubKey!
                .replaceAll(CryptoUtils.BEGIN_PUBLIC_KEY, "")
                .replaceAll(CryptoUtils.END_PUBLIC_KEY, "")
                .trim()
                .substring(0, 8);
      }
      _allKeyPairs![kAlias] = KeyPairWrapper(keyPair, metaData);
    }
    _saveKeyPairs();
    return true;
  }

  static bool renameKeyPair(String? oldAlias, String newAlias) {
    if (newAlias == null ||
        newAlias.length <= 0 ||
        (KeyPairManager.keyPairs!.containsKey(newAlias) && KeyPairManager.keyPairs![newAlias] != null) ||
        oldAlias == newAlias) {
      return false;
    }
    KeyPairManager.keyPairs![newAlias] = KeyPairManager.keyPairs![oldAlias];
    KeyPairManager.keyPairs![oldAlias] = null;
    KeyPairManager.keyPairs!.remove(oldAlias);
    _saveKeyPairs();
    return true;
  }

  static bool deleteKeyPair(String? alias) {
    if (alias == null ||
        alias.length <= 0 ||
        !KeyPairManager.keyPairs!.containsKey(alias) ||
        KeyPairManager.keyPairs![alias] == null) {
      return false;
    }
    KeyPairManager.keyPairs![alias] = null;
    KeyPairManager.keyPairs!.remove(alias);
    _saveKeyPairs();
    return true;
  }

  static Future<KeyPair> generateKeyPair(void _) async {
    var kp = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    String pubK = CryptoUtils.encodeRSAPublicKeyToPem(kp.publicKey as RSAPublicKey)
        .replaceAll(CryptoUtils.BEGIN_PUBLIC_KEY, "")
        .replaceAll(CryptoUtils.END_PUBLIC_KEY, "")
        .trim();
    String privK = CryptoUtils.encodeRSAPrivateKeyToPem(kp.privateKey as RSAPrivateKey)
        .replaceAll(CryptoUtils.BEGIN_PRIVATE_KEY, "")
        .replaceAll(CryptoUtils.END_PRIVATE_KEY, "")
        .trim();
    return KeyPair(pubK, privK);
  }
}

class KeyPairWrapper {
  final KeyPair keyPair;
  final Map? metaData;

  KeyPairWrapper(this.keyPair, this.metaData);

  KeyPairWrapper.fromReadable(Map map)
      : this.keyPair = KeyPair.fromReadable(map["keyPair"]),
        this.metaData = map["metaData"];

  Map toReadable() {
    return {
      "keyPair": keyPair.toReadable(),
      "metaData": metaData,
    }..removeWhere((key, value) => value == null);
  }
}

class KeyPair {
  final String? pubKey;
  final String? privKey;

  const KeyPair(this.pubKey, this.privKey);

  KeyPair.fromReadable(Map map)
      : this.pubKey = map["pubKey"],
        this.privKey = map["privKey"];

  Map toReadable() {
    return {
      "pubKey": pubKey,
      "privKey": privKey,
    }..removeWhere((key, value) => value == null);
  }
}

class VerifiableClaimManager {
  static bool? dirty;
  static Map<String?, VerifiableClaimWrapper?>? _allVerifiableClaims;

  static Map<String?, VerifiableClaimWrapper?>? get verifiableClaims {
    _loadVerifiableClaims();
    return _allVerifiableClaims;
  }

  static void _loadVerifiableClaims() {
    if (_allVerifiableClaims == null) {
      if (LocalStorage.contains("verifiableClaims")) {
        _allVerifiableClaims = {};
        LocalStorage.extract("verifiableClaims").entries.forEach((e) {
          _allVerifiableClaims![e.key] = VerifiableClaimWrapper.fromReadable(e.value);
        });
      } else {
        _allVerifiableClaims = {};
      }
    }
  }

  static void _saveVerifiableClaims() {
    _loadVerifiableClaims();
    Map<String?, Map> verifiableClaimsToSave = {};
    _allVerifiableClaims!.entries.forEach((e) {
      verifiableClaimsToSave[e.key] = e.value!.toReadable();
    });
    LocalStorage.enter("verifiableClaims", verifiableClaimsToSave);
  }

  static Future<String> addVerifiableClaims(VerifiableClaim verifiableClaim, {Map? metaData}) async {
    _loadVerifiableClaims();
    String kAlias =
        DateTime.now().toString() + md5.convert(utf8.encode(verifiableClaim.claim!)).toString().substring(0, 8);
    while (!(kAlias != null &&
        kAlias.length > 0 &&
        (!_allVerifiableClaims!.containsKey(kAlias) || _allVerifiableClaims![kAlias] == null))) {
      await Future.delayed(Duration(milliseconds: 200));
      kAlias = DateTime.now().toString() + md5.convert(utf8.encode(verifiableClaim.claim!)).toString().substring(0, 8);
    }
    _allVerifiableClaims![kAlias] = VerifiableClaimWrapper(verifiableClaim, metaData);
    _saveVerifiableClaims();
    return kAlias;
  }

  static bool deleteVerifiableClaim(String? alias) {
    if (alias == null ||
        alias.length <= 0 ||
        !VerifiableClaimManager.verifiableClaims!.containsKey(alias) ||
        VerifiableClaimManager.verifiableClaims![alias] == null) {
      return false;
    }
    VerifiableClaimManager.verifiableClaims![alias] = null;
    VerifiableClaimManager.verifiableClaims!.remove(alias);
    _saveVerifiableClaims();
    return true;
  }

  static bool updateVerifiableClaimSignature(String? alias, String? issuer, String? signature) {
    if (alias == null ||
        alias.length <= 0 ||
        !VerifiableClaimManager.verifiableClaims!.containsKey(alias) ||
        VerifiableClaimManager.verifiableClaims![alias] == null) {
      return false;
    }
    VerifiableClaimManager.verifiableClaims![alias]!.verifiableClaim.signature = signature;
    VerifiableClaimManager.verifiableClaims![alias]!.verifiableClaim.issuer = issuer;
    _saveVerifiableClaims();
    return true;
  }
}

class VerifyResult {
  final bool isValid;

  VerifyResult(this.isValid);
}

class VerifiableClaimWrapper {
  final VerifiableClaim verifiableClaim;
  final Map? metaData;

  VerifiableClaimWrapper(this.verifiableClaim, this.metaData);

  VerifiableClaimWrapper.fromReadable(Map map)
      : this.verifiableClaim = VerifiableClaim.fromReadable(map["verifiableClaim"]),
        this.metaData = map["metaData"];

  Map toReadable() {
    return {
      "verifiableClaim": verifiableClaim.toReadable(),
      "metaData": metaData,
    }..removeWhere((key, value) => value == null);
  }
}

class VerifiableClaim {
  final String? id;
  final String? ownerPubKey;
  String? issuer;
  String? signature;
  final String? claim;

  VerifiableClaim(this.id, this.ownerPubKey, this.claim, {this.issuer, this.signature});

  VerifiableClaim.fromReadable(Map map)
      : this.id = map["id"],
        this.ownerPubKey = map["ownerPubKey"],
        this.claim = map["claim"],
        this.issuer = map["issuer"],
        this.signature = map["signature"];

  Map toReadable() {
    return {
      "id": id,
      "ownerPubKey": ownerPubKey,
      "issuer": issuer,
      "signature": signature,
      "claim": claim,
    }..removeWhere((key, value) => value == null);
  }

  VerifyResult verifySignature(String? publicKey) {
    if (publicKey == null) {
      return VerifyResult(false);
    }
    final pubK = RSAKeyParser().parse("-----BEGIN PUBLIC KEY-----\r" + publicKey + "\r-----END PUBLIC KEY-----");
    final signer = Signer(RSASigner(RSASignDigest.SHA256, publicKey: pubK as RSAPublicKey?));
    signer.verify64(claim!, signature!);
    // final encrypter = Encrypter(RSAReversed(
    //   publicKey: pubK,
    // ));
    // encrypter.
    // final encrypted = Encrypted.fromBase64(encryptedText);
    // final decrypted = encrypter.decrypt(encrypted);
    return VerifyResult(true);
  }
}
