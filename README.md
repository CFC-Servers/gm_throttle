# gm_throttle
A library for Garry's Mod that allows simple, dynamic, and feature-rich rate limiting of functions

## Installation
Simply download a copy of the zip, or clone the repository straight into your addons folder!

### Download
The latest pre-compiled versions are available in **[Releases](https://github.com/CFC-Servers/gm_throttle/releases/)**

### Git Clone
Because this project uses Moonscript, keeping it updated via `git` is _slightly_ more involved.

The [`lua` branch](https://github.com/CFC-Servers/gm_throttle/tree/lua) is a lua-only branch containing the compiled code from the most recent release. You can use this branch to keep `gm_throttle` up to date.
```sh
git clone --single-branch --branch lua git@github.com:CFC-Servers/gm_throttle.git
```

Assuming you can get the project cloned (some hosting interfaces may not support this), any auto-updater software should work just fine.

## Usage
There are some comprehensive examples in the [examples folder](https://github.com/CFC-Servers/gm_throttle/tree/main/example), but a very simple usage example follows:

```lua
require( "throttler" )

-- The first step is to create a Throttler struct.

-- You can build a generic pre-filled structure and overwrite specific values:
local throttleStruct = Throttler:build()
throttleStruct.delay = 0.5 -- In seconds
throttleStruct.budget = 500

throttleStruct.failure = function( ent )
    ent.Owner:ChatPrint( "The thing was throttled!" )
end

throttleStruct.shouldSkip = function( ent )
    if ent.Owner:IsAdmin() then return true end
end

-- Once you have your Throttle Struct, you can use it to stub a function:
MyLib = {
    spammyFunction = function( ent )
        local data = ent:GetExpensiveThing()
        performExpensiveCalculation( data )
    end
}

-- The final step is to replace the desired function with your new throttle:
local throttle = Throttler:create( MyLib.spammyFunction, throttleStruct )
MyLib.spammyFunction = throttle
```
