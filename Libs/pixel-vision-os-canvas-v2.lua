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

function EditorUI:CreateCanvas(rect, size, scale, colorOffset, toolTip, emptyColorID, forceDraw)

  -- Create the button's default data
  local data = self:CreateData(rect, nil, toolTip, forceDraw)

  -- Customize the default name by adding Button to it
  data.name = "Canvas" .. data.name
  data.onClick = function(tmpData)


    self:CanvasRelease(tmpData, true)

  end

  data.triggerOnFirstPress = function(tmpData)

    self:CanvasPress(tmpData, true)

    -- Trigger fill here since it only happens on the fist press
    if(data.tool == "fill") then

      -- TODO need to set this one on a timer

      -- Update the fill color
      data.paintCanvas:SetPattern({data.brushColor + data.colorOffset}, 1, 1)

      data.paintCanvas:FloodFill(data.startPos.x, data.startPos.y)

      self:Invalidate(data)
    end

    if(data.onFirstPress ~= nil) then
      data.onFirstPress()
    end

  end

  data.penCanErase = false
  data.colorOffset = colorOffset
  data.emptyColorID = emptyColorID or - 1
  data.fill = false
  data.currentCursorID = 1
  -- Default color is 0
  data.brushColor = 0
  data.overColor = -1

  self:ResizeCanvas(data, size, scale)


  -- Clear the background so the mask color shows through
  DrawRect(rect.x, rect.y, rect.w, rect.h, emptyColorID, DrawMode.TilemapCache)

  -- data.currentTool = 1 -- default tool

  self:ResetValidation(data)

  return data

end

function EditorUI:ChangeCanvasTool(data, toolName)

  -- print("Change canvas tool", toolName)

  data.tool = toolName

  -- TODO change the cursor
  if(data.tool == "pen") then

    data.currentCursorID = 6

  elseif(data.tool == "eraser") then

    data.currentCursorID = 7

  else
    data.currentCursorID = 8

  end

  -- TODO change the drawing tool

end

function EditorUI:UpdateCanvas(data, hitRect)

  -- Make sure we have data to work with and the component isn't disabled, if not return out of the update method
  if(data == nil) then
    return
  end

  -- If the button has data but it's not enabled exit out of the update
  if(data.enabled == false) then

    -- If the button is disabled but still in focus we need to remove focus
    if(data.inFocus == true) then
      self:ClearFocus(data)
    end

    -- See if the button needs to be redrawn.
    self:RedrawCanvas(data)

    -- Shouldn't update the button if its disabled
    return

  end

  -- Make sure we don't detect a collision if the mouse is down but not over this button
  if(self.collisionManager.mouseDown and data.inFocus == false) then
    -- See if the button needs to be redrawn.
    self:RedrawCanvas(data)
    return
  end

  -- If the hit rect hasn't been overridden, then use the buttons own hit rect
  if(hitRect == nil) then
    hitRect = data.hitRect or data.rect
  end

  local overrideFocus = (data.inFocus == true and self.collisionManager.mouseDown)

  local inRect = self.collisionManager:MouseInRect(hitRect)

  -- Ready to test finer collision if needed
  if(inRect == true or overrideFocus) then

    -- If we are in the collision area, set the focus
    self:SetFocus(data, data.currentCursorID)

    -- Check to see if the button is pressed and has an onAction callback
    if(self.collisionManager.mouseReleased == true) then

      -- Click the button
      data.onClick(data)
      data.firstPress = true

    elseif(self.collisionManager.mouseDown) then

      local tmpPos = NewVector(
        Clamp(self.collisionManager.mousePos.x - data.rect.x, 0, data.rect.w - 1),
        Clamp(self.collisionManager.mousePos.y - data.rect.y, 0, data.rect.h - 1)
      )

      -- Modify scale
      tmpPos.x = tmpPos.x / data.scale
      tmpPos.y = tmpPos.y / data.scale

      if(data.firstPress ~= false) then

        -- Save start position
        data.startPos = NewVector(tmpPos.x, tmpPos.y)

        -- if(data.triggerOnFirstPress ~= nil) then
        -- Call the onPress method for the button
        data.triggerOnFirstPress(data)
        -- end

        -- Change the flag so we don't trigger first press again
        data.firstPress = false



      end

      self:DrawOnCanvas(data, tmpPos)

    end

  else

    if(data.inFocus == true) then
      data.firstPress = true
      -- If we are not in the button's rect, clear the focus
      self:ClearFocus(data)

    end

  end

  -- Capture keys to switch between different tools and options
  if( Key(Keys.Backspace, InputState.Released) ) then

    if(self.selectRect ~= nil) then

      -- Remove the pixel data from the temp canvas's selection
      self.tmpPaintCanvas:Clear()

      -- Change the stroke to a single pixel of white
      self.tmpPaintCanvas:SetStroke({1}, 1, 1)

      -- Change the stroke to a single pixel of white
      self.tmpPaintCanvas:SetPattern({1}, 1, 1)

      -- Draw a square to mask off the selected area on the main canvas
      self.tmpPaintCanvas:DrawSquare(self.selectRect.x, self.selectRect.y, self.selectRect.width, self.selectRect.height, true)

      -- Clear the selection
      self.selectRect = nil

      -- Merge the pixel data from the tmp canvas into the main canvas before it renders
      self.paintCanvas:Merge(self.tmpPaintCanvas, 0, true)

    end

  end

  -- Make sure we don't need to redraw the button.
  self:RedrawCanvas(data)

