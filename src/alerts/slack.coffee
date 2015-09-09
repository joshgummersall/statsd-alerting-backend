Alert = require './alert'
request = require 'request'

module.exports = class SlackAlert extends Alert
  sendToSlack: (message) ->
    options =
      url: @config.webhook
      json:
        username: @config.username
        channel: @config.channel
        text: message

    # Make webhook request and throw on any errors
    request.post options, (err, resp) ->
      throw err if err
      resp or= statusCode: 500
      throw new Error "[Slack] Received status code #{resp.statusCode}" \
        unless resp.statusCode < 400

  sendEvent: (event) ->
    @sendToSlack @formatEvent event

  sendMetricsEvent: (event) ->
    @sendToSlack @formatMetricsEvent event
