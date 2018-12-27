NewFileModal = {}
NewFileModal.__index = NewFileModal

function NewFileModal:Init()

  local _renameModal = {} -- our new object
  setmetatable(_renameModal, NewFileModal) -- make Account handle lookup

  width = 224
  height = 72

  _renameModal.canvas = NewCanvas(width, height)

  local displaySize = Display()

  _renameModal.title = "Rename File"

  _renameModal.rect = {
    x = math.floor(((displaySize.x - width) * .5) / 8) * 8,
    y = math.floor(((displaySize.y - height) * .5) / 8) * 8,
    w = width,
    h = height
  }

  _renameModal.currentSelection = 1
  _renameModal.message = message

  return _renameModal

end

function NewFileModal:SetText(title, inputText, description)

  self.title = title
  self.message = description
  self.defaultText = inputText

  -- self.editorUI:ChangeInputField(self.inputField, self.defaultText)
  -- Update the input field
  if(self.inputField ~= nil) then
    self.editorUI:ChangeInputField(self.inputField, self.defaultText)
  end

end

function NewFileModal:GetText()
  return self.inputField.text
end

function NewFileModal:Open()

  if(self.firstRun == nil) then

    -- Save a snapshot of the TilemapCache

    -- Draw the black background
    self.canvas:SetStroke({0}, 1, 1)
    self.canvas:SetPattern({0}, 1, 1)
    self.canvas:DrawSquare(0, 0, self.canvas.width - 1, self.canvas.height - 1, true)

    -- Draw the brown background
    self.canvas:SetStroke({12}, 1, 1)
    self.canvas:SetPattern({11}, 1, 1)
    self.canvas:DrawSquare(2, 8, self.canvas.width - 3, self.canvas.height - 3, true)

    local tmpX = (self.canvas.width - (#self.title * 4)) * .5

    self.canvas:DrawText(self.title:upper(), tmpX, 0, "small", 15, - 4)

    -- TODO need to draw highlight stroke

    self.canvas:SetStroke({15}, 1, 1)
    self.canvas:DrawLine(2, 8, self.canvas.width - 4, 8)
    self.canvas:DrawLine(2, 8, 2, self.canvas.height - 4)


    local spriteData = renameinputfield

    self.canvas:DrawSprites(spriteData.spriteIDs, 8, 16, spriteData.width)

    self.inputField = self.editorUI:CreateInputField({x = self.rect.x + 16, y = self.rect.y + 32, w = 192}, "Untitled", "Enter a new filename.", "file")

    -- Draw message text
    -- local wrap = WordWrap(self.message, (self.rect.w / 4) - 4)
    -- local lines = SplitLines(wrap)
    -- local total = #self.lines
    -- local startX = 8--
    -- local startY = 16--self.rect.y + 8
    --
    -- -- We want to render the text from the bottom of the screen so we offset it and loop backwards.
    -- for i = 1, total do
    --   self.canvas:DrawText(self.lines[i]:upper(), startX, (startY + ((i - 1) * 8)), "medium", 0, - 4)
    -- end


    self.buttons = {}

    -- TODO Create button states?
    --
    -- local buttonSize = {x = 32, y = 16}
    --
    -- local bX = math.floor((((self.rect.w - buttonSize.x) * .5) + self.rect.x) / 8) * 8
    -- local bY = math.floor(((self.rect.y + self.rect.h) - buttonSize.y - 8) / 8) * 8

    local backBtnData = self.editorUI:CreateButton({x = self.rect.x + 184, y = self.rect.y + 48}, "modalokbutton", "Accept the changes.")

    backBtnData.onAction = function()

      self.editorUI:EditInputField(self.inputField, false)

      if(self.onParentClose ~= nil) then
        self.onParentClose()
      end
    end

    local cancelBtnData = self.editorUI:CreateButton({x = self.rect.x + 144, y = self.rect.y + 48}, "modalcancelbutton", "Cancel renaming.")

    cancelBtnData.onAction = function()

      -- Restore the default text value
      self.editorUI:ChangeInputField(self.inputField, self.defaultText)

      -- Close the panel
      if(self.onParentClose ~= nil) then
        self.onParentClose()
      end
    end

    table.insert(self.buttons, backBtnData)
    table.insert(self.buttons, cancelBtnData)

    self.firstRun = false;

  end

  for i = 1, #self.buttons do
    self.editorUI:Invalidate(self.buttons[i])
  end

  self.canvas:DrawPixels(self.rect.x, self.rect.y, DrawMode.TilemapCache)

end

function NewFileModal:ShutdownTextField()
  self.editorUI:EditInputArea(self.inputField, false)
  self.editorUI:ResetValidation(self.inputField)
end

function NewFileModal:Close()

  self:ShutdownTextField()

  local filePath = self.currentDirectory .. self.inputField.text .. "." .. self.ext

  print("Create new file", self.ext, self.inputField.text, self.currentDirectory .. self.inputField.text .. "." .. self.ext)

  NewFile(filePath)
  -- Need to make sure the input field doesn't redraw so


  -- self.inputField.invalid = false
  -- print("Modal Close")
  -- if(self.onParentClose ~= nil) then
  --   self.onParentClose()
  -- end
end

function NewFileModal:Update(timeDelta)

  for i = 1, #self.buttons do
    self.editorUI:UpdateButton(self.buttons[i])
  end

  self.editorUI:UpdateInputField(self.inputField)

end

function NewFileModal:Draw()

end
