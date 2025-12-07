print("=== [Security Office Keypad Enabler] MOD LOADED ===\n")

local DEBUG = true
local KEYPAD_PATH = "/Game/Maps/Facility_Office4.Facility_Office4:PersistentLevel.Button_Keypad_Tier1_C_0"
local BUTTON_PATH = "/Game/Maps/Facility_Office4.Facility_Office4:PersistentLevel.Button_Generic_C_2"
local KEYPAD_FULL_NAME = "Button_Keypad_C " .. KEYPAD_PATH

local targetKeypad = nil
local indoorButton = nil

local function DebugLog(message)
    if DEBUG then
        print("[Security Office Keypad Enabler] " .. tostring(message) .. "\n")
    end
end

local function ConfigureObjects()
    DebugLog("Finding objects...")

    targetKeypad = StaticFindObject(KEYPAD_PATH)
    if targetKeypad and targetKeypad:IsValid() then
        local ok, err = pcall(function()
            targetKeypad.OneTimeUse = false
        end)
        if ok then
            DebugLog("Keypad configured")
        else
            DebugLog("WARNING: " .. tostring(err))
        end
    end

    indoorButton = StaticFindObject(BUTTON_PATH)
    if indoorButton and indoorButton:IsValid() then
        DebugLog("Indoor button found")
    end
end

local function HandleKeypadInteraction(Context)
    if not Context then return end

    local keypad = Context:get()
    if not keypad or not keypad:IsValid() then return end
    if not indoorButton or not indoorButton:IsValid() then return end
    if keypad:GetFullName() ~= KEYPAD_FULL_NAME then return end

    local ok, activated = pcall(function() return keypad.Activated end)
    if not ok or not activated then return end

    DebugLog("Triggering shutters")
    pcall(function() indoorButton:TriggerButtonWithoutUser() end)
end

local notifyRegistered = false

RegisterBeginPlayPostHook(function(ActorParam)
    local Actor = ActorParam:get()
    if not Actor or not Actor:IsValid() then return end

    local gameStateClass = Actor:GetClass():GetFName():ToString()
    if gameStateClass ~= "Abiotic_Survival_GameState_C" then return end

    DebugLog("Game state BeginPlay detected")

    if not notifyRegistered then
        notifyRegistered = true
        ExecuteWithDelay(5000, function()
            RegisterHook("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C:InteractWith_A", HandleKeypadInteraction)
            DebugLog("Hook registered")
            NotifyOnNewObject("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C", function(keypad)
                if keypad:GetFullName() == KEYPAD_FULL_NAME then
                    DebugLog("Target keypad spawned")
                    ExecuteWithDelay(1000, function()
                        ExecuteInGameThread(function()
                            ConfigureObjects()
                        end)
                    end)
                end
            end)
        end)
    end

    ExecuteWithDelay(5000, function()
        ExecuteInGameThread(function()
            ConfigureObjects()
        end)
    end)
end)

DebugLog("Mod loaded")