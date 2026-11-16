local min = math.min

---@alias ThrottleContext table|Entity

---@class ThrottleAdjustments
---@field id? fun( baseId: string ): string Receives the original id and returns the id to use for this execution
---@field delay? number
---@field budget? number
---@field refillRate? number

---@class ThrottleOptions
---@field id? string Identifier for this throttle (must be unique per context)
---@field context? ThrottleContext|fun( ...: any ): ThrottleContext Where to store the throttle data
---@field delay? number Seconds to wait between executions after the budget is spent
---@field budget? number How many executions are allowed before the delay applies
---@field refillRate? number How much budget to refill per second
---@field success? fun( ...: any ): boolean? Runs before the throttled function. Return false to prevent it
---@field failure? fun( ...: any ): any Runs when the execution is prevented
---@field shouldSkip? fun( ...: any ): boolean? Return true to skip the throttling logic
---@field adjust? fun( ...: any ): ThrottleAdjustments? Overrides the initial settings for this execution

---@class ThrottleStruct : ThrottleOptions
---@field id string
---@field context ThrottleContext|fun( ...: any ): ThrottleContext
---@field delay number
---@field budget number
---@field refillRate number
---@field success fun( ...: any ): boolean?
---@field failure fun( ...: any ): any
---@field shouldSkip fun( ...: any ): boolean?

---@class ThrottleState
---@field budget number
---@field lastUse number

---@class ThrottleRegistration
---@field func function
---@field throttledFunc function
---@field throttleStruct ThrottleStruct

---@class Throttler
---@field throttles table<string, ThrottleRegistration>
---@field throttleCount number
Throttler = Throttler or {}
Throttler.throttles = Throttler.throttles or {}
Throttler.throttleCount = Throttler.throttleCount or 0

---@type ThrottleAdjustments
local NO_ADJUSTMENTS = {}

local function noop()
end

local function getFirstArgument( first )
    return first
end

---@param context ThrottleContext
---@param id string
---@param budget number
---@return ThrottleState
local function getState( context, id, budget )
    local states = context._Throttles

    if not states then
        states = {}
        context._Throttles = states
    end

    local state = states[id]

    if not state then
        state = { budget = budget, lastUse = 0 }
        states[id] = state
    end

    return state
end

---@param func function
---@param success fun( ...: any ): boolean?
---@param ... any
---@return any ...
local function succeed( func, success, ... )
    if success( ... ) == false then return end

    return func( ... )
end

---@return ThrottleStruct
function Throttler:build()
    self.throttleCount = self.throttleCount + 1

    return {
        id = "throttler_limit_" .. self.throttleCount,
        context = getFirstArgument,
        delay = 1,
        budget = 1,
        refillRate = 1,
        success = noop,
        failure = noop,
        shouldSkip = noop
    }
end

---@generic F : function
---@param func F
---@param options? ThrottleOptions
---@return F throttledFunc
function Throttler:create( func, options )
    ---@type ThrottleStruct
    local struct = table.Merge( self:build(), options or {} )

    local baseId = struct.id
    local context = struct.context
    local delay = struct.delay
    local budget = struct.budget
    local refillRate = struct.refillRate
    local success = struct.success
    local failure = struct.failure
    local shouldSkip = struct.shouldSkip
    local adjust = struct.adjust

    local function throttledFunc( ... )
        if shouldSkip( ... ) == true then return succeed( func, success, ... ) end

        local adjustments = adjust and adjust( ... ) or NO_ADJUSTMENTS
        local adjustId = adjustments.id
        local id = adjustId and adjustId( baseId ) or baseId
        local callDelay = adjustments.delay or delay
        local callBudget = adjustments.budget or budget
        local callRefillRate = adjustments.refillRate or refillRate

        local callContext = context
        if type( callContext ) == "function" then callContext = callContext( ... ) end

        local state = getState( callContext, id, callBudget )

        local now = CurTime()
        local sinceLastUse = now - state.lastUse
        local refilledBudget = state.budget + sinceLastUse * callRefillRate
        local newBudget = min( refilledBudget, callBudget )

        if newBudget >= 1 then
            state.budget = newBudget - 1
            state.lastUse = now

            return succeed( func, success, ... )
        end

        if sinceLastUse < callDelay then return failure( ... ) end

        state.budget = newBudget
        state.lastUse = now

        return succeed( func, success, ... )
    end

    Throttler.throttles[baseId] = {
        func = func,
        throttledFunc = throttledFunc,
        throttleStruct = struct
    }

    return throttledFunc
end
