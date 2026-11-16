return WithThrottlerTests( {
    groupName = "Throttler delay",

    cases = {
        {
            name = "Blocks a call made before the delay has passed",
            func = function( state )
                local failure = stub()
                local throttled = Throttler:create( state.func, { failure = failure } )

                throttled( state.context )
                state.now = state.now + 0.5
                throttled( state.context )

                expect( state.func.callCount ).to.equal( 1 )
                expect( failure.callCount ).to.equal( 1 )
            end
        },

        {
            name = "Allows a call once the delay has passed",
            func = function( state )
                local throttled = Throttler:create( state.func )

                throttled( state.context )
                state.now = state.now + 1
                throttled( state.context )

                expect( state.func.callCount ).to.equal( 2 )
            end
        },

        {
            name = "Blocked calls do not refill the budget early",
            func = function( state )
                local throttled = Throttler:create( state.func )

                throttled( state.context )
                state.now = state.now + 0.5
                throttled( state.context )
                state.now = state.now + 0.1
                throttled( state.context )

                expect( state.func.callCount ).to.equal( 1 )
            end
        }
    }
} )
