Handlebars = require 'handlebars'

module.exports = class Alert
  constructor: (@config) ->
    @template = Handlebars.compile @config.template if @config.template

  renderEvent: (event) ->
    return unless @template

    @template event

  sendEvent: (event) ->
    eventString = @renderEvent event
    console.log eventString or event

  sendMetricsEvent: (event) ->
    eventString = @renderEvent event
    console.log eventString or event
