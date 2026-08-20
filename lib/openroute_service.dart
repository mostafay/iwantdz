import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OpenRouteService {
  final String apiKey;
  final String baseUrl = 'https://api.openrouteservice.org';

  OpenRouteService({required this.apiKey});

  Future<List<LatLng>> getDirections(
    double startLon,
    double startLat,
    double endLon,
    double endLat,
  ) async {
    final url = Uri.parse('$baseUrl/v2/directions/driving-car?start=$startLon,$startLat&end=$endLon,$endLat');

    final response = await http.get(
      url,
      headers: {
        'Authorization': apiKey,
        'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['features'] != null && data['features'].isNotEmpty) {
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        
        return coordinates.map((coord) {
          // OpenRouteService returns [longitude, latitude]
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();
      } else {
        throw Exception('No route found in response');
      }
    } else {
      throw Exception('Failed to fetch directions: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<LatLng>> getDirectionsWithWaypoints(
    double startLon,
    double startLat,
    List<List<double>> waypoints,
    double endLon,
    double endLat,
  ) async {
    final waypointsStr = waypoints.map((wp) => '${wp[0]},${wp[1]}').join('|');
    final url = Uri.parse(
      '$baseUrl/v2/directions/driving-car?start=$startLon,$startLat&end=$endLon,$endLat&waypoints=$waypointsStr',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': apiKey,
        'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['features'] != null && data['features'].isNotEmpty) {
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        
        return coordinates.map((coord) {
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();
      } else {
        throw Exception('No route found in response');
      }
    } else {
      throw Exception('Failed to fetch directions: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getRouteInfo(
    double startLon,
    double startLat,
    double endLon,
    double endLat,
  ) async {
    final url = Uri.parse('$baseUrl/v2/directions/driving-car?start=$startLon,$startLat&end=$endLon,$endLat');

    final response = await http.get(
      url,
      headers: {
        'Authorization': apiKey,
        'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['features'] != null && data['features'].isNotEmpty) {
        final properties = data['features'][0]['properties'] as Map<String, dynamic>;
        return {
          'distance': properties['segments'][0]['distance'] as double,
          'duration': properties['segments'][0]['duration'] as double,
        };
      } else {
        throw Exception('No route found in response');
      }
    } else {
      throw Exception('Failed to fetch directions: ${response.statusCode} - ${response.body}');
    }
  }
}
