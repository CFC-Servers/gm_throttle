return WithThrottlerTests( {
    groupName = "Throttler context",

    cases = {
        {
            name = "Tracks each context separately",
            func = function( state )
                local throttled = Throttler:create( state.func )

                throttled( state.context )
                throttled( {} )

                expect( state.func.callCount ).to.equal( 2 )
            end
        },

        {
            name = "Stores the throttle data on the context returned by a context function",
            func = function( state )
                local throttled = Throttler:create( state.func, {
                    context = function( _, context ) return context end
                } )

                throttled( "ignored", state.context )

                expect( state.context._Throttles ).to.exist()
            end
        },

        {
            name = "Uses a table context for every call",
            func = function( state )
                local throttled = Throttler:create( state.func, { context = state.context } )

                throttled( "first caller" )
                throttled( "second caller" )

                expect( state.func.callCount ).to.equal( 1 )
            end
        }
    }
} )
