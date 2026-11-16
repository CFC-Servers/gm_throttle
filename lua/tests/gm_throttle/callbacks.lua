return WithThrottlerTests( {
    groupName = "Throttler callbacks",

    cases = {
        {
            name = "Skips the throttle when shouldSkip returns true",
            func = function( state )
                local throttled = Throttler:create( state.func, {
                    shouldSkip = function() return true end
                } )

                throttled( state.context )
                throttled( state.context )

                expect( state.func.callCount ).to.equal( 2 )
                expect( state.context._Throttles ).to.beNil()
            end
        },

        {
            name = "Does not run the function when success returns false",
            func = function( state )
                local throttled = Throttler:create( state.func, {
                    success = function() return false end
                } )

                throttled( state.context )

                expect( state.func.callCount ).to.equal( 0 )
            end
        }
    }
} )
