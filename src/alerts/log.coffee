Alert = require './alert'

module.exports = class LogAlert extends Alert
  log: (args...) ->
    logFn = if @config.target is 'stdout' then console.log else console.error
    logFn.apply console, args

  sendEvent: (event) ->
    @log "[event]: #{JSON.stringify event}"

  sendMetricsEvent: (event) ->
    @log "[metrics event]: #{JSON.stringify event}"
