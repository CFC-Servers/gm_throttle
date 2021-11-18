import min from math
import Merge from table
import unpack, isentity, istable, CurTime from _G

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
--   delay
--     How long between executions
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
--     Function, return a table with any of the following keys: ["delay", "budget", "refillRate"] to override the initial settings for this execution

Throttler.build = (func=@_noop, struct={}) =>
    Merge {
        id: @_getId!
        context: self
        delay: 1
        budget: 1
        refillRate: 1
        success: func
        failure: @_noop
        shouldSkip: @_noop
        adjust: nil
    }, struct


Throttler.create = (throttleStruct=@build!) =>
    {
        :id, :context, :delay, :budget, :refillRate,
        :success, :failure, :shouldSkip, :adjust
    } = throttleStruct

    (...) ->
        args = {...}
        succeed = -> success unpack args
        fail = -> failure unpack args

        return succeed! if shouldSkip(unpack args) == true

        -- Perform adjustments
        if adjust
            adjustments = adjust unpack args

            delay = adjustments.delay or delay
            budget = adjustments.budget or budget
            refillRate = adjustments.refillRate or refillRate

        -- If context is a table/entity, use it, otherwise call it as a function with the given params
        context = not isfunction(context) and context or context unpack args

        context._Throttles or= {}
        context._Throttles[id] or= {
            budget: budget
            lastUse: 0
        }

        now = CurTime!
        throttle = context._Throttles[id]

        -- Refill the budget
        sinceLastUse = now - group.lastUse
        refillAmount = sinceLastUse * refillRate
        throttle.budget = min throttle.budget + refillAmount, budget

        -- Has budget, can use
        if throttle.budget > 0
            throttle.budget -= 1
            throttle.lastUse = now
            return succeed!

        -- Blocked by delay
        if sinceLastUse < delay
            fail!
            return false

        -- No budget, but has waited long enough since the last use
        throttle.lastUse = now
        return succeed!
