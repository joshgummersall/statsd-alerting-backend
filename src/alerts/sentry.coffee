Alert = require './alert'
Sentry = require 'raven'

module.exports = class SentryAlert extends Alert
  constructor: (@config) ->
    super
    @sentry = new Sentry.Client @config.dsn

  sendToSentry: (message) ->
    level = @config.level or 'info'
    @sentry.captureMessage message, {level}

  sendEvent: (event) ->
    @sendToSentry @formatEvent event

  sendMetricsEvent: (event) ->
    @sendToSentry @formatMetricsEvent event
