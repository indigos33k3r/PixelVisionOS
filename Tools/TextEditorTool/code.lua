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

local toolName = "Text Editor"


local pixelVisionOS = nil
local editorUI = nil

-- local fileSize = "000k"
local invalid = true

local rootDirectory = nil
local showLines = false
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

  -- targetFile = "/Workspace/Games/GGSystem/code.lua"

  if(targetFile ~= nil) then

    local pathSplit = string.split(targetFile, "/")

    -- Update title with file path
    toolTitle = pathSplit[#pathSplit - 1] .. "/" .. pathSplit[#pathSplit]

    local menuOptions = 
    {
      -- About ID 1
      {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName) end, toolTip = "Learn about PV8."},
      {divider = true},
      {name = "New", action = OnNewSound, enabled = false, key = Keys.N, toolTip = "Create a new text file."}, -- Reset all the values
      {name = "Save", action = OnSave, enabled = false, key = Keys.S, toolTip = "Save changes made to the text file."}, -- Reset all the values
      {name = "Revert", action = nil, enabled = false, key = Keys.R, toolTip = "Revert the text file to its previous state."}, -- Reset all the values
      {divider = true},
      {name = "Cut", action = OnCopyColor, enabled = false, key = Keys.X, toolTip = "Cut the currently selected text."}, -- Reset all the values
      {name = "Copy", action = OnCopyColor, enabled = false, key = Keys.C, toolTip = "Copy the currently selected text."}, -- Reset all the values
      {name = "Paste", action = OnPasteColor, enabled = false, key = Keys.V, toolTip = "Paste the last copied text."}, -- Reset all the values
      {name = "Toggle Lines", action = ToggleLineNumbers, key = Keys.L, toolTip = "Toggle the line numbers for the editor."}, -- Reset all the values
      {divider = true},
      {name = "Quit", key = Keys.Q, action = OnQuit, toolTip = "Quit the current game."}, -- Quit the current game
    }

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")


    vSliderData = editorUI:CreateSlider({x = 235, y = 20, w = 10, h = 193}, "vsliderhandle", "Scroll text vertically.")
    vSliderData.onAction = OnVerticalScroll

    hSliderData = editorUI:CreateSlider({ x = 4, y = 211, w = 233, h = 10}, "hsliderhandle", "Scroll text horizontally.", true)
    hSliderData.onAction = OnHorizontalScroll

    -- local lineWidth = 0
    --
    -- lineInputArea = editorUI:CreateInputArea({x = 8, y = 24, w = lineWidth, h = 184}, nil, "Click to edit the text.")
    -- editorUI:Enable(lineInputArea, false)
    -- lineInputArea.editable = false

    -- Add an extra 8 pixels between the line numbers
    -- lineWidth = lineWidth + 8

    -- Create input area
    inputAreaData = editorUI:CreateInputArea({x = 8, y = 24, w = 224, h = 184}, nil, "Click to edit the text.")
    inputAreaData.wrap = false
    inputAreaData.editable = true
    -- inputAreaData.colorOffset = 32
    inputAreaData.onAction = function(text)
      -- print("input area updated")
    end

    -- TODO need to read the toggle line state from the bios

    showLines = ReadBiosData("ShowLinesInTextEditor") == "True" and true or false

    RefreshEditor()

    ResetDataValidation()
    -- pixelVisionOS:DisplayMessage(toolName .. ": This tool allows you to edit text files.", 5)
    -- pixelVisionOS:ChangeTitle(toolTitle, "toolbariconfile")

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

function ToggleLineNumbers()

  -- TODO need to save this value to the bios

  showLines = not showLines

  WriteBiosData("ShowLinesInTextEditor", showLines == true and "True" or "False")

  DrawLineNumbers()

  -- inputAreaData.rect.x = 8 + lineWidth
  -- inputAreaData.width = 224 - lineWidth
  -- TODO this needs to shift the text area over and display the line numbers. Should be part of the tool, not the component

end

function CalculateLineGutter()

  -- if(totalLines == inputAreaData.totalLines) then
  --   return
  -- end

  -- Update total
  totalLines = inputAreaData.totalLines

  lineWidth = showLines == true and ((#tostring(totalLines) + 1) * 8) or 0

  -- Only resize the input field if the size doesn't match
  local newWidth = 224 - lineWidth
  if(inputAreaData.rect.w ~= newWidth) then
    editorUI:ResizeInputArea(inputAreaData, newWidth, 184, 8 + lineWidth, 24)
  end

end

function InvalidateData()

  -- Only everything if it needs to be
  if(invalid == true)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle .."*", "toolbariconfile")

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

  -- Reset the input field's text validation
  editorUI:InputAreaResetTextValidation(inputAreaData)

  pixelVisionOS:EnableMenuItem(4, false)

end

function OnClear()
  editorUI:ChangeInputArea(inputAreaData, "")
  editorUI:InputAreaInvalidateText(inputAreaData)
end

function RefreshEditor()

  -- print("Load Text File", targetFile)
  local tmpText = ReadTextFile(targetFile)

  -- fileSize = GetFileSizeAsString(targetFile)

  editorUI:ChangeInputArea(inputAreaData, tmpText)

  ResetDataValidation()

  DrawLineNumbers()

end

function OnSave()

  local success = SaveTextToFile(targetFile, editorUI:GetInputAreaText(inputAreaData), false)

  if(success == true) then
    pixelVisionOS:DisplayMessage("Saving '" .. targetFile .. "'.", 5 )
    ResetDataValidation()
  else
    pixelVisionOS:DisplayMessage("Unable to save '" .. targetFile .. "'.", 5 )
  end

end

function OnHorizontalScroll(value)
  editorUI:InputAreaScrollTo(inputAreaData, value, inputAreaData.scrollValue.v)

  -- editorUI:InputAreaScrollTo(lineInputArea, value, inputAreaData.scrollValue.v)
end

function OnVerticalScroll(value)
  editorUI:InputAreaScrollTo(inputAreaData, inputAreaData.scrollValue.h, value)

  DrawLineNumbers()

end

function DrawLineNumbers()

  -- Make sure the gutter is the correct size
  CalculateLineGutter()

  -- Only draw the line numbers if show lines is true
  if(showLines ~= true) then
    return
  end



  local offset = inputAreaData.scrollFirst - 1
  local totalLines = inputAreaData.height
  local padWidth = (lineWidth / 8) - 1
  for i = 1, inputAreaData.height do

    DrawText(string.lpad(tostring(i + offset), padWidth, "0") .. " ", 1, 2 + i, DrawMode.Tile, "input", 0)

  end

end

function Update(timeDelta)

  -- This needs to be the first call to make sure all of the editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- if(showLines == true) then
  --   editorUI:UpdateInputArea(lineInputArea)
  -- end

  -- Only update the tool's UI when the modal isn't active
  if(pixelVisionOS:IsModalActive() == false and targetFile ~= nil) then

    editorUI:UpdateInputArea(inputAreaData)

    if(inputAreaData.invalidText == true) then
      InvalidateData()
      DrawLineNumbers()
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

function Draw()


  RedrawDisplay()

  -- The ui should be the last thing to update after your own custom draw calls
  pixelVisionOS:Draw()

end
