Alerts = require './alerts'
_ = require 'underscore'
wildcard = require 'wildcard'

class AlertDistributor
  constructor: (@config) ->
    # Register events to dispatch alerts for
    @events = @config.events or []
    @metrics = @config.metrics or []

    # Build dispatchers for events
    @dispatchers = {}
    @dispatchers[type] = new klass @config[type] for type, klass of Alerts

  dispatchEvent: (type, event) ->
    return unless type of @dispatchers
    @dispatchers[type].sendEvent event

  dispatchMetricsEvent: (type, event) ->
    return unless type of @dispatchers
    @dispatchers[type].sendMetricsEvent event

  # Parse out event data from StatsD packet
  parsePacket: (packet) ->
    for event in packet.toString().split('\n') or []
      [name, data] = event.split ':'
      [metric, type] = data.split '|'
      {name, metric, type}

  # Matches using exact event or wildcard matching. I.e., "some.event.here"
  # will match against "some.event.here" or "some.*"
  # Note: `event.name` is what is listed in the configuration file
  matchEvent: (event, name) ->
    return true if event.name is name
    wildcard(event.name, name)?.length > 0

  # On each event forwarded from StatsD try to dispatch
  onPacket: (packet, rinfo) =>
    for {name, metric, type} in @parsePacket packet
      for event in @events when @matchEvent event, name
        @dispatchEvent event.alert, _.extend event, {name, metric, type}

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
    # Helper to extract a metric from StatsD flush
    getMetric = (metrics) ->
      (type, name, key) ->
        return unless metrics?
        keys = _.compact [type, name, key]
        tmp = metrics
        tmp = tmp[key] for key in keys when key of tmp
        tmp

    getCurrentMetric = getMetric metrics
    getLastMetric = getMetric @lastMetrics

    for event in @metrics
      # Extract alert data
      {name, type, key} = event
      {comparison, value} = @getMetricComparison event

      continue unless comparison? and value?

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
      @dispatchMetricsEvent event.alert, event \
        if @doComparison comparison, value, metric

    # Store metrics for delta comparisons
    @lastMetrics = metrics

# Create distributor instance and attach to event emitter
exports.init = (startupTime, config, events) ->
  alerter = new AlertDistributor config.alerts
  events.on 'packet', alerter.onPacket
  events.on 'flush', alerter.onFlush
  true
