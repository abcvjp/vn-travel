import 'package:location/location.dart' as LocationPlugin;
import 'package:flutter/material.dart';
import 'package:wemapgl/wemapgl.dart';
import 'ePage.dart';

import 'model/place.dart';
import 'api/place.dart';
import 'api/api_exception_mapper.dart';

import 'package:location/location.dart';

class DiscoveryPage extends ePage {
  DiscoveryPage() : super(const Icon(Icons.map), 'Discovery Map');

  @override
  Widget build(BuildContext context) {
    return const Discovery();
  }
}

class Discovery extends StatefulWidget {
  const Discovery();

  @override
  State createState() => DiscoveryState();
}

class DiscoveryState extends State<Discovery> {
  final _placeRepository = PlaceRepository(); // repo to fetch data
  final location = LocationPlugin.Location(); // location package instance

  WeMapController mapController;
  WeMapPlace curPlace;
  LocationData deviceLocation;

  // map config
  final int searchType = 1; //Type of search bar
  final LatLng _myLatLng = LatLng(21.038282, 105.782885);
  bool _myLocationEnabled = false;

  // symbols
  Symbol _focusPlaceSymbol;
  final String _placeIcon = "assets/symbols/place.png";
  final String _placeHolderIcon = "assets/symbols/placeholder.png";

  // suggest places data
  List<WeMapPlace> suggestedPlaces;
  Future<List<Place>> _futureSuggestedPlaces;

  // ui
  bool _isShowPlaceCard = false;

  Future<bool> _requestAcceptLocation() async {
    var hasPermissions = await location.hasPermission();
    if (hasPermissions == LocationPlugin.PermissionStatus.GRANTED) {
      return true;
    } else {
      await location.requestPermission();
      hasPermissions = await location.hasPermission();
      if (hasPermissions == LocationPlugin.PermissionStatus.GRANTED) {
        return true;
      } else {
        return false;
      }
    }
  }

  void _onMapCreated(WeMapController controller) {
    mapController = controller;
    mapController.onSymbolTapped.add(_onSymbolTapped);
  }

  void _onSymbolTapped(Symbol symbol) {
    print('on symbol tapped');
    final place = symbol.data['place'];
    if (place != null) {
      _focusPlace(place);
    }
  }

  void _onMapClick(point, latlng, place) {
    print('on map click');
    _focusPlace(place);
  }

