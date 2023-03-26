import min from math
import Merge from table
import unpack, isfunction, CurTime from _G

export Throttler = {}

Throttler._noop = ->
Throttler._getself = (e) -> e
Throttler._id = 0
Throttler._getId = =>
    @_id += 1
    "throttler_limit_#{@_id}"

-- Params:
--   id
--     A string identifier for this throttle (must be unique per context)
--
--   context
--     Where to store the throttles (table, entity, etc.)
--       - Accepts a function if you need to figure it out yourself each call
--
--
--   budget
--     How many times it can be called before being delayed
--
--   refillRate
--     How much of budget to refill per second
--
--   success
--     Function run when not throttled
--
--   failure
--     Function run if execution is prevented
--
--   shouldSkip
--     Function to decide if throttling logic should be skipped (return true to skip)
--
--   adjust
--     Function, return a table with any of the following keys: [ "budget", "refillRate", "id"] to override the initial settings for this execution

Throttler.build = () =>
    {
        id: @_getId!
        context: @_getself
        budget: 1
        refillRate: 1
        success: @_noop
        failure: @_noop
        shouldSkip: @_noop
        adjust: nil
    }


Throttler.throttles = {}
Throttler.create = (func, throttleStruct={}) =>
    {
        :id, :context, :budget, :refillRate,
        :success, :failure, :shouldSkip, :adjust
    } = Merge @build!, throttleStruct

    baseId = id

    throttledFunc = (...) ->
        args = {...}

        succeed = ->
            shouldRun = success unpack args
            return if shouldRun == false

            func unpack args

        fail = -> failure unpack args

        return succeed! if shouldSkip(unpack args) == true

        -- Perform adjustments
        -- TODO: Work out how to only do these adjustments when necessary
        if adjust
            adjustments = adjust unpack args
            adjustmentId = rawget(adjustments, "id")
            adjustmentId and= adjustmentId(baseId)

            id = adjustmentId if adjustmentId
            budget = rawget(adjustments, "budget") or budget
            refillRate = rawget(adjustments, "refillRate") or refillRate

        -- If context is a function, call it with the given params, otherwise use it as a table
        context = isfunction(context) and context(unpack args) or context

        throttles = context._Throttles
        if not throttles
            context._Throttles = {}
            throttles = context._Throttles

        throttle = rawget throttles, id
        if not throttle
            newThrottle = {
                budget: budget
                lastUse: 0
            }
            throttle = newThrottle
            rawset throttles, id, newThrottle

        now = CurTime!

        -- Refill the budget
        sinceLastUse = now - throttle.lastUse
        refillAmount = sinceLastUse * refillRate

        currentBudget = rawget throttle, "budget"
        newBudget = currentBudget + refillAmount
        newBudget = min newBudget, budget

        return fail! if newBudget < 1

        rawset throttle, "budget", newBudget - 1
        rawset throttle, "lastUse", now

        return succeed!


    Throttler.throttles[baseId] = { :func, :throttledFunc, :throttleStruct }

    return throttledFunc
