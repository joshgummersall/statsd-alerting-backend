Alert = require './alert'
NodeMailer = require 'nodemailer'

module.exports = class EmailAlert extends Alert
  constructor: (@config) ->
    super

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
