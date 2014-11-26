Alerts = require './alerts'
_ = require 'underscore'
wildcard = require 'wildcard'

# Mixin for number-ish testing
_.mixin
  isNumbery: (toTest = '') ->
    not _.isNaN Number toTest

module.exports = class AlertDistributor
  # Comparison functions for metrics events
  @COMPARISONS:
    gte: (a, b) -> a >= b
    gt: (a, b) -> a > b
    lte: (a, b) -> a <= b
    lt: (a, b) -> a < b
    delta: (a, b) -> a >= b

  constructor: (@config = {}) ->
    # Register events to dispatch alerts for
    @events = @config.events or []
    @metrics = @config.metrics or []

    # Build dispatchers for events
    @dispatchers = {}
    @dispatchers[type] = new klass @config[type] for type, klass of Alerts \
      when type of @config

  dispatchEvent: (type, event) ->
    throw new Error 'Undefined events alert type' unless type of @dispatchers
    @dispatchers[type].sendEvent event

  dispatchMetricsEvent: (type, event) ->
    throw new Error 'Undefined metrics alert type' unless type of @dispatchers
    @dispatchers[type].sendMetricsEvent event

  # Parse out event data from StatsD packet
  parsePacket: (packet) ->
    for event in packet.toString().split('\n') or []
      [name, data] = event.split ':'
      [metric, type] = data.split '|'
      metric = Number metric if _.isNumbery metric
      {name, metric, type}

  # Matches using exact event or wildcard matching. I.e., "some.event.here"
  # will match against "some.event.here" or "some.*"
  # Note: `event.name` is what is listed in the configuration file
  wildcardMatch: (a, b) ->
    return true if a.toLowerCase() is b.toLowerCase()
    wildcard(a, b)?.length > 0

  matchEvent: (event, name) ->
    @wildcardMatch event.name, name

  # Note: bound with fat arrow because it is passed as a function to
  # an event emitter binding and we want it bound to the instance
  onPacket: (packet, rinfo) =>
    for {name, metric, type} in @parsePacket packet
      for event in @events when @matchEvent event, name
        {comparison, value} = @getMetricComparison(event) or {}

        # No support for delta comparison on packet events
        if comparison is 'delta'
          throw new Error 'delta comparison not supported for event alerts'

        # If we have a comparison to do, do it and ignore things that
        # we shouldn't alert on
        continue unless @doComparison comparison, metric, value if comparison?

        # Note: the first argument to `extend` helps simulate a deep clone
        @dispatchEvent event.alert, _.extend {}, event, {name, metric, type}

  # Extract metric comparison type and value from event properties defined
  # in configuration file.
  getMetricComparison: (eventConfig) ->
    for key of @constructor.COMPARISONS when key of eventConfig
      comparison = key
      value = eventConfig[key]
      return {comparison, value}

  # Perform comparison using comparison functions defined above
  doComparison: (comparison, eventMetric, alertValue) ->
    compareFn = @constructor.COMPARISONS[comparison.toLowerCase()]
    compareFn?(eventMetric, alertValue) ? false

  # Extracts all metrics properties that match the metrics event
  # definition in the configuration file.
  extractMatchedMetrics: (metricsEvent, metrics) ->
    {type, name, key} = metricsEvent
    subMetrics = metrics?[type]
    return unless subMetrics

    fetchMetricsProperty = (metricsObj, metricsKey) ->
      if metricsKey? and metricsKey of metricsObj
        metricsObj[metricsKey]
      else
        metricsObj

    # Extract matched metrics, careful to wildcard match name
    matchedEventMetrics = []
    if name of subMetrics
      matchedEventMetrics.push
        name: name
        metric: fetchMetricsProperty subMetrics[name], key
    else
      # Grab first event from sub metrics that
      for evtName of subMetrics when @wildcardMatch name, evtName
        matchedEventMetrics.push
          name: evtName
          metric: fetchMetricsProperty subMetrics[evtName], key

    matchedEventMetrics

  # Note: bound with fat arrow because it is passed as a function to
  # an event emitter binding and we want it bound to the instance
  onFlush: (timestamp, metrics) =>
    for event in @metrics
      # Extract alert configuration
      {name, type, key} = event
      {comparison, value} = @getMetricComparison event

      continue unless comparison? and value?

      # Extract metric
      if comparison is 'delta'
        # We compute the absolute value of the delta
        currentMetrics = @extractMatchedMetrics {type, name, key}, metrics
        lastMetrics = @extractMatchedMetrics {type, name, key}, @lastMetrics

        # Index last metrics by name for delta computations
        lastMetricsByName = _.indexBy lastMetrics, 'name'

        # Compute delta metrics and return in proper format
        eventMetrics = for currentMetric in currentMetrics
          lastMetric = lastMetricsByName[currentMetric.name]?.metric
          if lastMetric?
            currentMetric.metric = Math.abs currentMetric.metric - lastMetric
          else
            currentMetric.metric = 0
          currentMetric
      else
        eventMetrics = @extractMatchedMetrics {type, name, key}, metrics

      continue unless eventMetrics?.length

      for metricsEvent in eventMetrics
        # Tag on actual metricsEvent information for alert
        event.name = metricsEvent.name
        event.metric = metricsEvent.metric

        # Compare and dispatch. Note: the first argument to @doComparison is the
        # actual computed metric sent from StatsD, the second is the configured value
        # to alert
        @dispatchMetricsEvent event.alert, event \
          if @doComparison comparison, metricsEvent.metric, value

    # Store metrics for delta comparisons
    @lastMetrics = metrics
