Measurements = Measurements or {}

local D = 2e6

function Measurements.MeasureCurrentZone()
    local zone_id, x, y, z = GetUnitRawWorldPosition("player")
    local map_id = GetCurrentMapId()

    -- d(string.format("Measuring zone %d, map id %d", zone_id, map_id))

    local nX1, nZ1 = GetRawNormalizedWorldPosition(zone_id, -D, y, -D)
    local nX2, nZ2 = GetRawNormalizedWorldPosition(zone_id,  D, y,  D)

    local scaleX  = (nX2 - nX1) / (2 * D)
    local offsetX = (nX2 + nX1) / 2
    local scaleZ  = (nZ2 - nZ1) / (2 * D)
    local offsetZ = (nZ2 + nZ1) / 2

    local xC = x * scaleX + offsetX
    local zC = z * scaleZ + offsetZ
    -- d(string.format("Player position normalized: x=%.3f, z=%.3f", xC, zC))

    local zeroX = offsetX 
    local zeroZ = offsetZ
    local oneX  = 1 * scaleX + offsetX
    local oneZ  = 1 * scaleZ + offsetZ

    -- d(string.format("Normalized (0,0): x=%.3f, z=%.3f", zeroX, zeroZ))
    -- d(string.format("Normalized (1,1): x=%.3f, z=%.3f", oneX, oneZ))

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

local function Init(event, name)
    if name ~= "Measurements" then return end
    EVENT_MANAGER:UnregisterForEvent("Measurements", EVENT_ADD_ON_LOADED)
    Measurements.savedVars = ZO_SavedVars:NewAccountWide("MeasurementsSavedVars", 1, nil, {})
    
    EVENT_MANAGER:RegisterForEvent("Measurements", EVENT_PLAYER_ACTIVATED, CheckCurrentZoneForMeasurements)
    EVENT_MANAGER:RegisterForEvent("Measurements", EVENT_PLAYER_TELEPORTED_LOCALLY, CheckCurrentZoneForMeasurements)
end


EVENT_MANAGER:RegisterForEvent("Measurements", EVENT_ADD_ON_LOADED, Init)