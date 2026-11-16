return WithThrottlerTests( {
    groupName = "Throttler budget",

    cases = {
        {
            name = "Allows a burst up to the budget",
            func = function( state )
                local throttled = Throttler:create( state.func, { budget = 3 } )

                for _ = 1, 4 do
                    throttled( state.context )
                end

                expect( state.func.callCount ).to.equal( 3 )
            end
        },

        {
            name = "Refills the budget at the refill rate",
            func = function( state )
                local throttled = Throttler:create( state.func, { budget = 2, delay = 10 } )

                throttled( state.context )
                throttled( state.context )
                state.now = state.now + 1
                throttled( state.context )
                throttled( state.context )

                expect( state.func.callCount ).to.equal( 3 )
            end
        }
    }
} )
