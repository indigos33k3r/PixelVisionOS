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

local toolName = "Color Tool"
local toolVersion = "v2.0"
local colorOffset = 0
-- local systemColorsPerPage = 64
local success = false
local emptyColorID = -1
local dragTime = 0
local dragDelay = .5

-- Default palette options
-- local pixelVisionOS.paletteColorsPerPage = 0
local maxPalettePages = 8
local paletteOffset = 0
local paletteColorPages = 0
local spriteEditorPath = ""
local spritesInvalid = false
-- local pixelVisionOS.totalPaletteColors = 0
local totalPalettePages = 0
local debugMode = false
-- local pixelVisionOS.paletteColors = {}
-- local maxColorsPerPalette = 16

local SaveShortcut, EditShortcut, DeleteShortcut, RevertShortcut, CopyShortcut, PasteShortcut = 4, 6, 7, 8, 10, 11

-- Create some Constants for the different color modes
local NoColorMode, SystemColorMode, PaletteMode = 0, 1, 2

-- The default selected mode is NoColorMode
local selectionMode = NoColorMode

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

  -- TODO For testing, we need a path
  -- rootDirectory = "/Workspace/Games/GGSystem/"
  -- rootDirectory = "/Workspace/Games/JumpNShootMan/"
  -- rootDirectory = "/Workspace/Games/ZeldaIIPalaceAnimation/"
  -- rootDirectory = "/Workspace/Games/ReaperBoyLD42Disk2/"

  if(rootDirectory ~= nil) then

    -- Load only the game data we really need
    success = gameEditor.Load(rootDirectory, {SaveFlags.System, SaveFlags.Colors, SaveFlags.ColorMap, SaveFlags.Sprites})

  end

  -- If data loaded activate the tool
  if(success == true) then


    -- Get a list of all the editors
    local editorMapping = FindEditors()

    -- Find the json editor
    spriteEditorPath = editorMapping["sprites"]

    -- spriteEditorPath = ReadMetaData("RootPath", "/") .."SpriteTool/"
    --
    -- -- Get the path to the editor from the bios
    -- local bioPath = ReadBiosData("SpriteEditor")
    --
    -- if(biosPath ~= nil) then
    --   spriteEditorPath = bioPath
    -- end

    -- print("Sprite Editor Path", spriteEditorPath)

    local menuOptions = 
    {
      -- About ID 1
      {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName .. " " .. toolVersion) end, toolTip = "Learn about PV8."},
      {divider = true},
      {name = "Edit Sprites", enabled = spriteEditorPath ~= nil, action = OnEditSprites, toolTip = "Open the sprite editor."},
      -- Reset all the values
      {name = "Save", action = OnSave, enabled = false, key = Keys.S, toolTip = "Save changes made to the colors.png file."}, -- Reset all the values
      {divider = true},
      {name = "Edit", action = OnEdit, enabled = false, key = Keys.E, toolTip = "Edit the currently selected color."},
      {name = "Delete", action = OnClear, enabled = false, key = Keys.D, toolTip = "Clear the currently selected color."},
      {name = "Revert", action = OnRevert, enabled = false, key = Keys.R, toolTip = "Revert the color its previous value."}, -- Reset all the values
      {divider = true},
      {name = "Copy", action = OnCopy, enabled = false, key = Keys.C, toolTip = "Copy the currently selected sound."}, -- Reset all the values
      {name = "Paste", action = OnPaste, enabled = false, key = Keys.V, toolTip = "Paste the last copied sound."}, -- Reset all the values

      {divider = true},
      {name = "Quit", key = Keys.Q, action = OnQuit, toolTip = "Quit the current game."}, -- Quit the current game
    }

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

    -- Split the root directory path
    local pathSplit = string.split(rootDirectory, "/")

    -- save the title with file path
    toolTitle = pathSplit[#pathSplit] .. "/colors.png"

    -- The first thing we need to do is rebuild the tool's color table to include the game's system and game colors.
    pixelVisionOS:ImportColorsFromGame()


    -- TODO this is debug code and can be removed when things are working

    if(debugMode == true) then
      colorMemoryCanvas = NewCanvas(8, TotalColors() / 8)

      print("Total Colors", pixelVisionOS.totalColors)
      local pixels = {}
      for i = 1, TotalColors() do
        local index = i - 1
        table.insert(pixels, index)
      end

      colorMemoryCanvas:SetPixels(pixels)
    end


    -- We need to modify the color selection sprite so we start with a reference to it
    local selectionPixelData = colorselection

    -- Now we need to create the item picker over sprite by using the color selection spriteIDs and changing the color offset
    _G["itempickerover"] = {spriteIDs = colorselection.spriteIDs, width = colorselection.width, colorOffset = 28}

    -- Next we need to create the item picker selected up sprite by using the color selection spriteIDs and changing the color offset
    _G["itempickerselectedup"] = {spriteIDs = colorselection.spriteIDs, width = colorselection.width, colorOffset = (_G["itempickerover"].colorOffset + 4)}


    -- Create an input field for the currently selected color ID
    colorIDInputData = editorUI:CreateInputField({x = 152, y = 208, w = 24}, "0", "The ID of the currently selected color.", "number")

    -- The minimum value is always 0 and we'll set the maximum value based on which color picker is currently selected
    colorIDInputData.min = 0

    -- Map the on action to the ChangeColorID method
    colorIDInputData.onAction = ChangeColorID

    -- Create a hex color input field
    colorHexInputData = editorUI:CreateInputField({x = 200, y = 208, w = 48}, "FF00FF", "Hex value of the selected color.", "hex")

    -- Call the UpdateHexColor function when a change is made
    colorHexInputData.onAction = UpdateHexColor

    -- Override string capture and only send uppercase characters to the field
    colorHexInputData.captureInput = function()
      return string.upper(InputString())
    end

    -- It's time to calculate the total number of system and palette colors

    -- Get the palette mode
    -- usePalettes = pixelVisionOS.paletteMode
    --

    -- Calculate the total system color pages, there are 4 in direct color mode (64 per page for 256 total) or 2 in palette mode (64 per page for 128 total)
    local maxSystemPages = math.ceil(pixelVisionOS.totalSystemColors / pixelVisionOS.systemColorsPerPage)

    -- Create the system color picker
    systemColorPickerData = pixelVisionOS:CreateColorPicker(
      {x = 8, y = 32, w = 128, h = 128}, -- Rect
      {x = 16, y = 16}, -- Tile size
      pixelVisionOS.totalSystemColors, -- Total colors, plus 1 for empty transparancy color
      pixelVisionOS.systemColorsPerPage, -- total per page
      maxSystemPages, -- max pages
      pixelVisionOS.colorOffset, -- Color offset to start reading from
      "itempicker", -- Selection sprite name
      "Select a color.", -- Tool tip
      false, -- Modify pages
      true, -- Enable dragging,
      true -- drag between pages
    )

    -- systemColorPickerData.onStartDrag = function()
    --
    --
    --
    -- end

    -- Create a function to handle what happens when a color is dropped onto the system color picker
    systemColorPickerData.onDropTarget = OnSystemColorDropTarget

    -- Manage what happens when a color is selected
    systemColorPickerData.onColorPress = function(value)

      -- Change the focus of the current color picker
      ForcePickerFocus(systemColorPickerData)

      -- Call the OnSelectSystemColor method to update the fields
      OnSelectSystemColor(value)

    end





    -- -- Create the palette color picker
    -- paletteColorPickerData = pixelVisionOS:CreateColorPicker(
    --   {x = 8, y = 184, w = 128, h = 32},
    --   {x = 16, y = 16},
    --   pixelVisionOS.totalPaletteColors,
    --   pixelVisionOS.paletteColorsPerPage,
    --   8,
    --   pixelVisionOS.colorOffset + 128,
    --   "itempicker",
    --   "Select a color.",
    --   true,
    --   true
    -- )
    --
    -- paletteColorPickerData.onColorPress = function(value)
    --   ForcePickerFocus(paletteColorPickerData)
    --   -- StartPickerDrag(systemColorPickerData.picker)
    -- end
    --
    -- paletteColorPickerData.onAddPage = AddPalettePage
    -- paletteColorPickerData.onRemovePage = RemovePalettePage
    --
    -- paletteColorPickerData.onDropTarget = OnPalettePickerDrop
    --
    -- -- Copy over all the palette colors to memory if we are in palette mode
    -- if(usePalettes) then
    --   pixelVisionOS:CopyPaletteColorsToMemory()
    -- end
    --
    spritePickerData = pixelVisionOS:CreateSpritePicker(
      {x = 152, y = 32, w = 96, h = 128 },
      {x = 8, y = 8},
      gameEditor:TotalSprites(),
      192,
      10,
      pixelVisionOS.colorOffset,
      "spritepicker",
      "Pick a sprite"
    )

    -- The sprite picker shouldn't be selectable on this screen but you can still change pages
    pixelVisionOS:EnableSpritePicker(spritePickerData, false, true)

    --
    -- -- Wire up the picker to change the color offset of the sprite picker
    -- paletteColorPickerData.onPageAction = function(value)
    --
    --   -- local valA = 128 + ((value - 1) * 16)
    --   -- local valB = PaletteOffset(value - 1)
    --   --
    --   -- print("CHANGE COLOR OFFSET OF SPRITES", value, valA, valB)
    --   -- Change the palette offset value
    --   spritePickerData.colorOffset = pixelVisionOS.gameColorOffset + PaletteOffset(value - 1)--128 + ((value - 1) * 16)--PaletteOffset(value)
    --   --pixelVisionOS.gameColorOffset + ((value - 1) * paletteColorPickerData.totalPerPage)
    --
    --   pixelVisionOS:OnSpritePageClick(spritePickerData, spritePickerData.pages.currentSelection)
    -- end
    --
    -- -- Need to convert sprites per page to editor's sprites per page value
    -- local spritePages = math.floor(gameEditor:TotalSprites() / 192)
    --
    -- if(gameEditor:Name() == ReadSaveData("editing", "undefined")) then
    --   lastSystemColorSelection = tonumber(ReadSaveData("systemColorSelection", "0"))
    --   -- lastTab = tonumber(ReadSaveData("tab", "1"))
    --   -- lastSelection = tonumber(ReadSaveData("selected", "0"))
    -- end
    -- --
    -- -- If we are opening a file, override the last tab selected
    -- -- local file = ReadMetaData("fileName", "colors.png") -- Load colors.png by default
    -- --
    -- -- if(file == "colors.png") then
    -- --   lastTab = 1
    -- --   lastSelection = 0
    -- -- elseif(file == "color-map.png") then
    -- --   lastTab = 2
    -- --   lastSelection = 0
    -- -- elseif(file == "flags.png") then
    -- --   lastTab = 3
    -- --   lastSelection = 0
    -- -- end
    --

    --
    pixelVisionOS:SelectColorPage(systemColorPickerData, 1)
    --
    --
    pixelVisionOS:SelectSpritePickerPage(spritePickerData, 1)
    --
    -- if(usePalettes == true) then
    --   pixelVisionOS:SelectColorPage(paletteColorPickerData, 1)
    -- end
    --
    -- Set the focus mode to none
    ForcePickerFocus()

    -- Reset the validation to update the title and set the validation flag correctly for any changes
    ResetDataValidation()

  else

    -- Patch background when loading fails

    -- Left panel
    DrawRect(8, 32, 128, 128, 0, DrawMode.TilemapCache)

    DrawRect(152, 32, 96, 128, 0, DrawMode.TilemapCache)

    DrawRect(152, 208, 24, 8, 0, DrawMode.TilemapCache)

    DrawRect(200, 208, 48, 8, 0, DrawMode.TilemapCache)

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

function OnPalettePickerDrop(src, dest)
  -- print("Palette Picker On Drop", src.name, dest.name)

  -- Two modes, accept colors from the system color picker or swap colors in the palette

  if(src.name == systemColorPickerData.name) then

    -- Get the index and add 1 to offset it correctly
    local id = editorUI:CalculatePickerPosition(dest.picker).index + 1

    -- Get the correct hex value
    local srcHex = Color(pixelVisionOS:CalculateRealColorIndex(src, src.picker.selected) + src.colorOffset)

    if(usePalettes == false) then

      -- We want to manually toggle the palettes before hand so we can add the first color before calling the AddPalettePage()
      TogglePaletteMode(true)

    end

    -- Make sure we only add colors to the end of the palette
    if(id >= dest.totalPerPage) then

      -- Set the ID to the last value so it is added to the end
      id = dest.totalPerPage

      -- print("Add Palette Color To End", id)

      -- Update the picker's total and total per page for the new item
      dest.total = dest.total + dest.totalPages
      dest.totalPerPage = dest.totalPerPage + 1

      -- Increase the colors per sprite value
      gameEditor:ColorsPerSprite(dest.totalPerPage)

      -- Invalidate since we increased the color per sprite
      InvalidateData()

    end

    -- Add the new color to the palette
    AddColorToPalette(dest.pages.currentSelection, id, srcHex)

    -- pixelVisionOS:CopyPaletteColorsToMemory()

    -- Force the picker to redraw the current page
    pixelVisionOS:OnColorPageClick(dest, dest.pages.currentSelection)

  end


end

function OnSystemColorDropTarget(src, dest)

  -- If the src and the dest are the same, we want to swap colors
  if(src.name == dest.name) then

    -- Get the source color ID
    sourceColorID = src.currentSelection

    -- Exit this swap if there is no src selection
    if(sourceColorID == nil) then
      return
    end

    -- Get the destination color ID
    local destColorID = pixelVisionOS:CalculateColorPickerPosition(src).index

    -- Make sure the colors are not the same
    if(sourceColorID ~= destColorID) then

      -- Need to shift src and dest ids based onthe color offset
      local realSrcID = sourceColorID + systemColorPickerData.colorOffset
      local realDestID = destColorID + systemColorPickerData.colorOffset

      -- Get the src and dest color hex value
      local srcColor = Color(realSrcID)
      local destColor = Color(realDestID)

      -- Make sure we are not moving a transparent color
      if(srcColor == pixelVisionOS.maskColor or destColor == pixelVisionOS.maskColor) then

        -- Display a message that transparent colors can't be moved
        pixelVisionOS:DisplayMessage("Can't move transparent system colors.", 5)

      else

        -- Swap the colors in the tool's color memory
        Color(realSrcID, destColor)
        Color(realDestID, srcColor)

        -- Select the new color spot
        pixelVisionOS:SelectColorPickerColor(systemColorPickerData, destColorID)

        -- Redraw the color page
        pixelVisionOS:DrawColorPage(systemColorPickerData)

        pixelVisionOS:DisplayMessage("Color ID '"..srcColor.."' was swapped with Color ID '"..destColor .."'", 5)

        InvalidateData()

      end

    end

  end

end

function OnEditSprites()
  pixelVisionOS:ShowMessageModal("Edit Sprites", "Do you want to open the Sprite Editor? All unsaved changes will be lost.", 160, true,
    function()
      if(pixelVisionOS.messageModal.selectionValue == true) then

        -- Set up the meta data for the editor for the current directory
        local metaData = {
          directory = rootDirectory,
        }

        -- Load the tool
        LoadGame(spriteEditorPath, metaData)

      end

    end
  )
end

local lastMode = nil

-- Changes the focus of the currently selected color picker
function ForcePickerFocus(src)

  -- Only one picker can be selected at a time so remove the selection from the opposite one.
  if(src == nil) then
    -- Save the mode
    selectionMode = NoColorMode

    -- Disable input fields
    editorUI:Enable(colorIDInputData, false)
    ToggleHexInput(false)



    -- Disable all option
    pixelVisionOS:EnableMenuItem(EditShortcut, false)
    pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
    pixelVisionOS:EnableMenuItem(RevertShortcut, false)

  elseif(src.name == systemColorPickerData.name) then

    -- Change the color mode to system color mode
    selectionMode = SystemColorMode

    -- Clear the picker selection
    pixelVisionOS:ClearColorPickerSelection(paletteColorPickerData)

    -- Enable the hex input field
    ToggleHexInput(true)

    -- Enable edit option
    pixelVisionOS:EnableMenuItem(EditShortcut, true)

  elseif(src.name == paletteColorPickerData.name) then

    -- Change the selection mode to palette mode
    selectionMode = PaletteMode

    -- Clear the system color picker selection
    pixelVisionOS:ClearColorPickerSelection(systemColorPickerData)

    -- Disable the hex input since you can't change palette colors directly
    ToggleHexInput(false)

    -- Disable edit option
    pixelVisionOS:EnableMenuItem(EditShortcut, false)
    pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
    pixelVisionOS:EnableMenuItem(RevertShortcut, false)

  end

  -- Test to see if the mode has changed
  if(lastMode ~= selectionMode) then

    -- Clear the selection and color from the previous mode
    lastSelection = value
    lastColor = colorHex

  end

end

function ToggleHexInput(value)
  editorUI:Enable(colorHexInputData, value)

  DrawText("#", 24, 26, DrawMode.Tile, "input", value and colorHexInputData.colorOffset or colorHexInputData.disabledColorOffset)

  if(value == false) then
    -- Clear values in fields
    -- Update the color id field
    editorUI:ChangeInputField(colorIDInputData, - 1, false)

    -- Update the color id field
    editorUI:ChangeInputField(colorHexInputData, string.sub(pixelVisionOS.maskColor, 2, 7), false)
  end
end



function AddPalettePage(data)

  -- print("Add Palette Page")

  -- If we are not using palettes, we need to warn the user before activating it
  if(usePalettes == false) then

    TogglePaletteMode(true)

  else

    local data = paletteColorPickerData

    -- TODO need to change the pagination to look at data.total not the picker total

    -- print("Data pre total", data.total, data.totalPerPage)

    if(data.totalPerPage == 0) then
      data.totalPerPage = gameEditor:ColorsPerSprite() + 1
    end

    -- Increase total colors
    data.total = data.total + data.totalPerPage
    data.picker.total = data.totalPerPage

    -- print("Data post total", data.total, data.totalPerPage)


    -- When setting up a new palette, we need to copy some colors over so its not empty

    local totalColors = gameEditor:ColorsPerSprite()

    -- print("Adding", totalColors, "to new palette")

    -- Loop through the page and add the first X colors to it
    for i = 1, totalColors do

      local index = i - 1
      local tmpColor = Color(pixelVisionOS.colorOffset + index)

      -- print("New Pal Color", tmpColor)

      AddColorToPalette(1, i, tmpColor)
    end

    pixelVisionOS:RebuildPickerPages(data)

    -- TODO need to select the last page
    pixelVisionOS:SelectColorPage(data, 1)

    pixelVisionOS:CopyPaletteColorsToMemory()

    pixelVisionOS:OnColorPageClick(data, data.pages.currentSelection)


  end

end

function TogglePaletteMode(value)

  local data = paletteColorPickerData

  if(value == true) then

    -- If we are not using palettes, we need to warn the user before activating it

    pixelVisionOS:ShowMessageModal("Activate Palette Mode", "Do you want to activate palette mode? This will split color memory in half and allocate 128 colors to the system and 128 to palettes. The sprites will also be reindexed to the first palette. Saving will rewrite the 'sprite.png' file. This can not be undone.", 160, true,
      function()
        if(pixelVisionOS.messageModal.selectionValue == true) then

          usePalettes = true

          gameEditor:ReindexSprites()

          pixelVisionOS:RedrawSpritePickerPage(spritePickerData)

          InvalidateSprites()

          -- Update the game editor palette modes
          gameEditor:PaletteMode(usePalettes)

          InvalidateData()

          AddPalettePage()

          RebuildPalette()

          pixelVisionOS:CopyPaletteColorsToMemory()

        end

      end
    )


  else

    pixelVisionOS:ShowMessageModal("Disable Palette Mode", "Disabeling the palette mode will return the game to 'Direct Color Mode'. Sprites will only display if they can match their colors to 'color.png' file. This process will also remove the palette colors and restore the system colors to support 256.", 160, true,
      function()
        if(pixelVisionOS.messageModal.selectionValue == true) then

          usePalettes = false

          -- Update the game editor palette modes
          gameEditor:PaletteMode(usePalettes)

          -- TODO remove color pages

        end

      end
    )

  end



  -- -- Reset the palette table
  -- RebuildPalette()
  --
  -- if(value == true) then
  --
  --   usePalettes = true
  --
  --   print(data.name, "Setting up palette mode")
  --
  --   data.picker.total = 1
  --   data.totalPerPage = 1
  --
  --   -- Enable the picker
  --   editorUI:Enable(data.picker, true)
  -- else
  --
  --   data.picker.total = 0
  --   data.totalPerPage = 0
  --
  --   usePalettes = false
  --
  --   -- Disable the picker
  --   editorUI:Enable(data.picker, false)
  --   pixelVisionOS:ClearColorPickerSelection(data)
  --
  -- end

end

function InvalidateSprites()

  spritesInvalid = true;


end

function ResetSpriteInvalidation()
  spritesInvalid = false;
end

function RebuildPalette()

  pixelVisionOS.paletteColors = {}

  -- Loop through all the colors and clear
  for i = 1, pixelVisionOS.totalColors do
    table.insert(pixelVisionOS.paletteColors, pixelVisionOS.maskColor)
  end

end

function AddColorToPalette(page, id, color)


  -- Palette memory is broken up into 16 blocks
  local totalPerPage = 16

  local offset = (page - 1) * totalPerPage

  -- print("Add Palette Color", page, id, color, offset)

  -- pixelVisionOS.paletteColors[id + offset] = color

  InvalidateData()

end

function RemoveColorFromPalette(id)

end

function ReplacePaletteColor(color1, color2)

  -- print("Replace Color", color1, "with", color2)

  -- local total = #pixelVisionOS.paletteColors
  --
  -- for i = 1, total do
  --   if(pixelVisionOS.paletteColors[i] == color1) then
  --     pixelVisionOS.paletteColors[i] = color2
  --   end
  -- end

end

-- Converts the fixed palette memory into a linear set of game color


function RestoreSystemColors()

  -- Clear all of the colors from the palettes
  -- pixelVisionOS.paletteColors = {}


  local total = pixelVisionOS.totalGameColors
  local startIndex = pixelVisionOS.gameColorOffset - 1
  local srcIndex = pixelVisionOS.colorOffset - 1

  -- Loop through and copy the colors from the system color blocks to the game color blocks
  for i = 1, total do

    Color(startIndex + i, Color(srcIndex + i))

  end

end

-- function UpdatePageButtonState()
--   editorUI:Enable(palettePageAddData, paletteColorPages < maxPalettePages)
--   editorUI:Enable(palettePageMinusData, paletteColorPages > 0)
-- end

function RemovePalettePage(data)
  -- print("Remove Palette Page")

  -- paletteColorPages = paletteColorPages - 1
  --
  -- -- Create pages for the palette
  -- RebuildPages(palettePageData, NewVector(120, 216), paletteColorPages, "Palette page ")
  --
  -- -- TODO if the current page is less than the total, move back a page


  if(data.totalPages <= 0) then

    -- pixelVisionOS:ShowMessageModal("Disable Palette Mode", "Do you want to disable palette mode? This will remove the palette colors from memory and set the system colors to 256.", 160, true,
    --   function()

    TogglePaletteMode(false)
    --
    --     -- Redraw the background
    --     DrawSprites(palettepickerbackground.spriteIDs, 1, 23, palettepickerbackground.width, false, false, DrawMode.Tile)
    --
    --     RestoreSystemColors()
    --
    --   end
    -- )

  else
    -- TODO need to clear colors in palette page?

    local lastPage = data.totalPages + 1
    local totalPerPage = 16

    local offset = lastPage * totalPerPage
    -- Palettes are fixed at 16 in memory
    for i = 1, totalPerPage do

      -- pixelVisionOS.paletteColors[i + offset] = pixelVisionOS.maskColor

    end

    pixelVisionOS:CopyPaletteColorsToMemory()
  end

end

-- function OnSpritePageClick(value)
--
--   RebuildSpritePage(NewRect(152, 32, 96, 128), value, 192, pixelVisionOS.colorOffset + pixelVisionOS.totalSystemColors + paletteOffset)
--
-- end

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

-- function CopyToolColorsToGame()
--
--   -- Clear the game's colors
--   gameEditor:ClearColors()
--
--   -- Force the game to have 256 colors
--   gameEditor:ColorPages(4)
--
--   -- Copy over all the new system colors from the tool's memory
--   for i = 1, pixelVisionOS.totalColors do
--
--     -- Calculate the correct color index
--     local index = i - 1
--
--     -- Read the color from the tool's memory starting at the system color offset
--     local newColor = Color(pixelVisionOS.systemColorOffset + index)
--
--     -- Set the game's color to the tool's color
--     gameEditor:Color(index, newColor)
--
--   end
--
-- end

function OnSave()

  -- Copy all of the colors over to the game
  pixelVisionOS:CopyGameColorsToGameMemory()

  -- These are the default flags we are going to save
  local flags = {SaveFlags.System, SaveFlags.Colors, SaveFlags.ColorMap, SaveFlags.System}

  -- If the sprites have been re-indexed and we are using palettes we need to save the changes
  if(spritesInvalid == true) then

    -- print("Save Sprites", usePalettes)
    if(usePalettes == true) then

      -- Add the color map flag
      table.insert(flags, SaveFlags.ColorMap)

    else
      -- TODO look for a color-map.png file in the current directory and delete it
    end

    -- Add the sprite flag
    table.insert(flags, SaveFlags.Sprites)

    -- Clear the sprite invalidation
    ResetSpriteInvalidation()

  end

  -- This will save the system data, the colors and color-map
  gameEditor:Save(rootDirectory, flags)

  -- Display a message that everything was saved
  pixelVisionOS:DisplayMessage("Your changes have been saved.", 5)

  -- Clear the validation
  ResetDataValidation()

end

function OnClear()

  local colorID = pixelVisionOS:CalculateRealColorIndex(systemColorPickerData)

  OnDeleteSystemColor(colorID)
  --
  -- UpdateHexColor("ff00ff")
end

function UpdateHexColor(value)

  value = "#".. value

  local colorID = pixelVisionOS:CalculateRealColorIndex(systemColorPickerData)
  -- CalculateRealIndex(systemColorPickerData.picker.selected, systemColorPageData, systemColorsPerPage)

  local realColorID = colorID + systemColorPickerData.colorOffset
  -- Shift the color based on the component's offset
  -- colorID =

  local currentColor = Color(realColorID)

  if(colorID == 255) then

    pixelVisionOS:ShowMessageModal(toolName .." Error", "You can not replace the last color which is reserved for transparency.", 160, false,
      -- Make sure we restore the color value after the modal closes
      function()

        -- Change the color back to the original value in the input field
        editorUI:ChangeInputField(colorHexInputData, currentColor:sub(2, - 1), false)

      end
    )

    -- Don't compare mask colors
  elseif(value == pixelVisionOS.maskColor) then

    -- TODO what happens when you delete a color a palette is referencing?
    OnDeleteSystemColor(colorID)

  else

    -- Make sure the color isn't duplicated
    for i = 1, pixelVisionOS.totalSystemColors do

      -- Test the new color against all of the existing system colors
      if(value == Color(pixelVisionOS.colorOffset + (i - 1))) then

        pixelVisionOS:ShowMessageModal(toolName .." Error", "'".. value .."' the same as system color ".. (i - 1) ..", enter a new color.", 160, false,
          -- Make sure we restore the color value after the modal closes
          function()

            -- Change the color back to the original value in the input field
            editorUI:ChangeInputField(colorHexInputData, currentColor:sub(2, - 1), false)

          end
        )

        -- Exit out of the update function
        return

      end

    end

    -- Update the editor's color
    local newColor = Color(realColorID, value)

    for i = 1, pixelVisionOS.totalColors do

      -- TODO need to make sure this is correct
      local index = (i - 1) + pixelVisionOS.colorOffset

      -- Get the current color in the tool's memory
      local tmpColor = Color(index)

      -- See if that color matches the old color
      if(tmpColor == currentColor and tmpColor ~= pixelVisionOS.maskColor) then

        -- Set the color to equal the new color
        Color(index, value)

      end

    end

    -- Test if the color is at the end
    if(colorID == systemColorPickerData.total - 1) then
      pixelVisionOS:AddNewColorToPicker(systemColorPickerData)
    end

    -- Rebuild the color pages after a change
    -- pixelVisionOS:DrawColorPage(systemColorPickerData)

    if(usePalettes == true and currentColor ~= pixelVisionOS.maskColor) then

      ReplacePaletteColor(currentColor, newColor)

      pixelVisionOS:CopyPaletteColorsToMemory()

      pixelVisionOS:DrawColorPage(paletteColorPickerData)

    end

    InvalidateData()

  end

end

function OnDeleteSystemColor(value)

  -- Calculate the total system colors from the picker
  local totalColors = systemColorPickerData.total - 1

  -- Test to see if we are on the last color
  if(value == totalColors) then

    -- Display a message to keep the user from deleting the mask color
    pixelVisionOS:ShowMessageModal(toolName .. " Error", "You can't delete the transparent color.", 160, false)

    -- Test to see if we only have one color left
  elseif(totalColors == 1) then

    -- Display a message to keep the user from deleting all of the system colors
    pixelVisionOS:ShowMessageModal(toolName .. " Error", "You must have at least 1 color.", 160, false)

  else

    pixelVisionOS:ShowMessageModal("Delete Color", "Are you sure you want to delete this system color? Doing so will shift all the colors over may change the colors in your sprites.", 160, true,
      function()
        if(pixelVisionOS.messageModal.selectionValue == true) then
          -- If the selection if valid, remove the system color
          DeleteSystemColor(value)
        end

      end
    )
  end

end

function DeleteSystemColor(value)

  -- Calculate the real color ID in the tool's memory
  local realColorID = value + systemColorPickerData.colorOffset

  -- Set the current tool's color to the mask value
  Color(realColorID, pixelVisionOS.maskColor)

  -- Copy all the colors to the game
  pixelVisionOS:CopyGameColorsToGameMemory()

  -- Reimport the game colors to rebuild the unique system color list
  pixelVisionOS:ImportColorsFromGame()

  -- Update the system picker with the new page total
  pixelVisionOS:ChangeColorPickerTotal(systemColorPickerData, pixelVisionOS.totalSystemColors)

  -- Deselect the system picker
  ForcePickerFocus()

  -- Invalidate the tool's data
  InvalidateData()

end

-- Manages selecting the correct color from a picker based on a change to the color id field
function ChangeColorID(value)

  -- print("Change Color ID", value)
  -- Check to see what mode we are in
  if(selectionMode == SystemColorMode) then

    -- Select the new color id in the system color picker
    pixelVisionOS:SelectColorPickerColor(systemColorPickerData, value)

  elseif(selectionMode == PaletteMode) then

    -- Select the new color id in the palette color picker
    pixelVisionOS:SelectColorPickerColor(paletteColorPickerData, value)

  end

end

local lastSelection = nil
local lastColor = nil

-- This is called when the picker makes a selection
function OnSelectSystemColor(value)

  pixelVisionOS:EnableMenuItem(DeleteShortcut, true)

  -- Calculate the color ID from the picker
  local colorID = pixelVisionOS:CalculateRealColorIndex(systemColorPickerData, value)

  -- Update the ID input field's max value from the OS's system color total
  colorIDInputData.max = pixelVisionOS.totalSystemColors - 1

  -- Enable the color id input field
  editorUI:Enable(colorIDInputData, true)

  -- Update the color id field
  editorUI:ChangeInputField(colorIDInputData, tostring(colorID), false)

  -- Enable the hex input field
  ToggleHexInput(true)

  -- Get the current hex value of the selected color
  local colorHex = Color(colorID + systemColorPickerData.colorOffset):sub(2, - 1)

  if(lastSelection ~= value) then

    lastSelection = value
    lastColor = colorHex

    -- print("Update last selection value", lastSelection, lastColor )

    pixelVisionOS:EnableMenuItem(RevertShortcut, true)

  end

  -- Update the selected color hex value
  editorUI:ChangeInputField(colorHexInputData, colorHex, false)

end

function Update(timeDelta)

  -- This needs to be the first call to make sure all of the editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- Only update the tool's UI when the modal isn't active
  if(pixelVisionOS:IsModalActive() == false) then

    if(success == true) then

      pixelVisionOS:UpdateSpritePicker(spritePickerData)

      editorUI:UpdateInputField(colorIDInputData)
      editorUI:UpdateInputField(colorHexInputData)

      -- System picker
      pixelVisionOS:UpdateColorPicker(systemColorPickerData)
      -- pixelVisionOS:UpdateColorPicker(paletteColorPickerData)

      if(IsExporting()) then
        pixelVisionOS:DisplayMessage("Saving " .. tostring(ReadExportPercent()).. "% complete.", 2)
      end

    end

  end

end

function Draw()

  RedrawDisplay()

  -- The ui should be the last thing to update after your own custom draw calls
  pixelVisionOS:Draw()

  if(debugMode) then
    colorMemoryCanvas:DrawPixels(256 - (8 * 3) - 2, 12, DrawMode.UI, 3)
  end

end

function Shutdown()

  -- WriteSaveData("editing", gameEditor:Name())
  -- WriteSaveData("tab", tostring(colorTabBtnData.currentSelection))
  -- WriteSaveData("selected", CalculateRealIndex(systemColorPickerData.picker.selected))

end

function rgbToHex(rgb)
  local hexadecimal = '0X'

  for key, value in pairs(rgb) do
    local hex = ''

    while(value > 0)do
      local index = math.fmod(value, 16) + 1
      value = math.floor(value / 16)
      hex = string.sub('0123456789ABCDEF', index, index) .. hex
    end

    if(string.len(hex) == 0)then
      hex = '00'

    elseif(string.len(hex) == 1)then
      hex = '0' .. hex
    end

    hexadecimal = hexadecimal .. hex
  end

  return hexadecimal
end
