CRXGUIClass = CRXGUIClass or chicagoRP.NewClass()

local GUIClass = CRXGUIClass

function GUIClass:__constructor()
	self.Font = "DermaDefault"
	self.InfoString = string.format("CRX Admin Mod :: CRP Collective | CRX v%f", CRX_VERSION)
	self.TimeString = "TimeShouldBeHere"

	-- Size of our frame
	self.FrameWidth = 1200
	self.FrameHeight = 840

    self.ThemeColor = chicagoRP.GetSecondaryColor(true)
    self.ThemeColor.a = 200
end

local dateParams = "%I:%M:%S %p"

function CRXClass:OpenMenu()
    -- Creates the base panels that the GUI is made of.
    self:MakeBasePanels()

    -- Adds the tabs CRX comes with (commands, groups, settings) along with custom ones.
    self:AddTabs()
end

function GUIClass:CloseMenu()
	if !IsValid(self.Frame) then return end

	self.Frame:AlphaTo(0, 0.5, 0, function(data, panel)
		if !IsValid(self.Frame) then return end

		self.Frame:Close()
	end)
end

function GUIClass:MakeBasePanels()
    self.Frame = vgui.Create("DFrame")
    self.Frame:SetSize(self.FrameWidth, self.FrameHeight)
    self.Frame:Center()

    self.Sheet = vgui.Create("DPropertySheet", self.Frame)

    self.InfoBar = vgui.Create("DPanel", self.Frame)
    self.InfoBar:SetSize(self.FrameWidth - (self.FrameWidth * 0.05), self.FrameHeight - (self.FrameHeight * 0.95))
    self.InfoBar:SetX(self.FrameWidth * 0.5 - self:GetWide() * 0.5, self.FrameHeight - 1)
    self.InfoBar:NoClipping(true)

    -- We have to do this to access our class inside of panel functions.
    -- Kind of hacky, but it works and doesn't hurt readability too much.
    local self2 = self

    function self.InfoBar:Paint(w, h)
        draw.RoundedBoxEx(4, 0, 1, w, h, self2.ThemeColor, false, false, true, true)

        local centerY = h * 0.5 - select(2, surface.GetTextSize(self2.InfoString)) * 0.5

        -- Version text
        surface.SetTextPos(5, centerY)
        surface.SetTextColor(0, 0, 0, 255)
        surface.DrawText(self2.InfoString)

        -- Time text
        draw.DrawText(self2.TimeString, self2.Font, w - 5, centerY, color_black, TEXT_ALIGN_RIGHT)
    end

    local lastTimeUpdate = 0

    function self.InfoBar:Think()
        if lastTimeUpdate > CurTime() + 0.99 then return end

        self2.TimeString = os.date(dateParams)

        lastTimeUpdate = CurTime()
    end
end

function GUIClass:AddTabs()
    -- Make command panels
    -- functionnamehere()

    -- Add custom tabs here.
    -- ???() 

    -- Make group panels
    -- functionnamehere()

    -- Make settings panels
    -- functionnamehere()
end