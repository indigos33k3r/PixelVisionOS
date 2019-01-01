--[[
	Pixel Vision 8 - New Template Script
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	This project was designed to display some basic instructions when you create
	a new tool.	Simply delete the following code and implement your own Init(),
	Update() and Draw() logic.

	Learn more about making Pixel Vision 8 games at https://www.gitbook.com/@pixelvision8
]]--

-- Load in the editor framework script to access tool components
LoadScript("sb-sprites")
LoadScript("pixel-vision-os-v2")

local toolName = "System Settings"


-- List of all the valid keys
local keyCodeMap = {
  {name = None, keyCode = 0, char = ""},
  {name = Backspace, keyCode = 8, char = "!"},
  {name = Tab, keyCode = 9, char = "@"},
  {name = Enter, keyCode = 13, char = "#"},
  -- {name = Escape, keyCode = 27, char = "$"},
  {name = Space, keyCode = 32, char = "%"},
  {name = Left, keyCode = 37, char = "^"},
  {name = Up, keyCode = 38, char = "&"},
  {name = Right, keyCode = 39, char = "*"},
  {name = Down, keyCode = 40, char = "("},
  {name = Delete, keyCode = 46, char = ")"},
  {name = Alpha0, keyCode = 48, char = "0"},
  {name = Alpha1, keyCode = 49, char = "1"},
  {name = Alpha2, keyCode = 50, char = "2"},
  {name = Alpha3, keyCode = 51, char = "3"},
  {name = Alpha4, keyCode = 52, char = "4"},
  {name = Alpha5, keyCode = 53, char = "5"},
  {name = Alpha6, keyCode = 54, char = "6"},
  {name = Alpha7, keyCode = 55, char = "7"},
  {name = Alpha8, keyCode = 56, char = "8"},
  {name = Alpha9, keyCode = 57, char = "9"},
  {name = A, keyCode = 65, char = "A"},
  {name = B, keyCode = 66, char = "B"},
  {name = C, keyCode = 67, char = "C"},
  {name = D, keyCode = 68, char = "D"},
  {name = E, keyCode = 69, char = "E"},
  {name = F, keyCode = 70, char = "F"},
  {name = G, keyCode = 71, char = "G"},
  {name = H, keyCode = 72, char = "H"},
  {name = I, keyCode = 73, char = "I"},
  {name = J, keyCode = 74, char = "J"},
  {name = K, keyCode = 75, char = "K"},
  {name = L, keyCode = 76, char = "L"},
  {name = M, keyCode = 77, char = "M"},
  {name = N, keyCode = 78, char = "N"},
  {name = O, keyCode = 79, char = "O"},
  {name = P, keyCode = 80, char = "P"},
  {name = Q, keyCode = 81, char = "Q"},
  {name = R, keyCode = 82, char = "R"},
  {name = S, keyCode = 83, char = "S"},
  {name = T, keyCode = 84, char = "T"},
  {name = U, keyCode = 85, char = "U"},
  {name = V, keyCode = 86, char = "V"},
  {name = W, keyCode = 87, char = "W"},
  {name = X, keyCode = 88, char = "X"},
  {name = Y, keyCode = 89, char = "Y"},
  {name = Z, keyCode = 90, char = "Z"},
  {name = LeftShift, keyCode = 160, char = "}"},
  {name = RightShift, keyCode = 161, char = "~"},
  {name = Semicolon, keyCode = 186, char = ";"},
  {name = Plus, keyCode = 187, char = "+"},
  {name = Comma, keyCode = 188, char = ","},
  {name = Minus, keyCode = 189, char = "-"},
  {name = Period, keyCode = 190, char = "."},
  {name = Question, keyCode = 191, char = "/"},
  {name = Tilde, keyCode = 192, char = "`"},
  {name = OpenBrackets, keyCode = 219, char = "["},
  {name = Pipe, keyCode = 220, char = "\\"},
  {name = CloseBrackets, keyCode = 221, char = "]"},
  {name = Quotes, keyCode = 222, char = "'"},
}

local pixelVisionOS = nil
local editorUI = nil

local shortcutKeys = {
  "RunGameKey",
  "ScreenshotKey",
  "RecordKey",
  "RestartKey"
}

