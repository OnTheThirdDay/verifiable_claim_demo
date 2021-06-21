import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// keyPairs

class LocalStorage {
  static late Box _box;

  static Future<void> initialization() async {
    await Hive.initFlutter();
    _box = await Hive.openBox("verifiable_claim_demo_data_box");
  }

  static Future<void> clear() async {
    await _box.clear();
  }

  static bool contains(dynamic key) {
    return _box.containsKey(key);
  }

  static dynamic extract(dynamic key) {
    return _box.get(key);
  }

  static Future<void> enter(dynamic key, dynamic value) async {
    return await _box.put(key, value);
  }
}
