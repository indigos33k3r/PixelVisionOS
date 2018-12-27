--[[
	Pixel Vision 8 - SFX Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

-- API Bridge
LoadScript("sb-sprites")
LoadScript("pixel-vision-os-v2")

local toolName = "Sound Editor"
local toolVersion = "v2.0"

local success = false
local playSound = false
local originalSounds = {}
local soundHistory = {}


local SoundProps = {
  CompressionAmount = 7,
  ChangeRepeat = 16,
  ChangeAmount = 17,
  ChangeSpeed = 18,
  ChangeAmount2 = 19,
  ChangeSpeed2 = 20,
  BitCrush = 31,
  BitCrushSpeed = 32
}

local knobData = {

  {name = "Volume", x = 40, y = 88, propID = 2, toolTip = "Volume is set to "},

  -- Envelope
  {name = "AttackTime", x = 80, y = 88, propID = 3, toolTip = "Attack Time is set to "},
  {name = "SustainTime", x = 104, y = 88, propID = 4, toolTip = "Sustain Time is set to "},
  {name = "SustainPunch", x = 128, y = 88, propID = 5, toolTip = "Sustain Punch is set to "},
  {name = "DecayTime", x = 152, y = 88, propID = 6, toolTip = "Decay Time is set to "},

  -- Frequency
  {name = "StartFrequency", x = 192, y = 88, propID = 8, toolTip = "Start Frequency is set to "},
  {name = "MinFrequency", x = 216, y = 88, propID = 9, toolTip = "Minimum Frequency is set to "},

  -- Slide
  {name = "Slide", x = 16, y = 128, propID = 10, toolTip = "Slide is set to "},
  {name = "DeltaSlide", x = 40, y = 128, propID = 11, toolTip = "Delta Slide is set to "},

  -- Vibrato
  {name = "VibratoDepth", x = 72, y = 128, propID = 12, toolTip = "Vibrato Depth is set to "},
  {name = "VibratoSpeed", x = 96, y = 128, propID = 13, toolTip = "Vibrato Speed is set to "},

  -- Harmonics
  {name = "OverTones", x = 128, y = 128, propID = 14, toolTip = "Over Tones is set to "},
  {name = "OverTonesFalloff", x = 152, y = 128, propID = 15, toolTip = "Over Tones Falloff is set to "},

  -- Square Wave
  {name = "SquareDuty", x = 192, y = 128, propID = 21, toolTip = "Square Duty is set to "},
  {name = "DutySweep", x = 216, y = 128, propID = 22, toolTip = "Duty Sweep is set to "},

  -- Phaser
  {name = "PhaserOffset", x = 16, y = 168, propID = 24, toolTip = "Phaser Offset is set to "},
  {name = "PhaserSweep", x = 40, y = 168, propID = 25, toolTip = "Phaser Sweep is set to "},

  -- Repeat
  {name = "RepeatSpeed", x = 72, y = 168, propID = 23, toolTip = "Repeat Speed is set to "},

  -- LP Filter
  {name = "LPFilterCutoff", x = 104, y = 168, propID = 26, toolTip = "LP Filter Cutoff is set to "},
  {name = "LPFilterCutoffSweep", x = 128, y = 168, propID = 27, toolTip = "LP Filter Cutoff Sweep is set to "},
  {name = "LPFilterResonance", x = 152, y = 168, propID = 28, toolTip = "LP Filter Resonance is set to "},

  -- HP Filter
  {name = HPFilterCutoff, x = 192, y = 168, propID = 29, toolTip = "HP Filter Cutoff is set to "},
  {name = HPFilterCutoffSweep, x = 216, y = 168, propID = 30, toolTip = "HP Filter Cutoff Sweep is set to "},

}

local sfxButtonData = {
  {name = "pickup", spriteName = "sfxbutton1", x = 8, y = 40, toolTip = "Create a randomized 'pickup' or coin sound effect."},
  {name = "explosion", spriteName = "sfxbutton2", x = 24, y = 40, toolTip = "Create a randomized 'explosion' sound effect."},
  {name = "powerup", spriteName = "sfxbutton3", x = 40, y = 40, toolTip = "Create a randomized 'power-up' sound effect."},
  {name = "shoot", spriteName = "sfxbutton4", x = 56, y = 40, toolTip = "Create a randomized 'laser' or 'shoot' sound effect."},
  {name = "jump", spriteName = "sfxbutton5", x = 72, y = 40, toolTip = "Create a randomized 'jump' sound effect."},
  {name = "hurt", spriteName = "sfxbutton6", x = 88, y = 40, toolTip = "Create a randomized 'hit' or 'hurt' sound effect."},
  {name = "select", spriteName = "sfxbutton7", x = 104, y = 40, toolTip = "Create a randomized 'blip' or 'select' sound effect."},
  {name = "random", spriteName = "sfxbutton8", x = 120, y = 40, toolTip = "Create a completely random sound effect."},
  {name = "melody", spriteName = "instrumentbutton1", x = 8, y = 56, toolTip = "Create a 'melody' instrument sound effect."},
  {name = "harmony", spriteName = "instrumentbutton2", x = 24, y = 56, toolTip = "Create a 'harmony' instrument sound effect."},
  {name = "bass", spriteName = "instrumentbutton3", x = 40, y = 56, toolTip = "Create a 'bass' instrument sound effect."},
  {name = "pad", spriteName = "instrumentbutton4", x = 56, y = 56, toolTip = "Create a 'pad' instrument sound effect."},
  {name = "lead", spriteName = "instrumentbutton5", x = 72, y = 56, toolTip = "Create a 'lead' instrument sound effect."},
  {name = "drums", spriteName = "instrumentbutton6", x = 88, y = 56, toolTip = "Create a 'drums' instrument sound effect."},
  {name = "snare", spriteName = "instrumentbutton7", x = 104, y = 56, toolTip = "Create a 'snare' instrument sound effect."},
  {name = "kick", spriteName = "instrumentbutton8", x = 120, y = 56, toolTip = "Create a 'kick' instrument sound effect."}
}

local waveButtonData = {
  {name = "Template1", spriteName = "wavebutton1", x = 120, y = 200, waveID = 4, toolTip = "Wave type triangle."},
  {name = "Template1", spriteName = "wavebutton2", x = 152, y = 200, waveID = 0, toolTip = "Wave type square."},
  {name = "Template1", spriteName = "wavebutton3", x = 184, y = 200, waveID = 1, toolTip = "Wave type sawtooth."},
  {name = "Template1", spriteName = "wavebutton4", x = 216, y = 200, waveID = 3, toolTip = "Wave type noise"},
}

local controlButtonData = {
  {name = "Play", spriteName = "playbutton", x = 8, y = 16, toolTip = "Play the current sound.", action = function() OnPlaySound() end},
  {name = "Stop", spriteName = "stopbutton", x = 24, y = 16, toolTip = "Stop the currently playing sound.", action = function() OnStopSound() end},
  {name = "Undo", spriteName = "undobutton", x = 48, y = 16, toolTip = "Undo the last SFX value change.", action = function() OnHistoryBack() end},
  {name = "Mutate", spriteName = "mutatebutton", x = 64, y = 16, toolTip = "Undo the last SFX value change.", action = function() OnMutate() end},
  {name = "Redo", spriteName = "redobutton", x = 80, y = 16, toolTip = "Redo the last SFX value change.", action = function() OnHistoryNext() end},
}

local currentID = 0

function InvalidateData()

  -- Only everything if it needs to be
  if(invalid == true)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle .."*", "toolbariconfile")
  -- pixelVisionOS:EnableActionButton(1, true)
  -- pixelVisionOS:EnableActionButtonTwoStep(2, true)

  pixelVisionOS:EnableMenuItem(4, true)

  invalid = true

end

function ResetDataValidation()

  -- Only everything if it needs to be
  if(invalid == false)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle, "toolbariconfile")
  invalid = false

  pixelVisionOS:EnableMenuItem(4, false)
  -- pixelVisionOS:EnableActionButton(1, false)
  -- pixelVisionOS:EnableActionButtonTwoStep(2, false)
  -- editorUI:EnableActionButton(3, false)
