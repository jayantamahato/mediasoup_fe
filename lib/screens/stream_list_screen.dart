import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/consumer_screen.dart';

class StreamListScreen extends StatefulWidget {
  const StreamListScreen({super.key});

  @override
  State<StreamListScreen> createState() => _StreamListScreenState();
}

class _StreamListScreenState extends State<StreamListScreen> {
  final dio = Dio();
  List lives = [];
  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      try {
        Response response = await dio.get('http://192.168.1.125:3000/live');
        if (response.statusCode == 200) {
          lives.clear();
          response.data.forEach((element) {
            lives.add(element);
          });
        }
        setState(() {});
      } on DioException catch (e) {
        log(e.toString());
      } catch (e) {
        log(e.toString());
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Consumer Screen"),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: ListView.builder(
            itemCount: lives.length,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () {
                  if (lives[index]['status'] == 'inactive') {
                    return;
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ConsumerScreen(
                                astrologerId: lives[index]['astrologerId'],
                                roomId: lives[index]['roomId'],
                              )));
                },
                title: Text(
                  "Host:" + lives[index]['astrologerId'],
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Room:" + lives[index]['roomId']),
                trailing: Chip(
                    avatar: Badge(
                      backgroundColor: lives[index]['status'] == 'active'
                          ? Colors.green
                          : Colors.red,
                    ),
                    label: Text(lives[index]['status'])),
              );
            }),
      ),
    );
  }
}