player1Keys = {
  "Player1UpKey",
  "Player1DownKey",
  "Player1LeftKey",
  "Player1RightKey",
  "Player1SelectKey",
  "Player1StartKey",
  "Player1AKey",
  "Player1BKey"
}

player2Keys = {
  "Player2UpKey",
  "Player2DownKey",
  "Player2LeftKey",
  "Player2RightKey",
  "Player2SelectKey",
  "Player2StartKey",
  "Player2AKey",
  "Player2BKey"
}

player1Buttons = {
  "Player1UpButton",
  "Player1DownButton",
  "Player1LeftButton",
  "Player1RightButton",
  "Player1SelectButton",
  "Player1StartButton",
  "Player1AButton",
  "Player1BButton"
}

player2Buttons = {
  "Player2UpButton",
  "Player2DownButton",
  "Player2LeftButton",
  "Player2RightButton",
  "Player2SelectButton",
  "Player2StartButton",
  "Player2AButton",
  "Player2BButton",
}



-- This this is an empty game, we will the following text. We combined two sets of fonts into
-- the default.font.png. Use uppercase for larger characters and lowercase for a smaller one.
local title = "EMPTY TOOL"
local messageTxt = "This is an empty tool template. Press Ctrl + 1 to open the editor or modify the files found in your workspace game folder."

-- Container for horizontal slider data
local hSliderData = nil
local vSliderData = nil
local backBtnData = nil
local nextBtnData = nil
local muteBtnData = nil
local paginationBtnData = nil
local volumeInputData = nil
local nameInputData = nil
local scaleInputData = nil
local playSound = false
local selectedInputID = 1

local buttonTypes = {
  "Up",
  "Down",
  "Left",
  "Right",
  "A",
  "B",
  "Select",
  "Start"
}

local buttonSpriteMap = {}
buttonSpriteMap["Up"] = {spriteData = dpadup, x = 96, y = 72}
buttonSpriteMap["Down"] = {spriteData = dpaddown, x = 96, y = 72}
buttonSpriteMap["Left"] = {spriteData = dpadleft, x = 96, y = 72}
buttonSpriteMap["Right"] = {spriteData = dpadright, x = 96, y = 72}
buttonSpriteMap["A"] = {spriteData = actionbtndown, x = 154, y = 82}
buttonSpriteMap["B"] = {spriteData = actionbtndown, x = 170, y = 82}
buttonSpriteMap["Select"] = {spriteData = startbtndown, x = 124, y = 90}
buttonSpriteMap["Start"] = {spriteData = startbtndown, x = 136, y = 90}

local totalButtons = #buttonTypes

local blinkTime = 0
local blinkDelay = .1
local blinkActive = false

local SaveShortcut = 3

function InvalidateData()

  -- Only everything if it needs to be
  if(invalid == true)then
    return
  end

  pixelVisionOS:ChangeTitle(toolName .."*", "toolbaricontool")

  invalid = true

  pixelVisionOS:EnableMenuItem(SaveShortcut, true)

end

function ResetDataValidation()

  -- Only everything if it needs to be
  if(invalid == false)then
    return
  end

  pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")
  invalid = false

  pixelVisionOS:EnableMenuItem(SaveShortcut, false)

end