end

function Init()

  BackgroundColor(22)

  -- Disable the back key in this tool
  EnableBackKey(false)

  -- Create an instance of the Pixel Vision OS
  pixelVisionOS = PixelVisionOS:Init()

  -- Get a reference to the Editor UI
  editorUI = pixelVisionOS.editorUI

  rootDirectory = ReadMetaData("directory", nil)

  if(rootDirectory ~= nil) then

    -- Load only the game data we really need
    success = gameEditor.Load(rootDirectory, {SaveFlags.System, SaveFlags.Sounds})

  end
  --
  -- -- TODO For testing, we need a path
  -- -- rootDirectory = "/Workspace/Games/SFXTool/"
  --
  -- if(rootDirectory == nil) then
  --
  --   -- Set the tool name with an error message
  --   pixelVisionOS:ChangeTitle(toolName .. " - Error Loading", "toolbariconfile")
  --
  --   -- Display an error that not root path was found
  --   pixelVisionOS:DisplayMessage("Error loading: Could not find a sound file to load.", 0)
  --
  --   -- Exit out of the initlization
  --   return
  --
  -- end

  -- success = gameEditor.Load(rootDirectory, {SaveFlags.System, SaveFlags.Sounds})

  if(success == true) then

    -- TODO need to display an error here if we can't load above

    local pathSplit = string.split(rootDirectory, "/")

    -- Update title with file path
    toolTitle = pathSplit[#pathSplit] .. "/sounds.json"

    -- Get the game name we are editing
    -- pixelVisionOS:ChangeTitle(toolTitle)

    local menuOptions = 
    {
      -- About ID 1
      {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName .. " " .. toolVersion) end, toolTip = "Learn about PV8."},
      {divider = true},
      {name = "New", action = OnNewSound, key = Keys.N, toolTip = "Revert the sound to empty."}, -- Reset all the values
      {name = "Save", action = OnSave, key = Keys.S, toolTip = "Save changes made to the sound.json file."}, -- Reset all the values
      {name = "Export", action = nil, key = Keys.E, enabled = false, toolTip = "Create a wav for the current SFX file."}, -- Reset all the values

      {name = "Revert", action = nil, key = Keys.R, enabled = false, toolTip = "Revert the sounds.json file to its previous state."}, -- Reset all the values
      {divider = true},
      {name = "Copy", action = OnCopySound, key = Keys.C, toolTip = "Copy the currently selected sound."}, -- Reset all the values
      {name = "Paste", action = OnPasteSound, key = Keys.V, enabled = false, toolTip = "Paste the last copied sound."}, -- Reset all the values

      {divider = true},
      {name = "Quit", key = Keys.Q, action = function() QuitCurrentTool() end, toolTip = "Quit the current game."}, -- Quit the current game
    }

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

    -- Get the total number of songs
    totalSounds = gameEditor:TotalSounds()
    totalChannels = gameEditor:TotalChannels()

    -- TODO need to replace this with the new number stepper component

    -- Picker Back
    backBtnData = editorUI:CreateButton({x = 200, y = 16}, "stepperback", "Previous sound.")
    backBtnData.onAction = OnPickerBack

    -- Picker Next
    nextBtnData = editorUI:CreateButton({x = 232, y = 16}, "steppernext", "Next sound.")
    nextBtnData.onAction = OnPickerNext

    -- SFX ID Field
    soundIDFieldData = editorUI:CreateInputField({x = 216, y = 24, w = 16}, "0", "Sound ID value.", "number")
    soundIDFieldData.min = 0
    soundIDFieldData.max = totalSounds - 1
    soundIDFieldData.onAction = OnChangeSoundID

    songNameFieldData = editorUI:CreateInputField({x = 104, y = 24, w = 88}, "Untitled", "Change the label of the selected sound.", "name")
    songNameFieldData.onAction = OnChangeName

    -- Create buttons


    totalKnobs = #knobData

    for i = 1, totalKnobs do

      local data = knobData[i]

      data.knobUI = editorUI:CreateKnob({x = data.x, y = data.y, w = 24, h = 24}, "knob", "Change the volume.")
      data.knobUI.type = data.name
      data.knobUI.onAction = function(value)

        local type = data.name
        local propID = data.propID

        -- local percentString = string.lpad(tostring(value * 100), 3, "0") .. "%"

        UpdateLoadedSFX(propID, value)

        UpdateKnobTooltip(data, value)

        -- data.knobUI.toolTip = "This value is " .. percentString .. "."
        -- pixelVisionOS:DisplayMessage("This value is now set to " .. percentString .. ".")

      end
      -- TODO need an action
      -- TODO need to get the default value

    end

    totalSFXButtons = #sfxButtonData

    for i = 1, totalSFXButtons do

      local data = sfxButtonData[i]

      -- TODO need to build sprite tables for each state
      data.buttonUI = editorUI:CreateButton({x = data.x, y = data.y}, data.spriteName, data.toolTip)
      data.buttonUI.onAction = function()
        print("Click")
        OnSFXAction(data.name)
      end

    end


    waveGroupData = editorUI:CreateToggleGroup(true)
    waveGroupData.onAction = function(value)
      print("Select Wave Button", value)
      OnChangeWave(value)
      --TODO refresh wave buttons
      -- TODO save wave data
    end

    totalWaveButtons = #waveButtonData

    for i = 1, totalWaveButtons do

      local data = waveButtonData[i]

      -- TODO need to build sprite tables for each state
      editorUI:ToggleGroupButton(waveGroupData, {x = data.x, y = data.y}, data.spriteName, data.toolTip)

    end

    totalControlButtonData = #controlButtonData

    for i = 1, totalControlButtonData do

      local data = controlButtonData[i]

      -- TODO need to build sprite tables for each state
      data.buttonUI = editorUI:CreateButton({x = data.x, y = data.y}, data.spriteName, data.toolTip)
      data.buttonUI.onAction = data.action

    end

    -- Look to see if there is a saved ID

    if(SessionID() == ReadSaveData("sessionID", "") and rootDirectory == ReadSaveData("rootDirectory", "")) then
      currentID = tonumber(ReadSaveData("currentID", "0"))
    end

    LoadSound(currentID)

    ResetDataValidation()

    pixelVisionOS:DisplayMessage(toolName..": Create and manage your game's sound effects.", 5)

  else

    -- Patch background when loading fails

    -- Left panel
    DrawRect(104, 24, 88, 8, 0, DrawMode.TilemapCache)

    DrawRect(214, 18, 25, 19, BackgroundColor(), DrawMode.TilemapCache)



    pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

    pixelVisionOS:ShowMessageModal(toolName .. " Error", "The tool could not load without a reference to a file to edit.", 160, false,
      function()
        QuitCurrentTool()
      end
    )

  end

