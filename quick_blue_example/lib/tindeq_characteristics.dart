// Progressor Primary Service
const service_uuid = "7e4e1701-1ea6-40c9-9dcc-13d34ffead57";

// Progressor Control Point Characteristic - Properties: Write
// Used to send commmands to the Progressor.
// Commands are encoded as a Tag Length Value byte sequence
// Tag(1), Length(1), Value(n)
const write_uuid = "7e4e1703-1ea6-40c9-9dcc-13d34ffead57";

// Progressor Data Point Characteristic - Properties: Notify
// Used to receive data from the Progressor.
// Data is encoded that same as the Control Point
// Notifications must be enable to receive data.
const notify_uuid = "7e4e1702-1ea6-40c9-9dcc-13d34ffead57";

// Progressor commands
enum Commands {
  none('none', 0x00),
  tareScale('Tare Scale', 0x64),
  startWeightMeas('Start Weight Measurement', 0x65),
  stopWeightMeas('Stop Weight Measurement', 0x66),
  startPeakRfdMeas('Start Peak RFD Measurement', 0x67),
  startPeakRfdMeasSeries('Start Peak RFD Measurement Series', 0x68),
  addCalibPoint('Add Calibration Point', 0x69),
  saveCalib('Save Calibration', 0x6a),
  getAppVersion('Get App Version', 0x6b),
  getErrInfo('Get Error info', 0x6c),
  clrErrInfo('Clear Error info', 0x6d),
  shutdown('Shutdown', 0x6e),
  getBatteryVoltage('Get Battery Voltage', 0x6F);

  const Commands(this.label, this.code);
  final String label;
  final int code;
}

// Progressor response codes
enum ResponseCodes {
  cmd('Command', 0),
  weightMeasure('Weight Measure', 1),
  rfdPeak('RFD Peak', 2),
  rfdPeakSeries('RFD PeakSeries', 3),
  lowPowerWarning('Low Power Warning', 4);

  const ResponseCodes(this.label, this.code);
  final String label;
  final int code;

  static ResponseCodes? getByCode(int code) {
    for (ResponseCodes responseCode in ResponseCodes.values) {
      if (responseCode.code == code) {
        return responseCode;
      }
    }
    return null;
  }
}
