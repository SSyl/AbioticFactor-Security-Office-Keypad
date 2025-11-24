print("=== [Security Office Keypad Enabler] MOD LOADED === \n")

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------
local DEBUG = false  -- Set to true to enable debug messages

-- The keypad that you originally have to hack to access the security office in the Office Sector
local KEYPAD_PATH = "/Game/Maps/Facility_Office4.Facility_Office4:PersistentLevel.Button_Keypad_Tier1_C_0"

-- The shutter button inside the security office that opens/closes the shutters/door
local BUTTON_PATH = "/Game/Maps/Facility_Office4.Facility_Office4:PersistentLevel.Button_Generic_C_2"

local KEYPAD_FULL_NAME = "Button_Keypad_C " .. KEYPAD_PATH

local targetKeypad = nil
local indoorButton = nil

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

local function DebugLog(message)
    if DEBUG then
        print("[Security Office Keypad Enabler] " .. tostring(message) .. "\n")
    end
end

-- Simplified validity check using built-in UObject:IsValid()
local function IsValidObject(obj)
    return obj ~= nil and obj:IsValid()
end

local function ConfigureObjects()
    DebugLog("Finding objects...")

    -- Find and configure the security keypad
    targetKeypad = StaticFindObject(KEYPAD_PATH)
    if IsValidObject(targetKeypad) then
        local ok, err = pcall(function()
            targetKeypad.OneTimeUse = false
        end)

        if ok then
            DebugLog("Keypad configured (OneTimeUse set to false)")
        else
            DebugLog("WARNING: Failed to set OneTimeUse on keypad: " .. tostring(err))
        end
    else
        DebugLog("WARNING: Keypad not found at path: " .. KEYPAD_PATH)
    end

    -- Find the indoor shutter button
    indoorButton = StaticFindObject(BUTTON_PATH)
    if IsValidObject(indoorButton) then
        DebugLog("Indoor button found and cached")
    else
        DebugLog("WARNING: Indoor button not found at path: " .. BUTTON_PATH)
    end
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

local function HandleKeypadInteraction(Context, _InteractingCharacter, _ComponentUsed)
    if not Context then
        DebugLog("WARNING: Context is nil in interaction hook")
        return
    end

    local ok, keypad = pcall(function()
        return Context:get()
    end)

    if not ok then
        DebugLog("WARNING: Failed to get Context object: " .. tostring(keypad))
        return
    end

    if not IsValidObject(keypad) or not IsValidObject(indoorButton) then
        if DEBUG then
            DebugLog("Interaction ignored (keypadValid=" .. tostring(IsValidObject(keypad)) ..
                     ", buttonValid=" .. tostring(IsValidObject(indoorButton)) .. ")")
        end
        return
    end

    if keypad:GetFullName() ~= KEYPAD_FULL_NAME then
        return
    end

    local activatedOk, isActivated = pcall(function()
        return keypad.Activated
    end)

    if not activatedOk then
        DebugLog("WARNING: Failed to read Activated property on keypad")
        return
    end

    if not isActivated then
        DebugLog("Keypad not yet hacked, ignoring interaction")
        return
    end

    DebugLog("Triggering shutters via keypad")
    local triggerOk = pcall(function()
        indoorButton:TriggerButtonWithoutUser()
    end)

    if not triggerOk then
        DebugLog("ERROR triggering shutters via keypad")
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

local hookRegistered = false

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(_Context)
    DebugLog("ClientRestart hook fired")

    ExecuteWithDelay(2000, function()
        ExecuteInGameThread(function()

            if not hookRegistered then
                DebugLog("Registering hooks...")

                local ok = pcall(function()
                    RegisterHook("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C:InteractWith_A", HandleKeypadInteraction)
                end)

                if ok then
                    DebugLog("Interaction hook registered successfully")
                else
                    DebugLog("ERROR: Failed to register interaction hook")
                end

                NotifyOnNewObject("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C", function(keypad)
                    ExecuteWithDelay(750, function()
                        ExecuteInGameThread(function()
                            if keypad and keypad:IsValid() and keypad:GetFullName() == KEYPAD_FULL_NAME then
                                DebugLog("Target keypad respawned, reconfiguring...")
                                ConfigureObjects()
                            end
                        end)
                    end)
                end)

                hookRegistered = true
            end

            -- Always configure objects when entering world
            ConfigureObjects()
        end)
    end)
end)

DebugLog("Mod finished loading")