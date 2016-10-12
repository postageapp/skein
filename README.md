# Skein

A RabbitMQ-based standard and implementation for Ruby that defines how to
dispatch [JSON-RPC](http://json-rpc.org) jobs over AMQP.

## Installation

The default [Bundler](http://bundler.io) configuration should be a good place
to start:

    bundle install


## Configuration

For testing, set up `config/rabbitmq.yml` with configuration parameters that
define how to connect to RabbitMQ.
