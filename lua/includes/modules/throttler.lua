local min
min = math.min
local Merge
Merge = table.Merge
local unpack, isfunction, CurTime
do
  local _obj_0 = _G
  unpack, isfunction, CurTime = _obj_0.unpack, _obj_0.isfunction, _obj_0.CurTime
end
Throttler = { }
Throttler._noop = function() end
Throttler._getself = function(e)
  return e
end
Throttler._id = 0
Throttler._getId = function(self)
  self._id = self._id + 1
  return "throttler_limit_" .. tostring(self._id)
end
Throttler.build = function(self)
  return {
    id = self:_getId(),
    context = self._getself,
    delay = 1,
    budget = 1,
    refillRate = 1,
    success = self._noop,
    failure = self._noop,
    shouldSkip = self._noop,
    adjust = nil
  }
end
Throttler.throttles = { }
Throttler.create = function(self, func, throttleStruct)
  if throttleStruct == nil then
    throttleStruct = { }
  end
  local id, context, delay, budget, refillRate, success, failure, shouldSkip, adjust
  do
    local _obj_0 = Merge(self:build(), throttleStruct)
    id, context, delay, budget, refillRate, success, failure, shouldSkip, adjust = _obj_0.id, _obj_0.context, _obj_0.delay, _obj_0.budget, _obj_0.refillRate, _obj_0.success, _obj_0.failure, _obj_0.shouldSkip, _obj_0.adjust
  end
  local baseId = id
  local throttledFunc
  throttledFunc = function(...)
    local args = {
      ...
    }
    local succeed
    succeed = function()
      local shouldRun = success(unpack(args))
      if shouldRun == false then
        return 
      end
      return func(unpack(args))
    end
    local fail
    fail = function()
      return failure(unpack(args))
    end
    if shouldSkip(unpack(args)) == true then
      return succeed()
    end
    if adjust then
      local adjustments = adjust(unpack(args))
      local adjustmentId = rawget(adjustments, "id")
      adjustmentId = adjustmentId and adjustmentId(baseId)
      if adjustmentId then
        id = adjustmentId
      end
      delay = rawget(adjustments, "delay") or delay
      budget = rawget(adjustments, "budget") or budget
      refillRate = rawget(adjustments, "refillRate") or refillRate
    end
    context = isfunction(context) and context(unpack(args)) or context
    local throttles = context._Throttles
    if not throttles then
      context._Throttles = { }
      throttles = context._Throttles
    end
    local throttle = rawget(throttles, id)
    if not throttle then
      local newThrottle = {
        budget = budget,
        lastUse = 0
      }
      throttle = newThrottle
      rawset(throttles, id, newThrottle)
    end
    local now = CurTime()
    local sinceLastUse = now - throttle.lastUse
    local refillAmount = sinceLastUse * refillRate
    rawset(throttle, "budget", min(rawget(throttle, "budget") + refillAmount, budget))
    local throttleBudget = rawget(throttle, "budget")
    if throttleBudget >= 1 then
      rawset(throttle, "budget", throttleBudget - 1)
      rawset(throttle, "lastUse", now)
      return succeed()
    end
    if sinceLastUse < delay then
      return fail()
    end
    rawset(throttle, "lastUse", now)
    return succeed()
  end
  Throttler.throttles[baseId] = {
    func = func,
    throttledFunc = throttledFunc,
    throttleStruct = throttleStruct
  }
  return throttledFunc
end
