import 'package:mongo_dart/mongo_dart.dart';
import '../constants/env.dart';

/// Singleton MongoDB Service
class MongoDbService {
  static Db? _db;

  /// Connect to MongoDB
  static Future<Db> connect() async {
    _db ??= await Db.create(Env.mongoUrl);

    if (!_db!.isConnected) {
      await _db!.open();
      print("✅ MongoDB connected successfully");
    }

    return _db!;
  }

  /// Get a collection by name
  static Future<DbCollection> getCollection(String name) async {
    final db = await connect();
    return db.collection(name);
  }

  /// Close connection (optional, rarely needed in Flutter)
  static Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _db = null;
      print("❌ MongoDB connection closed");
    }
  }
}
