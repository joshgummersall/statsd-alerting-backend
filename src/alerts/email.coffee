Alert = require './alert'
NodeMailer = require 'nodemailer'
Xoauth2 = require 'xoauth2'
_ = require 'underscore'

module.exports = class EmailAlert extends Alert
  constructor: (@config) ->
    super

    # Gmail supports XOAUTH2 which is preferable to SMPT based auth. If the
    # config specifies XOAUTH2 let's handle that specially.
    if @config.xoauth2
      xoauth2 = Xoauth2.createXOAuth2Generator @config.xoauth2
      @transport = NodeMailer.createTransport _.extend {}, @config.transport,
        auth: {xoauth2}
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
