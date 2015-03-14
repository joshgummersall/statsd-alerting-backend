Alert = require './alert'
Sentry = require 'raven'
_ = require 'underscore'
request = require 'request'

module.exports = class SentryAlert extends Alert

  # The options parameter allows additional data
  # into the log with reserved properties such as
  #   info: ''
  #   tags: {}
  #   extra: {}
  # https://github.com/getsentry/raven-node for more details
  sendToSentry: (message, options = {}) ->
    sentry = new Sentry.client @config.dsn
    options.level or= 'info'
    Sentry.captureMessage message, options

  sendEvent: (event, options) ->
    @sendToSentry [
      "Event alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join('\n'), options

  sendMetricsEvent: (event, options) ->
    @sendToSentry [
      "Metrics alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join('\n'), options
