import 'package:wemapgl/wemapgl.dart';

class Place {
  final String id;
  final String name;
  final String description;
  final String address;

  final String categoryId;
  final String authorId;
  final int likes;
  final List<Comment> comments;
  final Location location;

  Place(
      {this.id,
      this.name,
      this.description,
      this.address,
      this.categoryId,
      this.authorId,
      this.likes,
      this.comments,
      this.location});

  WeMapPlace toWeMapPlace() {
    return WeMapPlace(
      placeName: this.name,
      description: this.address,
      location: LatLng(this.location.lat, this.location.lng),
    );
  }

  factory Place.fromJson(Map<String, dynamic> parsedJson) {
    var commentList = parsedJson['comments'] as List;
    return new Place(
      id: parsedJson['_id'],
      name: parsedJson['name'],
      description: parsedJson['description'],
      address: parsedJson['address'],
      categoryId: parsedJson['categoryId'],
      authorId: parsedJson['authorId'],
      location: Location.fromJson(parsedJson['city']),
      comments: commentList.map((i) => Comment.fromJson(i)).toList(),
    );
  }
}

class Location {
  final double lat;
  final double lng;

  Location({this.lat, this.lng});

  factory Location.fromJson(Map<String, dynamic> parsedJson) {
    return new Location(
      lat: parsedJson['lat'],
      lng: parsedJson['lng'],
    );
  }
}

class Comment {
  final String userName;
  final String message;

  Comment({this.userName, this.message});

  factory Comment.fromJson(Map<String, dynamic> parsedJson) {
    return new Comment(
      userName: parsedJson['userName'],
      message: parsedJson['message'],
    );
  }
}