end

function UpdateLoadedSFX(propID, value)

  soundData[propID] = tostring(value)

  -- TODO save sound change
  -- TODO play sound change



  playSound = true
  -- OnPlaySound()

end

function OnChangeWave(value)

  -- TODO need to
  UpdateLoadedSFX(1, waveButtonData[value].waveID)

  UpdateWaveButtons()
end

function OnSFXAction(name)

  print("OnSFX", name)

  if(name == "pickup") then
    OnSoundTemplatePress(1)
  elseif(name == "explosion") then
    OnSoundTemplatePress(3)
  elseif(name == "powerup") then
    OnSoundTemplatePress(4)
  elseif(name == "shoot") then
    OnSoundTemplatePress(2)
  elseif(name == "jump") then
    OnSoundTemplatePress(6)
  elseif(name == "hurt") then
    OnSoundTemplatePress(5)
  elseif(name == "select") then
    OnSoundTemplatePress(7)
  elseif(name == "random") then
    OnSoundTemplatePress(8)
  elseif(name == "melody") then
    OnInstrumentTemplatePress(1)
  elseif(name == "harmony") then
    OnInstrumentTemplatePress(2)
  elseif(name == "bass") then
    OnInstrumentTemplatePress(3)
  elseif(name == "drums") then
    OnInstrumentTemplatePress(4)
  elseif(name == "lead") then
    OnInstrumentTemplatePress(5)
  elseif(name == "pad") then
    OnInstrumentTemplatePress(6)
  elseif(name == "snare") then
    OnInstrumentTemplatePress(7)
  elseif(name == "kick") then
    OnInstrumentTemplatePress(8)
  end


