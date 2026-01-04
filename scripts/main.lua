print("=== [Security Office Keypad Enabler] MOD LOADING ===\n")

local UEHelpers = require("UEHelpers")
local LogUtil = require("LogUtil")
local ConfigUtil = require("ConfigUtil")

-- ============================================================
-- CONFIG
-- ============================================================

local UserConfig = require("../config")
local Config = ConfigUtil.ValidateConfig(UserConfig, LogUtil.CreateLogger("Security Office Keypad (Config)", UserConfig))
local Log = LogUtil.CreateLogger("Security Office Keypad", Config)

-- ============================================================
-- CONSTANTS
-- ============================================================

local KEYPAD_PATH = "/Game/Maps/Facility_Office4.Facility_Office4:PersistentLevel.Button_Keypad_Tier1_C_0"
local BUTTON_PATH = "/Game/Maps/Facility_Office4.Facility_Office4:PersistentLevel.Button_Generic_C_2"
local KEYPAD_FULL_NAME = "Button_Keypad_C " .. KEYPAD_PATH

-- ============================================================
-- STATE
-- ============================================================

local targetKeypad = nil
local indoorButton = nil
local notifyRegistered = false
local LoadMapPostHookFired = false

-- ============================================================
-- FUNCTIONS
-- ============================================================

local function ConfigureObjects()
    targetKeypad = StaticFindObject(KEYPAD_PATH)
    if targetKeypad:IsValid() then
        local ok, err = pcall(function()
            targetKeypad.OneTimeUse = false
        end)
        if not ok then
            Log.Warning("Failed to configure keypad: %s", tostring(err))
        end
    else
        Log.Debug("Keypad not found - wrong map?")
    end

    indoorButton = StaticFindObject(BUTTON_PATH)
    if not indoorButton:IsValid() then
        Log.Debug("Indoor button not found - wrong map?")
    end
end

local function HandleKeypadInteraction(Context)
    if not Context then return end

    local keypad = Context:get()
    if not keypad:IsValid() then return end
    if not indoorButton or not indoorButton:IsValid() then return end  -- Keep nil check: cached variable
    if keypad:GetFullName() ~= KEYPAD_FULL_NAME then return end

    local ok, activated = pcall(function() return keypad.Activated end)
    if not ok or not activated then return end

    Log.Debug("Triggering shutters")
    pcall(function() indoorButton:TriggerButtonWithoutUser() end)
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

local function OnLoadMap(world)
    LoadMapPostHookFired = true

    if not world:IsValid() then return end

    local okFullName, fullName = pcall(function() return world:GetFullName() end)
    local mapName = okFullName and fullName and fullName:match("/Game/Maps/([^%.]+)")
    if not mapName then
        return
    end

    if not notifyRegistered then
        local asset, wasFound, wasLoaded = LoadAsset("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C")
        if wasFound and wasLoaded and asset:IsValid() then
            notifyRegistered = true
            ExecuteWithDelay(2500, function()
                local okHook, errHook = pcall(RegisterHook,
                    "/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C:InteractWith_A",
                    HandleKeypadInteraction
                )
                if not okHook then
                    Log.Error("Hook registration failed: %s", tostring(errHook))
                end
            end)

            NotifyOnNewObject("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C", function(keypad)
                if keypad:GetFullName() == KEYPAD_FULL_NAME then
                    ExecuteWithDelay(2500, function()
                        ExecuteInGameThread(function()
                            ConfigureObjects()
                        end)
                    end)
                end
            end)
        end
    end


    local isGameplayMap = not mapName:match("MainMenu")
    if isGameplayMap then
        ExecuteWithDelay(2500, function()
            ExecuteInGameThread(function()
                ConfigureObjects()
            end)
        end)
    end
end

RegisterLoadMapPostHook(function(Engine, World)
    local world = World:get()
    if world and world:IsValid() then
        OnLoadMap(world)
    end
end)

-- ============================================================
-- RACE CONDITION FALLBACK
-- ============================================================
-- UE4SS can initialize late, missing lifecycle hooks.
-- This polls until world is loaded, then invokes OnLoadMap manually.

local function PollForMissedHooks(attempts)
    attempts = attempts or 0

    if LoadMapPostHookFired then return end

    ExecuteInGameThread(function()
        local existingActor = FindFirstOf("Actor")
        if not existingActor:IsValid() then
            if attempts < 100 then
                ExecuteWithDelay(100, function()
                    PollForMissedHooks(attempts + 1)
                end)
            end
            return
        end

        -- World loaded but hook missed - invoke manually
        if not LoadMapPostHookFired then
            local world = UEHelpers.GetWorld()
            if world:IsValid() then
                Log.Debug("Fallback: LoadMapPostHook missed, invoking OnLoadMap manually")
                OnLoadMap(world)
            end
        end

        if not LoadMapPostHookFired then
            if attempts < 100 then
                ExecuteWithDelay(100, function()
                    PollForMissedHooks(attempts + 1)
                end)
            else
                Log.Error("Fallback polling gave up after %d attempts", attempts + 1)
            end
        else
            Log.Debug("Fallback succeeded on attempt %d", attempts + 1)
        end
    end)
end

PollForMissedHooks()

Log.Debug("Mod loaded")