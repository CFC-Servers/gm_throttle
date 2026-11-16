require( "throttler" )

local START_TIME = 100

--- Gives each case a controllable clock (state.now), a stubbed function to throttle (state.func),
--- and an empty context table (state.context)
---@param testGroup table
---@return table
function WithThrottlerTests( testGroup )
    testGroup.beforeEach = function( state )
        state.now = START_TIME
        stub( _G, "CurTime" ).with( function() return state.now end )

        state.func = stub()
        state.context = {}
    end

    return testGroup
end
