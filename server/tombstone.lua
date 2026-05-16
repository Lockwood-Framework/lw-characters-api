local DB      = exports['lw-db']:DB()

--- Fetches a single tombstone by state ID.
--- Returns nil if the character was pruned rather than killed — pruned
--- characters do not receive tombstone entries.
--- Must be called from within a Citizen.CreateThread.
---@param  stateId  string
---@return          table|nil
exports('GetTombstone', function(stateId)
    return DB.single(
        'SELECT * FROM `lw_character_tombstones` WHERE `state_id` = ?',
        { stateId }
    )
end)

--- Fetches all tombstone entries for a player account.
--- Used for per-account name uniqueness checks and player death history.
--- Ordered by died_at descending.
--- Must be called from within a Citizen.CreateThread.
---@param  license2  string
---@return           table[]
exports('GetTombstonesByLicense2', function(license2)
    return DB.query(
        'SELECT * FROM `lw_character_tombstones` WHERE `license2` = ? ORDER BY `died_at` DESC',
        { license2 }
    )
end)

--- Fetches all tombstone entries that have an epitaph.
--- Used by memorial display resources. Entries without an epitaph are
--- excluded — no epitaph means the player opted out of the memorial.
--- Ordered by died_at descending.
--- Must be called from within a Citizen.CreateThread.
---@return  table[]
exports('GetMemorialEntries', function()
    return DB.query(
        'SELECT * FROM `lw_character_tombstones` WHERE `epitaph` IS NOT NULL ORDER BY `died_at` DESC',
        {}
    )
end)