-- The Init() method is part of the game's lifecycle and called a game starts. We are going to
-- use this method to configure background color, ScreenBufferChip and draw a text box.
function Init()

  BackgroundColor(5)

  -- Disable the back key in this tool
  EnableBackKey(false)

  -- Create an instance of the Pixel Vision OS
  pixelVisionOS = PixelVisionOS:Init()

  -- Get a reference to the Editor UI
  editorUI = pixelVisionOS.editorUI

  local menuOptions = 
  {
    -- About ID 1
    {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName) end, toolTip = "Learn about PV8."},
    {divider = true},
    {name = "Save", action = OnSave, enabled = false, key = Keys.S, toolTip = "Save changes made to the controller mapping."}, -- Reset all the values
    {name = "Reset", action = OnReset, key = Keys.R, toolTip = "Revert controller mapping to its default value."}, -- Reset all the values
    {divider = true},
    {name = "Quit", key = Keys.Q, action = OnQuit, toolTip = "Quit the current game."}, -- Quit the current game
  }

  pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

  -- Change the title
  pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

  knobData = editorUI:CreateKnob({x = 16, y = 192, w = 24, h = 24}, "knob", "Change the volume.")
  knobData.onAction = OnValueChange
  knobData.value = Volume() / 100
  -- print( Volume())
  -- OnValueChange()
  editorUI:Enable(knobData, not Mute())


  -- Toggle Button
  muteBtnData = editorUI:CreateToggleButton({x = 40, y = 192}, "mute", "This is a toggle button.")
  muteBtnData.hitRect = {x = 40 + 2, y = 192 + 4, w = 28, h = 15}
  muteBtnData.onAction = OnMute
  muteBtnData.selected = Mute()

  scaleInputData = editorUI:CreateInputField({x = 96, y = 200, w = 8}, Scale(), "This changes the scale of the window when not in fullscreen.", "number")
  scaleInputData.min = 1
  scaleInputData.max = 4
  scaleInputData.onAction = OnChangeScale


  -- Check boxes
  checkboxGroupData = editorUI:CreateToggleGroup(7, false)
  checkboxGroupData.onAction = OnCheckbox

  local tmpCheckbox = editorUI:ToggleGroupButton(checkboxGroupData, {x = 120, y = 192, w = 8, h = 8}, "checkbox", "Toggle fullscreen mode.")
  tmpCheckbox.selected = Fullscreen()

  tmpCheckbox = editorUI:ToggleGroupButton(checkboxGroupData, {x = 120, y = 200, w = 8, h = 8}, "checkbox", "Enable the window to crop.")
  tmpCheckbox.selected = CropScreen()

  tmpCheckbox = editorUI:ToggleGroupButton(checkboxGroupData, {x = 120, y = 208, w = 8, h = 8}, "checkbox", "Stretch the display to fit the window.")
  tmpCheckbox.selected = StretchScreen()

  -- UpdateCheckBoxes()

  playerButtonGroupData = editorUI:CreateToggleGroup(true)
  playerButtonGroupData.onAction = OnPlayerSelection

  editorUI:ToggleGroupButton(playerButtonGroupData, {x = 208, y = 24, w = 8, h = 8}, "radiobutton", "Select player 1's controller map.")
  editorUI:ToggleGroupButton(playerButtonGroupData, {x = 208, y = 32, w = 8, h = 8}, "radiobutton", "Select player 2's controller map.")

  inputButtonGroupData = editorUI:CreateToggleGroup(true)
  inputButtonGroupData.onAction = OnInputSelection

  editorUI:ToggleGroupButton(inputButtonGroupData, {x = 96, y = 152, w = 8, h = 8}, "radiobutton", "This is radio button 1.")
  editorUI:ToggleGroupButton(inputButtonGroupData, {x = 144, y = 152, w = 8, h = 8}, "radiobutton", "This is radio button 2.")



  shortcutFields = {
    editorUI:CreateInputField({x = 176, y = 200, w = 8}, "", "ScreenShot"),
    editorUI:CreateInputField({x = 200, y = 200, w = 8}, "", "Record"),
    editorUI:CreateInputField({x = 224, y = 200, w = 8}, "", "Restart"),
  }

  usedShortcutKeys = {}

  for i = 1, #shortcutFields do
    local field = shortcutFields[i]
    field.type = field.toolTip

    local keyValue = ConvertKeyCodeToChar(tonumber(ReadMetaData(field.type .. "Key")))

    editorUI:ChangeInputField(field, keyValue)

    -- Save used keys
    usedShortcutKeys[field.type] = keyValue

    -- Create a new tooltip
    field.toolTip = "Remap the " .. field.type .. " key."

    field.captureInput = function()

      -- Validate the input before returning it to the input field
      return ValidateInput(field, usedShortcutKeys)

    end

    field.onAction = function(value)
      -- Save the new key map value
      RemapKey(field.type .. "Key", ConvertKeyToKeyCode(value))

      -- Let the user know the key has been saved
      pixelVisionOS:DisplayMessage("Setting '"..value.."' as the shortcut key.")

    end

  end

  inputFields = {
    editorUI:CreateInputField({x = 56, y = 80, w = 8}, "", "Up"),
    editorUI:CreateInputField({x = 56, y = 96, w = 8}, "", "Down"),
    editorUI:CreateInputField({x = 56, y = 112, w = 8}, "", "Left"),
    editorUI:CreateInputField({x = 56, y = 128, w = 8}, "", "Right"),
    editorUI:CreateInputField({x = 120, y = 120, w = 8}, "", "Select"),
    editorUI:CreateInputField({x = 144, y = 120, w = 8}, "", "Start"),
    editorUI:CreateInputField({x = 184, y = 120, w = 8}, "", "A"),
    editorUI:CreateInputField({x = 208, y = 120, w = 8}, "", "B")
  }

  -- We need to manually store values for all of the keys
  usedControllerKeys = {}

  -- Player 1 Keys
  for i = 1, #player1Keys do

    local key = player1Keys[i]

    usedControllerKeys[key] = ConvertKeyCodeToChar(tonumber(ReadMetaData(key)))

  end

  -- Player 2 Keys
  for i = 1, #player2Keys do

    local key = player2Keys[i]

    usedControllerKeys[key] = ConvertKeyCodeToChar(tonumber(ReadMetaData(key)))

  end

  -- TODO need to create a map for player 1 & 2 controller

  usedControllerButtons = {}

  for i = 1, #inputFields do
    local field = inputFields[i]
    field.type = field.toolTip

    field.toolTip = "Remap the " .. field.type .. " key."
    field.captureInput = function()

      -- TODO need to see what mode we are in and pass the correct used keys
      local usedKeys = usedControllerKeys



      return ValidateInput(field, usedKeys)

    end
    field.onAction = function(value)

      -- print("Remap", "Player", tostring(selectedPlayerID), field.type, "Key")

      -- TODO Only remap the player when we save
      -- RemapKey("Player" ..tostring(selectedPlayerID) .. field.type .. "Key", ConvertKeyToKeyCode(value))

      DrawInputSprite(field.type)

      InvalidateData()

    end

  end

  editorUI:SelectToggleButton(playerButtonGroupData, 1)

  -- RebuildUsedKeys()

