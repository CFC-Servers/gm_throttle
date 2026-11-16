return WithThrottlerTests( {
    groupName = "Throttler adjust",

    cases = {
        {
            name = "Applies adjustments to a single call",
            func = function( state )
                local throttled = Throttler:create( state.func, {
                    budget = 3,
                    refillRate = 0,
                    delay = 10,
                    adjust = function( context )
                        if context.isLimited then return { budget = 1 } end
                    end
                } )

                local limited = { isLimited = true }
                throttled( limited )
                throttled( limited )

                expect( state.func.callCount ).to.equal( 1 )

                for _ = 1, 4 do
                    throttled( state.context )
                end

                expect( state.func.callCount ).to.equal( 4 )
            end
        },

        {
            name = "Tracks each adjusted id separately",
            func = function( state )
                local throttled = Throttler:create( state.func, {
                    adjust = function( _, suffix )
                        return {
                            id = function( baseId ) return baseId .. "_" .. suffix end
                        }
                    end
                } )

                throttled( state.context, "a" )
                throttled( state.context, "b" )
                throttled( state.context, "a" )

                expect( state.func.callCount ).to.equal( 2 )
            end
        }
    }
} )
