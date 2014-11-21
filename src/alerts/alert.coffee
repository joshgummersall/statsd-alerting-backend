module.exports = class Alert
  constructor: (@config) ->

  sendEvent: (event) ->
    console.log event

  sendMetricsEvent: (event) ->
    console.log event
