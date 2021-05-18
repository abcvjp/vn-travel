import "urls.dart";
import "http_client.dart";
import "../model/place.dart";
import "api_exception.dart";

class PlaceRepository {
  final HttpClient _httpClient = HttpClient();

  Future<List<Place>> getSuggestedPlaces() async {
    final List<dynamic> dataListJson = await _httpClient.getRequest(Urls.place);

    if (dataListJson.isEmpty) {
      throw EmptyResultException();
    }

    return dataListJson.map((dataJson) => Place.fromJson(dataJson)).toList();
  }

  Future<Place> getPlace() async {
    final List<dynamic> dataListJson = await _httpClient.getRequest(Urls.place);

    if (dataListJson.isEmpty) {
      throw EmptyResultException();
    }

    return Place.fromJson(dataListJson.first);
  }

  Future<List<Place>> getAllPlaces() async {
    final List<dynamic> dataListJson = await _httpClient.getRequest(Urls.place);

    return dataListJson.map((dataJson) => Place.fromJson(dataJson)).toList();
  }
}