end

function Update(timeDelta)

  -- This needs to be the first call to make sure all of the editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- Only update the tool's UI when the modal isn't active
  if(pixelVisionOS:IsModalActive() == false) then
    -- If the tool didn't load, don't display any of the UI
    if(success == false) then
      return
    end
    editorUI:UpdateButton(backBtnData)
    editorUI:UpdateButton(nextBtnData)

    -- editorUI:UpdateToggleGroup(paginationBtnData)
    -- editorUI:UpdateToggleGroup(modeToggleGroupData)
    editorUI:UpdateInputField(soundIDFieldData)
    editorUI:UpdateInputField(songNameFieldData)

    for i = 1, totalKnobs do

      local data = knobData[i].knobUI

      -- TODO go through and make sure the value is correct, then update
      editorUI:UpdateKnob(data)

    end

    for i = 1, totalSFXButtons do

      local data = sfxButtonData[i].buttonUI

      editorUI:UpdateButton(data)

    end

    editorUI:UpdateToggleGroup(waveGroupData)

    for i = 1, totalControlButtonData do

      local data = controlButtonData[i].buttonUI

      editorUI:UpdateButton(data)

    end

    -- TODO this is not working
    local playing = gameEditor:IsChannelPlaying(0)
    if(playing) then
      print("Channel Playing", playing)
    end

    -- Only play sounds when the mouse is not down
    if(editorUI.collisionManager.mouseDown == false and playSound == true) then
      playSound = false
      ApplySoundChanges()
    end

  end

