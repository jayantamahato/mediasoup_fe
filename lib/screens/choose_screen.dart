import 'package:flutter/material.dart';
import 'package:frontend/screens/consumer_screen.dart';
import 'package:frontend/screens/producer_screen.dart';
import 'package:frontend/widgets/outline_btn.dart';
import 'package:frontend/widgets/filled_btn.dart';

import 'stream_list_screen.dart';

class ChooseScreen extends StatelessWidget {
  const ChooseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Media-soup Streaming"),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FilledBtn(onClick: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProducerScreen()));
            }),
            SizedBox(
              height: 25,
            ),
            OutlineBtn(onClick: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => StreamListScreen()));
            })
          ],
        ),
      ),
    );
  }
}
