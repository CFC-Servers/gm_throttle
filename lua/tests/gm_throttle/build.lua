return WithThrottlerTests( {
    groupName = "Throttler:build",

    cases = {
        {
            name = "Returns a struct with a unique id",
            func = function()
                local first = Throttler:build()
                local second = Throttler:build()

                expect( first.id ).to.beA( "string" )
                expect( first.id ).toNot.equal( second.id )
            end
        },

        {
            name = "Keeps ids unique after the module is required again",
            func = function()
                local before = Throttler:build()
                require( "throttler" )
                local after = Throttler:build()

                expect( after.id ).toNot.equal( before.id )
            end
        }
    }
} )
