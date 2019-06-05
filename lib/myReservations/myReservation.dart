import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lynight/widgets/slider.dart';
import 'package:lynight/myReservations/reservation.dart';
import 'package:lynight/nightCubPage/nightClubProfile.dart';
import 'package:lynight/myReservations/detailReservation.dart';
import 'package:lynight/authentification/auth.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:lynight/services/crud.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lynight/profilUtilisateur/selectProfilPicture.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ListPage extends StatefulWidget {
  ListPage({this.onSignOut});

//  final BaseAuth auth;
  final VoidCallback onSignOut;

  BaseAuth auth = new Auth();

  void _signOut() async {
    try {
      await auth.signOut();
      onSignOut();
    } catch (e) {
      print(e);
    }
  }

  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  String userId = 'userId';
  String userMail = 'userMail';
  CrudMethods crudObj = new CrudMethods();

  @override
  void initState() {
    super.initState();
    widget.auth.currentUser().then((id) {
      setState(() {
        userId = id;
      });
    });
    widget.auth.userEmail().then((mail) {
      setState(() {
        userMail = mail;
      });
    });
  }

  Widget _makeCard(oneReservationMap) {
    return Card(
      color: Colors.transparent,
      elevation: 15.0,
      margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: [Colors.blue, Colors.deepPurpleAccent, Colors.purple]),
          //color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.all(
            Radius.circular(25),
          ),
        ),
        child: _makeListTile(oneReservationMap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          Firestore.instance.collection('user').document(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        var userData = snapshot.data;
        List<dynamic> userReservationList = userData['reservation'];
        return pageConstruct(userReservationList, context);
      },
    );
  }

  Widget _makeListTile(oneReservationMap) {
    Timestamp reservationDate = oneReservationMap['date'];
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Container(
        padding: EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
            border: Border(
          right: BorderSide(width: 1.0, color: Colors.white),
        )),
        child: Icon(Icons.music_note, color: Colors.white),
      ),
      title: Text(
        oneReservationMap['boiteID'],
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.only(top: 5.0),
              child: Icon(Icons.date_range, color: Colors.white, size: 20.0),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(top: 5.0),
              child: Text(
                DateFormat('dd/MM/yyyy').format(reservationDate.toDate()),
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
          )
        ],
      ),
      trailing:
          Icon(Icons.keyboard_arrow_right, color: Colors.purple, size: 25.0),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailPage(reservation: oneReservationMap)),
        );
      },
    );
  }

  Widget _makeBody(userReservationList) {
    var mutableListOfReservation = new List.from(userReservationList);
    final SlidableController slidableController = SlidableController();

    if (userReservationList.isEmpty) {
      return Center(
        child: Text(
          'Aucune réservation',
          style: TextStyle(fontSize: 20.0),
        ),
      );
    }
    return Container(
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: userReservationList.length,
        itemBuilder: (BuildContext context, int index) {
          var date = DateFormat('dd/MM/yyyy').format(userReservationList[index]['date'].toDate());
          return Slidable(
            controller: slidableController,
            key: Key(Random().nextInt(1000).toString() +
                userReservationList[index]['date'].toString()),
            actionPane: SlidableScrollActionPane(),
            actionExtentRatio: 0.25,
            secondaryActions: <Widget>[
              IconSlideAction(
                caption: 'Supprimer',
                color: Colors.red,
                icon: Icons.delete,
                onTap: () {
                  setState(() {
                    mutableListOfReservation.removeAt(index);
                    Firestore.instance
                        .collection('user')
                        .document(userId)
                        .updateData({"reservation": mutableListOfReservation});
                  });
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("${userReservationList[index]['boiteID']} du $date Supprimé"),
                      action: SnackBarAction(
                        label: 'annuler',
                        textColor: Colors.white,
                        onPressed: () {
                          setState(() {
                            mutableListOfReservation.insert(index, userReservationList[index]);
                            Firestore.instance
                                .collection('user')
                                .document(userId)
                                .updateData({"reservation": mutableListOfReservation});
                          });
                        },
                      )));
                },
              ),
            ],
            dismissal: SlidableDismissal(
              child: SlidableDrawerDismissal(),
              onDismissed: (actionType) {
                setState(() {
                  mutableListOfReservation.removeAt(index);
                  Firestore.instance
                      .collection('user')
                      .document(userId)
                      .updateData({"reservation": mutableListOfReservation});
                });
              },
            ),
            child: _makeCard(mutableListOfReservation[index]),
          );
        },
      ),
    );
  }

  Widget pageConstruct(userReservationList, context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Mes reservations'),
      ),
      body: _makeBody(userReservationList),
      drawer: CustomSlider(
        userMail: userMail,
        signOut: widget._signOut,
        activePage: 'Reservations',
      ),
    );
  }
}
