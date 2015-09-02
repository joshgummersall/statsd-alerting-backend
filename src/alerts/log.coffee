Alert = require './alert'

module.exports = class LogAlert extends Alert
  log: (args...) ->
    logFn = if @config.target is 'stdout' then console.log else console.error
    logFn.apply console, args

  sendEvent: (event) ->
    eventString = @renderEvent event
    eventString = "[event]: #{JSON.stringify event}" unless eventString
    @log eventString

  sendMetricsEvent: (event) ->
    eventString = @renderMetricsEvent event
    eventString = "[metrics event]: #{JSON.stringify event}" unless eventString
    @log eventString
