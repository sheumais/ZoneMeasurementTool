Measurements = Measurements or {}

local D = 2e6

function Measurements.MeasureCurrentZone()
    local zone_id, x, y, z = GetUnitRawWorldPosition("player")
    local map_id = GetCurrentMapId()

    d(string.format("Measuring zone %d, map id %d", zone_id, map_id))

    local nX1, nZ1 = GetRawNormalizedWorldPosition(zone_id, -D, y, -D)
    local nX2, nZ2 = GetRawNormalizedWorldPosition(zone_id,  D, y,  D)

    local scaleX  = (nX2 - nX1) / (2 * D)
    local offsetX = (nX2 + nX1) / 2
    local scaleZ  = (nZ2 - nZ1) / (2 * D)
    local offsetZ = (nZ2 + nZ1) / 2

    local zeroX = -offsetX / scaleX
    local oneX  = (1 - offsetX) / scaleX
    local zeroZ = -offsetZ / scaleZ
    local oneZ  = (1 - offsetZ) / scaleZ

    local xC = x * scaleX + offsetX
    local zC = z * scaleZ + offsetZ
    d(string.format("Player position normalized: x=%.3f, z=%.3f", xC, zC))
    d(string.format("Normalized (0,0): x=%.3f, z=%.3f", zeroX, zeroZ))
    d(string.format("Normalized (1,1): x=%.3f, z=%.3f", oneX, oneZ))

    Measurements.savedVars[zone_id] = Measurements.savedVars[zone_id] or {}
    Measurements.savedVars[zone_id][map_id] = {
        scaleX  = scaleX,
        offsetX = offsetX,
        scaleZ  = scaleZ,
        offsetZ = offsetZ,
        zero    = { x = zeroX, z = zeroZ },
        one     = { x = oneX,  z = oneZ  }
    }
    return scaleX, offsetX, scaleZ, offsetZ
end

function Measurements.CheckCurrentZoneForMeasurements()
    SetMapToPlayerLocation() -- very necessary, otherwise map can be stuck even after loading screen
    local zone_id, _, _, _ = GetUnitRawWorldPosition("player")
    local map_id = GetCurrentMapId()
    -- d(string.format("Checking zone %d, map id %d", zone_id, map_id))

    Measurements.savedVars[zone_id] = Measurements.savedVars[zone_id] or {}
    if not Measurements.savedVars[zone_id][map_id] then Measurements:MeasureCurrentZone() end
end

local CheckCurrentZoneForMeasurements = Measurements.CheckCurrentZoneForMeasurements

function Measurements.DumpMapData()
    Measurements.savedVars["Dump"] = Measurements.savedVars["Dump"] or {}
    
    for mapId = 0, 3000 do
        local tile_count = GetMapNumTilesForMapId(mapId)
        local name = GetMapNameById(mapId)
        if name and name ~= "" and tile_count and tile_count > 0 then
            local mapEntry = {
                name = name,
                tileCount = tile_count,
                tiles = {}
            }

            for tileIndex = 1, tile_count do
                local texture = GetMapTileTextureForMapId(mapId, tileIndex)
                table.insert(mapEntry.tiles, texture)
            end

            Measurements.savedVars["Dump"][mapId] = mapEntry
        end
    end
end

local function Init(event, name)
    if name ~= "Measurements" then return end
    EVENT_MANAGER:UnregisterForEvent("Measurements", EVENT_ADD_ON_LOADED)
    Measurements.savedVars = ZO_SavedVars:NewAccountWide("MeasurementsSavedVars", 1, nil, {})
    
    EVENT_MANAGER:RegisterForEvent("Measurements", EVENT_PLAYER_ACTIVATED, CheckCurrentZoneForMeasurements)
    EVENT_MANAGER:RegisterForEvent("Measurements", EVENT_PLAYER_TELEPORTED_LOCALLY, CheckCurrentZoneForMeasurements)
end


EVENT_MANAGER:RegisterForEvent("Measurements", EVENT_ADD_ON_LOADED, Init)