Alert = require './alert'
Hipchatter = require 'hipchatter'

module.exports = class HipChatAlert extends Alert
  constructor: (@config) ->
    super

    @api = new Hipchatter @config.key
    # Check that the configured room exists, otherwise create it
    @api.get_room @config.room, (err, response) =>
      if err
        # room does not exist, let's create it
        room_data =
          name: @config.room
        @api.create_room room_data, (err, response) ->
          throw new Error "[Hipchat] Couldn't create room: #{err}" if err

  sendToHipChat: (message) ->
    # color of the message defaults to yellow if it's falsey in the config
    options = {
      message
      color: @config.color or 'yellow'
    }
    @api.notify @config.room, options, (err) ->
      throw new Error "[Hipchat] Couldn't send message to room: #{err}" if err

  sendEvent: (event) ->
    @sendToHipChat @formatEvent event

  sendMetricsEvent: (event) ->
    @sendToHipChat @formatMetricsEvent event
