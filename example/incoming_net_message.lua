require( "throttler" )

--
-- This throttles the rate at which players can send the "wire_friendslist" net message to the server.
-- If they're throttled more than 50 times, they'll be kicked from the server.
--
local function throttleWireFriendslist()
    local receiver = net.Receivers["wire_friendslist"]

    local throttle = {
        delay = 0.1,
        budget = 5,
        refillRate = 10,

        -- Store the throttle data on the player
        context = function( ply )
            return ply
        end,

        failure = function( ply )
            local count = ply.throttleCount

            if count > 50 then
                ply:Kick( "Net message spam" )
            else
                ply.throttleCount = count + 1
            end
        end,

        -- You could subtract from their throttleCount every time they succesfully send a message
        success = function( ply )
            local count = ply.throttleCount
            if count == 0 then return end

            ply.throttleCount = count - 1

            -- You can also run extra logic after the throttle checks pass

            if ply.netMessageBanned then -- (lol idk)
                return false -- Stops the wrapped function from being run
            end
        end
    }

    net.Receivers["wire_friendslist"] = Throttler.create( receiver, throttle )
end
