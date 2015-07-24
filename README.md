# express-graceful-shutdown-handler

[![NPM Version][npm-image]][npm-url]
[![NPM Downloads][downloads-image]][downloads-url]

Middleware to handle graceful shutdown on any uncaught exception.

After encountering an exception this middleware stops accepting new requests, waits for the user's exception handler and all currently running requests to finish within a certain grace period and exits.

## Installation

```bash
$ npm install express-graceful-shutdown-handler
```

## API

```js
var gracefulShutdown = require('express-graceful-shutdown-handler')

```

**Note** Requiring the module adds a `uncaughtException` listener.


### gracefulShutdown(options)

Creates a graceful shutdown middleware with the given `options`.

**Note** Make sure it's attached as the first middleware.

##### domainEnabled

Create a new domain and bind request and response to it. This enables the library to return 500 error on the request that caused an unhandled exception to happen, instead of severing the connection.

The default value is `true`.

##### domainIdFunc

If `domainEnabled` is set to true, you can look at `process.domain.id` in your `onExceptionFn` to see the unique request id. This function is given `req` and is expected to return this id.

The default behavior is to return an incremented number for each request.

##### onExceptionFn

Sets a function which will be called in the event of an unhandled exception. The function is given `err` as the first argument and `callback` as the second argument.

The default value is a call to `console.error`.

##### shutdownGraceSeconds

Controls the grace period which is given for your exception handler and currently running requests to finish. If they are not completed within this time, process is killed anyway.

The default value is `15`.

##### inShutdownRespondWithStatus

Control the status which is returned for any new request done after the shutdown process is started. Use it in your load balancer (e.g. `nginx`) to redirect the request to another server.

The default value is `503`.

## Example

A simple example using `express-graceful-shutdown-handler` to log the exception asynchronously (for example to Slack), waiting for the logger to complete the request.

```js
var express = require('express')
var gracefulShutdown = require('express-graceful-shutdown-handler')

var app = express()

###
Unhandled exceptions handling w/ graceful shutdown.
###

app.use(gracefulShutdown({
  onExceptionFn: function (err, callback) { logger.error(err, callback); }
}))

app.get('/cause_exc', function (req, res, next) {
  setTimeout(function() {
    throw new Error("Error!");
  }, 1000);
})

app.get('/long_running_request', function (req, res, next) {
  setTimeout(function() {
    res.sendStatus(200);
  }, 10000);
})
```

Use `curl` to fetch the `/long_running_request` route, then immediately after fetch the `/cause_exc` route.

You'll see the exception logged to the console and the first request to finish before server is killed.

Every consecutive request will return with HTTP status code `503`.


## License

[MIT](LICENSE)

[npm-image]: https://img.shields.io/npm/v/express-graceful-shutdown-handler.svg
[npm-url]: https://npmjs.org/package/express-graceful-shutdown-handler
[downloads-image]: https://img.shields.io/npm/dm/express-graceful-shutdown-handler.svg
[downloads-url]: https://npmjs.org/package/express-graceful-shutdown-handler
