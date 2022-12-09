import 'dart:async';
import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';

import 'package:ssh/ssh.dart';

import 'package:maltaroads/model/sensors.dart';
import 'package:path/path.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:sqflite/sqflite.dart';

class PotholeDatabase {
  static final PotholeDatabase instance = PotholeDatabase._init();

  static Database _database;

  PotholeDatabase._init();

  String dbName = 'pothole.db';
  bool writeToDatabase = true;

  Future<Database> get database async {
    if (_database != null) return _database;

    String deviceId = await PlatformDeviceId.getDeviceId;
    dbName = deviceId + '.db';

    _database = await _initDB(dbName);
    return _database;
  }

  void transferFileFTP() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    FTPConnect ftpConnect = FTPConnect('ftp.drivehq.com',
        user: 'anthony.scerri.20@um.edu.mt', pass: '231273Asd');

    File fileToUpload = File(path);
    await ftpConnect.connect();

    ftpConnect.changeDirectory('Maltaroads');

    bool res =
        await ftpConnect.uploadFileWithRetry(fileToUpload, pRetryCount: 2);

    //rename uploaded file
    DateTime today = new DateTime.now();

    String prefix =
        "${today.year.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}-${today.hour.toString().padLeft(2, '0')}-${today.minute.toString().padLeft(2, '0')}";

    bool err = await ftpConnect.rename(dbName, prefix + '_' + dbName);

    await ftpConnect.disconnect();
    print(res);
  }

  void transferFileSFTP() async {
    writeToDatabase = false;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    var client = new SSHClient(
      host: "192.168.1.230",
      port: 22,
      username: "sftpmr",
      passwordOrKey: "MaltaMalta123",
    );
    await client.connect();
    await client.connectSFTP();

    await client.sftpUpload(
      path: path,
      toPath: "./sftpmr/",
      callback: (progress) {
        print(progress); // read upload progress
      },
    );
    await client.disconnectSFTP();
    writeToDatabase = true;
  }

  Future<Database> _initDB(String filePath) async {
    // /data/user/0/com.example.maltaroads/databases
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    //Delete the DB file - 2 commands
    //final file = File(path);
    //await file.delete();

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final realType = 'REAL';
    final integerType = 'INTEGER';
    final numericType = 'NUMERIC';
    final textType = 'TEXT';
    final boolType = 'BOOL';
    final blobType = 'BLOB';

    await db.execute('''
    CREATE TABLE $tablePotholes (
      ${SensorFields.id} $idType,
      ${SensorFields.ts} $textType,
      ${SensorFields.phoneTS} $textType,
      ${SensorFields.timeDiff} $integerType,
      ${SensorFields.long} $realType,
      ${SensorFields.lat} $realType,      
      ${SensorFields.accX} $realType,
      ${SensorFields.accY} $realType,
      ${SensorFields.accZ} $realType,
      ${SensorFields.userAccX} $realType,
      ${SensorFields.userAccY} $realType,
      ${SensorFields.userAccZ} $realType,
      ${SensorFields.gyroX} $realType,
      ${SensorFields.gyroY} $realType,
      ${SensorFields.gyroZ} $realType,
      ${SensorFields.direction} $realType,
      ${SensorFields.batchNo} $textType,
      ${SensorFields.kalmanLong} $realType,
      ${SensorFields.kalmanLat} $realType,
      ${SensorFields.speed} $realType
    )
    
    ''');
  }

  Future<Sensor> create(Sensor sensor) async {
    if (writeToDatabase) {
      final db = await instance.database;

      final id = await db.insert(tablePotholes, sensor.toJson());
      return null;
    }
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }

  Future<Sensor> readSensor(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      tablePotholes,
      columns: SensorFields.values,
      where: '${SensorFields.id} = ? ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Sensor.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Sensor>> readAllSensorData() async {
    final db = await instance.database;

    final orderBy = '${SensorFields.id} ASC';
    // final result = await db.rawQuery('select * from $tablePotholes ORDER BY $orderBY');

    final result = await db.query(tablePotholes, orderBy: orderBy);

    var jsonData = result.map((json) => Sensor.fromJson(json)).toList();
    return jsonData;
  }

  Future<int> update(Sensor sensor) async {
    final db = await instance.database;

    return db.update(
      tablePotholes,
      sensor.toJson(),
      where: '${SensorFields.id} = ?',
      whereArgs: [sensor.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(tablePotholes,
        where: '${SensorFields.id} = ?', whereArgs: [id]);
  }

  Future<int> deleteAllRecords(int id) async {
    final db = await instance.database;

    return await db.delete(tablePotholes, where: '${SensorFields.id} != 0');
  }
}
