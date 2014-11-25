AlertDistributor = require './alert_distributor'

# Create distributor instance and attach to event emitter
exports.init = (startupTime, config, events) ->
  alerter = new AlertDistributor config.alerts
  events.on 'packet', alerter.onPacket
  events.on 'flush', alerter.onFlush
  true
