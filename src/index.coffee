Alerts = require './alerts'
_ = require 'underscore'

class AlertDistributor
  constructor: (@config) ->
    @events = @config.events or []
    @metrics = @config.metrics or []
    @alertConfig =
      slack: @config.slack or {}
      email: @config.email or {}
      log: @config.log or {}

  dispatch: (event) ->
    Alerts.build(event, @alertConfig).send()

  parsePacket: (packet) ->
    for event in packet.toString().split('\n') or []
      [name, data] = event.split ':'
      [metric, type] = data.split '|'
      {name, metric, type}

  onPacket: (packet, rinfo) =>
    for {name, metric, type} in @parsePacket packet
      for event in @events when event.name is name
        @dispatch _.extend event, {metric, type}

  # Extract metric comparison type and value from event options
  getMetricComparison: (event) ->
    for key in ['gte', 'lte', 'gt', 'lt', 'delta'] when key of event
      comparison = key
      value = event[key]
      return {comparison, value}

  # Perform comparison. Yeah this is gross.
  doComparison: (comparison, value, metric) ->
    switch comparison
      when 'gte'
        return metric >= value
      when 'gt'
        return metric > value
      when 'lte'
        return metric <= value
      when 'lt'
        return metric < value
      else
        return false

  # Care about: greater than, less than, bigger than certain delta
  onFlush: (timestamp, metrics) =>
    getMetric = (metrics) ->
      (type, name, key) ->
        metrics?[type]?[name]?[key]

    getCurrentMetric = getMetric metrics
    getLastMetric = getMetric @lastMetric

    for event in @metrics
      # Extract alert data
      {name, type, key} = event
      {comparison, value} = @getMetricComparison event

      # Extract metric
      if comparison is 'delta'
        # We compute the absolute value of the delta and use a 'gte' comparison
        currentMetric = getCurrentMetric type, name, key
        lastMetric = getLastMetric type, name, key
        comparison = 'gte'
        metric = if currentMetric and lastMetric \
          then Math.abs currentMetric - lastMetric else 0
      else
        metric = getCurrentMetric type, name, key

      continue unless metric?

      # Tag on metric for alert
      event.metric = metric
      @dispatch event if @doComparison comparison, value, metric

    # Store metrics for delta comparisons
    @lastMetrics = metrics

exports.init = (startupTime, config, events) ->
  alerter = new AlertDistributor config.alerts
  events.on 'packet', alerter.onPacket
  events.on 'flush', alerter.onFlush
  true