end

function ApplySoundChanges(autoPlay)

  -- Save sound changes
  local settingsString = ""
  local total = #soundData

  for i = 1, total do
    local value = soundData[i]
    if(value ~= "" or value ~= nil) then
      settingsString = settingsString .. soundData[i]
    end
    if(i <= total) then
      settingsString = settingsString .. ","
    end
  end

  local id = CurrentSoundID()
  gameEditor:Sound(id, settingsString)
  InvalidateData()

  UpdateHistory(soundHistory)

  if(autoPlay ~= false) then
    OnPlaySound()
  end

end

function UpdateHistory(settingsString)

  -- TODO need to see where the historyPos is and remove any values after that index
  -- TODO need to see what the total history is and remove values from the beginning of the list to make room for the new setting value

  -- Insert the settingsString at the end of the list
  table.insert(soundHistory, settingsString)

  -- Update the history position to the end of the list
  historyPos = #soundHistory

  print("Total History", historyPos)

  UpdateHistoryButtons()

end

local historyPos = 1

function OnHistoryBack()
  -- if(historyPos > 1) then
  OnPageChange(historyPos - 1)
  -- end

end

function OnHistoryNext()
  -- if(historyPos < #soundHistory) then
  OnPageChange(historyPos + 1)
  -- end
end

function OnRestoreSoundHistory(value)

  if(historyPos < 1) then
    historyPos = 1
  elseif(historyPos > #soundHistory) then
    historyPos = #soundHistory
  end

  UpdateHistoryButtons()

end

function UpdateHistoryButtons()

  editorUI:Enable(controlButtonData[3].buttonUI, historyPos < #soundHistory and historyPos > 1)
  editorUI:Enable(controlButtonData[5].buttonUI, historyPos ~= #soundHistory)

end

function Draw()

  -- Copy over the screen buffer
  RedrawDisplay()

  pixelVisionOS:Draw()

end

function OnSave()

  -- This will save the system data, the colors and color-map
  gameEditor:Save(rootDirectory, {SaveFlags.System, SaveFlags.Sounds})

  -- Display a message that everything was saved
  pixelVisionOS:DisplayMessage("You're changes have been saved.", 5)

  -- Clear the validation
  ResetDataValidation()

  -- Clear the sound cache
  originalSounds = {}

end

function OnPage(value)
  activePage = activePanel[value]
  activePage:Open()
end

function CurrentSoundID()
  return tonumber(soundIDFieldData.text)
end

function OnSoundTemplatePress(value)

  gameEditor:GenerateSound(CurrentSoundID(), value)
  gameEditor:PlaySound(CurrentSoundID())

  local id = CurrentSoundID()

  -- Reload the sound data
  LoadSound(id, false)

  InvalidateData()
end

local playFlag = true
local playDelay = .2
local playTime = 0

function OnPlaySound()
  -- print("Play Sound")
  gameEditor:StopSound()
  gameEditor:PlaySound(CurrentSoundID())
end

function OnInstrumentTemplatePress(value)

  local template = nil

  if(value == 1) then
    -- Melody
    template = "0,.5,,.2,,.2,.3,.1266,,,,,,,,,,,,,,,,,,1,,,,,,"
  elseif(value == 2) then
    -- Harmony
    template = "0,.5,,.01,,.509,.3,.1266,,,,,,,,,,,,,.31,,,,,1,,,.1,,,";

  elseif(value == 3) then
    -- Bass
    template = "4,1,,.01,,.509,.3,.1266,,,,,,,,,,,,,.31,,,,,1,,,.1,,,";

  elseif(value == 4) then
    -- Drums
    template = "3,.5,,.01,,.209,.1,.1668,,,,,,,,,,,,,.31,,,,,.3,,,.1,,,-.1";

  elseif(value == 5) then
    -- Lead
    template = "4,.5,.6,.01,,.609,.3,.1347,,,,,.2,,,,,,,,.31,,,,,1,,,.1,,,";

  elseif(value == 6) then
    -- Pad
    template = "4,.5,.5706,.4763,.0767,.8052,.3043,.1266,,,-.002,-.6654,.1035,.5323,.6592,.5553,.2062,-.2339,-.3279,.6005,-.4241,-.0038,.8698,-.0032,,.6377,.1076,-.6659,.0221,.0164,.4068,-.3421";

  elseif(value == 7) then
    -- Snare
    template = "3,.5,.032,.11,.6905,.4,.1015,.1668,.0412,-.2434,.0259,.1296,.4162,.7,1,.2053,.069,.7284,-.2346,.065,.5,-.213,.0969,-.1699,.8019,.1452,-.0715,.3,.1509,.9632,.4123,-.3067";

  elseif(value == 8) then
    -- Kick
    template = "4,.6,,.2981,.1079,.1122,.0225,.1826,.0583,-.2287,.1341,.3666,.0704,.0258,.1558,.0187,.1626,.2816,-.0543,.3192,.0642,.3733,.2103,-.3137,-.3065,.8693,-.3045,.4969,.0218,-.015,.1222,.0003";

  end

  if(template ~= nil) then
    UpdateSound(template)
  end

end

function UpdateSound(settings, autoPlay)
  local id = CurrentSoundID()

  gameEditor:Sound(id, settings)

  if(autoPlay ~= false) then
    gameEditor:PlaySound(CurrentSoundID())
  end

  -- Reload the sound data
  LoadSound(id, false)


  InvalidateData()

end

function OnChangeSoundID(text)

  -- convert the text value to a number
  local value = tonumber(text)

  -- update buttons
  editorUI:Enable(backBtnData, value > soundIDFieldData.min)
  editorUI:Enable(nextBtnData, value < soundIDFieldData.max)

  -- Load the sound into the editor
  LoadSound(value)

end

function LoadSound(value, clearHistory)

  currentID = value

  -- Load the current sounds string data so we can edit it
  soundData = {}

  local data = gameEditor:Sound(value)

  if(originalSounds[value] == nil) then
    -- Make a copy of the sound
    originalSounds[value] = data
  end

  local tmpValue = ""

  for i = 1, #data do
    local c = data:sub(i, i)

    if(c == ",") then

      table.insert(soundData, tmpValue)
      tmpValue = ""
    else
      tmpValue = tmpValue .. c
    end

    -- do something with c
  end

  Refresh()

  local label = gameEditor:SoundLabel(value)

  editorUI:ChangeInputField(songNameFieldData, label, false)
  editorUI:ChangeInputField(soundIDFieldData, currentID, false)

  if(clearHistory ~= false) then
    historyPos = 1
    soundHistory = {}
    OnRestoreSoundHistory(1)
  end

  UpdateHistory(data)

  -- TODO need to refresh the editor panels
end

function Refresh()

  for i = 1, totalKnobs do
    local knob = knobData[i]

    local value = soundData[knob.propID] ~= "" and tonumber(soundData[knob.propID]) or 0

    UpdateKnobTooltip(knob, value)

    -- print(knob.name, knob.knobUI, knob.propID, value)
    editorUI:ChangeKnob(knob.knobUI, math.abs(value), false)

  end

  UpdateWaveButtons()

end

function UpdateKnobTooltip(knobData, value)

  local percentString = string.lpad(tostring(value * 100), 3, "0") .. "%"

  knobData.knobUI.toolTip = knobData.toolTip .. percentString .. "."

end

function UpdateWaveButtons()

  local waveID = soundData[1]

  local tmpID = 1

  for i = 1, totalWaveButtons do
    if(tonumber(waveID) == waveButtonData[i].waveID) then
      tmpID = i
      break
    end
  end

  EnableWavePanel(tmpID == 2)

  editorUI:SelectToggleButton(waveGroupData, tmpID, false)

end

function EnableWavePanel(value)

  local spriteData = value == true and squarewavepanelenabled or squarewavepaneldisabled

  if(spriteData ~= nil) then
    DrawSprites(spriteData.spriteIDs, 23, 14, spriteData.width, false, false, DrawMode.Tile)
  end

  for i = 1, totalKnobs do

    local tmpKnob = knobData[i]
    if(tmpKnob.name == "SquareDuty" or tmpKnob.name == "DutySweep") then
      editorUI:Enable(tmpKnob.knobUI, value)
    end

  end

end


function OnRevertSound()

  local id = CurrentSoundID()

  if(originalSounds[id] ~= nil) then

    UpdateSound(originalSounds[id])

  end

end

function OnChangeName(value)

  local id = CurrentSoundID()

  local label = gameEditor:SoundLabel(id, value)

  InvalidateData()

end

function OnPickerBack()
  local value = tonumber(soundIDFieldData.text)
  OnPageChange(value - 1)

end

function OnPickerNext()
  local value = tonumber(soundIDFieldData.text)
  OnPageChange(value + 1)
end

function OnPageChange(value)

  if(value < soundIDFieldData.min) then
    value = soundIDFieldData.min

  elseif(value > soundIDFieldData.max) then
    value = soundIDFieldData.max
  end

  local stringValue = tostring(value)

  if(soundIDFieldData.text ~= stringValue) then
    editorUI:ChangeInputField(soundIDFieldData, stringValue)
  end

  editorUI:Enable(backBtnData, value > soundIDFieldData.min)
  editorUI:Enable(nextBtnData, value < soundIDFieldData.max)

end

function OnNewSound()
  gameEditor:NewSound(CurrentSoundID())

  InvalidateData()
end

local soundClipboard = nil

function OnCopySound()
  local id = CurrentSoundID()

  soundClipboard = {name = songNameFieldData.text, data = gameEditor:Sound(id)}

  pixelVisionOS:DisplayMessage("Sound '".. id .. "' has been copied.", 5)

  pixelVisionOS:EnableMenuItem(9, true)
end

-- function SetClipboard(value)
--
--   clipboard = value
--
--   editorUI:Enable(pasteBtnData, clipboard ~= nil)
--
-- end



function OnPasteSound()
  local id = CurrentSoundID()
  gameEditor:SoundLabel(id, soundClipboard.name)
  gameEditor:Sound(id, soundClipboard.data)

  pixelVisionOS:DisplayMessage("New data has been pasted into sound '".. id .. "'.", 5)

  LoadSound(id)

  soundClipboard = nil

  InvalidateData()

  OnPlaySound()

  pixelVisionOS:EnableMenuItem(9, false)

end

function OnPlaySound()

  id = CurrentSoundID()

  gameEditor:PlaySound(id)
end

function OnStopSound()

  gameEditor:StopSound()

end

function OnMutate()
  id = CurrentSoundID()

  gameEditor:Mutate(id)
  gameEditor:PlaySound(id)

  LoadSound(id)

  InvalidateData()
end

function Shutdown()

  -- Save the current session ID
  WriteSaveData("sessionID", SessionID())

  WriteSaveData("rootDirectory", rootDirectory)

  -- Make sure we don't save paths in the tmp directory
  WriteSaveData("currentID", currentID)


end
