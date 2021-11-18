require( "throttler" )

--
-- Throttles e2's holoScale(index, vector) function
-- This allows players to call the function 100 times at an unlimited rate,
-- but once the budget is spent, players will need to wait 0.15s between calls.
--
-- The budget refills at a rate of 2/second.
--
-- E2s spawned by Admins will not be subject to the throttle (shouldSkip).
-- E2s spawned by Users will only have a budget of 50, and a slightly slower refill rate. (adjust).
--
local function throttleHoloScale()
    local signature = "holoScale(nv)"
    local holoScale = wire_expression2_funcs[signature][3]

    local throttle = {
        delay = 0.15,
        budget = 100,
        refillRate = 2,

        failure = function( chip )
            chip.player:ChatPrint( "holoScale was throttled!" )
        end,

        -- This function gets all of the parameters that gets passed to holoScale
        -- In this case, the first parameter is the chip - that's where we want to store the throttle data
        context = function( chip )
            return chip
        end,

        adjust = function( chip )
            if chip.player:GetUserGroup() == "user" then
                return {
                    budget = 50,
                    refillRate = 1.25
                }
            end
        end,

        shouldSkip = function(chip)
            if chip.player:IsAdmin() then
                return true
            end
        end
    }

    wire_expression2_funcs[signature][3] = Throttler.create( holoScale, throttle )
end

