print("=== [Security Office Keypad Enabler] MOD LOADING ===\n")

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
local GameStateHookFired = false

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

local function OnGameState(world)
    GameStateHookFired = true

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

    if mapName:match("MainMenu") then return end
    ExecuteWithDelay(2500, function()
        ExecuteInGameThread(function()
            ConfigureObjects()
        end)
    end)
end

-- Hook callback for GameState:ReceiveBeginPlay
local function OnGameStateHook(Context)
    Log.Debug("Abiotic_Survival_GameState:ReceiveBeginPlay fired")

    local gameState = Context:get()
    if not gameState:IsValid() then return end

    local okWorld, world = pcall(function() return gameState:GetWorld() end)
    if okWorld and world and world:IsValid() then
        OnGameState(world)
    end
end

-- ============================================================
-- GAMESTATE HOOK REGISTRATION VIA POLLING
-- ============================================================
-- Blueprint may not be loaded at mod init.
-- Poll until GameState exists, then register hook + handle current map.

local hookRegistered = false

local function PollForMissedHook(attempts)
    attempts = attempts or 0

    if GameStateHookFired then return end

    ExecuteInGameThread(function()
        local base = FindFirstOf("GameStateBase")
        if not base:IsValid() then
            if attempts < 100 then
                ExecuteWithDelay(100, function()
                    PollForMissedHook(attempts + 1)
                end)
            else
                Log.Error("GameStateBase never found after %d attempts", attempts + 1)
            end
            return
        end

        -- Register hook once any GameState exists (even main menu)
        if not hookRegistered then
            local ok = pcall(RegisterHook,
                "/Game/Blueprints/Meta/Abiotic_Survival_GameState.Abiotic_Survival_GameState_C:ReceiveBeginPlay",
                OnGameStateHook
            )
            if ok then
                hookRegistered = true
                Log.Debug("Hook registered")
            end
        end

        -- If already in gameplay map, handle current map manually
        local gameState = FindFirstOf("Abiotic_Survival_GameState_C")
        if gameState:IsValid() then
            Log.Debug("Gameplay GameState found, invoking OnGameState")
            local okWorld, world = pcall(function() return gameState:GetWorld() end)
            if okWorld and world and world:IsValid() then
                OnGameState(world)
            end
        end
    end)
end

PollForMissedHook()

Log.Debug("Mod loaded")