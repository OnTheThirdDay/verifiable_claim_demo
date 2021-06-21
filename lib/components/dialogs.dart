import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum AlertResult {
  confirm,
  cancel,
}

class Dialogs {
  static OverlayEntry? _loadingOverlay;

  static void showLoading(
    BuildContext context, {
    String? content,
    Color barrierColor = Colors.black12,
    bool barrierDismissible = true,
  }) {
    _loadingOverlay = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: barrierDismissible ? hideLoading : null,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            alignment: Alignment.center,
            color: barrierColor,
            child: Container(
              alignment: Alignment.center,
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Platform.isAndroid
                      ? CircularProgressIndicator()
                      : Theme(
                          data: ThemeData.dark(),
                          child: CupertinoActivityIndicator(
                            radius: 15,
                          ),
                        ),
                  if (content != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Material(
                        child: Text(
                          content,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        color: Colors.transparent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context)!.insert(_loadingOverlay!);
  }

  static void hideLoading() {
    if (_loadingOverlay != null) {
      _loadingOverlay?.remove();
      _loadingOverlay = null;
    }
  }

  static void showAlertDialog(
    BuildContext context, {
    String? title,
    Widget? titleWidget,
    String? content,
    Widget? contentWidget,
    String? confirm,
    String? cancel,
    bool hideCancel = false,
    bool hideConfirm = false,
    bool barrierDismissible = false,
    void Function(AlertResult result)? onDismiss,
  }) async {
    if (Platform.isAndroid) {
      showDialog<void>(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (BuildContext context) {
            return AlertDialog(
              title: titleWidget ??
                  (title == null
                      ? null
                      : Text(
                          title,
                        )),
              content: contentWidget ??
                  (content == null
                      ? null
                      : Text(
                          content,
                        )),
              actions: <Widget>[
                TextButton(
                  child: Text(confirm ?? "confirm"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onDismiss != null) onDismiss(AlertResult.confirm);
                  },
                ),
                if (!hideCancel)
                  TextButton(
                    child: Text(cancel ?? "cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onDismiss != null) onDismiss(AlertResult.cancel);
                    },
                  ),
              ],
            );
          });
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: titleWidget ??
                (title == null
                    ? null
                    : Text(
                        title,
                      )),
            content: contentWidget ??
                (content == null
                    ? null
                    : Text(
                        content,
                      )),
            actions: <Widget>[
              if (!hideCancel)
                CupertinoDialogAction(
                  child: Text(cancel ?? "cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onDismiss != null) onDismiss(AlertResult.cancel);
                  },
                ),
              CupertinoDialogAction(
                child: Text(confirm ?? "confirm"),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onDismiss != null) onDismiss(AlertResult.confirm);
                },
              ),
            ],
          );
        },
      );
    }
  }
}
