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
( Read more about the Throttle Struct [below](https://github.com/CFC-Servers/gm_throttle/blob/main/README.md#the-throttle-structure) )
```lua
require( "throttler" )

-- The first step is to create a Throttler struct.

-- You can build a generic pre-filled structure and overwrite specific values:
local struct = Throttler:build()
struct.delay = 0.5 -- In seconds
struct.budget = 500

struct.failure = function( ent )
    ent.Owner:ChatPrint( "The thing was throttled!" )
end

struct.shouldSkip = function( ent )
    if ent.Owner:IsAdmin() then return true end
end

-- Once you have your Throttle Struct, you can use it to stub a function:
MyLib = {
    spammyFunction = function( ent )
        local data = ent:GetExpensiveThing()
        performExpensiveCalculation( data )
    end
}

local throttle = Throttler:create( MyLib.spammyFunction, struct )
MyLib.spammyFunction = throttle
```

## The Throttle Structure
| Param            | Type                        | Description                                                                                                      | Default                            |
|------------------|-----------------------------|------------------------------------------------------------------------------------------------------------------|------------------------------------|
| **`id`**         | `string`                    | An identifier for this throttle (must be unique per `context`)                                                   | `throttler_limit_#`                |
| **`context`**    | `table`/`entity`/`function` | Where to store the throttle data (Accepts a function that returns a context object)                                                          | Function returning the first param |
| **`delay`**      | `float`                     | How long to wait between executions after the budget is expended                                                 | `1`                                |
| **`refillRate`** | `float`                     | How much budget to refill per second                                                                             | `1`                                |
| **`success`**    | `function`                  | A callback to run when the execution succeeds (before calling the throttled func)                                | `noop`                             |
| **`failure`**    | `function`                  | A callback to run when the execution is prevented                                                                | `noop`                             |
| **`shouldSkip`** | `function`                  | Function used to decide if throttling logic should be applied for this execution (return true to skip)           | `noop`                             |
| **`adjust`**     | `function`                  | Return a table with any of: [`delay`,`budget`,`refillRate`,`id`] to override initial settings for this execution | `noop`                             |
