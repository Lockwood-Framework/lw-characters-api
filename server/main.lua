local DB      = exports['lw-db']:DB()

-- ---------------------------------------------------------------------------
-- Slot override validation — runs immediately on resource start.
-- Clamps any override above Config.MaxSlots and warns on the server console.
-- ---------------------------------------------------------------------------
for license2, count in pairs(Config.SlotOverrides) do
    if count > Config.MaxSlots then
        print(('[^3WARN^7] lw-characters-api: SlotOverride for %s exceeds MaxSlots (%d). Clamping to %d.')
            :format(license2, Config.MaxSlots, Config.MaxSlots))
        Config.SlotOverrides[license2] = Config.MaxSlots
    end
end

-- ---------------------------------------------------------------------------
-- Migrations
-- ---------------------------------------------------------------------------
AddEventHandler('lw-core:ready', function()
    exports['lw-db']:RegisterMigration('lw-characters-api', '001_create_characters', [[
        CREATE TABLE IF NOT EXISTS `lw_characters` (
            `state_id`        VARCHAR(17)                NOT NULL,
            `license2`        VARCHAR(60)                NOT NULL,
            `first_name`      VARCHAR(32)                NOT NULL,
            `last_name`       VARCHAR(32)                NOT NULL,
            `status`          ENUM('active', 'deceased') NOT NULL DEFAULT 'active',
            `last_x`          FLOAT                      NULL,
            `last_y`          FLOAT                      NULL,
            `last_z`          FLOAT                      NULL,
            `last_heading`    FLOAT                      NULL,
            `deceased_at`     TIMESTAMP                  NULL,
            `created_at`      TIMESTAMP                  NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `last_played_at`  TIMESTAMP                  NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`state_id`),
            CONSTRAINT `fk_characters_license2`
                FOREIGN KEY (`license2`)
                REFERENCES `lw_players` (`license2`)
                ON UPDATE CASCADE
                ON DELETE CASCADE
        )
    ]])

    exports['lw-db']:RegisterMigration('lw-characters-api', '002_create_tombstones', [[
        CREATE TABLE IF NOT EXISTS `lw_character_tombstones` (
            `state_id`    VARCHAR(17)  NOT NULL,
            `license2`    VARCHAR(60)  NOT NULL,
            `first_name`  VARCHAR(32)  NOT NULL,
            `last_name`   VARCHAR(32)  NOT NULL,
            `epitaph`     VARCHAR(250) NULL,
            `died_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`state_id`)
        )
    ]])
end)

-- ---------------------------------------------------------------------------
-- Pruning check — fires when a player session is created.
-- Character selection loads but an overlay blocks interaction until resolved.
-- ---------------------------------------------------------------------------
AddEventHandler('lw-core:playerConnected', function(source, session)
    local info = GetSlotInfo(session.license2)

    if info.used > info.allowed then
        TriggerEvent('lw-characters-api:pruningRequired', source, info.used - info.allowed)
    end
end)

-- ---------------------------------------------------------------------------
-- Update last_played_at when a character is selected.
-- ---------------------------------------------------------------------------
AddEventHandler('lw-core:characterSelected', function(source, stateId)
    CreateThread(function()
        DB.update(
            'UPDATE `lw_characters` SET `last_played_at` = CURRENT_TIMESTAMP WHERE `state_id` = ?',
            { stateId }
        )
    end)
end)

-- ---------------------------------------------------------------------------
-- Best-effort final location save on character unload.
-- Covers both logout and disconnect. The periodic loop is the primary
-- mechanism — this is a last-chance write before the session tears down.
-- ---------------------------------------------------------------------------
AddEventHandler('lw-core:characterUnloaded', function(source, stateId)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end

    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Skip if coords are at origin — ped is likely already invalid.
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then return end

    CreateThread(function()
        SaveLocation(stateId, coords, heading)
    end)
end)

-- ---------------------------------------------------------------------------
-- Periodic location save loop — starts after DB is confirmed live.
-- ---------------------------------------------------------------------------
AddEventHandler('lw-db:ready', function()
    CreateThread(function()
        while true do
            Wait(Config.SaveInterval * 1000)

            local players = exports['lw-core']:GetAllPlayers()

            for source, session in pairs(players) do
                if session.stateId then
                    local ped = GetPlayerPed(source)
                    if ped and ped ~= 0 then
                        local coords  = GetEntityCoords(ped)
                        local heading = GetEntityHeading(ped)

                        if coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0 then
                            CreateThread(function()
                                SaveLocation(session.stateId, coords, heading)
                            end)
                        end
                    end
                end
            end
        end
    end)
end)