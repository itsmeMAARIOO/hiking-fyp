import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart'; // your root App widget

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // (Optional) Test MongoDB connection at startup
  // import MongoDbService if you want to connect immediately
  // await MongoDbService.connect();

  runApp(const MyApp());
}
