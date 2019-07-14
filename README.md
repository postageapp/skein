# Skein

[Skein](https://en.wikipedia.org/wiki/V_formation) is a RabbitMQ-based method
for handling remote procedure calls (RPC) and pub/sub channels over AMQP using
[JSON-RPC](http://json-rpc.org) payloads.

## Dependencies

This library requires an active AMQP server like [RabbitMQ](http://rabbitmq.com)
and a Ruby driver for AMQP like [Bunny](http://rubybunny.info) or
[March Hare](http://rubymarchhare.info).

Both JRuby and MRI Ruby are supported with the appropriate driver.

## Installation

The default [Bundler](http://bundler.io) configuration should be a good place
to start:

    bundle install

## Configuration

For testing, set up `config/rabbitmq.yml` with configuration parameters that
define how to connect to RabbitMQ.

## Client Modes

### RPC

An RPC client can make blocking or non-blocking calls. By default calls are
blocking, but they can be made non-blocking by adding `!` to the end of the
method name. For example:

    client = Skein::Client.rpc('test_queue')

    client.request!(test: 'data')

    client.close

Note that non-blocking calls are fire-and-forget, there is no way of knowing
if that operation succeeded or failed.

### Worker

The back-end that receives and processes RPC calls is instantiated as
a `Skein::Client::Worker` instance:

    class Responder < Skein::Client::Worker
      def request
        {
          result: true
        }
      end
    end

    Responder.new('test_queue')
