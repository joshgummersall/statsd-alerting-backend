Alert = require './alert'
request = require 'request'

module.exports = class SlackAlert extends Alert
  body: ->
    "Dispatching alert for #{@event.name}! (#{@event.metric})"

  send: ->
    options =
      url: "#{@config.slack.host}/services/hooks/incoming-webhook"
      qs:
        token: @config.slack.token
      json:
        username: @config.slack.username
        channel: @config.slack.channel
        text: @body()

    request.post options, (err, resp) ->
      throw err if err
      resp or= statusCode: 500
      throw new Error "[Slack] Received status code #{resp.statusCode}" \
        unless resp.statusCode < 400
