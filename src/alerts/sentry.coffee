Alert = require './alert'
Sentry = require 'raven'

module.exports = class SentryAlert extends Alert
  constructor: (@config) ->
    super @config
    @sentry = new Sentry.Client @config.dsn

  sendToSentry: (message) ->
    level = @config.level or 'info'
    @sentry.captureMessage message, {level}

  sendEvent: (event) ->
    eventString = @renderEvent event
    eventString = [
      "Event alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join '\n' unless eventString

    @sendToSentry eventString

  sendMetricsEvent: (event) ->
    eventString = @renderMetricsEvent event
    eventString = [
      "Metrics alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join '\n' unless eventString

    @sendToSentry eventString
