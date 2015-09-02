Handlebars = require 'handlebars'

module.exports = class Alert
  constructor: (@config) ->
    # Support separate templates for events and metric events
    {template, metricTemplate} = @config
    @template = Handlebars.compile template if template
    @metricTemplate = Handlebars.compile metricTemplate if metricTemplate

  renderEvent: (event) ->
    return unless @template

    @template event

  sendEvent: (event) ->
    eventString = @renderEvent event
    console.log eventString or event

  renderMetricsEvent: (event) ->
    return unless @metricTemplate

    @metricTemplate event

  sendMetricsEvent: (event) ->
    eventString = @renderMetricsEvent event
    console.log eventString or event
