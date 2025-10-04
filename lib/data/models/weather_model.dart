class Weather {
  final String condition;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String location;

  Weather({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.location,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      condition: json['weather'][0]['main'].toString().toLowerCase(),
      temperature: json['main']['temp'].toDouble(),
      humidity: json['main']['humidity'].toInt(),
      windSpeed: json['wind']['speed'].toDouble(),
      location: json['name'],
    );
  }
}
