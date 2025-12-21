print("=== [Security Office Keypad Enabler] MOD LOADED ===\n")

local DEBUG = true
local KEYPAD_PATH = "/Game/Maps/Facility_Office4.Facility_Office4:PersistentLevel.Button_Keypad_Tier1_C_0"
local BUTTON_PATH = "/Game/Maps/Facility_Office4.Facility_Office4:PersistentLevel.Button_Generic_C_2"
local KEYPAD_FULL_NAME = "Button_Keypad_C " .. KEYPAD_PATH

local targetKeypad = nil
local indoorButton = nil

local function Log(message, level)
    level = level or "info"

    if level == "debug" and not DEBUG then
        return
    end

    local prefix = ""
    if level == "error" then
        prefix = "ERROR: "
    elseif level == "warning" then
        prefix = "WARNING: "
    end

    print("[Security Office Keypad Enabler] " .. prefix .. tostring(message) .. "\n")
end

local function ConfigureObjects()
    Log("Finding objects...", "debug")

    targetKeypad = StaticFindObject(KEYPAD_PATH)
    if targetKeypad:IsValid() then
        local ok, err = pcall(function()
            targetKeypad.OneTimeUse = false
        end)
        if ok then
            Log("Keypad configured", "debug")
        else
            Log(tostring(err), "warning")
        end
    end

    indoorButton = StaticFindObject(BUTTON_PATH)
    if indoorButton:IsValid() then
        Log("Indoor button found", "debug")
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

    Log("Triggering shutters", "debug")
    pcall(function() indoorButton:TriggerButtonWithoutUser() end)
end

local notifyRegistered = false

RegisterBeginPlayPostHook(function(ActorParam)
    local Actor = ActorParam:get()
    if not Actor or not Actor:IsValid() then return end

    local gameStateClass = Actor:GetClass():GetFName():ToString()
    if gameStateClass ~= "Abiotic_Survival_GameState_C" then return end

    Log("Game state BeginPlay detected", "debug")

    if not notifyRegistered then
        notifyRegistered = true
        ExecuteWithDelay(5000, function()
            RegisterHook("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C:InteractWith_A", HandleKeypadInteraction)
            Log("Hook registered", "debug")
            NotifyOnNewObject("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C", function(keypad)
                if keypad:GetFullName() == KEYPAD_FULL_NAME then
                    Log("Target keypad spawned", "debug")
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

Log("Mod loaded", "debug")