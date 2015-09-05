Alert = require './alert'
Pagerduty = require 'pagerduty'

module.exports = class PagerdutyAlert extends Alert
  constructor: (@config) ->
    super
    @pager = new Pagerduty serviceKey: @config.key

  sendToPagerduty: (description, event) ->
    {name} = event
    @pager.create {description, incidentKey: name, details: event}

  defaultEvent: ->
    'event alert'

  sendEvent: (event) ->
    @sendToPagerduty @formatEvent(event), event

  defaultMetricsEvent: ->
    'metrics alert'

  sendMetricsEvent: (event) ->
    @sendToPagerduty @formatMetricsEvent(event), event
