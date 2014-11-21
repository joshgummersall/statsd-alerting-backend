module.exports = class Alert
  constructor: (@event, @config) ->

  body: ->
    @event

  send: ->
    console.log @body()
