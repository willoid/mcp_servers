import '../../models/mcp_tool.dart';

class WeatherMCPServer {
  final String name = 'weather_server';

  final List<MCPTool> tools = [
    MCPTool(
      name: 'get_weather',
      description: 'Get the current weather conditions for a city',
      inputSchema: {
        'type': 'object',
        'properties': {
          'city': {'type': 'string', 'description': 'The city name'},
          'units': {
            'type': 'string',
            'description': 'Temperature units (celsius or fahrenheit)',
            'default': 'celsius',
          },
        },
        'required': ['city'],
      },
      serverUrl: 'weather_server',
    ),
  ];

  Future<Map<String, dynamic>> executeTools(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      switch (toolName) {
        case 'get_weather':
          final city = arguments['city'] as String;
          final units = arguments['units'] ?? 'celsius';

          final temp = (15 + (city.hashCode % 20)).toDouble();
          final conditions = ['sunny', 'cloudy', 'rainy', 'snowy'][city.hashCode % 4];

          return {
            'city': city,
            'temperature': units == 'fahrenheit' ? (temp * 9 / 5 + 32).round() : temp.round(),
            'units': units == 'fahrenheit' ? '°F' : '°C',
            'conditions': conditions,
            'humidity': 60 + (city.hashCode % 30),
            'wind_speed': 5 + (city.hashCode % 20),
          };
        default:
          return {'error': 'Unknown tool: $toolName'};
      }
    } catch (e) {
      return {'error': 'error executing tool: $e'};
    }
  }
}