  void _onSearchSelected(place) {
    print('on search selected');
    mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: place.location,
          zoom: 15.0,
        ),
      ),
    );
    _focusPlace(place);
  }

  void _focusPlace(WeMapPlace place) {
    if (curPlace == null && _focusPlaceSymbol == null) {
      _addSymbol(place.location, 'tappedMapSymbol').then((symbol) {
        _focusPlaceSymbol = symbol;
      });
      setState(() {
        curPlace = place;
        _isShowPlaceCard = true;
      });
    } else if (curPlace != null && _focusPlaceSymbol != null) {
      mapController.updateSymbol(
        _focusPlaceSymbol,
        SymbolOptions(geometry: place.location),
      );
      setState(() {
        curPlace = place;
        _isShowPlaceCard = true;
      });
    } else {
      print('error focus place');
    }
  }

  void _unfocusPlace() {
    if (_focusPlaceSymbol != null) {
      mapController.removeSymbol(_focusPlaceSymbol);
    }
    setState(() {
      curPlace = null;
      _focusPlaceSymbol = null;
      _isShowPlaceCard = false;
    });
  }

  Future<Symbol> _addSymbol(LatLng location,
      [String type = 'place', Place place]) {
    Map data = {"type": type, "place": place};
    var icon;
    switch (type) {
      case 'place':
        icon = _placeIcon;
        break;
      default:
        icon = _placeHolderIcon;
    }
    return mapController.addSymbol(
      SymbolOptions(
        geometry: location,
        iconImage: icon,
      ),
      data,
    );
  }

  void initState() {
    super.initState();
    _requestAcceptLocation().then((permissionGranted) {
      if (permissionGranted) {
        setState(() {
          _myLocationEnabled = true;
        });
        _futureSuggestedPlaces = _placeRepository.getSuggestedPlaces();
      }
    });
  }

  void dispose() {
    mapController?.onSymbolTapped?.remove(_onSymbolTapped);
    mapController.removeSymbols(mapController.symbols);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Stack(
        children: <Widget>[
          WeMap(
            myLocationEnabled: _myLocationEnabled,
            myLocationRenderMode: MyLocationRenderMode.NORMAL,
            myLocationTrackingMode: MyLocationTrackingMode.Tracking,
            onMapClick: _onMapClick,
            onStyleLoadedCallback: () {
              // add suggested places symbol
              _addSymbol(LatLng(21.038282, 105.782885), 'place');
              _addSymbol(LatLng(21.036043, 105.782288), 'place');
            },
            reverse: false,
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _myLatLng,
              zoom: 15.0,
            ),
            destinationIcon: "assets/symbols/destination.png",
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: WeMapSearchBar(
                      location: (deviceLocation != null)
                          ? (LatLng(deviceLocation.latitude,
                              deviceLocation.longitude))
                          : _myLatLng,
                      searchValue:
                          (curPlace != null) ? curPlace.placeName : null,
                      showYourLocation: false,
                      hintText: 'Tìm trên map',
                      onSelected: _onSearchSelected,
                      onClearInput: _unfocusPlace,
                    ),
                  ),
                ],
              ),
              Spacer(),
              (_isShowPlaceCard && curPlace != null)
                  ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: Icon(Icons.place_outlined, size: 30.0),
                              title: Text(curPlace.placeName),
                              subtitle: Text(curPlace.description),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                TextButton(
                                  child: const Text('THÊM ĐỊA ĐIỂM'),
                                  onPressed: () {/* ... */},
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  child: const Text('DẪN ĐƯỜNG'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => WeMapDirection(
                                                originIcon:
                                                    "assets/symbols/origin.png",
                                                destinationIcon:
                                                    "assets/symbols/destination.png",
                                                destinationPlace: curPlace,
                                              )),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        ),
                      ))
                  : (_myLocationEnabled
                      ? FutureBuilder<List<Place>>(
                          future: _futureSuggestedPlaces,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.none ||
                                snapshot.connectionState ==
                                    ConnectionState.waiting) {
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: Text('đang tìm kiếm địa điểm...'),
                              );
                            } else if (snapshot.hasError) {
                              return Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Text(ApiExceptionMapper.toErrorMessage(
                                      snapshot.error)));
                            } else {
                              // process data
                              final places = snapshot.data;
                              suggestedPlaces =
                                  places.map((i) => i.toWeMapPlace()).toList();

                              return DraggableScrollableSheet(
                                initialChildSize: 0.08,
                                minChildSize: 0.05,
                                maxChildSize: 0.5,
                                builder:
                                    (BuildContext context, myscrollController) {
                                  return Container(
                                    margin: EdgeInsets.only(
                                        left: 10.0, right: 10.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(15.0),
                                          topRight: Radius.circular(15.0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 1,
                                          // offset: Offset(0, 1),
                                        )
                                      ],
                                    ),
                                    child: MediaQuery.removePadding(
                                      context: context,
                                      removeTop: true,
                                      child: ListView.builder(
                                        itemCount: 10,
                                        controller: myscrollController,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          if (index == 0) {
                                            return Column(children: [
                                              Center(
                                                  child: Icon(Icons
                                                      .drag_handle_rounded)),
                                              Text(
                                                  'Thấy ... địa điểm gần bạn!'),
                                            ]);
                                          }
                                          index -= 1;
                                          return ListTile(
                                            title: Text('item'),
                                            trailing: Icon(Icons
                                                .arrow_forward_ios_rounded),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        )
                      : Align(
                          alignment: Alignment.bottomCenter,
                          child: Text("Vị trí của bạn đang tắt!"),
                        ))
            ],
          ),
        ],
      ),
    );
  }
}
