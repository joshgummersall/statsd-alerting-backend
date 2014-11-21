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

TODO: this

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

## Configuration

TODO: this

## Example Configuration

```json
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
