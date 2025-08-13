import 'package:flutter/material.dart';

Future showIncomingCall(
    {required BuildContext context,
    required Function callback,
    required String title}) async {
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          child: Column(
            children: [
              Text("$title"),
              SizedBox(
                height: 60,
                width: MediaQuery.of(context).size.width,
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        callback();
                      },
                      child: Text("Accept"),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      });
}
