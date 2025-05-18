import 'package:flutter/material.dart';

import '../public_voice_call.dart';

Future<void> showCallingSheet(
    {required BuildContext context,
    required String astrologerId,
    required String roomId}) async {
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
              ),
              Text("Public calls",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
              ListTile(
                  contentPadding:
                      EdgeInsets.only(left: 10, right: 0, top: 5, bottom: 5),
                  leading: CircleAvatar(),
                  title: Text(' voice call'),
                  subtitle: Text('@Rs.20/min'),
                  trailing: TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PublicVoiceCallConsumer(
                                      astrologerId: astrologerId,
                                      roomId: roomId,
                                    )));
                      },
                      child: Text("call"))),
              ListTile(
                  contentPadding:
                      EdgeInsets.only(left: 10, right: 0, top: 5, bottom: 5),
                  leading: CircleAvatar(),
                  title: Text(' video call'),
                  subtitle: Text('@Rs.20/min'),
                  trailing: TextButton(onPressed: () {}, child: Text("call"))),
              SizedBox(
                height: 25,
              ),
              Text(
                "Private calls",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 10,
              ),
              ListTile(
                  contentPadding:
                      EdgeInsets.only(left: 10, right: 0, top: 5, bottom: 5),
                  leading: CircleAvatar(),
                  title: Text(' voice call'),
                  subtitle: Text('@Rs.20/min'),
                  trailing: TextButton(onPressed: () {}, child: Text("call"))),
              ListTile(
                  contentPadding:
                      EdgeInsets.only(left: 10, right: 0, top: 5, bottom: 5),
                  leading: CircleAvatar(),
                  title: Text(' video call'),
                  subtitle: Text('@Rs.20/min'),
                  trailing: TextButton(onPressed: () {}, child: Text("call")))
            ],
          ),
        );
      });
}