end

function DrawInputSprite(type)

  -- print("DrawInputSprite", type)

  local data = buttonSpriteMap[type]

  if(data ~= nil) then
    local spriteData = data.spriteData
    DrawSprites(spriteData.spriteIDs, data.x, data.y, spriteData.width)
  end

  if(type == "Select" or type == "Start") then
    DrawSprites(startinputon.spriteIDs, type == "Select" and 126 or 138, 99, startinputon.width)
  else
    DrawBlinkSprite()
  end

end

function ValidateInput(field, useKeys)

  local key = OnCaptureKey()

  -- Check to see if the key is not empty
  if(key ~= "") then

    -- Look for douplicate keys
    if(CheckActionKeyDoups(key, useKeys) == true) then

      editorUI:EditInputField(field, false)

      -- TODO this used to show the key but it would require adding sprites to small font
      pixelVisionOS:DisplayMessage("The key is already being used.", 2)

      return ""

    end

  end

  -- If the key is valid, save a local reference to it
  useKeys[field.type] = key

  -- Return the new key to the input field
  return key
end

function CheckActionKeyDoups(key, keyMap)

  local value = false

  for k, v in pairs(keyMap) do
    -- print("Checking", k, v)

    if(key == v) then
      return true
    end

  end

  return value

end

-- Converts a key code into a char character
function ConvertKeyCodeToChar(keyCode)

  local value = -1

  for i = 1, #keyCodeMap do
    if(keyCodeMap[i].keyCode == keyCode) then
      return keyCodeMap[i].char
    end
  end

  return value

end

function ConvertKeyToKeyCode(key)

  -- print("Convert Key", key)

  local keyCode = -1

  for i = 1, #keyCodeMap do

    if(keyCodeMap[i].char == key) then
      return keyCodeMap[i].keyCode
    end

  end

  return keyCode

end

function OnCaptureKey()

  -- Show blinking light for controller
  if(blinkActive) then
    DrawBlinkSprite()
  end

  local total = #keyCodeMap

  for i = 1, total do

    -- TODO need to test to see if the keyCode is already assigned
    local key = keyCodeMap[i]

    if(Key(key.keyCode)) then
      return key.char
    end

  end

  return ""

end

function DrawBlinkSprite()
  DrawSprites(inputbuttonon.spriteIDs, 154, 62, inputbuttonon.width)
end

function OnChangeScale(value)
  Scale(tonumber(value))
end

