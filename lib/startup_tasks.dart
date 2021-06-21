import 'package:verifiable_claim_demo/local_models.dart';

import 'local_storage.dart';

class StartupTasks {
  static Future<void> initializeLocalStorage() async {
    await LocalStorage.initialization();
  }

  static Future<void> clearLocalStorage() async {
    await LocalStorage.clear();
  }

  static Future<void> initializeNForumLocalData() async {
    await LocalStorage.initialization();
    KeyPairManager.loadLocalKeyPairs();
  }

  static Future<void> startupAll() async {
    await initializeLocalStorage();
    await initializeNForumLocalData();
  }
}