end

function EditorUI:DrawOnCanvas(data, mousePos, toolID)


  -- data.tool = "pen" -- toolID or data.currentTool

  -- TODO make sure the mouse is still inside of the canvas

  -- print("Draw", "Pos", pos.x, pos.y, "Start Pos", data.startPos.x, data.startPos.y)

  -- TODO force draw
  -- data.drawMode = true



  -- if(data.drawMode == true or data.overMenu == nil) then

  -- Get the start position for a new drawing
  if(data.startPos ~= nil) then



    -- Test for the data.tool and perform a draw action
    if(data.tool == "pen") then



      if(data.penCanErase == true) then

        local overColorID = data.paintCanvas:ReadPixelAt(mousePos.x, mousePos.y) - data.colorOffset

        if(overColorID > 0) then
          data.tmpPaintCanvas:SetStroke({data.emptyColorID}, 1, 1)
        else
          self:ResetCanvasStroke(data)
        end

        data.tmpPaintCanvas:SetStrokePixel(mousePos.x, mousePos.y)

      else

        self:ResetCanvasStroke(data)

        data.tmpPaintCanvas:DrawLine(data.startPos.x, data.startPos.y, mousePos.x, mousePos.y)

      end


      data.startPos = NewVector(mousePos.x, mousePos.y)

      self:Invalidate(data)

    elseif(data.tool == "eraser") then

      -- Change the stroke the empty color
      data.tmpPaintCanvas:SetStroke({data.emptyColorID}, 1, 1)

      data.tmpPaintCanvas:DrawLine(data.startPos.x, data.startPos.y, mousePos.x, mousePos.y)
      data.startPos = NewVector(mousePos.x, mousePos.y)

      self:Invalidate(data)

    elseif(data.tool == "line") then

      data.tmpPaintCanvas:Clear()

      self:ResetCanvasStroke(data)

      data.tmpPaintCanvas:DrawLine(data.startPos.x, data.startPos.y, mousePos.x, mousePos.y, data.fill)

      self:Invalidate(data)

    elseif(data.tool == "box") then


      data.tmpPaintCanvas:Clear()

      self:ResetCanvasStroke(data)

      data.tmpPaintCanvas:DrawSquare(data.startPos.x, data.startPos.y, mousePos.x, mousePos.y, data.fill)

      self:Invalidate(data)

    elseif(data.tool == "select") then

      -- Save start position
      -- if(data.selectRect == nil) then
      data.selectRect = NewRect(data.startPos.x, data.startPos.y, mousePos.x, mousePos.y)
      -- else
      --
      -- end
      --
      -- data.selectRect.width = mousePos.x - data.selectRect.x
      -- data.selectRect.height = mousePos.y - data.selectRect.y

      -- print("Rect", data.selectRect.x, data.selectRect.y, data.selectRect.width, data.selectRect.height)

      if(math.abs(data.selectRect.x - data.selectRect.width) <= 2 or math.abs(data.selectRect.y - data.selectRect.width) <= 2) then
        data.selectRect = nil

        data.tmpPaintCanvas:Clear()

        -- print("Clear Rect")
      end

      -- data.tmpPaintCanvas:Clear()
      --
      -- -- Change the stroke to a single pixel
      -- data.tmpPaintCanvas:SetStroke({0, 1}, 2, 1)
      --
      -- data.tmpPaintCanvas:DrawSquare(data.startPos.x, data.startPos.y, mousePos.x, mousePos.y, false)

    elseif(data.tool == "circle") then

      data.tmpPaintCanvas:Clear()

      self:ResetCanvasStroke(data)

      data.tmpPaintCanvas:DrawEllipse(data.startPos.x, data.startPos.y, mousePos.x, mousePos.y, data.fill)

      self:Invalidate(data)

    elseif(data.tool == "eyedropper") then

      data.overColor = data.paintCanvas:ReadPixelAt(mousePos.x, mousePos.y) - data.colorOffset

    elseif(data.tool == "select") then

      -- print("select", data.startPos.x, data.startPos.y)

    end


  end

  -- end

end

function EditorUI:ResetCanvasStroke(data)

  -- Set stroke to 1 if no stroke has been selected or use the stroke value from the picker
  -- if(self.modalLineEditor == nil)then

  --print("Canvas", data.brushColor, data.colorOffset)

  local realBrushColor = data.brushColor + data.colorOffset

  -- Change the stroke to a single pixel
  data.tmpPaintCanvas:SetStroke({realBrushColor}, 1, 1)
  -- else
  --   local stroke = self.modalLineEditor.lines[self.modalLineEditor.currentSelection]
  --   self.tmpPaintCanvas:SetStroke(stroke.pattern, stroke.size.x, stroke.size.y)
  -- end

