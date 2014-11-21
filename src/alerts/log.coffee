Alert = require './alert'

module.exports = class LogAlert extends Alert
  body: ->
    "[#{@event.name}]: Dispatching event!"
