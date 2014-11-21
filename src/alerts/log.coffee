Alert = require './alert'

module.exports = class LogAlert extends Alert
  sendEvent: (event) ->
    console.log "[event]: #{JSON.stringify event}"

  sendMetricsEvent: (event) ->
    console.log "[metrics event]: #{JSON.stringify event}"
