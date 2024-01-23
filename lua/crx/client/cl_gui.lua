CRXGUIClass = CRXGUIClass or chicagoRP.NewClass()

local GUIClass = CRXGUIClass

function GUIClass:__constructor()
    self.Frames = {}
    self.Tabs = {}

	self.Font = "DermaDefault"
	self.InfoString = string.format("CRX Admin Mod :: CRP Collective | CRX v%f", CRX_VERSION)
	self.TimeString = "TimeShouldBeHere"

	-- Size of our frame
	self.FrameWidth = 1200
	self.FrameHeight = 840

    self.ThemeColor = chicagoRP.GetSecondaryColor(true)
    self.ThemeColor.a = 200
end

local lastTimeUpdate = 0

function GUIClass:Think()
    -- If the panel isn't active, no need to update the string.
    if !self.MenuOpen then return end

    -- Only update the string (roughly) once per second.
    if lastTimeUpdate > CurTime() + 0.99 then return end

    self.TimeString = os.date(dateParams)

    lastTimeUpdate = CurTime()
end

local dateParams = "%I:%M:%S %p"

function CRXClass:OpenMenu()
    self.MenuOpen = true

    -- Creates the base panels that the GUI is made of.
    local frame = self:BuildBasePanels()

    -- Inserts the menu frame into the frames table.
    table.insert(self.Frames, frame)

    -- Adds the tabs CRX comes with (commands, groups, settings) along with custom ones.
    self:BuildTabs(frame)

    -- Get the DPropertySheet and first tab.
    local sheet = frame:GetChild(1)
    local tabTable = sheet.Items[1]

    -- Set the active tab to the first tab (commands).
    sheet:SetActiveTab(tabTable.Tab)
end

function GUIClass:CloseMenus()
    for i = 1, #self.Frames do
        local frame = self.Frames[i]

        if !IsValid(frame) then return end

        frame:AlphaTo(0, 0.5, 0, function(data, panel)
            if !IsValid(frame) then return end

            frame:Close()
        end)
    end

    -- Empty the frames table.
    self.Frames = {}
end

function GUIClass:CloseMenu(frame)
	if !IsValid(frame) then return end

	frame:AlphaTo(0, 0.5, 0, function(data, panel)
		if !IsValid(frame) then return end

        -- We have to use RemoveByValue because the table is sequential.
        table.RemoveByValue(self.Frames, frame)

		frame:Close()
	end)
end

function GUIClass:BuildBasePanels()
    -- We have to do this to access our class inside of panel functions.
    -- Kind of hacky, but it works and doesn't hurt readability too much.
    local self2 = self

    local frame = vgui.Create("DFrame")
    frame:SetSize(self.FrameWidth, self.FrameHeight)
    frame:Center()
    frame:SetSizable(true)
    frame:SetMinWidth(600)
    frame:SetMinHeight(420)

    local oPerformLayout = frame.PerformLayout   

    function frame:PerformLayout(w, h)
        -- Scale our frame's buttons.
        oPerformLayout(self, w, h)

        -- DPropertySheet scales the active DTab's panel internally.
        -- However, we still need to call our custom PerformLayout method.
        local sheet = self:GetChild(1)
        local tab = sheet:GetActiveTab()

        -- This should never happen but it's best to check anyways.
        if !IsValid(tab) then return end

        local tabInfo = self.Tabs[tab.TabIndex]

        -- Modules aren't always using PerformLayout to scale their panels.
        if !isfunction(tabInfo.PerformLayoutCallback) then return end

        -- Call the tab's custom PerformLayout callback.
        tabInfo.PerformLayoutCallback(tab:GetPanel())
    end

    local oldOnMouseReleased = frame.OnMouseReleased
    local lastW, lastH = self.FrameWidth, self.FrameHeight

    function frame:OnMouseReleased(keycode)
        -- If the keycode isn't mouse1, the frame wasn't being resized.
        if keycode != MOUSE_FIRST then return end

        local newW, newH = self:GetSize()

        -- If the frame's size hasn't changed, do nothing.
        if lastW == newW and lastH == newH then return end

        -- Update last size.
        lastW, lastH = newW, newH

        -- Set frame width/height to the new size.
        self2.FrameWidth, self2.FrameHeight = newW, newH
    end

    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)

    local oldCrossFade = sheet.CrossFade

    function sheet:CrossFade(anim, delta, data)
        oldCrossFade(anim, delta, data)

        if !data or !IsValid(data.OldTab) or !IsValid(data.NewTab) then return end

        local old = data.OldTab:GetPanel()
        local new = data.NewTab:GetPanel()

        -- Check if the animation has just started.
        if IsValid(new) and anim.Started then
            local tabInfo = self.Tabs[data.NewTab.TabIndex]

            -- Add our new tab's panels.
            tabInfo.BuildCallback(new)
        end

        -- Clear the last tab's panels.
        if IsValid(old) and anim.Finished then
            old:Clear()
        end
    end

    infoBar = vgui.Create("DPanel", frame)
    infoBar:SetSize(self.FrameWidth - (self.FrameWidth * 0.05), self.FrameHeight - (self.FrameHeight * 0.95))
    infoBar:SetX(self.FrameWidth * 0.5 - infoBar:GetWide() * 0.5, self.FrameHeight - 1)
    infoBar:NoClipping(true)

    function infoBar:Paint(w, h)
        draw.RoundedBoxEx(4, 0, 1, w, h, self2.ThemeColor, false, false, true, true)

        local centerY = h * 0.5 - select(2, surface.GetTextSize(self2.InfoString)) * 0.5

        -- Version text
        surface.SetTextPos(5, centerY)
        surface.SetTextColor(0, 0, 0, 255)
        surface.DrawText(self2.InfoString)

        -- Time text
        draw.DrawText(self2.TimeString, self2.Font, w - 5, centerY, color_black, TEXT_ALIGN_RIGHT)
    end
end

function GUIClass:BuildTabs(frame)
    if !IsValid(frame) then return end

    -- Get the DPropertySheet.
    local sheet = frame:GetChild(1)

    for i = 1, #self.Tabs do
        local tab = self.Tabs[i]
        local parentPanel = vgui.Create("DPanel", sheet)
        local tabTable = sheet:AddSheet(tab.Name, parentPanel, tab.Icon)

        -- Store the table index in the DTab for later use.
        tabTable.Tab.TabIndex = i
    end
end

local defaultIcon = "icon16/link.png"

function GUIClass:AddTab(name, icon, callback, performlayout)
    if !string.IsValid(name) then return end

    -- You need to provide a callback to build your panels in.
    if !isfunction(callback) then return end

    local tab = {}
    tab.Name = name
    tab.Icon = icon or defaultIcon
    tab.BuildCallback = callback
    tab.PerformLayout = performlayout

    table.insert(self.Tabs, tab)
end

function GUIClass:RemoveTab(name)
    if !string.IsValid(name) then return end

    -- No hashtable so we have to do a loop.
    table.RemoveByValue(self.Tabs, name)
end