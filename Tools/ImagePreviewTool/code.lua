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
LoadScript("pixel-vision-os-color-picker-v2")

local toolName = "Image Preview"
local debugMode = false

local pixelVisionOS = nil
local editorUI = nil

-- local fileSize = "000k"
local invalid = true

local rootDirectory = nil
local showLines = false
local lineWidth = 0
local totalLines = 0
local viewport = {x = 8, y = 24, w = 224, h = 184}

local mouseOrigin = {x = 0, y = 0}
local boundary = {x = 0, y = 0, w = 0, h = 0}
local scrollPos = {x = 0, y = 0}
local isPanning = false
local scrollDelay = .2
local scrollTime = 0


-- local loadTime = 0
-- local loadDelay = 0
-- local firstRun = true
local imageLoaded = false

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

    -- Start the load process and display an error if it fail
    if(gameEditor:LoadImage(targetFile) == true) then

      local pathSplit = string.split(targetFile, "/")

      -- Update title with file path
      toolTitle = pathSplit[#pathSplit - 1] .. "/" .. pathSplit[#pathSplit]

      ResetDataValidation()

      gameEditor:StartLoading()

    else

      pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

      pixelVisionOS:ShowMessageModal(toolName .. " Error", "The tool was not able to load the correct file", 160, false,
        function()
          QuitCurrentTool()
        end
      )

    end

  else

    pixelVisionOS:ChangeTitle(toolName, "toolbaricontool")

    pixelVisionOS:ShowMessageModal(toolName .. " Error", "The tool could not load without a reference to a file to edit.", 160, false,
      function()
        QuitCurrentTool()
      end
    )
  end



end

function SelectLayer(value)

  layerMode = value - 1
  --
  gameEditor:RenderMapLayer(layerMode)
  -- -- gameEditor:NextRenderStep()
  --
  -- InvalidateMap()
  --
  -- -- Clear background
  -- DrawRect(viewport.x, viewport.y, viewport.w, viewport.h, pixelVisionOS.emptyColorID, DrawMode.TilemapCache)

end

function InvalidateMap()
  mapInvalid = true
end

function ResetMapValidation()
  mapInvalid = false
end

-- function OnQuit()
--
--   -- if(invalid == true) then
--   --
--   --   pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have unsaved changes. Do you want to save your work before you quit?", 160, true,
--   --     function()
--   --       if(pixelVisionOS.messageModal.selectionValue == true) then
--   --         -- Save changes
--   --         OnSave()
--   --
--   --       end
--   --
--   --       -- Quit the tool
--   --       QuitCurrentTool()
--   --     end
--   --   )
--   --
--   -- else
--   -- Quit the tool
--   QuitCurrentTool()
--   -- end
--
-- end

function InvalidateData()

  -- Only everything if it needs to be
  if(invalid == true)then
    return
  end

  pixelVisionOS:ChangeTitle(toolTitle .."*", "toolbariconfile")

  -- pixelVisionOS:EnableMenuItem(4, true)

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
  -- editorUI:InputAreaResetTextValidation(inputAreaData)

  -- pixelVisionOS:EnableMenuItem(4, false)

end
local scrollInvalid = true

function OnHorizontalScroll(value)

  -- TODO this is wrong but works when I use ABS... need to fix it
  scrollPos.x = math.abs(math.floor(((viewport.w - boundary.w) - viewport.w) * value))
  --
  -- print("scrollPos.x", scrollPos.x)

  InvalidateMap()
end

function OnVerticalScroll(value)
  -- scrollPos.y = math.floor((viewport.h - boundary.h) * value)
  -- print("scrollPos.y", scrollPos.y)
  scrollPos.y = math.abs(math.floor(((viewport.h - boundary.h) - viewport.h) * value))

  InvalidateMap()
end
--
-- function LoadTool()
--
--   print("Ready to load tool")
--
--
--
-- end

