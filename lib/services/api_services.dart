import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String apiKey = dotenv.env['OPENWEATHER_API_KEY']!;
  Future<WeatherModel> fetchWeather(String city) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric",
    );

    try {
      final response = await http.get(url);

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherModel.fromJson(data);
      } else {
        throw Exception("City not found");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }
}
