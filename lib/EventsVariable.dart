import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:connect_plus/Event.dart';

class EventsVariables extends StatefulWidget {
  @override
  _EventsVariablesState createState() => _EventsVariablesState();
}

class _EventsVariablesState extends State<EventsVariables> {
  var ip, port;
  var event_list = [];
  var emptyList = false;
  var mostRecentEvent;
  Uint8List mostRecentEventImg;
  final LocalStorage localStorage = new LocalStorage("Connect+");

  @override
  void initState() {
    super.initState();
    setEnv();
    getEvents();
  }

  setEnv() {
    port = DotEnv().env['PORT'];
    ip = DotEnv().env['SERVER_IP'];
  }

  void getEvents() async {
    String token = localStorage.getItem("token");
    var url = 'http://$ip:$port/event/recent';

    var response = await http.get(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    });

    if (response.statusCode == 200) {
      setState(() {
        event_list = json.decode(response.body);
        if (event_list.isEmpty)
          emptyList = true;
        else
          this.mostRecentEvent = event_list.elementAt(0);
        this.mostRecentEventImg =
            base64Decode(event_list.elementAt(0)['poster']['fileData']);
      });
    }
  }

  Widget mostRecent() {
    var height = MediaQuery.of(context).size.height;

    if (mostRecentEvent == null) return CircularProgressIndicator();
    return SizedBox(
        child: Card(
      child: Hero(
        tag: mostRecentEvent['name'],
        child: Material(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Event(
                          event: mostRecentEvent['name'],
                          erg: mostRecentEvent['ERG']["name"],
                        )),
              );
            },
            child: GridTile(
                footer: Container(
                  color: Colors.white70,
                  child: ListTile(
                    title: Column(children: <Widget>[
                      Text(mostRecentEvent["name"].toString(),
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text("Start Date: "),
                            Text(mostRecentEvent['startDate'].toString().split("T")[0],
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w800)),
                          ])
                    ]),
                  ),
                ),
                child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      image: new DecorationImage(
                          image: MemoryImage(mostRecentEventImg),
                          fit: BoxFit.cover),
                    ))),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final _scrollController = ScrollController();
    var height = MediaQuery.of(context).size.height;
    if (emptyList) return Center(child: Text("No Events"));
    return Column(
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(left: 6, right: 6),
            child: Container(height: height * 0.27, child: mostRecent())),
        Expanded(
            child: Padding(
                padding: EdgeInsets.only(left: 6, right: 6),
                child: Scrollbar(
                    controller: _scrollController,
                    isAlwaysShown: true,
                    child: ListView(
                      controller: _scrollController,
                      physics: ClampingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      children: constructEvents(),
                    )))),
      ],
    );
  }

  List<Widget> constructEvents() {
    List<Widget> list = List<Widget>();
    for (var event in event_list) {
      if(event['name'] != mostRecentEvent['name'])
      list.add(Single_Event(
          event_name: event['name'],
          event_picture: base64Decode(event['poster']['fileData']),
          event_date: event['startDate'].toString().split("T")[0],
          event: event));
    }
    return list;
  }
}

class Single_Event extends StatelessWidget {
  final event_name;
  final event_picture;
  final event_date;
  final event;

  //constructor
  Single_Event({
    this.event_name,
    this.event_picture,
    this.event_date,
    this.event,
  });
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return SizedBox(
        height: height,
        width: width * 0.65,
        child: Card(
          child: Hero(
            tag: event_name,
            child: Material(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Event(
                              event: event_name,
                              erg: event['ERG']["name"],
                            )),
                  );
                },
                child: GridTile(
                    footer: Container(
                      color: Colors.white70,
                      child: ListTile(
                        title: Column(children: <Widget>[
                          Text(event_name,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("Start Date: "),
                                Text(event_date,
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w800)),
                              ])
                        ]),
                      ),
                    ),
                    child: Image.memory(
                      event_picture,
                      fit: BoxFit.cover,
                    )),
              ),
            ),
          ),
        ));
  }
}
