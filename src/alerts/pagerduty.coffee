Alert = require './alert'
Pagerduty = require 'pagerduty'

module.exports = class PagerdutyAlert extends Alert
  constructor: (@config) ->
    @pager = new Pagerduty serviceKey: @config.key
    super @config

  sendToPagerduty: (description, event) ->
    {name} = event
    @pager.create {description, incidentKey: name, details: event}

  sendEvent: (event) ->
    description = @renderEvent event
    description = 'event alert' unless description
    @sendToPagerduty description, event

  sendMetricsEvent: (event) ->
    description = @renderMetricsEvent event
    description = 'metrics alert' unless description
    @sendToPagerduty description, event
