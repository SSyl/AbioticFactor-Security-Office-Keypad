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

local function HandleKeypadInteraction(Context, InteractingCharacter, ComponentUsed)
    -- Validate context parameter
    if not Context then
        DebugLog("WARNING: Context is nil in interaction hook")
        return
    end

    -- Extract the actual keypad object from context
    local ok, self = pcall(function()
        return Context:get()
    end)

    if not ok then
        DebugLog("WARNING: Failed to get Context object: " .. tostring(self))
        return
    end

    -- Ensure both keypad and button are valid before proceeding
    if not IsValidObject(self) or not IsValidObject(indoorButton) then
        if DEBUG then
            DebugLog("Interaction ignored (keypadValid=" .. tostring(IsValidObject(self)) ..
                     ", buttonValid=" .. tostring(IsValidObject(indoorButton)) .. ")")
        end
        return
    end

    -- Verify this is the specific keypad we're targeting
    if self:GetFullName() ~= KEYPAD_FULL_NAME then
        return
    end

    -- Check if keypad has been hacked (Activated property set to true)
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

    -- Trigger the shutters by calling the button's function
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

-- Watch for keypad respawns when level streaming occurs
NotifyOnNewObject("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C", function(ConstructedObject)
    if not IsValidObject(ConstructedObject) then
        return
    end

    -- Only reconfigure if this is our specific target keypad
    if ConstructedObject:GetFullName() == KEYPAD_FULL_NAME then
        DebugLog("Target keypad found, configuring...")
        ExecuteWithDelay(1000, ConfigureObjects)
    end
end)

-- Register interaction hook (delayed to ensure Blueprint is fully loaded)
ExecuteWithDelay(1500, function()
    local success, err = pcall(function()
        RegisterHook("/Game/Blueprints/Environment/Switches/Button_Keypad.Button_Keypad_C:InteractWith_A", HandleKeypadInteraction)
    end)

    if success then
        DebugLog("Interaction hook registered successfully")
    else
        DebugLog("ERROR: Failed to register hook: " .. tostring(err))
    end
end)

DebugLog("Mod initialization started - hooks will be registered shortly")