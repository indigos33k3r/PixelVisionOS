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
function PixelVisionOS:OpenModal(modal, callBack)

  -- Try to close the modal first
  -- self:CloseModal()

  SaveTilemapCache()

  -- Clear the mouse focus
  self.editorUI:ClearFocus()

  -- Set the active modal
  self.activeModal = modal

  -- Route the onClose to this close method
  self.activeModal.onParentClose = function()
    self:CloseModal()
  end

  self.onCloseCallback = callBack

  -- Activate the new modal
  self.activeModal:Open()

  -- Disable the menu button in the toolbar
  self.editorUI:Enable(self.titleBar.iconButton, false)

end

function PixelVisionOS:CloseModal()
  if(self.activeModal ~= nil) then
    self.activeModal:Close()

    RestoreTilemapCache()

    self.editorUI:ClearFocus()

    -- TODO need to restore the title bar time

  end

  self.activeModal = nil

  -- print("Modal Callback", onCloseCallback ~= nil)
  -- Trigger the callback so other objects can know when the modal is closed
  if(self.onCloseCallback ~= nil) then
    self.onCloseCallback()

    self.onCloseCallback = nil
  end

  -- Enable the menu button in the toolbar
  self.editorUI:Enable(self.titleBar.iconButton, true)

end

function PixelVisionOS:UpdateModal(deltaTime)

  if(self.activeModal == nil) then
    return;
  end

  self.activeModal:Update(deltaTime)

end

function PixelVisionOS:DrawModal()

  if(self.activeModal == nil) then
    return;
  end

  self.activeModal:Draw()

end

function PixelVisionOS:IsModalActive()
  return self.activeModal ~= nil
end
