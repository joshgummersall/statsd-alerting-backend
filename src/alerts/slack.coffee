Alert = require './alert'
request = require 'request'

module.exports = class SlackAlert extends Alert
  sendToSlack: (message) ->
    options =
      url: "#{@config.host}/services/hooks/incoming-webhook"
      qs:
        token: @config.token
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
    @sendToSlack [
      "Event alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join '\n'

  sendMetricsEvent: (event) ->
    @sendToSlack [
      "Metrics alert for #{event.name}!"
      "```#{JSON.stringify event}```"
    ].join '\n'
