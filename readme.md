statsd-alerting-backend
======================

A backend plugin for [Statsd](https://github.com/etsy/statsd/) to perform some
basic alerting on events.

## Overview

Suppose you wanted to use StatsD as your main event stream aggregator due
to its simple interface and its ease of integration with existing services.
Perfect! Now, what if you want to send out some alerts based on certain events?
Let's do it!

## Configuring Alerts

There are two different types of alerts that are supported. Those are "event" alerts
and "metric" alerts (see example configuration file for both). "Event" alerts are
things that you want to be alerted on immediately. An example of an event you would
likely want to be alerted on immediately is an uncaught exception.

"Metrics" alerts are a bit more complicated. StatsD publishes aggregate metrics at
a configurable rate (default is every ten seconds). Perhaps you wanted to be alerted
when the 90th percentile average time for an event exceeds a certain value. You can
do that (check out the example configuration for how to set that up).

This plugin is very young and I plan to include more sophisticated alerting features
as well as more alert types. Feel free to leave feedback via the issues for things
you would like to see added.

## Installation

In your StatsD installation folder, run:

```bash
$ npm install statsd-alerting-backend
```

Include the backend in your `config.js` file (see example configuration file below
for complete configuration example).

```json
{
  "backends": ["statsd-alerting-backend"]
}
```

## Development

This plugin is written in CoffeeScript that is compiled to Javascript automatically
when publishing to NPM (see `gulpfile.js` and `package.json` for more details). To
work on this plugin, simply clone the repository and run `npm install`. I would suggest
running `gulp watch` in a separate shell to watch the source Coffeescript files for
changes and automatically compile them to Javascript files.

## Configuration

TODO: this

## Example Configuration

```
{
  backends: ["statsd-alerting-backend"],

  alerts: {
    slack: {
      host: "<SLACK_HOST>",
      token: "<SLACK_TOKEN>",
      username: "statsd-alerts",
      channel: "#alerts"
    },

    email: {},

    events: [{
      name: "some.event.name",
      alert: "log"
    }],

    metrics: [{
      name: "some.event.timer.name",
      type: "timer_data",
      key: "mean_90",
      gte: 8297,
      alert: "slack"
    }]
  }
}
```

## Contributing

Feel free to [leave issues here](https://github.com/joshgummersall/statsd-alerting-backend/issues)
or fork the project and submit pull requests. If there is a feature you would like added
just submit an issue describing the feature and I will do my best.
