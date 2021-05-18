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

class DiscoveryState extends State<Discovery>
    with AutomaticKeepAliveClientMixin<Discovery> {
  @override
  bool get wantKeepAlive => true;

  final _placeRepository = PlaceRepository(); // repo to fetch data
  final location = LocationPlugin.Location(); // location package instance

  WeMapController mapController;
  WeMapPlace curPlace;
  LocationData deviceLocation;

  // map config
  int searchType = 1; //Type of search bar
  String searchPlaceName;
  LatLng _myLatLng = LatLng(21.038282, 105.782885);
  bool _myLocationEnabled = false;

  // symbols
  Symbol _selectedSymbol; // only place symbols
  Symbol _tappedMapSymbol;
  String _placeIcon = "assets/symbols/origin.png";

  // suggest places data
  Future<List<Place>> suggestedPlaces;

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
    if (_tappedMapSymbol != null) {
      // dang nhap vao current tapped map symbol
      if (_tappedMapSymbol == symbol) {
        // nhap lai vao current tapped map symbol
        mapController.removeSymbol(_tappedMapSymbol);
        setState(() {
          curPlace = null;
          _isShowPlaceCard = false;
          _tappedMapSymbol = null;
        });
        return;
      }
      // đang nhấp vào current tapped symbol nhưng vừa nhấp vào place symbol
      mapController.removeSymbol(_tappedMapSymbol);
      _tappedMapSymbol = null;
    }
    if (_selectedSymbol != null) {
      _updateSelectedSymbol(
        const SymbolOptions(iconSize: 1.0),
      );
    }
    if (_selectedSymbol != symbol) {
      _selectedSymbol = symbol;
      _updateSelectedSymbol(
        SymbolOptions(
          iconSize: 1.4,
        ),
      );
      setState(() {
        curPlace = symbol.data['place'];
        _isShowPlaceCard = true;
      });
    } else {
      setState(() {
        _selectedSymbol = null;
        _isShowPlaceCard = false;
      });
    }
  }

  void _onUntappedSelectedPlace() {
    _updateSelectedSymbol(SymbolOptions(
      iconSize: 1.0,
    ));
  }

  void _onMapClick(point, latlng, _place) {
    print('on map click');
    curPlace = _place;
    // don't work: mapController.showPlaceCard(_place);

    if (_tappedMapSymbol != null) {
      mapController
          .updateSymbol(
              _tappedMapSymbol,
              SymbolOptions(
                geometry: _place.location,
              ))
          .then((value) {
        setState(() {
          _tappedMapSymbol.data['place'] = _place;
        });
      });
    } else {
      _addSymbol(latlng, 'tappedMapSymbol').then((symbol) {
        _tappedMapSymbol = symbol;
      });
    }
    if (_selectedSymbol != null) {
      _updateSelectedSymbol(
        SymbolOptions(iconSize: 1.0),
      );
      _selectedSymbol = null;
    }
    setState(() {
      curPlace = _place;
      _isShowPlaceCard = true;
    });
  }

  Future<Symbol> _addSymbol(LatLng location,
      [String type = 'place', Place place]) {
    Map data = {"type": type, "place": place};
    var icon;
    switch (type) {
      case 'place':
        icon = "assets/symbols/placeholder.png";
        break;
      default:
        icon = "assets/symbols/origin.png";
    }
    return mapController.addSymbol(
      SymbolOptions(
        geometry: location,
        iconImage: icon,
      ),
      data,
    );
  }

  void _updateSelectedSymbol(SymbolOptions changes) {
    mapController.updateSymbol(_selectedSymbol, changes);
  }

  void initState() {
    super.initState();
    _requestAcceptLocation().then((permissionStatus) {
      if (_myLocationEnabled != permissionStatus) {
        setState(() {
          _myLocationEnabled = permissionStatus;
        });
      }
      if (_myLocationEnabled) {
        location.getLocation().then((location) {
          deviceLocation = location;
          suggestedPlaces = _placeRepository.getSuggestedPlaces();
        });
      }
    });
  }

  void dispose() {
    mapController?.onSymbolTapped?.remove(_onSymbolTapped);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return new Scaffold(
      body: Stack(
        children: <Widget>[
          WeMap(
            myLocationEnabled: false,
            myLocationRenderMode: MyLocationRenderMode.NORMAL,
            myLocationTrackingMode: MyLocationTrackingMode.Tracking,
            onMapClick: _onMapClick,
            onPlaceCardClose: () {
              print("Place Card closed");
            },
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
                      onSelected: (_place) {
                        setState(() {
                          curPlace = _place;
                          _isShowPlaceCard = true;
                        });
                        mapController.moveCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: curPlace.location,
                              zoom: 15.0,
                            ),
                          ),
                        );
                      },
                      onClearInput: () {
                        setState(() {
                          curPlace = null;
                          if (_isShowPlaceCard) {
                            _isShowPlaceCard = false;
                          }
                          // mapController.showPlaceCard(place);
                        });
                      },
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
                                  onPressed: () {/* ... */},
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        ),
                      ))
                  : (_myLocationEnabled
                      ? FutureBuilder<List<Place>>(
                          future: suggestedPlaces,
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
                              // final places = snapshot.data;
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
                                            title: Text('item ${index}'),
                                            trailing: Icon(Icons.add),
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
