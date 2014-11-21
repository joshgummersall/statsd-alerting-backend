Alert = require './alert'
Pagerduty = require 'pagerduty'

module.exports = class PagerdutyAlert extends Alert
  constructor: (@config) ->
    @pager = new Pagerduty serviceKey: @config.key

  sendToPagerduty: (description, event) ->
    @pager.create {description, details: event}

  sendEvent: (event) ->
    @sendToPagerduty 'event alert', event

  sendMetricsEvent: (event) ->
    @sendToPagerduty 'metrics alert', event
