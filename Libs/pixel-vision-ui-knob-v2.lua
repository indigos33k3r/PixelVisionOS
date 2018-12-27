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

function EditorUI:CreateKnob(rect, spriteName, toolTip)

  -- Create a generic component data object
  local data = self:CreateData(rect, spriteName, toolTip, forceDraw)

  data.rotation = 
  {
    -- "0",
    -- "10",
    -- "20",
    "30",
    "40",
    "50",
    "60",
    "70",
    "80",
    "90",
    "100",
    "110",
    "120",
    "130",
    "140",
    "150",
    "160",
    "170",
    "180",
    "190",
    "200",
    "210",
    "220",
    "230",
    "240",
    "250",
    "260",
    "270",
    "280",
    "290",
    "300",
    "310",
    "320",
    -- "330",
    -- "340",
    -- "350"
  }

  -- Add the name of the component type to the default data name value
  data.name = "Knob" .. data.name

  -- Configure extra data properties needed to run the slider component
  data.horizontal = true
  data.size = rect.w or rect.h
  data.value = 0
  data.handleX = 0
  data.handleY = 0
  data.handleSize = 1

  -- This is applied to the top when horizontal and the left when vertical
  data.offset = offset or 0

  -- Calculate the handle's size based on the sprite
  local spriteData = _G[data.spriteName .. data.rotation[1]]
  --
  -- -- If there is a sprite calculate the handle size
  if(spriteData ~= nil) then

    data.spriteDrawArgs = {spriteData.spriteIDs, data.rect.x, data.rect.y, spriteData.width, false, false, DrawMode.Sprite, 0, false}

  end
  -- Need to account for the correct orientation
  data.handleCenter = data.handleSize / 2

  -- Make sure that the tilemap has the correct flag values

  -- self:SetUIFlags(data.tiles.c, data.tiles.r, data.tiles.w, data.tiles.h, data.flagID)

  -- Return the data
  return data

end

function EditorUI:UpdateKnob(data)

  -- Make sure we have data to work with and the component isn't disabled, if not return out of the update method
  if(data == nil) then
    return
  end

  local size = data.size - data.handleSize

  if(data.enabled == true) then

    local overrideFocus = (data.inFocus == true and self.collisionManager.mouseDown)

    -- Ready to test finer collision if needed
    if(self.collisionManager:MouseInRect(data.rect) == true or overrideFocus) then

      -- TODO need to fix focus when you have the mouse down from another UI element and roll over a slider
      -- Set focus

      if(self.inFocusUI == nil) then

        self:SetFocus(data)


      end

      -- Check to see if the mouse is down to update the handle position
      if(self.collisionManager.mouseDown == true and data.inFocus) then

        -- Need to calculate the new x position
        local newPos = self.collisionManager.mousePos.x - data.handleCenter

        -- Make sure the position is in range
        if(newPos > size + data.rect.x) then
          newPos = size + data.rect.x
        elseif(newPos < data.rect.x) then
          newPos = data.rect.x
        end

        -- Save the new position
        data.handleX = newPos

        -- Need to calculate the value
        local percent = math.ceil(((data.handleX - data.rect.x) / size) * 100) / 100

        self:ChangeKnob(data, percent)

      end

    else

      -- If the mouse is not in the rect, clear the focus
      if(data.inFocus == true and self.collisionManager.mouseDown == false) then
        self:ClearFocus(data)
      end

    end

  end

  -- If the component has changes and the mouse isn't over it, update the handle
  if(data.invalid == true) then

    data.handleX = data.handleX + (data.value * size)
    data.handleY = data.handleY + data.offset

    -- Clear the validation
    self:ResetValidation(data)

  end

  -- Calculate rotation
  local rotationID = math.floor(data.value * #data.rotation)

  if(rotationID < 1) then
    rotationID = 1
  elseif(rotationID > #data.rotation) then
    rotationID = #data.rotation
  end

  -- Update the handle sprites
  local spriteData = _G[data.spriteName .. data.rotation[rotationID]] -- data.enabled == true and data.cachedSpriteData.up or data.cachedSpriteData.disabled

  -- If the slider has focus, show the over state
  -- if(data.inFocus == true) then
  --   spriteData = data.cachedSpriteData.over
  -- end

  -- TODO this should be cached an only drawn when the player is interacting with it

  -- Make sure we have sprite data to render
  if(spriteData ~= nil and data.spriteDrawArgs ~= nil) then

    -- Update the draw arguments for the sprite

    -- Sprite Data
    data.spriteDrawArgs[1] = spriteData.spriteIDs

    -- X pos
    -- data.spriteDrawArgs[2] = data.handleX
    --
    -- -- Y pos
    -- data.spriteDrawArgs[3] = data.handleY

    -- color offsets
    -- 16 is disabled (the last color should be set to match the background the knob is on)
    -- 20 is up
    -- 24 is over

    -- Color Offset
    if(data.enabled) then

      data.spriteDrawArgs[8] = data.inFocus == true and 24 or 20
    else
      data.spriteDrawArgs[8] = 16
    end

    self:NewDraw("DrawSprites", data.spriteDrawArgs)

  end

  -- Return the slider data value
  return data.value

end

function EditorUI:ChangeKnob(data, percent, trigger)

  -- If there is no data or the value is the same as what's being passed in, don't update the component
  if(data == nil or data.value == percent) then
    return
  end

  -- Set the new value
  data.value = percent

  -- TODO shouldn't this be onUpdate?
  if(data.onAction ~= nil and trigger ~= false) then
    data.onAction(percent)
  end

  -- Invalidate the component's display
  self:Invalidate(data)

end
