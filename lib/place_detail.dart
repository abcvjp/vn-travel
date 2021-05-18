import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:wemapgl/wemapgl.dart';
import './model/place.dart';
import './api/place.dart';
import './api/api_exception_mapper.dart';

class PlaceDetail extends StatefulWidget {
  @override
  _PlaceDetailState createState() => _PlaceDetailState();
}

class _PlaceDetailState extends State<PlaceDetail> {
  final _placeRepository = PlaceRepository();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Place>(
        future: _placeRepository.getPlace(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.none ||
              snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text(ApiExceptionMapper.toErrorMessage(snapshot.error));
          } else {
            final place = snapshot.data;
            return Text('${place.address}');
          }
        });
  }
}
