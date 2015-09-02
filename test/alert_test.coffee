Alert = require '../src/alerts/alert'
should = require 'should'

describe 'Alert', ->
  beforeEach ->
    @sampleEvent =
      name: 'some.event'
      metric: 1
      type: 'c'

    @sampleMetricEvent =
      name: 'some.metric.event'

  describe 'renderEvent', ->
    it 'returns undefined with no template', ->
      a = new Alert {}
      should.not.exist a.renderEvent @sampleEvent

    it 'returns the rendered event string with a template', ->
      a = new Alert
        template: '{{name}} event with metric {{metric}}{{type}}'
      a.renderEvent(@sampleEvent).should.eql 'some.event event with metric 1c'

    it 'renders uses a separate metrics template', ->
      a = new Alert
        metricTemplate: '{{name}} metrics event'
      a.renderMetricsEvent(@sampleMetricEvent)
        .should.eql 'some.metric.event metrics event'
