Alert = require './alert'
Hipchatter = require 'hipchatter'

module.exports = class HipChatAlert extends Alert
  constructor: (@config) ->
    @api = new Hipchatter @config.key
    # Check that the configured room exists, otherwise create it
    @api.get_room @config.room, (err, response) ->
      if err
        # room does not exist, let's create it
        room_data =
          name: @config.room
        @api.create_room room_data, (err, response) ->
          if err
            throw new Error "[Hipchat] Couldn't create room: #{err}"

  sendToHipChat: (message) ->
    # color of the message defaults to yellow if it's falsey in the config
    options =
      message: message
      color: @config.color or 'yellow'
    @api.notify @config.room, options, (err, response) ->
      if err
        throw new Error "[Hipchat] Couldn't send message to room: #{err}"

  sendEvent: (event) ->
    @sendToHipChat [
      "Event alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join '\n'

  sendMetricsEvent: (event) ->
    @sendToHipChat [
      "Metrics alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join '\n'
