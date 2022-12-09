// code from:   https://github.com/rekab-app/background_locator/issues/74
// leonardoayres commented on Jun 11, 2020

import 'dart:math' as Math;

// Original code by Paul Doust (https://stackoverflow.com/users/2110762/stochastically)
class KalmanLatLong {
  final double _minAccuracy = 1;

  double _qMetresPerSecond;
  double _timeStampMilliseconds;
  double _lat;
  double _lng;
  double
      _variance; // P matrix.  Negative means object uninitialised.  NB: units irrelevant, as long as same units used throughout

  KalmanLatLong(double qMetresPerSecond) {
    this._qMetresPerSecond = qMetresPerSecond;
    this._variance = -1;
  }

  double get timeStamp {
    return this._timeStampMilliseconds;
  }

  double get latitude {
    return this._lat;
  }

  double get longitude {
    return this._lng;
  }

  double get accuracy {
    return Math.sqrt(this._variance);
  }

  void setState(
      double lat, double lng, double accuracy, double timeStampMilliseconds) {
    this._lat = lat;
    this._lng = lng;
    this._variance = accuracy * accuracy;
    this._timeStampMilliseconds = timeStampMilliseconds;
  }

  ///
  /// Kalman filter processing for lattitude and longitude.
  ///
  /// latMeasurement: New measurement of lattidude.
  ///
  /// lngMeasurement: New measurement of longitude.
  ///
  /// accuracy: Measurement of 1 standard deviation error in metres.
  ///
  /// timeStampMilliseconds: Time of measurement.
  ///
  /// returns: new state.
  ///
  void process(double latMeasurement, double lngMeasurement, double accuracy,
      double timeStampMilliseconds) {
    if (accuracy < this._minAccuracy) accuracy = this._minAccuracy;
    if (this._variance < 0) {
      // if variance < 0, object is unitialised, so initialise with current values
      this._timeStampMilliseconds = timeStampMilliseconds;
      this._lat = latMeasurement;
      this._lng = lngMeasurement;
      this._variance = accuracy * accuracy;
    } else {
      // else apply Kalman filter methodology

      double timeIncMilliseconds =
          timeStampMilliseconds - this._timeStampMilliseconds;
      if (timeIncMilliseconds > 0) {
        // time has moved on, so the uncertainty in the current position increases
        this._variance += timeIncMilliseconds *
            this._qMetresPerSecond *
            this._qMetresPerSecond /
            1000;
        this._timeStampMilliseconds = timeStampMilliseconds;
        // TO DO: USE VELOCITY INFORMATION HERE TO GET A BETTER ESTIMATE OF CURRENT POSITION
      }

      // Kalman gain matrix K = Covarariance * Inverse(Covariance + MeasurementVariance)
      // NB: because K is dimensionless, it doesn't matter that variance has different units to lat and lng
      double K = this._variance / (this._variance + accuracy * accuracy);
      // apply K
      this._lat += K * (latMeasurement - this._lat);
      this._lng += K * (lngMeasurement - this._lng);
      // new Covarariance  matrix is (IdentityMatrix - K) * Covarariance
      this._variance = (1 - K) * this._variance;
    }
  }
}
