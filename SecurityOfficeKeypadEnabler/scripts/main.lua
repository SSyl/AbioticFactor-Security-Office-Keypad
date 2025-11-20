print("=== [Security Office Keypad Enabler] MOD LOADED ===")

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------
local DEBUG = true  -- Set to true to enable debug messages

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
        print("[Security Office Keypad Enabler] " .. tostring(message))
    end
end

local function IsValidObject(obj)
    if obj == nil then
        return false
    end

    if type(obj.IsValid) ~= "function" then
        return false
    end

    return obj:IsValid()
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
        DebugLog("WARNING: Keypad not found!")
    end

    -- Find the indoor shutter button
    indoorButton = StaticFindObject(BUTTON_PATH)
    if IsValidObject(indoorButton) then
        DebugLog("Indoor button found")
    else
        DebugLog("WARNING: Indoor button not found!")
    end
end

local function HandleKeypadInteraction(Context, InteractingCharacter, ComponentUsed)

    if not Context then
        DebugLog("WARNING: Context is nil in interaction hook")
        return
    end

    local ok, self = pcall(function()
        return Context:get()
    end)

    if not ok then
        DebugLog("WARNING: Failed to get Context object: " .. tostring(self))
        return
    end

    if not (IsValidObject(self) and IsValidObject(indoorButton)) then
        if DEBUG then
            DebugLog("Interaction ignored (keypadValid=" .. tostring(IsValidObject(self)) ..
                     ", buttonValid=" .. tostring(IsValidObject(indoorButton)) .. ")")
        end
        return
    end

    if self:GetFullName() ~= KEYPAD_FULL_NAME then
        return
    end

    -- Check if keypad has been hacked
    local activatedSuccess, isActivated = pcall(function()
        return self.Activated
    end)

    if not activatedSuccess then
        DebugLog("WARNING: Failed to read Activated property on keypad")
        return
    end

    if not isActivated then
        DebugLog("Keypad not yet hacked, ignoring interaction")
        return
    end

    -- Trigger the shutters when you press the keypad by calling the toggle function from the button inside
    DebugLog("Triggering shutters via keypad")
    local success, err = pcall(function()
        indoorButton:TriggerButtonWithoutUser()
    end)

    if not success then
        DebugLog("ERROR triggering shutters via keypad: " .. tostring(err))
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

-- Initial object configuration (delayed to ensure objects are loaded)
ExecuteWithDelay(2500, ConfigureObjects)

-- Handle keypad respawns/reloads when level streaming occurs
NotifyOnNewObject("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C", function(ConstructedObject)
    if not IsValidObject(ConstructedObject) then
        return
    end

    if ConstructedObject:GetFullName() == KEYPAD_FULL_NAME then
        DebugLog("Target keypad reloaded, reconfiguring...")
        ExecuteWithDelay(2500, ConfigureObjects)
    end
end)

-- Register interaction hook (delayed to ensure Blueprint is fully loaded)
ExecuteWithDelay(3000, function()
    local success, err = pcall(function()
        RegisterHook("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C:InteractWith_A", HandleKeypadInteraction)
    end)

    if success then
        DebugLog("Hook registered")
    else
        DebugLog("ERROR: Failed to register hook: " .. tostring(err))
    end
end)