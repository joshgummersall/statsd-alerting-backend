Alert = require './alert'

module.exports = class LogAlert extends Alert
  log: (args...) ->
    logFn = if @config.target is 'stdout' then console.log else console.error
    logFn.apply console, args

  sendEvent: (event) ->
    @log @formatEvent event

  sendMetricsEvent: (event) ->
    @log @formatMetricsEvent event
