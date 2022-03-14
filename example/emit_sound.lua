require( "throttler" )

--
-- Throttles Entity:EmitSound to 1/second, per-sound.
-- NPCs can emit sounds without being throttled.
-- Ambient sounds also won't be throttled.
--
local function throttleEmitSound()

    local throttle = Throttler:build()
    throttle.delay = 1
    throttle.budget = 1
    throttle.refillRate = 1

    -- We make a new table on the entity to store a throttle for each soundPath.
    -- That way, this one Throttle can track budgets/delays etc. separately for each sound
    throttle.context = function( e, soundPath )
        e.SoundThrottles = e.SoundThrottles or {}

        if not e.SoundThrottles[soundPath] then
            e.SoundThrottles[soundPath] = {}
        end

        return e.SoundThrottles[soundPath]
    end

    -- OR

    throttle.adjust = function( _, soundPath )
        -- id expects a function that modifies the original ID
        -- We append the soundPath here so the throttler will track the throttles for each sound separately
        return {
            id = function( baseId )
                return baseId .. "_" .. soundPath
            end
        }
    end

    throttle.shouldSkip = function( e, soundPath )
        if e:IsNPC() then
            return true
        end

        if string.StartWith( soundPath, "ambient/" ) then
            return true
        end
    end

    local entityMeta = FindMetaTable( "Entity" )
    entityMeta._EmitSound = entityMeta._EmitSound or entityMeta.EmitSound
    entityMeta.EmitSound = Throttler.create( entityMeta._EmitSound, throttle )
end