function OnVolumeFieldUpdate(text)

  local value = tonumber(text / 100)

  -- editorUI:ChangeSlider(hSliderData, value, false)
  -- editorUI:ChangeSlider(vSliderData, value, false)
  editorUI:ChangeKnob(knobData, value, false)

end

function OnValueChange(value)

  Volume(value * 100)

  pixelVisionOS:DisplayMessage("Volume is now set to " .. tostring(value * 100) .. "%.")

  playSound = true

end

function OnCheckbox(id, value)

  -- TODO need to disable some settings depending on which mode is set
  if(id == 1) then
    Fullscreen(value)
  elseif(id == 2) then
    CropScreen(value)
  elseif(id == 3) then
    StretchScreen(value)
  end

end

function OnPlayerSelection(value)

  if(invalid == true) then

    pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have not saved your changes for this controller. Do you want to save them before switching to a different player?", 160, true,
      function()
        if(pixelVisionOS.messageModal.selectionValue == true) then
          -- Save changes
          OnSave()

        end

        -- TODO looks like there may be a race condition when switching between players here and selection is not displayed correctly from tilemap cache

        -- Quit the tool
        TriggerPlayerSelection(value)

      end
    )

  else
    -- Quit the tool
    TriggerPlayerSelection(value)
  end

end

function TriggerPlayerSelection(value)
  selectedPlayerID = value

  local message = "Player " .. value .. " was selected."

  -- Display the correct highlight state for the player label
  for i = 1, 2 do

    local spriteData = _G["player"..i..(i == value and "selected" or "up")]

    DrawSprites(spriteData.spriteIDs, 27, 2 + i, spriteData.width, false, false, DrawMode.Tile)
  end

  -- Update the controller number
  local spriteData = _G["controller"..value]

  DrawSprites(spriteData.spriteIDs, 16, 7, spriteData.width, false, false, DrawMode.Tile)

  -- Reset the input selection
  editorUI:SelectToggleButton(inputButtonGroupData, selectedInputID, false)

  -- Manually force the input selection to redraw all the input fields
  OnInputSelection(selectedInputID)

end

function OnInputSelection(value)

  if(invalid == true) then

    pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have not saved your changes for this controller. Do you want to save them before switching to a different input mode?", 160, true,
      function()
        if(pixelVisionOS.messageModal.selectionValue == true) then
          -- Save changes
          OnSave()

        end

        -- TODO looks like there may be a race condition when switching between players here and selection is not displayed correctly from tilemap cache

        -- Quit the tool
        TriggerInputSelection(value)

      end
    )

  else
    -- Quit the tool
    TriggerInputSelection(value)
  end

end

function TriggerInputSelection(value)
  -- print("On Input Selected")

  selectedInputID = value

  local pos = {13, 19}
  -- Display the correct highlight state for the player label
  for i = 1, 2 do

    local spriteName = i == 1 and "keyboard" or "controller"
    local spriteData = _G[spriteName..(i == value and "selected" or "up")]

    DrawSprites(spriteData.spriteIDs, pos[i], 19, spriteData.width, false, false, DrawMode.Tile)
  end

  local message = "Input mode " .. value .. " was selected."

  local inputMap = _G["player"..selectedPlayerID.."Keys"]

  for i = 1, #inputMap do
    local field = inputFields[i]
    -- print("Display Input Player " .. selectedPlayerID .. " map " .. inputMap[i] .. " value " .. ReadMetaData(inputMap[i]))
    editorUI:ChangeInputField(field, ConvertKeyCodeToChar(tonumber(ReadMetaData(inputMap[i]))), false)
  end

  -- Update the input fields with all the correct values
  -- upInputData
  -- downInputData
  -- leftInputData
  -- rightInputData
  -- selectInputData
  -- startInputData
  -- aInputData
  -- bInputData
end

-- function UpdatePickerButtons(text)
--
--   print("UpdatePickerButtons", text)
--
--   if(text == "") then
--     text = "0"
--   end
--   -- convert the text value to a number
--   local value = tonumber(text)
--
--   -- update buttons
--   editorUI:Enable(backBtnData, value > scaleInputData.min)
--   editorUI:Enable(nextBtnData, value < scaleInputData.max)
--
-- end

function OnMute(value)

  Mute(value)
  -- Enable or disable the volume input field and sliders based on the mute value
  -- editorUI:Enable(volumeInputData, not value)
  -- editorUI:Enable(hSliderData, not value)
  -- editorUI:Enable(vSliderData, not value)
  editorUI:Enable(knobData, not value)
