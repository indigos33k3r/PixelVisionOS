--[[
	Pixel Vision 8 - Display Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

-- API Bridge
LoadScript("sb-sprites")
LoadScript("pixel-vision-os-v2")
LoadScript("pixel-vision-os-color-picker-v2")
LoadScript("pixel-vision-os-sprite-picker-v2")
LoadScript("pixel-vision-os-canvas-v2")

local toolName = "Sprite Tool"
local toolVersion = "v2.0"
local colorOffset = 0
local systemColorsPerPage = 64
local success = false
local emptyColorID = -1
local originalPixelData = nil
local lastSelection = -1
local lastColorID = 0
local colorEditorPath = "/"

local tools = {"pen", "eraser", "line", "box", "circle", "eyedropper", "fill"}--, "select"}

ClearShortcut, SaveShortcut, RevertShortcut, CopyShortcut, PasteShortcut, SpriteBuilderShortcut = 4, 5, 6, 8, 9, 11, 12

function InvalidateData()

  -- Only everything if it needs to be
  if(invalid == true)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle .."*", "toolbariconfile")

  invalid = true

  pixelVisionOS:EnableMenuItem(SaveShortcut, true)

end

function ResetDataValidation()

  -- print("Reset Validation")
  -- Only everything if it needs to be
  if(invalid == false)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle, "toolbariconfile")
  invalid = false

  pixelVisionOS:EnableMenuItem(SaveShortcut, false)

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

  -- print("Root Directory", rootDirectory)

  -- TODO For testing, we need a path
  -- rootDirectory = "/Workspace/Games/GGSystem/"
  -- rootDirectory = "/Workspace/Games/JumpNShootMan/"
  -- rootDirectory = "/Workspace/Games/ZeldaIIPalaceAnimation/"
  -- rootDirectory = "/Workspace/Games/ReaperBoyLD42Disk2/"

  if(rootDirectory == nil) then

  else

    -- Load only the game data we really need
    success = gameEditor.Load(rootDirectory, {SaveFlags.System, SaveFlags.Colors, SaveFlags.ColorMap, SaveFlags.Sprites}) -- colorEditor:LoadTmpEngine()

  end

  -- If data loaded activate the tool
  if(success == true) then


    -- Get a list of all the editors
    local editorMapping = FindEditors()

    -- Find the json editor
    colorEditorPath = editorMapping["colors"]

    local menuOptions = 
    {
      -- About ID 1
      {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName .. " " .. toolVersion) end, toolTip = "Learn about PV8."},
      {divider = true},
      {name = "Edit Colors", enabled = colorEditorPath ~= nil, action = OnEditColors, toolTip = "Open the color editor."},
      {name = "Clear", action = OnClear, enabled = false, key = Keys.D, toolTip = "Clear the currently selected color."}, -- Reset all the values
      {name = "Save", action = OnSave, key = Keys.S, enabled = false, toolTip = "Save changes made to the colors.png file."}, -- Reset all the values

      {name = "Revert", action = OnRevert, enabled = false, key = Keys.R, toolTip = "Revert the colors.png file to its previous state."}, -- Reset all the values
      {divider = true},
      {name = "Copy", action = OnCopySprite, enabled = false, key = Keys.C, toolTip = "Copy the currently selected sound."}, -- Reset all the values
      {name = "Paste", action = OnPasteSprite, enabled = false, key = Keys.V, toolTip = "Paste the last copied sound."}, -- Reset all the values

      {divider = true},
      {name = "Optimize", action = OnOptimize, toolTip = "Remove duplicate sprites."},
      {name = "Sprite Builder", action = OnSpriteBuilder, key = Keys.B, toolTip = "Generate a sprite table from a project's SpriteBuilder dir."}, -- Reset all the values
      {divider = true},
      {name = "Quit", key = Keys.Q, action = OnQuit, toolTip = "Quit the current game."}, -- Quit the current game
    }

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")


    -- The first thing we need to do is rebuild the tool's color table to include the game's system and game colors.

    ImportColorsFromGame()

    _G["itempickerover"] = {spriteIDs = colorselection.spriteIDs, width = colorselection.width, colorOffset = 28}

    _G["itempickerselectedup"] = {spriteIDs = colorselection.spriteIDs, width = colorselection.width, colorOffset = (_G["itempickerover"].colorOffset + 4)}

    _G["spritepickerover"] = {spriteIDs = spritepicker.spriteIDs, width = spritepicker.width, colorOffset = 28}

    _G["spritepickerselectedup"] = {spriteIDs = spritepicker.spriteIDs, width = spritepicker.width, colorOffset = (_G["spritepickerover"].colorOffset + 4)}

    spriteIDInputData = editorUI:CreateInputField({x = 176, y = 208, w = 32}, "0", "The ID of the currently selected color.", "number")
    spriteIDInputData.min = 0
    spriteIDInputData.max = gameEditor:TotalSprites() - 1
    spriteIDInputData.onAction = ChangeSpriteID

    sizeBtnData = editorUI:CreateButton({x = 224, y = 200}, "sprite1x", "Pick the sprite size.")
    sizeBtnData.onAction = OnNextSpriteSize

    editorUI:Enable(sizeBtnData, false)

    toolBtnData = editorUI:CreateToggleGroup()
    toolBtnData.onAction = OnSelectTool


    for i = 1, #tools do
      local offsetY = ((i - 1) * 16) + 32
      local rect = {x = 144, y = offsetY, w = 16, h = 16}
      editorUI:ToggleGroupButton(toolBtnData, rect, tools[i], "This is tool button " .. tostring(i))
    end

    -- TODO if using palettes, need to replace this with palette color value
    local totalColors = pixelVisionOS.totalSystemColors
    local totalPerPage = 16--pixelVisionOS.systemColorsPerPage
    local maxPages = 8
    colorOffset = pixelVisionOS.colorOffset

    -- Check the game editor if palettes are being used
    usePalettes = gameEditor:PaletteMode()

    if(usePalettes == true) then
      totalColors = 128
      colorOffset = colorOffset + 128

      -- Change color label to palette
      DrawSprites(gamepalettetext.spriteIDs, 24 / 8, 168 / 8, gamepalettetext.width, false, false, DrawMode.Tile)

    end

    canvasData = editorUI:CreateCanvas(
      {
        x = 8,
        y = 32,
        w = 128,
        h = 128
      },
      {
        x = 128,
        y = 128
      },
      1,
      colorOffset,
      "Draw on the canvas",
      pixelVisionOS.emptyColorID
    )

    canvasData.onAction = OnSaveCanvasChanges
    -- canvasData.onFirstPress = OnCanvasFirstPress

    spritePickerData = pixelVisionOS:CreateSpritePicker(
      {x = 152 + 16, y = 32, w = 80, h = 128 },
      {x = 8, y = 8},
      gameEditor:TotalSprites(),
      192 - 32,
      10,
      colorOffset,
      "spritepicker",
      "Pick a sprite",
      false,
      true,
      true
    )

    spritePickerData.onSpriteAction = OnSelectSprite
    spritePickerData.onDropTarget = OnSpritePickerDrop

    -- TODO setting the total to 0
    paletteColorPickerData = pixelVisionOS:CreateColorPicker(
      {x = 8, y = 184, w = 128, h = 32},
      {x = 16, y = 16},
      totalColors,
      totalPerPage,
      maxPages,
      colorOffset,
      "itempicker",
      "Select a color."
    )

    paletteColorPickerData.onColorPress = function(value)

      -- if we are in palette mode, just get the currents selection. If we are in direct color mode calculate the real color index
      value = usePalettes and paletteColorPickerData.picker.selected or pixelVisionOS:CalculateRealColorIndex(paletteColorPickerData, value)

      -- Make sure if we select the last color, we mark it as the mask color
      if(value == paletteColorPickerData.total - 1) then
        value = -1
      end

      lastColorID = value

      -- Set the canvas brush color
      editorUI:CanvasBrushColor(canvasData, value)

    end

    -- Wire up the picker to change the color offset of the sprite picker
    paletteColorPickerData.onPageAction = function(value)

      -- If we are not in palette mode, don't change the sprite color offset
      if(usePalettes == true) then

        -- Calculate the new color offset
        local newColorOffset = colorOffset + ((value - 1) * paletteColorPickerData.totalPerPage)

        -- Update the sprite picker color offset
        spritePickerData.colorOffset = newColorOffset


        -- Update the canvas color offset
        canvasData.colorOffset = newColorOffset

        pixelVisionOS:OnSpritePageClick(spritePickerData, spritePickerData.pages.currentSelection)

        UpdateCanvas(lastSelection)

        editorUI:SelectPicker(paletteColorPickerData.picker, lastColorID)

      end

    end

    -- Need to convert sprites per page to editor's sprites per page value
    -- local spritePages = math.floor(gameEditor:TotalSprites() / 192)

    if(gameEditor:Name() == ReadSaveData("editing", "undefined")) then
      lastSystemColorSelection = tonumber(ReadSaveData("systemColorSelection", "0"))
      -- lastTab = tonumber(ReadSaveData("tab", "1"))
      -- lastSelection = tonumber(ReadSaveData("selected", "0"))
    end

    local pathSplit = string.split(rootDirectory, "/")

    -- Update title with file path
    toolTitle = pathSplit[#pathSplit] .. "/" .. "sprites.png"



    editorUI:SelectToggleButton(toolBtnData, 1)

    pixelVisionOS:SelectColorPage(paletteColorPickerData, 1)
    pixelVisionOS:SelectColorPickerColor(paletteColorPickerData, 0)

    -- pixelVisionOS:SelectSpritePickerPage(spritePickerData, 1)

    pixelVisionOS:SelectSpritePickerSprite(spritePickerData, 0)
    -- TODO this is not being triggered, need a better way to select the first sprite

    local startSprite = 0

    if(SessionID() == ReadSaveData("sessionID", "") and rootDirectory == ReadSaveData("rootDirectory", "")) then
      startSprite = tonumber(ReadSaveData("selectedSprite", "0"))
    end

    -- pixelVisionOS:ResetSpritePicker(spritePickerData)
    -- spritePickerData.currentSelection = -1
    -- -- Change the input field and load the correct sprite
    -- editorUI:ChangeInputField(spriteIDInputData, startSprite)

    ChangeSpriteID(startSprite)
    -- OnSelectSprite(startSprite)
    -- local tmpPixelData = gameEditor:Sprite(0)
    --
    -- -- TODO simulate selecting the first sprite
    -- editorUI:ResizeCanvas(canvasData, NewVector(8, 8), 16, tmpPixelData)

    ResetDataValidation()

  else

    -- Patch background when loading fails

    -- Left panel
    DrawRect(8, 32, 128, 128, 0, DrawMode.TilemapCache)

    DrawRect(168, 32, 80, 128, 0, DrawMode.TilemapCache)

    DrawRect(8, 184, 128, 32, 0, DrawMode.TilemapCache)

    DrawRect(176, 208, 32, 8, 0, DrawMode.TilemapCache)

    DrawRect(136, 164, 3, 9, BackgroundColor(), DrawMode.TilemapCache)
    DrawRect(248, 180, 3, 9, BackgroundColor(), DrawMode.TilemapCache)
    DrawRect(136, 220, 3, 9, BackgroundColor(), DrawMode.TilemapCache)



    pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

    pixelVisionOS:ShowMessageModal(toolName .. " Error", "The tool could not load without a reference to a file to edit.", 160, false,
      function()
        QuitCurrentTool()
      end
    )

  end



end


function OnSpritePickerDrop(src, dest)

  -- print("On Sprite Drop")

  -- If the src and the dest are the same, we want to swap colors
  if(src.name == dest.name) then

    -- Get the source color ID
    srcSpriteID = src.currentSelection

    -- Exit this swap if there is no src selection
    if(srcSpriteID == nil) then
      return
    end

    -- Get the destination color ID
    local destSpriteID = pixelVisionOS:CalculateSpritePickerPosition(src).index

    -- Make sure the colors are not the same
    if(srcSpriteID ~= destSpriteID) then

      -- Need to shift src and dest ids based onthe color offset
      -- local realSrcID = srcSpriteID-- + systemColorPickerData.colorOffset
      -- local realDestID = destSpriteID-- + systemColorPickerData.colorOffset

      -- TODO need to account for the scroll offset?
      -- print("Swap sprite", srcSpriteID, destSpriteID)

      local srcSprite = gameEditor:Sprite(srcSpriteID)
      local destSprite = gameEditor:Sprite(destSpriteID)

      -- Swap the sprite in the tool's color memory
      gameEditor:Sprite(srcSpriteID, destSprite)
      gameEditor:Sprite(destSpriteID, srcSprite)


      pixelVisionOS:RedrawSpritePickerPage(src)

      ChangeSpriteID(destSpriteID)

      InvalidateData()

    end

  end

end

function OnEditColors()
  pixelVisionOS:ShowMessageModal("Edit Colors", "Do you want to open the Color Editor? All unsaved changes will be lost.", 160, true,
    function()
      if(pixelVisionOS.messageModal.selectionValue == true) then

        -- Set up the meta data for the editor for the current directory
        local metaData = {
          directory = rootDirectory,
        }

        -- Load the tool
        LoadGame(colorEditorPath, metaData)

      end

    end
  )
end

local copiedSpriteData = nil

function OnCopySprite()

  local index = pixelVisionOS:CalculateRealSpriteIndex(spritePickerData)

  copiedSpriteData = gameEditor:Sprite(index)

  -- copiedSpriteData = {}
  --
  -- local colorOffset = pixelVisionOS.gameColorOffset
  -- -- Need to loop through the pixel data and change the offset
  -- local total = #tmpPixelData
  -- for i = 1, total do
  --   copiedSpriteData[i] = tmpPixelData[i] - colorOffset
  -- end

  pixelVisionOS:EnableMenuItem(PasteShortcut, true)

end

function OnPasteSprite()

  if(copiedSpriteData == nil) then
    return
  end

  local index = pixelVisionOS:CalculateRealSpriteIndex(spritePickerData)

  gameEditor:Sprite(index, copiedSpriteData)

  copiedSpriteData = nil

  pixelVisionOS:EnableMenuItem(RevertShortcut, false)

  pixelVisionOS:RedrawSpritePickerPage(spritePickerData)

  UpdateCanvas(index)

  pixelVisionOS:EnableMenuItem(PasteShortcut, false)

end


function OnRevert()

  pixelVisionOS:ShowMessageModal("Clear Sprite", "Do you want to revert the sprite's pixel data to it's original state?", 160, true,
    function()
      if(pixelVisionOS.messageModal.selectionValue == true) then
        -- Save changes
        RevertSprite()

      end

    end
  )

end

function RevertSprite()

  -- print("Revert Sprite", originalPixelData)

  local index = pixelVisionOS:CalculateRealSpriteIndex(spritePickerData)

  gameEditor:Sprite(index, originalPixelData)

  -- Select the current sprite to update the canvas
  pixelVisionOS:SelectSpritePickerSprite(spritePickerData, index)

  -- Redraw the sprite picker page
  pixelVisionOS:RedrawSpritePickerPage(spritePickerData)

  -- Invalidate the tool's data
  InvalidateData()

  pixelVisionOS:EnableMenuItem(RevertShortcut, false)
  pixelVisionOS:EnableMenuItem(ClearShortcut, not IsSpriteEmpty(originalPixelData))

end

function OnClear()

  pixelVisionOS:ShowMessageModal("Clear Sprite", "Do you want to clear all of the pixel data for the current sprite?", 160, true,
    function()
      if(pixelVisionOS.messageModal.selectionValue == true) then
        -- Save changes
        ClearSprite()

      end

    end
  )

end



function ClearSprite()

  -- TODO need to link this up to the size
  -- get the total number of pixels in the current sprite selection
  local total = 8 * 8


  -- TODO we should calculate an empty sprite when changing sizes instead of doing it over and over again on clear sprite

  -- Create an empty table for the pixel data
  tmpPixelData = {}

  -- Loop through the total pixels and set them to -1
  for i = 1, total do
    tmpPixelData[i] = - 1
  end

  -- Find the currents sprite index
  local index = pixelVisionOS:CalculateRealSpriteIndex(spritePickerData)

  -- Update the currently selected sprite
  gameEditor:Sprite(index, tmpPixelData)

  -- Select the current sprite to update the canvas
  pixelVisionOS:SelectSpritePickerSprite(spritePickerData, index)

  -- Redraw the sprite picker page
  pixelVisionOS:RedrawSpritePickerPage(spritePickerData)

  -- Invalidate the tool's data
  InvalidateData()

  pixelVisionOS:EnableMenuItem(RevertShortcut, true)
  pixelVisionOS:EnableMenuItem(ClearShortcut, false)

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

function OnOptimize()

  pixelVisionOS:ShowMessageModal("Optimize Sprites", "Before you optimize the sprites, you should make a backup copy of the current 'sprite.png' file. After this process, if you save your changes, it will overwrite the existing 'sprite.png' file.", 160, true,
    function()
      if(pixelVisionOS.messageModal.selectionValue == true) then
        TriggerOptimization()
      end
    end
  )

end

function TriggerOptimization()

  local oldCount = gameEditor:SpritesInRam()

  gameEditor:OptimizeSprites()

  local newCount = gameEditor:SpritesInRam()

  -- print("Optimized", oldCount, newCount)

  -- TODO force these to redraw?
  --

  pixelVisionOS:ResetSpritePicker(spritePickerData)
  -- ChangeSpriteID(0)

  local percent = Clamp(100 - math.ceil(newCount / oldCount * 100), 0, 100)

  -- Show summary modal and invalidate the data when the modal is closed
  pixelVisionOS:ShowMessageModal("Optimization Complete", "The sprite optimizer was able to compress sprite memory by ".. percent .. "%. If you save your changes, the previous 'sprite.png' file will be overwritten.", 160, false, function()

    InvalidateData()
  end)


end

function OnSaveCanvasChanges()



  local pixelData = editorUI:GetCanvasPixelData(canvasData)
  local canvasSize = editorUI:GetCanvasSize(canvasData)

  local tmpX = spritePickerData.picker.selectedDrawArgs[2] + spritePickerData.picker.borderOffset
  local tmpY = spritePickerData.picker.selectedDrawArgs[3] + spritePickerData.picker.borderOffset

  if(spritePickerData.picker.selected > - 1)then
    DrawPixels(pixelData, tmpX, tmpY, canvasSize.width, canvasSize.height, DrawMode.TilemapCache)
  end

  local total = #pixelData

  for i = 1, total do
    pixelData[i] = pixelData[i] - colorOffset
  end

  local realIndex = pixelVisionOS:CalculateRealSpriteIndex(spritePickerData)

  -- Update the current sprite in the picker
  gameEditor:Sprite(realIndex, pixelData)

  if(canvasData.invalid == true) then
    -- Invalidate the sprite tool since we change some pixel data
    InvalidateData()

    -- Reset the canvas invalidation since we copied it
    editorUI:ResetValidation(canvasData)

  end

  -- Make sure the clear button is enabled since a change has happened to the canvas
  pixelVisionOS:EnableMenuItem(ClearShortcut, true)
  pixelVisionOS:EnableMenuItem(RevertShortcut, true)

end


function OnSelectTool(value)

  local toolName = tools[value]

  editorUI:ChangeCanvasTool(canvasData, toolName)

  -- We disable the color selection when switching over to the eraser
  if(toolName == "eraser") then

    --  Clear the current color selection
    pixelVisionOS:ClearColorPickerSelection(paletteColorPickerData)

    -- Disable the color picker
    pixelVisionOS:EnableColorPicker(paletteColorPickerData, false)

  else

    -- We need to restore the color when switching back to a new tool

    -- Make sure the last color is in range
    if(lastColorID == nil or lastColorID == -1) then

      -- For palette mode, we set the color to the last color per sprite but for direct color mode we set it to the last system color
      lastColorID = usePalettes and gameEditor:ColorsPerSprite() or paletteColorPickerData.total - 1

    end

    -- Enable co
    pixelVisionOS:EnableColorPicker(paletteColorPickerData, true)

    -- Need to find the right color if we are in palette mode
    if(usePalettes == true) then

      lastColorID = last

    end

    pixelVisionOS:SelectColorPickerColor(paletteColorPickerData, lastColorID)

  end

end

local spriteSize = 1
local maxSpriteSize = 4

function OnNextSpriteSize()


  if(Key(Keys.LeftShift)) then
    spriteSize = spriteSize - 1

    if(spriteSize < 1) then
      spriteSize = maxSpriteSize
    end

  else
    spriteSize = spriteSize + 1
    if(spriteSize > maxSpriteSize) then
      spriteSize = 1
    end
  end

  local spriteName = "sprite"..tostring(spriteSize).."x"

  sizeBtnData.cachedSpriteData = {
    up = _G[spriteName .. "up"],
    down = _G[spriteName .. "down"] ~= nil and _G[spriteName .. "down"] or _G[spriteName .. "selectedup"],
    over = _G[spriteName .. "over"],
    selectedup = _G[spriteName .. "selectedup"],
    selectedover = _G[spriteName .. "selectedover"],
    selecteddown = _G[spriteName .. "selecteddown"] ~= nil and _G[spriteName .. "selecteddown"] or _G[spriteName .. "selectedover"],
    disabled = _G[spriteName .. "disabled"],
    empty = _G[spriteName .. "empty"] -- used to clear the sprites
  }

  editorUI:Invalidate(sizeBtnData)

end

function ImportColorsFromGame()


  pixelVisionOS:ImportColorsFromGame()

end


function OnSave()

  -- TODO need to save all of the colors back to the game

  -- This will save the system data, the colors and color-map
  gameEditor:Save(rootDirectory, {SaveFlags.System, SaveFlags.Sprites})

  -- Display a message that everything was saved
  pixelVisionOS:DisplayMessage("Your changes have been saved.", 5)

  -- Clear the validation
  ResetDataValidation()

end

function OnSelectSprite(value)

  -- TODO need to convert the value to the Real ID

  value = pixelVisionOS:CalculateRealSpriteIndex(spritePickerData, value)



  editorUI:ChangeInputField(spriteIDInputData, value, false)

  UpdateCanvas(value)

end

function UpdateCanvas(value)
  -- Save the original pixel data from the selection
  local tmpPixelData = gameEditor:Sprite(value)

  local scale = 16 -- TODO need to get the real scale
  local size = NewVector(8, 8)

  -- TODO simulate selecting the first sprite
  editorUI:ResizeCanvas(canvasData, size, scale, tmpPixelData)

  -- If this is a new selection we want to save the original pixel data for the revert option
  if(value ~= lastSelection) then

    originalPixelData = {}

    -- local colorOffset = pixelVisionOS.gameColorOffset
    -- Need to loop through the pixel data and change the offset
    local total = #tmpPixelData
    for i = 1, total do
      originalPixelData[i] = tmpPixelData[i] - colorOffset
    end

    lastSelection = value

    pixelVisionOS:EnableMenuItem(RevertShortcut, false)

    -- Only enable the clear menu when the sprite is not empty
    pixelVisionOS:EnableMenuItem(ClearShortcut, not IsSpriteEmpty(tmpPixelData))


    pixelVisionOS:EnableMenuItem(CopyShortcut, true)

  end

end

function IsSpriteEmpty(pixelData)

  local total = #pixelData

  for i = 1, total do
    if(pixelData[i] ~= -1) then
      return false
    end
  end

  return true

end

function ChangeSpriteID(value)

  -- Need to convert the text into a number
  value = tonumber(value)

  pixelVisionOS:SelectSpritePickerSprite(spritePickerData, value)

  editorUI:ChangeInputField(spriteIDInputData, value, false)

  UpdateCanvas(value)

  pixelVisionOS:RedrawSpritePickerPage(spritePickerData)

  -- TODO don't know why I need to force this to stop dragging here?
  spritePickerData.dragging = false

end

function Update(timeDelta)

  -- This needs to be the first call to make sure all of the editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- Only update the tool's UI when the modal isn't active
  if(pixelVisionOS:IsModalActive() == false) then
    if(success == true) then



      pixelVisionOS:UpdateSpritePicker(spritePickerData)

      editorUI:UpdateInputField(spriteIDInputData)
      -- editorUI:UpdateInputField(colorHexInputData)

      editorUI:UpdateButton(sizeBtnData)

      editorUI:UpdateCanvas(canvasData)

      if(canvasData.tool == "eyedropper") then

        local colorID = canvasData.overColor

        --


        -- TODO need to account for direct color mode or palette mode
        -- TODO in palette mode, use % to find the correct color on any page since you only paint with 0 - 16

        -- Only update the color selection when it's new
        if(colorID ~= lastColorID) then

          if(usePalettes == true) then
            -- print("colorID", colorID)
          end

          lastColorID = colorID

          if(colorID == -1) then

            local lastColor = usePalettes and gameEditor:ColorsPerSprite() or paletteColorPickerData.total - 1

            pixelVisionOS:SelectColorPickerColor(paletteColorPickerData, lastColor)

          else

            pixelVisionOS:SelectColorPickerColor(paletteColorPickerData, lastColorID)

          end

        end


      end

      editorUI:UpdateToggleGroup(toolBtnData)

      -- System picker
      -- pixelVisionOS:UpdateColorPicker(systemColorPickerData)
      pixelVisionOS:UpdateColorPicker(paletteColorPickerData)

      if(IsExporting()) then
        -- print("Exporting", tostring(ReadExportPercent()).. "% complete.")
        pixelVisionOS:DisplayMessage("Saving " .. tostring(ReadExportPercent()).. "% complete.", 2)
      end

    end
  end

end

function Draw()

  RedrawDisplay()

  -- The ui should be the last thing to update after your own custom draw calls
  pixelVisionOS:Draw()

end

function Shutdown()

  -- Save the current session ID
  WriteSaveData("sessionID", SessionID())

  WriteSaveData("rootDirectory", rootDirectory)

  WriteSaveData("selectedSprite", spritePickerData.currentSelection)

  -- TODO need to add selected tool, color and color page

end

function OnSpriteBuilder()

  -- print("rootDirectory", rootDirectory)
  local count = gameEditor:RunSpriteBuilder(rootDirectory)

  if(count > 0) then
    pixelVisionOS:DisplayMessage(count .. " sprites were processed for the 'sb-sprites.lua' file.")
  else
    pixelVisionOS:DisplayMessage("No sprites were found in the 'SpriteBuilder' folder.")
  end

end
