Handlebars = require 'handlebars'

module.exports = class Alert
  constructor: (@config) ->
    # Support separate templates for events and metric events
    {template, metricTemplate} = @config
    @template = Handlebars.compile template if template
    @metricTemplate = Handlebars.compile metricTemplate if metricTemplate

  defaultEvent: (event) ->
    eventString = [
      "Event alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join '\n'

  renderEvent: (event) ->
    return unless @template

    @template event

  formatEvent: (event) ->
    @renderEvent(event) or @defaultEvent event

  sendEvent: (event) ->
    console.log @formatEvent event

  defaultMetricsEvent: (event) ->
    eventString = [
      "Metrics alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join '\n'

  renderMetricsEvent: (event) ->
    return unless @metricTemplate

    @metricTemplate event

  formatMetricsEvent: (event) ->
    @renderMetricsEvent(event) or @defaultMetricsEvent event

  sendMetricsEvent: (event) ->
    console.log @formatMetricsEvent event