function OnImageLoaded()

  -- if(success) then

  pixelVisionOS:ImportColorsFromGame()

  -- DrawRect(viewport.x, viewport.y, viewport.w, viewport.h, pixelVisionOS.emptyColorID, DrawMode.TilemapCache)



  local menuOptions = 
  {
    -- About ID 1
    {name = "About", action = function() pixelVisionOS:ShowAboutModal(toolName) end, toolTip = "Learn about PV8."},
    {divider = true},
    {name = "Save Colors", enabled = true, action = function() OnSavePNG(true, false, false) end, toolTip = "Create a 'color-map.png' file."},
    {name = "Save Sprites", enabled = true, action = function() OnSavePNG(false, true, false) end, toolTip = "Create a 'sprite.png' file."},
    {name = "Save Tilemap", enabled = true, action = function() OnSavePNG(false, false, true) end, toolTip = "Create a 'tilemap.json' file."},
    {divider = true},
    {name = "Toggle Palette", enabled = true, action = function() debugMode = not debugMode end, toolTip = "Shows a preview of the color palette."},
    {divider = true},
    {name = "Quit", key = Keys.Q, action = QuitCurrentTool, toolTip = "Quit the current game."}, -- Quit the current game
  }

  pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

  -- Setup map viewport

  local mapSize = gameEditor:TilemapSize()

  mapSize.x = mapSize.x * 8
  mapSize.y = mapSize.y * 8

  -- TODO need to modify the viewport to make sure the map fits inside of it correctly

  viewport.w = math.min(mapSize.x, viewport.w)
  viewport.h = math.min(mapSize.y, viewport.h)

  -- Calculate the boundary for scrolling
  boundary.w = mapSize.x - viewport.w
  boundary.h = mapSize.y - viewport.h

  -- print("boundary", boundary.w, boundary.h)
  -- TODO need to see if we need the scroll bars

  if(boundary.h > 0) then
    vSliderData = editorUI:CreateSlider({x = 235, y = 20, w = 10, h = 193}, "vsliderhandle", "Scroll text vertically.")
    vSliderData.onAction = OnVerticalScroll
  end

  if(boundary.w > 0) then
    hSliderData = editorUI:CreateSlider({ x = 4, y = 211, w = 233, h = 10}, "hsliderhandle", "Scroll text horizontally.", true)
    hSliderData.onAction = OnHorizontalScroll
  end

  ResetDataValidation()

  SelectLayer(1)

  toolLoaded = true

  local totalColors = gameEditor:TotalColors()

  colorMemoryCanvas = NewCanvas(8, totalColors / 8)

  local pixels = {}
  for i = 1, totalColors do
    local index = i + 255
    table.insert(pixels, index)
  end

  colorMemoryCanvas:SetPixels(pixels)

end

function Update(timeDelta)

  -- This needs to be the first call to make sure all of the editor UI is updated first
  pixelVisionOS:Update(timeDelta)

  -- We only want to run this when a modal isn't active. Mostly to stop the tool if there is an error modal on load
  if(pixelVisionOS:IsModalActive() == false) then


    if(imageLoaded == false) then

      local percent = ReadPreloaderPercent()
      pixelVisionOS:DisplayMessage("Loading image " .. percent .. "%")

      -- If preloading is done, exit the loading loop
      if(percent >= 100) then
        imageLoaded = true

        -- print("Image Loaded")
        OnImageLoaded()

      end

    end


    -- Only update the tool's UI when the modal isn't active
    if(targetFile ~= nil and toolLoaded == true) then

      scrollPos = gameEditor:ScrollPosition()

      -- Update the slider
      editorUI:UpdateSlider(vSliderData)

      -- Update the slider
      editorUI:UpdateSlider(hSliderData)

      if(gameEditor.renderingMap == true) then
        gameEditor:NextRenderStep()
        pixelVisionOS:DisplayMessage("Rendering Layer " .. tostring(gameEditor.renderPercent).. "% complete.", 2)
        InvalidateMap()
      end

    end

  end

end

function Draw()


  RedrawDisplay()

  if(mapInvalid == true and toolLoaded == true) then

    -- update the scroll position

    -- print("Render", scrollPos.x, scrollPos.y)
    gameEditor:ScrollPosition(scrollPos.x, scrollPos.y)

    local useBG = false--bgBtnData.selected
    local bgColor = pixelVisionOS.emptyColorID

    gameEditor:CopyRenderToDisplay(viewport.x, viewport.y, viewport.w, viewport.h, 255, bgColor)

    if(debugMode) then
      colorMemoryCanvas:DrawPixels(8, 24, DrawMode.UI, 3)
    end
  end


  -- The ui should be the last thing to update after your own custom draw calls
  pixelVisionOS:Draw()

end

function OnSavePNG(color, sprite, tilemap)

  local label = "none"
  local menuID = 0
  if(color) then
    label = "colors"
    menuID = 3
  elseif(sprite) then
    label = "sprites"
    menuID = 4
  elseif(tilemap) then
    label = "tilemap"
    menuID = 5
  end

  pixelVisionOS:ShowMessageModal("Export " .. label, "This will override any existing file in the directory. Do you want to do this?", 160, true,
    function()
      if(pixelVisionOS.messageModal.selectionValue == true) then
        -- Save changes

        local flags = {}

        if(color == true) then

          -- Add the color map flag
          table.insert(flags, SaveFlags.Colors)

        end

        if(sprite == true) then

          -- Add the color map flag
          table.insert(flags, SaveFlags.Sprites)

        end

        if(tilemap == true) then

          -- Add the color map flag
          table.insert(flags, SaveFlags.Tilemap)

        end

        -- This will save the system data, the colors and color-map
        gameEditor:Save(rootDirectory, flags)

        pixelVisionOS:EnableMenuItem(menuID, false)

      end

    end
  )


end
