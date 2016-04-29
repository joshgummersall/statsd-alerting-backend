Alert = require './alert'
Hipchat = require 'node-hipchat'

module.exports = class HipChatAlert extends Alert
  constructor: (@config) ->
    super

    @client = new Hipchat @config.key

  sendToHipChat: (message) ->
    @client.postMessage
      room_id: @config.room
      from: @config.from or 'statsd-alerting-backend'
      message: message
      notify: @config.notify
      color: @config.color or 'yellow'
      (err) ->
        throw err if err

  sendEvent: (event) ->
    @sendToHipChat @formatEvent event

  sendMetricsEvent: (event) ->
    @sendToHipChat @formatMetricsEvent event