end

function EditorUI:RedrawCanvas(data)

  if(data == nil) then
    return
  end

  -- Draw the final canvas to the display on each frame
  data.paintCanvas:DrawPixels(data.rect.x, data.rect.y, DrawMode.TilemapCache, data.scale)

  if(data.tmpPaintCanvas.invalid == true) then
    -- Draw the tmp layer on top of everything since it has the active drawing's pixel data
    data.tmpPaintCanvas:DrawPixels(data.rect.x, data.rect.y, DrawMode.TilemapCache, data.scale)


  end

  -- Draw a selection rect on top of everything
  if(data.selectRect ~= nil) then

    data.tmpPaintCanvas:Clear()

    local lastCenteredValue = data.tmpPaintCanvas:DrawCentered()

    data.tmpPaintCanvas:DrawCentered(false)

    -- Change the stroke to a single pixel
    data.tmpPaintCanvas:SetStroke({0}, 1, 1)

    data.tmpPaintCanvas:LinePattern(2, data.selectionCounter)

    data.tmpPaintCanvas:DrawSquare(data.selectRect.x, data.selectRect.y, data.selectRect.width, data.selectRect.height, false)

    -- Draw the canvas to the display
    data.tmpPaintCanvas:DrawPixels(data.paintCanvasPos.x, data.paintCanvasPos.y, DrawMode.UI)

    data.tmpPaintCanvas:LinePattern(1, 0)

    data.tmpPaintCanvas:DrawCentered(lastCenteredValue)

  end


end

-- Use this to perform a click action on a button. It's used internally when a mouse click is detected.
function EditorUI:CanvasRelease(data, callAction)

  -- print("Canvas Release")


  -- Clear the start position
  data.startPos = nil

  -- Return if the selection rect is nil
  if(data.selectRect ~= nil) then
    return
  end

  -- if(data.tmpPaintCanvas.invalid == true) then

  -- TODO Removed the validation here, need to see why this doesn't work?

  -- print("Copy tmp canvas buffer")
  -- Save the last drawing
  -- data.lastDrawing = data.tmpPaintCanvas:GetPixels()

  if(data.tmpPaintCanvas.invalid == true) then

    -- print("Merge tmp canvas", )
    -- Merge the pixel data from the tmp canvas into the main canvas before it renders
    data.paintCanvas:Merge(data.tmpPaintCanvas, 0, true)

    -- Clear the last drawing value
    -- data.lastDrawing = nil

    -- Clear the canvas
    data.tmpPaintCanvas:Clear()

    -- Normally clearing the canvas invalidates it but se want to reset it until its drawn in again
    data.tmpPaintCanvas:ResetValidation()

  end
  --
  --

  -- end

  -- trigger the canvas action callback
  if(data.onAction ~= nil and callAction ~= false) then

    -- Trigger the onAction call back and pass in the double click value if the button is set up to use it
    data.onAction()

  end

end

function EditorUI:CanvasPress(data, callAction)

  -- print("onPress", "Update canvas")

  data.tmpPaintCanvas:Invalidate()

  if(data.onPress ~= nil and callAction ~= false) then

    -- Trigger the onPress
    data.onPress()

  end

end

function EditorUI:ResizeCanvas(data, size, scale, pixelData)

  -- data.canvas = NewCanvas(rect.w, rect.h)

  -- Create a new canvas for drawing into
  data.paintCanvas = NewCanvas(size.x, size.y)

  -- Create a temporary canvas
  data.tmpPaintCanvas = NewCanvas(size.x, size.y)

  -- Set scale for calculation
  data.scale = scale or 1

  -- TODO need to copy pixel data over to the canvas
  if(pixelData ~= nil) then

    local total = #pixelData

    -- print("Total Pixels", total)
    for i = 1, total do

      local color = pixelData[i]

      pixelData[i] = color == -1 and data.emptyColorID or (color + data.colorOffset)

    end

    data.paintCanvas:SetPixels(0, 0, size.x, size.y, pixelData);

  end

end

function EditorUI:GetCanvasSize(data)

  return NewRect(data.rect.x, data.rect.y, data.paintCanvas.width, data.paintCanvas.height)
end

function EditorUI:ToggleCanvasFill(data, value)

  data.fill = value or not data.fill

  return data.fill

end

function EditorUI:ToggleCanvasCentered(data, value)

  value = value or not data.tmpPaintCanvas:DrawCentered()

  data.tmpPaintCanvas:DrawCentered(value)

  return value

end

function EditorUI:CanvasBrushColor(data, value)

  data.brushColor = value

end

function EditorUI:GetCanvasPixelData(data)

  return data.paintCanvas:GetPixels()

end
