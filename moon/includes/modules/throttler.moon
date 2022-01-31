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
--     Function, return a table with any of the following keys: ["delay", "budget", "refillRate", "id"] to override the initial settings for this execution

Throttler.build = () =>
    {
        id: @_getId!
        context: self
        delay: 1
        budget: 1
        refillRate: 1
        success: @_noop
        failure: @_noop
        shouldSkip: @_noop
        adjust: nil
    }


Throttler.create = (func, throttleStruct=@build!) =>
    {
        :id, :context, :delay, :budget, :refillRate,
        :success, :failure, :shouldSkip, :adjust
    } = Merge @build!, throttleStruct

    baseId = id

    (...) ->
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

            id = adjustments.id and adjustments.id( baseId ) or id
            delay = adjustments.delay or delay
            budget = adjustments.budget or budget
            refillRate = adjustments.refillRate or refillRate

        -- If context is a table/entity, use it, otherwise call it as a function with the given params
        context = isfunction(context) and context(unpack args) or context

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
        if throttle.budget >= 1
            throttle.budget -= 1
            throttle.lastUse = now
            return succeed!

        -- Blocked by delay
        return fail! if sinceLastUse < delay

        -- No budget, but has waited long enough since the last use
        throttle.lastUse = now
        return succeed!
