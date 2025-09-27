import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ===== ENTRY POINT จริง =====
void appMain() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AQI Dark',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C55E),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const AQIPage(),
    );
  }
}

class AQIPage extends StatefulWidget {
  const AQIPage({super.key});
  @override
  State<AQIPage> createState() => _AQIPageState();
}

class _AQIPageState extends State<AQIPage> {
  late Future<AQIData> _future;
  @override
  void initState() {
    super.initState();
    _future = AQIService.fetchHere(); // ใช้ /feed/here
  }

  void _reload() => setState(() => _future = AQIService.fetchHere());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1220), Color(0xFF101826)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: FutureBuilder<AQIData>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error: ${snap.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  );
                }

                final d = snap.data!;
                final cat = _categoryFor(d.aqi);
                final aqiColor = _colorFor(d.aqi);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.city,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (d.updatedAt != null)
                                Text(
                                  '(Updated on ${d.updatedAt})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.25),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${d.aqi}',
                            style: TextStyle(
                              fontSize: 96,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              color: aqiColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Air Quality Index',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: aqiColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(.06),
                        ),
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 3.2,
                        children: [
                          _obsCard(
                            Icons.thermostat,
                            'Temperature',
                            d.temperatureC != null
                                ? '${d.temperatureC!.toStringAsFixed(1)} °C'
                                : '--',
                          ),
                          _obsCard(
                            Icons.water_drop,
                            'Humidity',
                            d.humidity != null
                                ? '${d.humidity!.round()} %'
                                : '--',
                          ),
                          _obsCard(
                            Icons.air,
                            'Wind Speed',
                            d.wind != null
                                ? '${d.wind!.toStringAsFixed(1)} m/s'
                                : '--',
                          ),
                          _obsCard(
                            Icons.speed,
                            'Pressure',
                            d.pressure != null
                                ? '${d.pressure!.round()} hPa'
                                : '--',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),
                    Center(
                      child: FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          shape: const StadiumBorder(),
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _categoryFor(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color _colorFor(int aqi) {
    if (aqi <= 50) return const Color(0xFF86EFAC);
    if (aqi <= 100) return const Color(0xFFFACC15);
    if (aqi <= 150) return const Color(0xFFF59E0B);
    if (aqi <= 200) return const Color(0xFFEF4444);
    if (aqi <= 300) return const Color(0xFFA78BFA);
    return const Color(0xFF9CA3AF);
  }

  Widget _obsCard(IconData icon, String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Service + Model =====
class AQIService {
  static const String _token = '8d2393c2c0fafc1a150a130e80cdb2d5701ae0cc';
  static const String _base = 'https://api.waqi.info/feed';

  static Future<AQIData> fetchHere() async {
    final uri = Uri.parse('$_base/here/?token=$_token');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }
    final map = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (map['status'] != 'ok') {
      throw Exception('API error: ${map['data'] ?? map['status']}');
    }
    return AQIData.fromJson(map['data'] as Map<String, dynamic>);
  }
}

class AQIData {
  final int aqi;
  final String city;
  final double? temperatureC, humidity, wind, pressure;
  final String? updatedAt;

  AQIData({
    required this.aqi,
    required this.city,
    this.temperatureC,
    this.humidity,
    this.wind,
    this.pressure,
    this.updatedAt,
  });

  factory AQIData.fromJson(Map<String, dynamic> j) {
    final iaqi = (j['iaqi'] ?? {}) as Map<String, dynamic>;
    double? _num(dynamic v) => v == null ? null : (v as num).toDouble();
    return AQIData(
      aqi: (j['aqi'] ?? 0) is int ? j['aqi'] as int : (j['aqi'] as num).round(),
      city: (j['city']?['name'] ?? 'Unknown') as String,
      temperatureC: _num(iaqi['t']?['v']),
      humidity: _num(iaqi['h']?['v']),
      wind: _num(iaqi['w']?['v']),
      pressure: _num(iaqi['p']?['v']),
      updatedAt: j['time']?['s'] as String?,
    );
  }
}
