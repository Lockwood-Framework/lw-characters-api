local DB      = exports['lw-db']:DB()
local LWUtils = exports['lw-shared']:GetUtils()

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Returns the configured slot allowance for a player.
--- Already clamped to Config.MaxSlots at startup — no need to clamp here.
---@param  license2  string
---@return           integer
local function GetSlotAllowance(license2)
    return Config.SlotOverrides[license2] or Config.DefaultSlots
end

-- ---------------------------------------------------------------------------
-- Module-level functions
-- Accessible to other server scripts in this resource (main.lua).
-- ---------------------------------------------------------------------------

--- Returns slot usage and character list for a player account.
--- `used` counts Active characters only — Deceased do not consume a slot.
--- `characters` includes Active and Deceased rows for character selection display.
--- Must be called from within a Citizen.CreateThread.
---@param  license2  string
---@return           table  { allowed: integer, used: integer, characters: table[] }
function GetSlotInfo(license2)
    local allowed    = GetSlotAllowance(license2)
    local characters = DB.query(
        'SELECT * FROM `lw_characters` WHERE `license2` = ? ORDER BY `last_played_at` DESC',
        { license2 }
    )

    local used = 0
    for _, char in ipairs(characters) do
        if char.status == LWUtils.Enums.CharacterStatus.Active then
            used = used + 1
        end
    end

    return {
        allowed    = allowed,
        used       = used,
        characters = characters,
    }
end

--- Returns whether a first + last name combination is available for a player.
--- Checks both active characters and tombstones — deceased names are permanently
--- locked to the account. Name comparison is case-insensitive.
--- Must be called from within a Citizen.CreateThread.
---@param  license2   string
---@param  firstName  string
---@param  lastName   string
---@return            boolean
function IsNameAvailable(license2, firstName, lastName)
    local inChars = DB.scalar([[
        SELECT 1 FROM `lw_characters`
        WHERE  `license2`   = ?
        AND    LOWER(`first_name`) = LOWER(?)
        AND    LOWER(`last_name`)  = LOWER(?)
        LIMIT  1
    ]], { license2, firstName, lastName })

    if inChars then return false end

    local inTombstones = DB.scalar([[
        SELECT 1 FROM `lw_character_tombstones`
        WHERE  `license2`   = ?
        AND    LOWER(`first_name`) = LOWER(?)
        AND    LOWER(`last_name`)  = LOWER(?)
        LIMIT  1
    ]], { license2, firstName, lastName })

    return not inTombstones
end

-- ---------------------------------------------------------------------------
-- Exports
-- ---------------------------------------------------------------------------

exports('GetSlotInfo', function(license2)
    return GetSlotInfo(license2)
end)

exports('IsNameAvailable', function(license2, firstName, lastName)
    return IsNameAvailable(license2, firstName, lastName)
end)