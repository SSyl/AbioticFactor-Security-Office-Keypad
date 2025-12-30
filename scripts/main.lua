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

-- ============================================================
-- FUNCTIONS
-- ============================================================

local function ConfigureObjects()
    Log.Debug("Finding objects...")

    targetKeypad = StaticFindObject(KEYPAD_PATH)
    if targetKeypad:IsValid() then
        local ok, err = pcall(function()
            targetKeypad.OneTimeUse = false
        end)
        if ok then
            Log.Debug("Keypad configured")
        else
            Log.Warning("Failed to configure keypad: %s", tostring(err))
        end
    end

    indoorButton = StaticFindObject(BUTTON_PATH)
    if indoorButton:IsValid() then
        Log.Debug("Indoor button found")
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

RegisterLoadMapPostHook(function()
    Log.Debug("Map loaded")

    -- Filter out main menu - only run in actual game world
    local gameState = UEHelpers.GetGameStateBase()
    if not gameState:IsValid() then
        Log.Debug("Skipping - no GameState found")
        return
    end

    local ok, gameStateClass = pcall(function()
        return gameState:GetClass():GetFName():ToString()
    end)

    if not ok or gameStateClass ~= "Abiotic_Survival_GameState_C" then
        Log.Debug("Skipping - not in game world (main menu?)")
        return
    end

    -- One-time hook registration
    if not notifyRegistered then
        notifyRegistered = true
        ExecuteWithDelay(2500, function()
            local okHook, errHook = pcall(RegisterHook,
                "/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C:InteractWith_A",
                HandleKeypadInteraction
            )

            if okHook then
                Log.Debug("Hook registered")
            else
                Log.Error("Hook registration failed: %s", tostring(errHook))
            end

            NotifyOnNewObject("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C", function(keypad)
                if keypad:GetFullName() == KEYPAD_FULL_NAME then
                    Log.Debug("Target keypad spawned")
                    ExecuteWithDelay(1000, function()
                        ExecuteInGameThread(function()
                            ConfigureObjects()
                        end)
                    end)
                end
            end)
        end)
    end

    -- Configure existing objects after map settles
    ExecuteWithDelay(2500, function()
        ExecuteInGameThread(function()
            ConfigureObjects()
        end)
    end)
end)

Log.Debug("Mod loaded")