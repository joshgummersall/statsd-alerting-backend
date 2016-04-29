Alert = require './alert'
NodeMailer = require 'nodemailer'
Xoauth2 = require 'xoauth2'
_ = require 'underscore'

module.exports = class EmailAlert extends Alert
  constructor: (@config) ->
    super

    # Support XOAUTH2 configuration via `service` and `xoauth2` keys
    if @config.xoauth2
      @transport = NodeMailer.createTransport
        service: @config.service
        auth:
          xoauth2: Xoauth2.createXOAuth2Generator @config.xoauth2
    else
      @transport = NodeMailer.createTransport @config.transport

  sendEmail: (subject, text) ->
    @transport.sendMail _.extend({}, @config.mailOptions, {subject, text}),
      (err) ->
        throw err if err

  sendEvent: (event) ->
    subject = @config.eventAlertSubject or 'Event Alert'
    @sendEmail subject, @formatEvent event

  sendMetricsEvent: (event) ->
    subject = @config.metricsEventAlert or 'Metrics Event Alert'
    @sendEmail subject, @formatMetricsEvent event
