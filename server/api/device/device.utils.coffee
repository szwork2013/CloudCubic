require '../../common/init'

fs = require 'fs'
cert = fs.readFileSync __dirname + '/../../cert/LeoPushCert.pem'
key  = fs.readFileSync __dirname + '/../../cert/LeoPushKey.pem'

apn = require 'apn'

options =
  cert: cert
  key: key
  passphrase: 'password'

apnConnection = new apn.Connection(options)

Device = _u.getModel 'device'

class DeviceUtils
  classname: 'DeviceUtils'
  push: (deviceToken, notice) ->
    myDevice = new apn.Device(deviceToken)

    note = @_buildNote notice

    apnConnection.pushNotification note, myDevice

  _buildNote: (notice) ->
    note = new apn.Notification()
    note.alert = Const.Notification[notice.type]
    note.sound = 'ping.aiff'
    note.payload.payload = JSON.stringify notice

    return note

  pushToUser: (userId, notice) ->
    Device.getByUserId userId
    .then (devices) =>
      _.each devices, (device) =>
        @push device.deviceToken, notice
      return

exports.DeviceUtils = DeviceUtils
