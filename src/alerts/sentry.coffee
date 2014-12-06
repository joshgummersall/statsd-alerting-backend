Alert = require './alert'
Sentry = require 'raven'
_ = require 'underscore'
request = require 'request'

module.exports = class SentryAlert extends Alert
  @defaults =
    level: 'info'

  # The options parameter allows additional data
  # into the log with reserved parameters such as
  #   info: ''
  #   tags: {}
  #   extra: {}
  # https://github.com/getsentry/raven-node for more details
  sendToSentry: (message, options) ->
    sentry = new Sentry.client @config.dsn
    options = _.defaults options, @defaults
    Sentry.captureMessage message, options

  sendEvent: (event, options={}) ->
    @sendToSentry "Event alert for #{event.name}!\n```#{JSON.stringify event}```",
      options

  sendMetricsEvent: (event, options={}) ->
    @sendToSentry "Metrics alert for #{event.name}!\n```#{JSON.stringify event}```",
      options
