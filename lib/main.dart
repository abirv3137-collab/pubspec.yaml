import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

void main() => runApp(const BusAlertApp());

class BusAlertApp extends StatelessWidget {
  const BusAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AlertScreen(),
    );
  }
}

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  String? selectedStop;
  String seatNumber = "";
  String currentStatus = "লোকেশন ট্র্যাকিং বন্ধ";
  bool isAlertActive = false;

  final Map<String, Map<String, double>> routeStops = {
    "নরসিংদী (Velanagar)": {"lat": 23.9228, "lng": 90.7169},
    "ভৈরব বাজার (Bhairab)": {"lat": 24.0483, "lng": 90.9856},
    "আশুগঞ্জ (Ashuganj)": {"lat": 24.0375, "lng": 91.0118},
    "ব্রাহ্মণবাড়িয়া (Kuti Chumuhani)": {"lat": 23.8347, "lng": 91.1344},
    "ব্রাহ্মণবাড়িয়া টার্মিনাল": {"lat": 23.9642, "lng": 91.1147},
  };

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  void startTracking() async {
    if (selectedStop == null || seatNumber.isEmpty) {
      setState(() { currentStatus = "অনুগ্রহ করে সিট নম্বর এবং স্টপেজ সিলেক্ট করুন!"; });
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() { currentStatus = "GPS পারমিশন দেওয়া হয়নি!"; });
      return;
    }

    setState(() {
      isAlertActive = true;
      currentStatus = "আপনার গন্তব্য ট্র্যাক করা হচ্ছে...";
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50)
    ).listen((Position position) {
      if (!isAlertActive) return;
      
      double targetLat = routeStops[selectedStop]!["lat"]!;
      double targetLng = routeStops[selectedStop]!["lng"]!;

      double distanceInKM = calculateDistance(position.latitude, position.longitude, targetLat, targetLng);

      setState(() {
        currentStatus = "গন্তব্য থেকে দূরত্ব: ${distanceInKM.toStringAsFixed(2)} কি.মি.";
      });

      if (distanceInKM <= 1.0) {
        triggerAlert();
      }
    });
  }

  void triggerAlert() {
    FlutterRingtonePlayer().playAlarm(volume: 1.0, looping: true);
    setState(() { isAlertActive = false; });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("🚨 গন্তব্য চলে এসেছে!"),
          content: Text("সিট নম্বর $seatNumber, আপনার স্টপেজ '$selectedStop' কাছাকাছি। দয়া করে নামার প্রস্তুতি নিন।"),
          actions: [
            TextButton(
              child: const Text("অ্যালার্ম বন্ধ করুন"),
              onPressed: () {
                FlutterRingtonePlayer().stop();
                Navigator.of(context).pop();
                setState(() {
                  currentStatus = "গন্তব্যে পৌঁছে গেছেন। অ্যালার্ম বন্ধ।";
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("বাস যাত্রী এলার্ট অ্যাপ"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "আপনার সিট নম্বর দিন (যেমন: A1, B2)", border: OutlineInputBorder()),
              onChanged: (value) { seatNumber = value; },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              hint: const Text("কোথায় নামবেন সিলেক্ট করুন"),
              items: routeStops.keys.map((String stop) {
                return DropdownMenuItem<String>(value: stop, child: Text(stop));
              }).toList(),
              onChanged: (value) { setState(() { selectedStop = value; }); },
              decoration: const OutlineInputBorder(),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Text(currentStatus, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isAlertActive ? null : startTracking,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)),
              child: const Text("এলার্ট চালু করুন"),
            )
          ],
        ),
      ),
    );
  }
}
