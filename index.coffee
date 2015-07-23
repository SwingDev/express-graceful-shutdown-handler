_          = require 'lodash'
onFinished = require 'on-finished'

class ExpressGracefulShutdown
  constructor: (options) ->
    # Parse options
    @onExceptionFn               = options.onExceptionFn
    @shutdownGraceSeconds        = options.shutdownGraceSeconds
    @inShutdownRespondWithStatus = options.inShutdownRespondWithStatus

    # Initialize vars
    @gracefulShutdownMode   = false
    @pendingRequestsCount   = 0
    @pendingExceptionsCount = 0

    # Setup
    process.on 'uncaughtException', @exceptionHandler

  # Middleware
  middleware: () =>
    (req, res, next) =>
      @pendingRequestsCount += 1
      onFinished res, @requestFinishHandler

      if @gracefulShutdownMode
        return res.sendStatus @inShutdownRespondWithStatus

      next()

  # Event Handlers
  exceptionHandler: (exc) =>
    # Correct for current request, which threw the exception.
    @pendingRequestsCount   -= 1

    # Go into shutdown mode.
    @gracefulShutdownMode = true
    @startHardKillTimer()

    @pendingExceptionsCount += 1
    @onExceptionFn exc, () =>
      @pendingExceptionsCount -= 1
      @applyKillConditions()

  requestFinishHandler: () =>
    @pendingRequestsCount -= 1
    @applyKillConditions()

  # Hard kill timer
  startHardKillTimer: () ->
    return if @hardKillTimer?

    @hardKillTimer = setTimeout () =>
      @killProcess()
    , @shutdownGraceSeconds * 1000

  # Actions
  applyKillConditions: () ->
    console.log "queue <#{@pendingRequestsCount}, #{@pendingExceptionsCount}>"

    return if not @gracefulShutdownMode
    return if @pendingRequestsCount   > 0
    return if @pendingExceptionsCount > 0

    @killProcess()

  killProcess: () ->
    process.exit(1)


module.exports = (options) ->
  defaultOptions = {
    onExceptionFn: (exc, callback) ->
      console.error exc
      callback()
    shutdownGraceSeconds: 15
    inShutdownRespondWithStatus: 503
  }

  new ExpressGracefulShutdown(_.assign(defaultOptions, options)).middleware()
