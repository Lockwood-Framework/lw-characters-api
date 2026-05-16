-- ---------------------------------------------------------------------------
-- lw-characters-api — server configuration
-- ---------------------------------------------------------------------------

Config = {}

-- Default number of character slots per player.
Config.DefaultSlots = 4

-- Hard ceiling on character slots regardless of overrides.
-- Any SlotOverrides entry above this value will be clamped at startup.
Config.MaxSlots = 8

-- Maximum length of a permadeath epitaph in characters.
-- Drives both DB column size and the validation in SetCharacterDeceased.
Config.MaxEpitaphLength = 250

-- Seconds between periodic character location saves.
-- Location is also written on any full character save regardless of this interval.
Config.SaveInterval = 300

-- Per-player slot overrides keyed by license2 identifier.
-- Values above Config.MaxSlots are clamped to Config.MaxSlots at startup.
-- Example:
--   ['license2:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = 6,
Config.SlotOverrides = {
    ['license2:dd39ad26cf8b67f1a2cabed316bb59f7aafd7e33'] = 8,
}