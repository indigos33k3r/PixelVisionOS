--
-- Copyright (c) 2017, Jesse Freeman. All rights reserved.
--
-- Licensed under the Microsoft Public License (MS-PL) License.
-- See LICENSE file in the project root for full license information.
--
-- Contributors
-- --------------------------------------------------------
-- This is the official list of Pixel Vision 8 contributors:
--
-- Jesse Freeman - @JesseFreeman
-- Christina-Antoinette Neofotistou - @CastPixel
-- Christer Kaitila - @McFunkypants
-- Pedro Medeiros - @saint11
-- Shawn Rakowski - @shwany
--

function PixelVisionOS:ImportColorsFromGame()

  -- Resize the tool's color memory to 512 so it can store the tool and game colors
  gameEditor:ResizeToolColorMemory()

  -- We'll save the game's mask color
  self.maskColor = gameEditor:MaskColor()

  -- Games are capped at 256 colors
  self.totalColors = 256

  self.emptyColorID = self.totalColors - 1

  -- The color offset is the first position where a game's colors are stored in the tool's memory
  self.colorOffset = self.totalColors

  -- Clear all the tool's colors
  for i = 1, self.totalColors do
    local index = i - 1
    Color(index + self.colorOffset, self.maskColor)
  end

  -- Set the color mode
  self.paletteMode = gameEditor:PaletteMode()

  -- Calculate the total available system colors based on the palette mode
  self.totalSystemColors = self.paletteMode and self.totalColors / 2 or self.totalColors

  -- We want to subtract 1 from the system colors to make sure the last color is always empty for the mask
  self.totalSystemColors = self.totalSystemColors - 1

  -- There are always 128 total palette colors in memory
  self.totalPaletteColors = 128

  -- We display 64 system colors per page
  self.systemColorsPerPage = 64

  -- We display 16 palette colors per page
  self.paletteColorsPerPage = 16

  -- We need to copy over all of the game's colors to the tools color memory.

  -- Get all of the game's colors
  local gameColors = gameEditor:Colors()

  -- Create a table for all of the system colors so we can track unique colors
  self.systemColors = {}

  -- Loop through all of the system colors and add them to the tool
  for i = 1, self.totalSystemColors do

    -- Calculate the color's index
    local index = i - 1

    -- Get the color from the game
    local tmpColor = gameEditor:Color(index)

    -- get the game color at the current index
    local color = gameColors[i]

    -- Look to see if we have the system color or if its not the mask color
    if(table.indexOf(self.systemColors, color) == -1 and color ~= self.maskColor) then

      -- Reset the index to the last ID of the system color's array
      index = #self.systemColors

      -- Add the system color to the table
      table.insert(self.systemColors, color)

      -- Save the game's color to the tool's memory
      Color(index + self.colorOffset, tmpColor)

    end

  end

  -- TODO there should always be at least one transparent color at the end of the system color list

  -- Update the system color total to match the unique colors found plus 1 for the last color to be empty
  self.totalSystemColors = #self.systemColors + 1

  --
  -- -- Set the color mode
  -- self.paletteMode = gameEditor:PaletteMode()
  --
  -- -- Create two tables to store system and palette colors
  -- self.systemColors = {}
  -- self.paletteColors = {}
  --
  -- -- If we are in palette mode, we need to split the total colors in half
  -- local startTotal = self.paletteMode == true and (self.totalColors / 2) or self.totalColors
  --
  -- self.systemColorsPerPage = 64
  --
  -- -- Save the start position of the system colors
  -- self.systemColorOffset = self.colorOffset
  -- self.totalSystemColors = 0
  -- self.totalPaletteColors = 0
  -- -- Loop through all the system colors and make sure they are unique
  -- -- for i = 1, startTotal do
  -- --
  -- --   local color = gameColors[i]
  -- --   if(table.indexOf(self.systemColors, color) == -1 and color ~= self.maskColor) then
  -- --     table.insert(self.systemColors, color)
  -- --   end
  -- --
  -- -- end
  -- self.paletteColorsPerPage = 16
  --
  -- local colorCount = 0
  --
  -- for i = 1, 256 do
  --
  --   local index = i - 1
  --
  --   local tmpColor = gameEditor:Color(index)
  --
  --   -- Add colors to the palette list
  --   if(self.paletteMode == true and i > 127) then
  --
  --     -- Add colors to the system color list
  --     if(tmpColor ~= self.maskColor) then
  --       colorCount = colorCount + 1
  --     end
  --
  --     -- There are 16 colors total in a palette
  --     if(i % self.paletteColorsPerPage == (self.paletteColorsPerPage - 1)) then
  --
  --       if(colorCount > 0) then
  --         self.totalPaletteColors = self.totalPaletteColors + self.paletteColorsPerPage
  --       end
  --
  --       colorCount = 0
  --     end
  --
  --     -- Add the color to the palette color table
  --     table.insert(self.paletteColors, tmpColor)
  --
  --   else
  --
  --     if(table.indexOf(self.systemColors, tmpColor) == -1 and tmpColor ~= self.maskColor) then
  --       -- print("Add System Color", i, "at", #self.systemColors)
  --       table.insert(self.systemColors, tmpColor)
  --     end
  --
  --   end
  --
  -- end
  --
  -- -- Save the unique system colors
  -- self.totalSystemColors = #self.systemColors
  -- -- self.totalPaletteColors = #self.paletteColors
  --
  --
  --
  -- -- self.totalGameColors = 0--#gameColors
  --
  -- -- TODO this is  duplicated, and should be a single value
  -- self.gameColorOffset = self.colorOffset
  --
  -- self:CopyColorsToMemory()
  --
  -- -- Only create palettes if we load up in palette mode
  -- if(self.paletteMode) then
  --
  --   self:CopyPaletteColorsToMemory()
  --
  -- end

end



function PixelVisionOS:CopyPaletteColorsToMemory()

  -- -- Find the game color start index
  -- local startIndex = self.colorOffset - 1 + 127
  --
  -- -- Clear all the previous colors
  -- for i = 1, 256 do
  --   local index = i - 1
  --   Color(startIndex + index, self.maskColor)
  -- end
  --
  -- -- get the palette data
  -- local data = paletteColorPickerData
  --
  -- -- Figure out the total colors
  -- -- local total =
  --
  -- -- Set the page counter
  -- local page = 1
  --
  -- -- Start the ID at 0
  -- local id = 0
  --
  -- -- Loop through the total palette colors
  -- for i = 1, self.totalPaletteColors do
  --
  --   -- Increate the ID by 1 on each loop
  --   id = id + 1
  --
  --   -- Set the color based on the current position and find the right palette color
  --   Color(startIndex + i, self.paletteColors[id])
  --
  --   -- Check if we are on a new page to skip the empty colors
  --   if(i % self.paletteColorsPerPage == 0) then
  --
  --     -- Increase the current palette page
  --     page = page + 1
  --
  --     -- Shift the ID over to the next page of palette colors
  --     id = (page - 1) * 16
  --
  --   end
  --
  -- end

end

function PixelVisionOS:CopyGameColorsToGameMemory()

  -- Clear the game's colors
  gameEditor:ClearColors()

  -- Force the game to have 256 colors
  gameEditor:ColorPages(4)

  -- Copy over all the new system colors from the tool's memory
  for i = 1, self.totalColors do

    -- Calculate the index of the color
    local index = i - 1

    -- Read the color from the tool's memory starting at the system color offset
    local newColor = Color(index + self.colorOffset)

    -- Set the game's color to the tool's color
    gameEditor:Color(index, newColor)

  end

end

function PixelVisionOS:CopyColorsToMemory()

  -- -- if(self.paletteMode)
  --
  -- for i = 1, 256 do
  --
  --   local index = i - 1
  --
  --   local color = self.maskColor
  --
  --   if(self.paletteMode and i > 128) then
  --     color = self.paletteColors[i]
  --   else
  --
  --     if(i <= self.totalSystemColors) then
  --       color = self.systemColors[i]
  --     end
  --   end
  --
  --   Color(self.systemColorOffset + index, color)
  --
  -- end

end