end

function OnPage(value)
  pixelVisionOS:DisplayMessage("Page " .. value .. " selected")
end

-- The Update() method is part of the game's life cycle. The engine calls Update() on every frame
-- before the Draw() method. It accepts one argument, timeDelta, which is the difference in
-- milliseconds since the last frame.
function Update(timeDelta)

  -- This needs to be the first call to make sure all of the OS and editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- Only update the tool's UI when the modal isn't active
  if(pixelVisionOS:IsModalActive() == false) then

    editorUI:UpdateKnob(knobData)
    --
    -- Update buttons
    editorUI:UpdateButton(muteBtnData)


    -- Update toggle groups
    editorUI:UpdateToggleGroup(checkboxGroupData)
    editorUI:UpdateToggleGroup(playerButtonGroupData)
    editorUI:UpdateToggleGroup(inputButtonGroupData)

    editorUI:UpdateInputField(scaleInputData)

    for i = 1, #shortcutFields do
      editorUI:UpdateInputField(shortcutFields[i])
    end

    for i = 1, #inputFields do
      editorUI:UpdateInputField(inputFields[i])
    end

    if(editorUI.collisionManager.mouseDown == false and playSound == true) then
      PlayRawSound("0,1,,.2,,.2,.3,.1266,,,,,,,,,,,,,,,,,,1,,,,,,")
      playSound = false
      -- print("Play sound")
    end

    -- Loop through all of the inputs and see if a controller button should be pressed

    -- See if we are in keyboard mode
    if(selectedInputID == 1) then

      -- Loop through each of the input fields
      for i = 1, #inputFields do

        -- Get the field and its value
        local field = inputFields[i]
        local value = field.text

        -- Test if the input field's map value is down
        if(Key(ConvertKeyToKeyCode(value), InputState.Down)) then

          -- Update the sprite
          DrawInputSprite(field.type)

        end

      end

      -- If we are not in keyboard mode, it will switch to the controller mode
    else

      -- Loop through each of the buttons
      for i = 1, totalButtons do

        -- Go through each button and see if it is down for the selected player
        if(Button(i - 1, InputState.Down, selectedPlayerID - 1)) then

          -- Draw the correct sprite
          DrawInputSprite(buttonTypes[i])

        end

      end

    end

    blinkTime = blinkTime + timeDelta

    if(blinkTime > blinkDelay) then
      blinkTime = 0
      blinkActive = not blinkActive
    end

    -- Modify mute buttons if global value changes
    local newMuteValue = Mute()

    if(lastMuteValue ~= newMuteValue) then
      lastMuteValue = newMuteValue
      editorUI:Enable(knobData, not lastMuteValue)
      editorUI:ToggleButton(muteBtnData, lastMuteValue, false)
      editorUI:ChangeKnob(knobData, Volume() / 100, false)
    end

  end

end

-- The Draw() method is part of the game's life cycle. It is called after Update() and is where
-- all of our draw calls should go. We'll be using this to render sprites to the display.
function Draw()

  -- We can use the RedrawDisplay() method to clear the screen and redraw the tilemap in a
  -- single call.
  RedrawDisplay()

  -- The UI should be the last thing to draw after your own custom draw calls
  pixelVisionOS:Draw()

end

function OnSave()

  -- TODO loop through all of the input fields and make sure they are saved to the bios

  for i = 1, #inputFields do

    local field = inputFields[i]
    local value = field.text
    RemapKey("Player" ..tostring(selectedPlayerID) .. field.type .. "Key", ConvertKeyToKeyCode(value))
    --
    -- print("Save", tostring(selectedPlayerID) .. field.type .. "Key", ConvertKeyToKeyCode(value))
  end

  ResetDataValidation()

end

function OnReset()

  -- TODO Loop through all the keys and reset everything to the default values

end

function OnQuit()

  if(invalid == true) then

    pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have unsaved changes. Do you want to save your work before you quit?", 160, true,
      function()
        if(pixelVisionOS.messageModal.selectionValue == true) then
          -- Save changes
          OnSave()

        end

        -- Quit the tool
        QuitCurrentTool()

      end
    )

  else
    -- Quit the tool
    QuitCurrentTool()
  end

end
