import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:location/location.dart';
import 'package:screen/screen.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:maltaroads/model/sensors.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:maltaroads/db/pothole_db.dart';
import 'package:maltaroads/util/kalman_filter.dart';

class SensorsExample extends StatefulWidget {
  @override
  _SensorsExampleState createState() => _SensorsExampleState();
}

//to use
//        Timer.periodic(Duration(milliseconds: 200), (Timer timer) {

class _SensorsExampleState extends State<SensorsExample> {
  List<double> _accelerometerValues;
  List<double> _userAccelerometerValues = [0, 0, 0];
  List<double> _gyroscopeValues = [0, 0, 0];
  List<double> _magnetometerValues;

  List<String> sensorData = [];
  final Location location = Location();
  int variance = 10;
  String _batchNumber = '';

  Timer sensorReadTimer;
  Timer writeDataTimer;

  double _kalmanLatitude;
  double _kalmanLongtitude;

  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  KalmanLatLong filter = KalmanLatLong(2);

  //SQFlite start
  Future addSensorReading() async {
    final sensor = Sensor(
      ts: _gpsTimestamp.toString(),
      phoneTS: _phoneTimestamp.toString(),
      timeDiff: _timeDiff,
      lat: _currentPosition.longitude,
      long: _currentPosition.latitude,
      accX: _accelerometerValues[0],
      accY: _accelerometerValues[1],
      accZ: _accelerometerValues[2],
      userAccX: _userAccelerometerValues[0],
      userAccY: _userAccelerometerValues[1],
      userAccZ: _userAccelerometerValues[2],
      gyroX: _gyroscopeValues[0],
      gyroY: _gyroscopeValues[1],
      gyroZ: _gyroscopeValues[2],
      direction: _direction,
      batchNo: _batchNumber,
      kalmanLat: _kalmanLatitude,
      kalmanLong: _kalmanLongtitude,
      speed: _speed,
    );

    await PotholeDatabase.instance.create(sensor);
    // use the below to read all the data from SQLITE
    //var sensorData = await PotholeDatabase.instance.readAllSensorData();
  }
  //SQFlite end

  LocationData _currentPosition;
  double _direction;
  double _speed;
  double _altitude;
  int _gpsTimestamp;
  int _phoneTimestamp;
  int _timeDiff;

  @override
  void initState() {
    super.initState();
    syncTime();
    changeSettings();
    getRandomBatchNumber(6);
    _getCurrentLocation();
  }

  Future<bool> changeSettings(
      {LocationAccuracy accuracy = LocationAccuracy.high,
      int interval = 1,
      double distanceFilter = 0}) async {
    bool change = await location.changeSettings();
    return change;
  }

  getRandomBatchNumber(int len) {
    var r = Random();
    _batchNumber =
        String.fromCharCodes(List.generate(len, (index) => r.nextInt(33) + 89));
  }

  _getCurrentLocation() {
    Screen.keepOn(true);

    location.onLocationChanged.listen((LocationData currentLocation) async {
      if (mounted) {
        setState(() {
          _currentPosition = currentLocation;
          _speed =
              ((currentLocation.speed.roundToDouble() * 18) / 5); //ms to km/h
          _altitude = currentLocation.altitude.roundToDouble();

          if (_gpsTimestamp != currentLocation.time.toInt()) {
            _gpsTimestamp = currentLocation.time.toInt();
            _timeDiff = GlobalVar.MobileSyncDiff.toInt();
            //     (DateTime.now().millisecondsSinceEpoch.toInt() - _gpsTimestamp);
          }

          //Remove Kalman filter to reduce CPU and increase sampling rate efficiency

          filter.process(
              currentLocation.latitude,
              currentLocation.longitude,
              currentLocation.accuracy,
              double.parse(DateTime.now()
                  .microsecondsSinceEpoch
                  .toString())); //0.02 = 20 milliseconds
          _kalmanLatitude = filter.latitude;
          _kalmanLongtitude = filter.longitude;
          //_kalmanLatitude = 0.01;
          //_kalmanLongtitude = 0.01;
        });
      }
    });

    //Accelerometer events
    _streamSubscriptions
        .add(accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerValues = <double>[event.x, event.y, event.z];
        _phoneTimestamp = DateTime.now().millisecondsSinceEpoch;
      });
    }));

    //UserAccelerometer events

    _streamSubscriptions
        .add(userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        _userAccelerometerValues = <double>[event.x, event.y, event.z];
      });
    }));

    _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
      });
    }));

    //Compass events

    _streamSubscriptions.add(FlutterCompass.events.listen((double direction) {
      setState(() {
        _direction = direction;
      });
    }));
/*
    _streamSubscriptions.add(
      magnetometerEvents.listen(
        (MagnetometerEvent event) {
          setState(() {
            _magnetometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
*/
    // 50 Hz sensorReadTimer = Timer.periodic(Duration(milliseconds: 20), (_) {
    // 40Hz = 25 ms
    sensorReadTimer = Timer.periodic(Duration(milliseconds: 20), (_) {
      addSensorReading();
    });
  }

  @override
  void dispose() {
    for (StreamSubscription<dynamic> sub in _streamSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(1))?.toList();
    final List<String> gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(1))?.toList();
    final List<String> userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        ?.toList();

    return Scaffold(
        appBar: AppBar(
            title: Text('Road Anomaly - IoT Sensor reading '),
            centerTitle: true),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Accelerometer [X,Y,Z] : $accelerometer',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1, fontSize: 15)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('UserAccelerometer  [X,Y,Z] : $userAccelerometer',
                  style: TextStyle(height: 1, fontSize: 15)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Gyroscope  [X,Y,Z] : $gyroscope',
                  style: TextStyle(height: 1, fontSize: 15)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Latitude: $_kalmanLatitude',
                  style: TextStyle(height: 1, fontSize: 15)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Longtitude: $_kalmanLongtitude',
                  style: TextStyle(height: 1, fontSize: 15)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('GPS Timestamp: $_gpsTimestamp',
                  style: TextStyle(height: 1, fontSize: 15)),
            ),
            Padding(
              padding: const EdgeInsets.all(70.0),
              child: Text('Speed: $_speed',
                  style: TextStyle(height: 1, fontSize: 40)),
            ),
            /*
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Alt: $_altitude',
                  style: TextStyle(height: 1, fontSize: 40)),
            ),
            */
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 20)),
              onPressed: () {
                PotholeDatabase.instance.deleteAllRecords(0);
              },
              child: Text('Delete database'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 20)),
              onPressed: () {
                PotholeDatabase.instance.transferFileSFTP();
              },
              child: Text('    Transfer file    '),
            ),
          ],
        ));
  }
}

Future<bool> syncTime() async {
  // return mobile's clock time diff from GPS' atomic clock
  double diff = 0;

  Location location = Location();

  for (int i = 0; i < 10; i++) {
    var loc = await location.getLocation();
    diff = (diff +
        (double.parse(DateTime.now().millisecondsSinceEpoch.toString()) -
            double.parse(loc.time.toString())));
    print(i);
  }
  GlobalVar.MobileSyncDiff = diff / 10;
  return true;
}

class GlobalVar {
  static double MobileSyncDiff = 0;
}

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Code Snippets',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new SensorsExample(),
    );
  }
}
