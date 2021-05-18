class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String userName;
  final String password;
  final String address;
  final String role;
  final List<Favourite> favourites;
  final List<Checkin> checkins;

  User(
      {this.id,
      this.firstName,
      this.lastName,
      this.email,
      this.userName,
      this.password,
      this.address,
      this.role,
      this.favourites,
      this.checkins});

  factory User.fromJson(Map<String, dynamic> parsedJson) {
    var favouriteList = parsedJson['favourites'] as List;
    var checkinList = parsedJson['checkins'] as List;

    return new User(
      id: parsedJson['_id'],
      firstName: parsedJson['firstName'],
      lastName: parsedJson['lastName'],
      email: parsedJson['email'],
      userName: parsedJson['userName'],
      password: parsedJson['password'],
      address: parsedJson['address'],
      role: parsedJson['role'],
      favourites: favouriteList.map((i) => Favourite.fromJson(i)).toList(),
      checkins: checkinList.map((i) => Checkin.fromJson(i)).toList(),
    );
  }
}

class Favourite {
  final String placeId;
  final String date;

  Favourite({this.placeId, this.date});

  factory Favourite.fromJson(Map<String, dynamic> parsedJson) {
    return new Favourite(
      placeId: parsedJson['placeId'],
      date: parsedJson['date'],
    );
  }
}

class Checkin {
  final String placeId;
  final String date;

  Checkin({this.placeId, this.date});

  factory Checkin.fromJson(Map<String, dynamic> parsedJson) {
    return new Checkin(
      placeId: parsedJson['placeId'],
      date: parsedJson['date'],
    );
  }
}
