final String tablePotholes = 'potholes';

class SensorFields {
  static final List<String> values = [
    /// Add all fields
    id, ts, phoneTS, timeDiff, long, lat, accX, accY, accZ, userAccX, userAccY,
    userAccZ,
    gyroX, gyroY, gyroZ, direction,
    batchNo, kalmanLong, kalmanLat, speed
  ];

  static final String id = '_id';
  static final String ts = '_ts';
  static final String phoneTS = '_phoneTS';
  static final String timeDiff = '_timeDiff';
  static final String long = '_long';
  static final String lat = '_lat';
  static final String accX = '_ax';
  static final String accY = '_ay';
  static final String accZ = '_az';
  static final String userAccX = '_uax';
  static final String userAccY = '_uay';
  static final String userAccZ = '_uaz';
  static final String gyroX = '_gx';
  static final String gyroY = '_gy';
  static final String gyroZ = '_gz';
  static final String direction = '_direction';
  static final String batchNo = '_batchNo';
  static final String kalmanLong = '_kalmanLong';
  static final String kalmanLat = '_kalmanLat';
  static final String speed = '_speed';
}

class Sensor {
  final int id;
  final String ts;
  final String phoneTS;
  final int timeDiff;
  final double long;
  final double lat;
  final double accX;
  final double accY;
  final double accZ;
  final double userAccX;
  final double userAccY;
  final double userAccZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double direction;
  final String batchNo;
  final double kalmanLong;
  final double kalmanLat;
  final double speed;

  const Sensor({
    this.id,
    this.ts,
    this.phoneTS,
    this.timeDiff,
    this.long,
    this.lat,
    this.accX,
    this.accY,
    this.accZ,
    this.userAccX,
    this.userAccY,
    this.userAccZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
    this.direction,
    this.batchNo,
    this.kalmanLong,
    this.kalmanLat,
    this.speed,
  });

  static Sensor fromJson(Map<String, Object> json) => Sensor(
        id: json[SensorFields.id] as int,
        ts: json[SensorFields.ts] as String,
        phoneTS: json[SensorFields.phoneTS] as String,
        timeDiff: json[SensorFields.timeDiff],
        long: json[SensorFields.long] as double,
        lat: json[SensorFields.lat] as double,
        accX: json[SensorFields.accX] as double,
        accY: json[SensorFields.accY] as double,
        accZ: json[SensorFields.accZ] as double,
        userAccX: json[SensorFields.userAccX] as double,
        userAccY: json[SensorFields.userAccY] as double,
        userAccZ: json[SensorFields.userAccZ] as double,
        gyroX: json[SensorFields.gyroX] as double,
        gyroY: json[SensorFields.gyroY] as double,
        gyroZ: json[SensorFields.gyroZ] as double,
        direction: json[SensorFields.direction] as double,
        batchNo: json[SensorFields.batchNo] as String,
        kalmanLong: json[SensorFields.long] as double,
        kalmanLat: json[SensorFields.lat] as double,
        speed: json[SensorFields.speed] as double,
      );

  Map<String, Object> toJson() => {
        SensorFields.id: id,
        SensorFields.ts: ts,
        SensorFields.phoneTS: phoneTS,
        SensorFields.timeDiff: timeDiff,
        SensorFields.long: long,
        SensorFields.lat: lat,
        SensorFields.accX: accX,
        SensorFields.accY: accY,
        SensorFields.accZ: accZ,
        SensorFields.userAccX: userAccX,
        SensorFields.userAccY: userAccY,
        SensorFields.userAccZ: userAccZ,
        SensorFields.gyroX: gyroX,
        SensorFields.gyroY: gyroY,
        SensorFields.gyroZ: gyroZ,
        SensorFields.direction: direction,
        SensorFields.batchNo: batchNo,
        SensorFields.kalmanLong: kalmanLong,
        SensorFields.kalmanLat: kalmanLat,
        SensorFields.speed: speed,
        //SensorField.isImportant: isIMportant ? 1 : 0, (convert from bool to 1/0)
        //SensorField.Date: date.toIso8601String()
      };
}
