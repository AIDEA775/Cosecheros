import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cosecheros/login/current_user.dart';
import 'package:cosecheros/models/cosecha.dart';
import 'package:cosecheros/shared/constants.dart';
import 'package:cosecheros/shared/helpers.dart';
import 'package:cosecheros/shared/marker_icon_generator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'cosecha_preview.dart';

class HomeMap extends StatefulWidget {
  @override
  HomeMapState createState() => HomeMapState();
}

class HomeMapState extends State<HomeMap> with AutomaticKeepAliveClientMixin {
  Completer<GoogleMapController> _controller = Completer();
  String _mapStyle;
  BitmapDescriptor _markerIcon;

  PersistentBottomSheetController _bottomSheetController;

  static CameraPosition initPos =
      CameraPosition(target: LatLng(-31.416998, -64.183657), zoom: 10);

  void initMarkerIcon() async {
    _markerIcon = await MarkerGenerator(96.0).bitmapDescriptorFrom(
        Icons.place, Colors.black, Colors.transparent, Colors.transparent);
  }

  @override
  void initState() {
    super.initState();
    initPosition();
    // initMarkerIcon();

    rootBundle.loadString('assets/app/map_style.json').then((string) {
      _mapStyle = string;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _createMarkerImageFromAsset(context);
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(Constants.collection)
              .where("timestamp",
                  isGreaterThan: DateTime.now().subtract(Duration(days: 30)))
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            Set<Marker> _markers = Set();

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState != ConnectionState.waiting) {
              _markers.addAll(
                snapshot.data.docs
                    .map((doc) => Cosecha.fromSnapshot(doc))
                    .where((element) => element.latLng != null)
                    .map((e) => _createMarker(e)),
              );
            }
            return GoogleMap(
              mapType: MapType.normal,
              markers: _markers,
              compassEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              initialCameraPosition: initPos,
              onMapCreated: (GoogleMapController controller) {
                print("onMapCreated");
                _controller.complete(controller);
                controller.setMapStyle(_mapStyle);
              },
              onTap: (e) {
                hideBottomSheet();
                print(e);
              },
            );
          },
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: getLogo(context),
            ),
          ),
        ),
        SafeArea(
          child: Align(alignment: Alignment.topRight, child: topButtons()),
        )
      ],
    );
  }

  Widget getLogo(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Stroked text as border.
        Text(
          'Cosecheros',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = Color(0xFFF5F5F5),
          ),
        ),
        // Solid text as fill.
        Text(
          'Cosecheros',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ],
    );
  }

  Widget topButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.gps_fixed,
              color: Theme.of(context).accentColor,
            ),
            onPressed: () {
              updateByCurrentPos();
            },
          ),
          SizedBox(width: 4),
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.face_rounded,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onPressed: () {
              showProfile();
            },
          ),
        ],
      ),
    );
  }

  showProfile() async {
    String name = CurrentUser.instance.data.name?.trim() ?? "";
    String photoURL = CurrentUser.instance.data.photo;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  foregroundImage:
                      photoURL == null ? null : NetworkImage(photoURL),
                  child: Text(name.isEmpty ? 'A' : getInitials(name)),
                ),
                SizedBox(height: 16),
                Text(
                  name.isEmpty ? "Anónimo" : name,
                  style: Theme.of(context).textTheme.headline6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  "Cosechero aprendiz",
                  style: Theme.of(context).textTheme.caption,
                ),
                SizedBox(height: 16),
                TextButton(
                  child: Text(
                    "cerrar sesión".toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .button
                        .copyWith(color: Colors.red[600]),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }

  String getInitials(String input) =>
      input.split(' ').map((e) => e[0]).take(2).join();

  void updateByCurrentPos() async {
    final pos = await getCurrentPosition();
    if (pos != null) {
      print("updateByCurrentPos: $pos: wait for map controller");
      final GoogleMapController controller = await _controller.future;
      print("updateByCurrentPos: $pos: controller ready, animating...");
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: pos, zoom: 12.0),
      ));
    }
  }

  void initPosition() async {
    var pos = await getLastPosition();
    if (pos != null) {
      print("initPosition: $pos");
      // Intentamos ganarle al mapa y reescribir la posición inicial
      initPos = CameraPosition(target: pos, zoom: 10);
      print("initPosition: $pos: wait for map controller");
      final GoogleMapController controller = await _controller.future;
      print("initPosition: $pos: controller ready, move!");
      controller.moveCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: pos, zoom: 10.0),
      ));
    }
    updateByCurrentPos();
  }

  Future<void> _createMarkerImageFromAsset(BuildContext context) async {
    if (_markerIcon == null) {
      final ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size.square(48));
      final bitmap = await BitmapDescriptor.fromAssetImage(
          imageConfiguration, 'assets/app/plant_1.png');
      setState(() {
        _markerIcon = bitmap;
      });
    }
  }

  Marker _createMarker(Cosecha model) {
    if (_markerIcon != null) {
      return Marker(
        markerId: MarkerId(model.id),
        position: model.latLng,
        icon: _markerIcon,
        onTap: () {
          hideBottomSheet();
          _bottomSheetController = showBottomSheet(
            context: context,
            builder: (context) => ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: double.infinity),
              child: Card(
                margin: EdgeInsets.only(top: 36),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.0)),
                ),
                child: CosechaPreview(model),
              ),
            ),
          );
        },
      );
    } else {
      return Marker(
        markerId: MarkerId(model.id),
        position: model.latLng,
      );
    }
  }

  void hideBottomSheet() {
    if (_bottomSheetController != null) {
      Navigator.of(context).pop();
      _bottomSheetController = null;
    }
  }
}
