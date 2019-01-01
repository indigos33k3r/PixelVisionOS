--[[
	Pixel Vision 8 - Debug Tool
	Copyright (C) 2016, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

-- Load in the editor framework script to access tool components
LoadScript("sb-sprites")
LoadScript("pixel-vision-os-v2")

local toolName = "Log Preview"


local pixelVisionOS = nil
local editorUI = nil

-- local fileSize = "000k"
local invalid = true

local rootDirectory = nil
-- local showLines = false
local lineWidth = 0
local totalLines = 0

function Init()

  BackgroundColor(5)

  -- Disable the back key in this tool
  EnableBackKey(false)

  -- Create an instance of the Pixel Vision OS
  pixelVisionOS = PixelVisionOS:Init()

  -- Get a reference to the Editor UI
  editorUI = pixelVisionOS.editorUI

  rootDirectory = ReadMetaData("directory", nil)

  -- Get the target file
  targetFile = ReadMetaData("file", nil)

  -- TODO this is hardcoded
  targetFile = "/Tmp/Log.txt"

  if(targetFile ~= nil) then

    -- local pathSplit = string.split(targetFile, "/")

    -- Update title with file path
    -- toolTitle = pathSplit[#pathSplit - 1] .. "/" .. pathSplit[#pathSplit]

    local menuOptions = 
    {
      -- About ID 1
      {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName) end, toolTip = "Learn about PV8."},
      {divider = true},
      {name = "Clear", action = OnClearLog, toolTip = "Clear the log file."}, -- Reset all the values
      {divider = true},
      {name = "Quit", key = Keys.Q, action = OnQuit, toolTip = "Quit the current game."}, -- Quit the current game
    }

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

    vSliderData = editorUI:CreateSlider({x = 235, y = 20, w = 10, h = 193}, "vsliderhandle", "Scroll text vertically.")
    vSliderData.onAction = OnVerticalScroll

    hSliderData = editorUI:CreateSlider({ x = 4, y = 211, w = 233, h = 10}, "hsliderhandle", "Scroll text horizontally.", true)
    hSliderData.onAction = OnHorizontalScroll

    -- Create input area
    inputAreaData = editorUI:CreateInputArea({x = 8, y = 24, w = 224, h = 184}, nil, "Click to edit the text.")
    inputAreaData.wrap = true
    inputAreaData.editable = false

    editorUI:Enable(inputAreaData, false)
    inputAreaData.disabledColorOffset = 0
    -- inputAreaData.onAction = function(text)
    --   -- print("input area updated")
    -- end

    -- TODO need to read the toggle line state from the bios

    -- showLines = ReadBiosData("ShowLinesInTextEditor") == "True" and true or false

    RefreshEditor()

    -- ResetDataValidation()
    -- pixelVisionOS:DisplayMessage(toolName .. ": This tool allows you to edit text files.", 5)
    pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

  else

    pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

    pixelVisionOS:ShowMessageModal(toolName .. " Error", "The tool could not load without a reference to a file to edit.", 160, false,
      function()
        QuitCurrentTool()
      end
    )
  end

end

function OnQuit()

  QuitCurrentTool()

end

function CalculateLineGutter()

  -- Update total
  totalLines = inputAreaData.totalLines

  -- Only resize the input field if the size doesn't match
  local newWidth = 224
  if(inputAreaData.rect.w ~= newWidth) then
    editorUI:ResizeInputArea(inputAreaData, newWidth, 184, 8, 24)
  end

end

function OnClear()
  editorUI:ChangeInputArea(inputAreaData, "")
  editorUI:InputAreaInvalidateText(inputAreaData)
end

function RefreshEditor()

  local tmpText = ReadTextFile(targetFile)

  editorUI:ChangeInputArea(inputAreaData, tmpText)

end


function OnHorizontalScroll(value)
  editorUI:InputAreaScrollTo(inputAreaData, value, inputAreaData.scrollValue.v)
end

function OnVerticalScroll(value)
  editorUI:InputAreaScrollTo(inputAreaData, inputAreaData.scrollValue.h, value)
end


function Update(timeDelta)

  -- This needs to be the first call to make sure all of the editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- Only update the tool's UI when the modal isn't active
  if(pixelVisionOS:IsModalActive() == false and targetFile ~= nil) then

    editorUI:UpdateInputArea(inputAreaData)

    if(inputAreaData.invalidText == true) then
      InvalidateData()
    end

    -- Check to see if we should show the horizontal slider
    local showVSlider = inputAreaData.totalLines > inputAreaData.height

    -- Test if we need to show or hide the slider
    if(vSliderData.enabled ~= showVSlider) then
      editorUI:Enable(vSliderData, showVSlider)
    end

    if(vSliderData.value ~= inputAreaData.scrollValue.v) then
      editorUI:ChangeSlider(vSliderData, inputAreaData.scrollValue.v, false)
    end

    -- editorUI:UpdateButton(lineBtnData)

    -- Update the slider
    editorUI:UpdateSlider(vSliderData)

    -- Check to see if we should show the vertical slider
    local showHSlider = inputAreaData.maxLineWidth > inputAreaData.width

    if(hSliderData.value ~= inputAreaData.scrollValue.h) then
      editorUI:ChangeSlider(hSliderData, inputAreaData.scrollValue.h, false)
    end

    -- Test if we need to show or hide the slider
    if(hSliderData.enabled ~= showHSlider) then
      editorUI:Enable(hSliderData, showHSlider)
    end

    -- Update the slider
    editorUI:UpdateSlider(hSliderData)

  end

end

function OnClearLog()


  pixelVisionOS:ShowMessageModal("Clear Log", "Are you sure you want to clear the log? This can't be undone.", 160, true,
    function()
      if(pixelVisionOS.messageModal.selectionValue == true) then
        -- Save changes

        ClearLog()
        RefreshEditor()

        pixelVisionOS:EnableMenuItem(3, false)

      end

    end
  )

end

function Draw()


  RedrawDisplay()

  -- The ui should be the last thing to update after your own custom draw calls
  pixelVisionOS:Draw()

end
