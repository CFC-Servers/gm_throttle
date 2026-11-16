return WithThrottlerTests( {
    groupName = "Throttler:create",

    cases = {
        {
            name = "Passes every argument through and returns the result",
            func = function( state )
                local countArguments = function( ... ) return select( "#", ... ) end
                local throttled = Throttler:create( countArguments )

                expect( throttled( state.context, nil, nil ) ).to.equal( 3 )
            end
        }
    }
} )
