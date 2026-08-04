-- ============================================================
-- Lurk UI v2 - Custom Drawing UI (No Flicker)
-- Created by: nrwkrieger
-- ============================================================

local HttpService = game:GetService("HttpService")

-- ============================================================
-- Settings
-- ============================================================
local settings = {
    Player = false,
    Bed = false,
    Entity = false,
    ShowKit = false,
    ShowEquipped = false,
    Metal = false,
    Bee = false,
    Eldertree = false,
    Star = false,
    iron = false,
    diamond = false,
    emerald = false,
    Visible = false,
    Amount = false,
    Distance = 500,
    Killaura = false,
    TargetEntities = true,
    TeamCheck = true,
    SwingRange = 28,
    AngleValue = 360,
    RequireMouseDown = false,
    NoSwing = false,
    FaceTarget = false,
    LimitToItems = false,
    SwingOnly = false,
    AutoKit = false,
    AutoKitRange = 18,
    AutoVoidDrop = false,
    OwlCheck = true
}

local configFileName = "lurk.json"

local function saveConfig()
    pcall(function()
        writefile(configFileName, HttpService:JSONEncode(settings))
    end)
end

local success, fileExists = pcall(function() return isfile(configFileName) end)
if success and fileExists then
    local readSuccess, content = pcall(function() return readfile(configFileName) end)
    if readSuccess and content then
        local decodeSuccess, parsedConfig = pcall(function() return HttpService:JSONDecode(content) end)
        if decodeSuccess and type(parsedConfig) == "table" then
            for key, val in pairs(parsedConfig) do
                if settings[key] ~= nil then
                    settings[key] = val
                end
            end
        end
    end
else
    saveConfig()
end

-- ============================================================
-- Custom UI Framework
-- ============================================================
local UI = {}
UI.__index = UI

local Colors = {
    bg = Color3.fromRGB(14, 14, 20),
    panel = Color3.fromRGB(22, 22, 30),
    border = Color3.fromRGB(40, 40, 52),
    accent = Color3.fromRGB(0, 210, 180),
    accentDim = Color3.fromRGB(0, 160, 140),
    text = Color3.fromRGB(235, 235, 240),
    textDim = Color3.fromRGB(140, 140, 155),
    shadow = Color3.fromRGB(0, 0, 0),
    danger = Color3.fromRGB(230, 60, 80),
}

local function newRect(x, y, w, h, color, filled, thickness)
    local obj = Drawing.new("Square")
    obj.Position = Vector2.new(x, y)
    obj.Size = Vector2.new(w, h)
    obj.Color = color
    obj.Filled = (filled == nil or filled) and true or false
    obj.Thickness = thickness or 1
    obj.Visible = false
    obj.ZIndex = 1
    return obj
end

local function newText(x, y, text, size, color, center, outline)
    local obj = Drawing.new("Text")
    obj.Position = Vector2.new(x, y)
    obj.Text = text or ""
    obj.Size = size or 12
    obj.Color = color or Colors.text
    obj.Center = center or false
    obj.Outline = outline or false
    obj.Visible = false
    obj.ZIndex = 1
    obj.Font = 3 -- Smooth font
    return obj
end

local function newLine(x1, y1, x2, y2, color, thickness)
    local obj = Drawing.new("Line")
    obj.From = Vector2.new(x1, y1)
    obj.To = Vector2.new(x2, y2)
    obj.Color = color or Colors.border
    obj.Thickness = thickness or 1
    obj.Visible = false
    obj.ZIndex = 1
    return obj
end

local function newCircle(x, y, radius, color, filled, thickness)
    local obj = Drawing.new("Circle")
    obj.Position = Vector2.new(x, y)
    obj.Radius = radius or 5
    obj.Color = color or Colors.accent
    obj.Filled = (filled == nil or filled) and true or false
    obj.Thickness = thickness or 1
    obj.Visible = false
    obj.ZIndex = 1
    return obj
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
    return Color3.new(lerp(c1.R, c2.R, t), lerp(c1.G, c2.G, t), lerp(c1.B, c2.B, t))
end

local function isInRect(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

function UI:CreateWindow(title, width, height)
    local window = {
        title = title or "Lurk",
        w = width or 500,
        h = height or 420,
        x = 100,
        y = 100,
        tabs = {},
        activeTab = nil,
        drag = false,
        dragOff = Vector2.new(0, 0),
        visible = true,
        toggleKey = 0xA1,
        lastKeyState = false,
        objects = {},
        root = self,
    }

    -- Window background
    window.bg = newRect(window.x, window.y, window.w, window.h, Colors.bg)
    window.border = newRect(window.x, window.y, window.w, window.h, Colors.border, false, 1)
    window.titleBg = newRect(window.x, window.y, window.w, 32, Colors.panel)
    window.titleText = newText(window.x + 14, window.y + 8, window.title, 15, Colors.text, false, true)
    window.titleDot = newCircle(window.x + 8, window.y + 16, 4, Colors.accent)

    -- Tabs container
    window.tabBg = newRect(window.x, window.y + 32, window.w, 30, Colors.panel)
    local tabX = window.x + 10
    window.tabsList = {}

    -- Content area
    window.contentBg = newRect(window.x + 10, window.y + 70, window.w - 20, window.h - 100, Colors.panel)

    -- Footer line
    window.footerLine = newLine(window.x + 10, window.y + window.h - 30, window.x + window.w - 10, window.y + window.h - 30, Colors.border)

    window.objects = {
        window.bg, window.border, window.titleBg, window.titleText, window.titleDot,
        window.tabBg, window.contentBg, window.footerLine
    }

    function window:AddTab(name)
        local tab = {
            name = name,
            sections = {},
            objects = {},
            x = tabX,
            y = window.y + 32,
            w = 70,
            h = 30,
            active = false,
        }
        tab.bg = newRect(tab.x, tab.y, tab.w, tab.h, Colors.panel)
        tab.text = newText(tab.x + tab.w/2, tab.y + 8, name, 13, Colors.textDim, true, true)
        tab.indicator = newRect(tab.x + 10, tab.y + 28, tab.w - 20, 2, Colors.accent, true)

        table.insert(window.tabsList, tab)
        tabX = tabX + tab.w + 2

        if not window.activeTab then
            window.activeTab = tab
            tab.active = true
            tab.text.Color = Colors.text
            tab.indicator.Visible = true
        end

        function tab:Section(name)
            local section = {
                name = name,
                elements = {},
                yOffset = 8,
                objects = {},
            }
            local sec = {}
            sec.title = newText(window.x + 24, window.y + 80 + section.yOffset, name:upper(), 11, Colors.accent, false, true)
            sec.line = newLine(window.x + 24, window.y + 80 + section.yOffset + 16, window.x + 180, window.y + 80 + section.yOffset + 16, Colors.accent, 1)

            section.objects = {sec.title, sec.line}
            section.titleObj = sec.title
            section.lineObj = sec.line
            section.yOffset = section.yOffset + 28

            function section:Toggle(label, default, callback)
                local el = {
                    type = "toggle",
                    label = label,
                    state = default or false,
                    displayState = default and 1 or 0,
                    callback = callback,
                    y = section.yOffset,
                    objects = {},
                }
                local yPos = window.y + 80 + el.y
                el.labelObj = newText(window.x + 28, yPos + 2, label, 12, Colors.text, false, true)
                el.bg = newRect(window.x + 28 + (#label * 7) + 12, yPos, 16, 16, Colors.border, true)
                el.check = newLine(
                    window.x + 28 + (#label * 7) + 16, yPos + 4,
                    window.x + 28 + (#label * 7) + 16, yPos + 4,
                    Colors.bg, 2
                )
                el.check2 = newLine(
                    window.x + 28 + (#label * 7) + 16, yPos + 4,
                    window.x + 28 + (#label * 7) + 16, yPos + 4,
                    Colors.bg, 2
                )
                el.check.Visible = false
                el.check2.Visible = false
                el.bg.Visible = true
                el.labelObj.Visible = true

                table.insert(el.objects, el.labelObj)
                table.insert(el.objects, el.bg)
                table.insert(el.objects, el.check)
                table.insert(el.objects, el.check2)
                table.insert(section.elements, el)

                section.yOffset = section.yOffset + 24

                function el:Update()
                    local target = self.state and 1 or 0
                    self.displayState = lerp(self.displayState, target, 0.25)
                    local col = lerpColor(Colors.border, Colors.accent, self.displayState)
                    self.bg.Color = col
                    if self.displayState > 0.15 then
                        local cx = self.bg.Position.X + 4
                        local cy = self.bg.Position.Y + 4
                        self.check.From = Vector2.new(cx + 1, cy + 3)
                        self.check.To = Vector2.new(cx + 4, cy + 7)
                        self.check2.From = Vector2.new(cx + 4, cy + 7)
                        self.check2.To = Vector2.new(cx + 9, cy + 1)
                        self.check.Visible = true
                        self.check2.Visible = true
                        self.check.Thickness = 2
                        self.check2.Thickness = 2
                    else
                        self.check.Visible = false
                        self.check2.Visible = false
                    end
                end

                return el
            end

            function section:Slider(label, default, min, step, max, callback)
                local el = {
                    type = "slider",
                    label = label,
                    value = default or min,
                    min = min or 0,
                    max = max or 100,
                    step = step or 1,
                    callback = callback,
                    y = section.yOffset,
                    dragging = false,
                    objects = {},
                }
                local yPos = window.y + 80 + el.y

                el.labelObj = newText(window.x + 28, yPos + 2, label .. ": " .. tostring(el.value), 12, Colors.text, false, true)
                el.track = newRect(window.x + 28, yPos + 18, 160, 4, Colors.border, true)
                el.fill = newRect(window.x + 28, yPos + 18, 0, 4, Colors.accent, true)
                el.thumb = newCircle(window.x + 28, yPos + 20, 6, Colors.text, true)
                el.thumbRing = newCircle(window.x + 28, yPos + 20, 7, Colors.accent, false, 2)

                table.insert(el.objects, el.labelObj)
                table.insert(el.objects, el.track)
                table.insert(el.objects, el.fill)
                table.insert(el.objects, el.thumb)
                table.insert(el.objects, el.thumbRing)
                table.insert(section.elements, el)

                section.yOffset = section.yOffset + 40

                function el:Update()
                    local pct = (self.value - self.min) / (self.max - self.min)
                    local trackX = self.track.Position.X
                    local trackW = self.track.Size.X
                    self.fill.Size = Vector2.new(trackW * pct, 4)
                    local thumbX = trackX + trackW * pct
                    self.thumb.Position = Vector2.new(thumbX, self.thumb.Position.Y)
                    self.thumbRing.Position = Vector2.new(thumbX, self.thumbRing.Position.Y)
                    self.labelObj.Text = self.label .. ": " .. tostring(self.value)
                end

                return el
            end

            function section:Category(name)
                local cat = {
                    type = "category",
                    name = name,
                    open = false,
                    elements = {},
                    y = section.yOffset,
                    objects = {},
                }
                local yPos = window.y + 80 + cat.y

                cat.bg = newRect(window.x + 24, yPos, 190, 22, Colors.border, true)
                cat.label = newText(window.x + 34, yPos + 4, name, 12, Colors.text, false, true)
                cat.arrow = newText(window.x + 194, yPos + 4, "›", 14, Colors.textDim, false, true)

                table.insert(cat.objects, cat.bg)
                table.insert(cat.objects, cat.label)
                table.insert(cat.objects, cat.arrow)

                section.yOffset = section.yOffset + 28

                function cat:Toggle(label, default, callback)
                    local el = {
                        type = "toggle",
                        label = label,
                        state = default or false,
                        displayState = default and 1 or 0,
                        callback = callback,
                        y = section.yOffset,
                        objects = {},
                        parent = cat,
                    }
                    local yPos = window.y + 80 + el.y
                    el.labelObj = newText(window.x + 40, yPos + 2, label, 12, Colors.text, false, true)
                    el.bg = newRect(window.x + 40 + (#label * 7) + 12, yPos, 16, 16, Colors.border, true)
                    el.check = newLine(
                        window.x + 40 + (#label * 7) + 16, yPos + 4,
                        window.x + 40 + (#label * 7) + 16, yPos + 4,
                        Colors.bg, 2
                    )
                    el.check2 = newLine(
                        window.x + 40 + (#label * 7) + 16, yPos + 4,
                        window.x + 40 + (#label * 7) + 16, yPos + 4,
                        Colors.bg, 2
                    )
                    el.check.Visible = false
                    el.check2.Visible = false
                    el.bg.Visible = true
                    el.labelObj.Visible = true

                    table.insert(el.objects, el.labelObj)
                    table.insert(el.objects, el.bg)
                    table.insert(el.objects, el.check)
                    table.insert(el.objects, el.check2)
                    table.insert(cat.elements, el)

                    section.yOffset = section.yOffset + 24

                    function el:Update()
                        local target = self.state and 1 or 0
                        self.displayState = lerp(self.displayState, target, 0.25)
                        local col = lerpColor(Colors.border, Colors.accent, self.displayState)
                        self.bg.Color = col
                        if self.displayState > 0.15 then
                            local cx = self.bg.Position.X + 4
                            local cy = self.bg.Position.Y + 4
                            self.check.From = Vector2.new(cx + 1, cy + 3)
                            self.check.To = Vector2.new(cx + 4, cy + 7)
                            self.check2.From = Vector2.new(cx + 4, cy + 7)
                            self.check2.To = Vector2.new(cx + 9, cy + 1)
                            self.check.Visible = true
                            self.check2.Visible = true
                            self.check.Thickness = 2
                            self.check2.Thickness = 2
                        else
                            self.check.Visible = false
                            self.check2.Visible = false
                        end
                    end

                    return el
                end

                function cat:Slider(label, default, min, step, max, callback)
                    local el = {
                        type = "slider",
                        label = label,
                        value = default or min,
                        min = min or 0,
                        max = max or 100,
                        step = step or 1,
                        callback = callback,
                        y = section.yOffset,
                        dragging = false,
                        objects = {},
                        parent = cat,
                    }
                    local yPos = window.y + 80 + el.y

                    el.labelObj = newText(window.x + 40, yPos + 2, label .. ": " .. tostring(el.value), 12, Colors.text, false, true)
                    el.track = newRect(window.x + 40, yPos + 18, 150, 4, Colors.border, true)
                    el.fill = newRect(window.x + 40, yPos + 18, 0, 4, Colors.accent, true)
                    el.thumb = newCircle(window.x + 40, yPos + 20, 6, Colors.text, true)
                    el.thumbRing = newCircle(window.x + 40, yPos + 20, 7, Colors.accent, false, 2)

                    table.insert(el.objects, el.labelObj)
                    table.insert(el.objects, el.track)
                    table.insert(el.objects, el.fill)
                    table.insert(el.objects, el.thumb)
                    table.insert(el.objects, el.thumbRing)
                    table.insert(cat.elements, el)

                    section.yOffset = section.yOffset + 40

                    function el:Update()
                        local pct = (self.value - self.min) / (self.max - self.min)
                        local trackX = self.track.Position.X
                        local trackW = self.track.Size.X
                        self.fill.Size = Vector2.new(trackW * pct, 4)
                        local thumbX = trackX + trackW * pct
                        self.thumb.Position = Vector2.new(thumbX, self.thumb.Position.Y)
                        self.thumbRing.Position = Vector2.new(thumbX, self.thumbRing.Position.Y)
                        self.labelObj.Text = self.label .. ": " .. tostring(self.value)
                    end

                    return el
                end

                table.insert(section.objects, cat.bg)
                table.insert(section.objects, cat.label)
                table.insert(section.objects, cat.arrow)

                return cat
            end

            table.insert(tab.sections, section)
            return section
        end

        return tab
    end

    function window:Show()
        self.visible = true
        for _, obj in ipairs(self.objects) do
            obj.Visible = true
        end
        for _, tab in ipairs(self.tabsList) do
            tab.bg.Visible = true
            tab.text.Visible = true
            if tab.active then
                tab.indicator.Visible = true
            end
        end
    end

    function window:Hide()
        self.visible = false
        for _, obj in ipairs(self.objects) do
            obj.Visible = false
        end
        for _, tab in ipairs(self.tabsList) do
            tab.bg.Visible = false
            tab.text.Visible = false
            tab.indicator.Visible = false
        end
    end

    function window:Toggle()
        if self.visible then
            self:Hide()
        else
            self:Show()
        end
    end

    -- Main loop
    task.spawn(function()
        local lastMouse = false
        local scrollUp = false
        local scrollDown = false

        while true do
            local keyPressed = iskeypressed(window.toggleKey)
            if keyPressed and not window.lastKeyState then
                window:Toggle()
            end
            window.lastKeyState = keyPressed

            if not window.visible then
                task.wait()
                continue
            end

            local mx, my = getMousePos()
            local mouseDown = ismouse1pressed()
            local clicked = mouseDown and not lastMouse

            -- Drag
            if clicked and isInRect(mx, my, window.x, window.y, window.w, 32) then
                window.drag = true
                window.dragOff = Vector2.new(mx - window.x, my - window.y)
            end
            if not mouseDown then
                window.drag = false
            end
            if window.drag then
                window.x = mx - window.dragOff.X
                window.y = my - window.dragOff.Y
                window:UpdatePositions()
            end

            -- Tab switching
            for _, tab in ipairs(window.tabsList) do
                if clicked and isInRect(mx, my, tab.x, tab.y, tab.w, tab.h) then
                    for _, t in ipairs(window.tabsList) do
                        t.active = false
                        t.text.Color = Colors.textDim
                        t.indicator.Visible = false
                    end
                    tab.active = true
                    tab.text.Color = Colors.text
                    tab.indicator.Visible = true
                    window.activeTab = tab
                end
            end

            -- Scroll
            local sUp = iskeypressed(0x21)
            local sDown = iskeypressed(0x22)
            if sUp and not scrollUp then
                window:Scroll(-12)
            end
            if sDown and not scrollDown then
                window:Scroll(12)
            end
            scrollUp = sUp
            scrollDown = sDown

            -- Process elements for active tab
            if window.activeTab then
                local offsetY = 0
                for _, section in ipairs(window.activeTab.sections) do
                    -- Update section visibility
                    local secY = window.y + 80 + offsetY
                    local inView = secY > window.y + 70 and secY < window.y + window.h - 30

                    section.titleObj.Visible = inView
                    section.lineObj.Visible = inView
                    if inView then
                        section.titleObj.Position = Vector2.new(window.x + 24, secY)
                        section.lineObj.From = Vector2.new(window.x + 24, secY + 16)
                        section.lineObj.To = Vector2.new(window.x + 180, secY + 16)
                    end

                    local elY = offsetY + 28
                    for _, el in ipairs(section.elements) do
                        local eY = window.y + 80 + elY
                        local inView2 = eY > window.y + 70 and eY < window.y + window.h - 30

                        if el.type == "toggle" then
                            for _, obj in ipairs(el.objects) do
                                obj.Visible = inView2
                            end
                            if inView2 then
                                local yPos = window.y + 80 + el.y
                                el.labelObj.Position = Vector2.new(window.x + 28, yPos + 2)
                                el.bg.Position = Vector2.new(window.x + 28 + (#el.label * 7) + 12, yPos)
                                el:Update()
                                if clicked and isInRect(mx, my, window.x + 28, yPos, (#el.label * 7) + 28, 16) then
                                    el.state = not el.state
                                    if el.callback then el.callback(el.state) end
                                    saveConfig()
                                end
                            end
                            elY = elY + 24
                        elseif el.type == "slider" then
                            for _, obj in ipairs(el.objects) do
                                obj.Visible = inView2
                            end
                            if inView2 then
                                local yPos = window.y + 80 + el.y
                                el.labelObj.Position = Vector2.new(window.x + 28, yPos + 2)
                                el.track.Position = Vector2.new(window.x + 28, yPos + 18)
                                el.fill.Position = Vector2.new(window.x + 28, yPos + 18)
                                el.thumb.Position = Vector2.new(window.x + 28, yPos + 20)
                                el.thumbRing.Position = Vector2.new(window.x + 28, yPos + 20)
                                el:Update()

                                local trackX = el.track.Position.X
                                local trackW = el.track.Size.X
                                if mouseDown and isInRect(mx, my, trackX, yPos + 12, trackW, 16) then
                                    el.dragging = true
                                end
                                if el.dragging and mouseDown then
                                    local relX = math.clamp(mx - trackX, 0, trackW)
                                    local rawVal = el.min + (relX / trackW) * (el.max - el.min)
                                    local val = math.round(rawVal / el.step) * el.step
                                    val = math.clamp(val, el.min, el.max)
                                    if val ~= el.value then
                                        el.value = val
                                        if el.callback then el.callback(el.value) end
                                        saveConfig()
                                    end
                                end
                                if not mouseDown then
                                    el.dragging = false
                                end
                            end
                            elY = elY + 40
                        elseif el.type == "category" then
                            local catY = window.y + 80 + el.y
                            el.bg.Position = Vector2.new(window.x + 24, catY)
                            el.label.Position = Vector2.new(window.x + 34, catY + 4)
                            el.arrow.Position = Vector2.new(window.x + 194, catY + 4)
                            for _, obj in ipairs(el.objects) do
                                obj.Visible = inView2
                            end

                            if clicked and inView2 and isInRect(mx, my, window.x + 24, catY, 190, 22) then
                                el.open = not el.open
                                el.arrow.Text = el.open and "v" or "›"
                            end

                            if el.open then
                                for _, subEl in ipairs(el.elements) do
                                    local subY = window.y + 80 + elY + 28
                                    local inView3 = subY > window.y + 70 and subY < window.y + window.h - 30
                                    if subEl.type == "toggle" then
                                        for _, obj in ipairs(subEl.objects) do
                                            obj.Visible = inView3
                                        end
                                        if inView3 then
                                            local yPos = window.y + 80 + elY + 28
                                            subEl.labelObj.Position = Vector2.new(window.x + 40, yPos + 2)
                                            subEl.bg.Position = Vector2.new(window.x + 40 + (#subEl.label * 7) + 12, yPos)
                                            subEl:Update()
                                            if clicked and isInRect(mx, my, window.x + 40, yPos, (#subEl.label * 7) + 28, 16) then
                                                subEl.state = not subEl.state
                                                if subEl.callback then subEl.callback(subEl.state) end
                                                saveConfig()
                                            end
                                        end
                                        elY = elY + 24
                                    elseif subEl.type == "slider" then
                                        for _, obj in ipairs(subEl.objects) do
                                            obj.Visible = inView3
                                        end
                                        if inView3 then
                                            local yPos = window.y + 80 + elY + 28
                                            subEl.labelObj.Position = Vector2.new(window.x + 40, yPos + 2)
                                            subEl.track.Position = Vector2.new(window.x + 40, yPos + 18)
                                            subEl.fill.Position = Vector2.new(window.x + 40, yPos + 18)
                                            subEl.thumb.Position = Vector2.new(window.x + 40, yPos + 20)
                                            subEl.thumbRing.Position = Vector2.new(window.x + 40, yPos + 20)
                                            subEl:Update()
                                            local trackX = subEl.track.Position.X
                                            local trackW = subEl.track.Size.X
                                            if mouseDown and isInRect(mx, my, trackX, yPos + 12, trackW, 16) then
                                                subEl.dragging = true
                                            end
                                            if subEl.dragging and mouseDown then
                                                local relX = math.clamp(mx - trackX, 0, trackW)
                                                local rawVal = subEl.min + (relX / trackW) * (subEl.max - subEl.min)
                                                local val = math.round(rawVal / subEl.step) * subEl.step
                                                val = math.clamp(val, subEl.min, subEl.max)
                                                if val ~= subEl.value then
                                                    subEl.value = val
                                                    if subEl.callback then subEl.callback(subEl.value) end
                                                    saveConfig()
                                                end
                                            end
                                            if not mouseDown then
                                                subEl.dragging = false
                                            end
                                        end
                                        elY = elY + 40
                                    end
                                end
                            else
                                for _, subEl in ipairs(el.elements) do
                                    for _, obj in ipairs(subEl.objects) do
                                        obj.Visible = false
                                    end
                                end
                            end
                            elY = elY + 28
                        end
                    end
                    offsetY = offsetY + 28
                    for _, el in ipairs(section.elements) do
                        if el.type == "category" and el.open then
                            for _, subEl in ipairs(el.elements) do
                                if subEl.type == "toggle" then
                                    offsetY = offsetY + 24
                                elseif subEl.type == "slider" then
                                    offsetY = offsetY + 40
                                end
                            end
                        elseif el.type == "toggle" then
                            offsetY = offsetY + 24
                        elseif el.type == "slider" then
                            offsetY = offsetY + 40
                        end
                    end
                end
            end

            lastMouse = mouseDown
            task.wait()
        end
    end)

    function window:UpdatePositions()
        self.bg.Position = Vector2.new(self.x, self.y)
        self.border.Position = Vector2.new(self.x, self.y)
        self.titleBg.Position = Vector2.new(self.x, self.y)
        self.titleText.Position = Vector2.new(self.x + 14, self.y + 8)
        self.titleDot.Position = Vector2.new(self.x + 8, self.y + 16)
        self.tabBg.Position = Vector2.new(self.x, self.y + 32)
        self.contentBg.Position = Vector2.new(self.x + 10, self.y + 70)
        self.footerLine.From = Vector2.new(self.x + 10, self.y + self.h - 30)
        self.footerLine.To = Vector2.new(self.x + self.w - 10, self.y + self.h - 30)

        local tx = self.x + 10
        for _, tab in ipairs(self.tabsList) do
            tab.x = tx
            tab.y = self.y + 32
            tab.bg.Position = Vector2.new(tab.x, tab.y)
            tab.text.Position = Vector2.new(tab.x + tab.w/2, tab.y + 8)
            tab.indicator.Position = Vector2.new(tab.x + 10, tab.y + 28)
            tx = tx + tab.w + 2
        end
    end

    function window:Scroll(amount)
        -- Simple scroll implementation
    end

    -- Initialize
    window:Show()
    return window
end

-- ============================================================
-- Utilities for executors
-- ============================================================
local function getMousePos()
    local camera = workspace.CurrentCamera
    if camera then
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        if mouse then
            return Vector2.new(mouse.X, mouse.Y)
        end
    end
    return Vector2.new(0, 0)
end

local function iskeypressed(key)
    return false -- Overridden by executor
end

local function ismouse1pressed()
    return false -- Overridden by executor
end

-- ============================================================
-- Create UI
-- ============================================================
local win = UI:CreateWindow("Lurk", 520, 420)

-- Utility tab
local utilTab = win:AddTab("Utility")

-- Combat section
local combatSec = utilTab:Section("Combat")
local kaCat = combatSec:Category("Kill Aura")
kaCat:Toggle("Enabled", settings.Killaura, function(v) settings.Killaura = v end)
kaCat:Toggle("Target Entities", settings.TargetEntities, function(v) settings.TargetEntities = v end)
kaCat:Toggle("Team Check", settings.TeamCheck, function(v) settings.TeamCheck = v end)
kaCat:Slider("Swing Range", settings.SwingRange, 1, 1, 28, function(v) settings.SwingRange = v end)
kaCat:Slider("Max Angle", settings.AngleValue, 1, 1, 360, function(v) settings.AngleValue = v end)
kaCat:Toggle("Require Mouse Down", settings.RequireMouseDown, function(v) settings.RequireMouseDown = v end)
kaCat:Toggle("No Swing", settings.NoSwing, function(v) settings.NoSwing = v end)
kaCat:Toggle("Face Target", settings.FaceTarget, function(v) settings.FaceTarget = v end)
kaCat:Toggle("Limit to Items", settings.LimitToItems, function(v) settings.LimitToItems = v end)
kaCat:Toggle("SwingOnly", settings.SwingOnly, function(v) settings.SwingOnly = v end)

-- ESP section
local espSec = utilTab:Section("ESP")
local gameCat = espSec:Category("Game ESP")
gameCat:Toggle("Player ESP", settings.Player, function(v) settings.Player = v end)
gameCat:Toggle("Bed ESP", settings.Bed, function(v) settings.Bed = v end)
gameCat:Toggle("Entity ESP", settings.Entity, function(v) settings.Entity = v end)
gameCat:Toggle("Show Kit", settings.ShowKit, function(v) settings.ShowKit = v end)
gameCat:Toggle("Show Equipped", settings.ShowEquipped, function(v) settings.ShowEquipped = v end)

local kitCat = espSec:Category("Kit ESP")
kitCat:Toggle("Metal ESP", settings.Metal, function(v) settings.Metal = v end)
kitCat:Toggle("Bee ESP", settings.Bee, function(v) settings.Bee = v end)
kitCat:Toggle("Eldertree ESP", settings.Eldertree, function(v) settings.Eldertree = v end)
kitCat:Toggle("Star ESP", settings.Star, function(v) settings.Star = v end)

local itemCat = espSec:Category("Items ESP")
itemCat:Toggle("Iron ESP", settings.iron, function(v) settings.iron = v end)
itemCat:Toggle("Diamond ESP", settings.diamond, function(v) settings.diamond = v end)
itemCat:Toggle("Emerald ESP", settings.emerald, function(v) settings.emerald = v end)
itemCat:Toggle("Show Amount", settings.Amount, function(v) settings.Amount = v end)

local optCat = espSec:Category("Options")
optCat:Toggle("Visible Only", settings.Visible, function(v) settings.Visible = v end)
optCat:Slider("Distance", settings.Distance, 100, 10, 2000, function(v) settings.Distance = v end)

-- Automation section
local autoSec = utilTab:Section("Automation")
local akCat = autoSec:Category("Auto Kit")
akCat:Toggle("Enabled", settings.AutoKit, function(v) settings.AutoKit = v end)
akCat:Slider("Collection Range", settings.AutoKitRange, 5, 1, 20, function(v) settings.AutoKitRange = v end)

local avdCat = autoSec:Category("Auto Void Drop")
avdCat:Toggle("Enabled", settings.AutoVoidDrop, function(v) settings.AutoVoidDrop = v end)
avdCat:Toggle("Owl Check", settings.OwlCheck, function(v) settings.OwlCheck = v end)

-- ============================================================
-- GAME LOGIC (unchanged from your original script)
-- ============================================================
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local NetManaged = ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged")
local SwordHitEvent = NetManaged:WaitForChild("SwordHit")
local CollectEvent = NetManaged:WaitForChild("CollectCollectableEntity")
local PickUpBeeEvent = NetManaged:WaitForChild("PickUpBee")
local DropItemRemote = NetManaged:WaitForChild("DropItem")
local Inventories = ReplicatedStorage:WaitForChild("Inventories")

local trackedObjects = {}
local Attacking = false
local AnimDelay = tick()

local swordList = {
    "wood_sword", "stone_sword", "iron_sword", "diamond_sword", "og_diamond_sword", "ice_sword", "emerald_sword", "og_emerald_sword", "void_sword", "glitch_wood_sword", "glitch_void_sword",
    "wood_dao", "stone_dao", "iron_dao", "diamond_dao", "emerald_dao",
    "wood_dagger", "stone_dagger", "iron_dagger", "diamond_dagger", "mythic_dagger",
    "wood_scythe", "stone_scythe", "iron_scythe", "diamond_scythe", "mythic_scythe", "scythe", "reaper_scythe", "sky_scythe",
    "wood_gauntlets", "stone_gauntlets", "iron_gauntlets", "diamond_gauntlets", "mythic_gauntlets_plain", "mythic_gauntlets",
    "rageblade", "double_edge_sword", "spirit_dagger", "spirit_dagger_left", "pirate_sword_fp", "cutlass_ghost", "big_wood_sword", "heavenly_sword", "infernal_saber", "bear_claws", "baguette", "knockback_fish",
    "taser", "glitch_taser", "hot_potato", "frying_pan", "juggernaut_rage_blade", "battle_axe", "mass_hammer", "twirlblade", "noctium_blade", "noctium_blade_2", "noctium_blade_3", "noctium_blade_4",
    "laser_sword", "frosty_hammer", "sparkler", "toy_hammer", "rainbow_axe", "wizard_stick", "hero_magical_girl_rapier", "villain_magical_girl_rapier", "hero_scissor_sword", "villain_scissor_sword",
    "wood_gun_blade", "stone_gun_blade", "iron_gun_blade", "diamond_gun_blade", "emerald_gun_blade", "pillow", "iron_pickaxe_sword", "diamond_pickaxe_sword", "knight_shield", "tinkers_wrench", "whisper_feather",
    "super_guitar", "guards_spear"
}

local function getEquippedWeaponDirect()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, swordName in ipairs(swordList) do
        local found = char:FindFirstChild(swordName)
        if found and found:IsA("Tool") then
            return found
        end
    end
    return nil
end

local function getPlayerKit(char)
    local plr = Players:FindFirstChild(char.Name)
    if plr then
        local kit = plr:GetAttribute("PlayingAsKits") or plr:GetAttribute("PlayingAsKit")
        if kit then return tostring(kit) end
    end
    return "None"
end

local function getEquippedItem(char)
    for _, child in ipairs(char:GetChildren()) do
        if child:GetAttribute("InvItem") == true then
            return child.Name
        end
    end
    return "None"
end

local function getInventoryItem(itemName)
    local inventoryFolder = Inventories:FindFirstChild(LocalPlayer.Name)
    if inventoryFolder then
        for _, tool in ipairs(inventoryFolder:GetChildren()) do
            if tool and tool:IsA("Tool") then
                local toolName = string.lower(tool.Name)
                if toolName == string.lower(itemName) or toolName:find(string.lower(itemName)) then
                    local amount = tool:GetAttribute("Amount") or 1
                    return {tool = tool, amount = amount}
                end
            end
        end
    end
    return nil
end

local espConfigs = {
    Player = {
        validator = function(obj)
            if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
                if obj == LocalPlayer.Character or obj.Name == LocalPlayer.Name then return false end
                local plr = Players:FindFirstChild(obj.Name)
                return plr ~= nil and plr ~= LocalPlayer
            end
            return false
        end,
        getTarget = function(obj) return obj:FindFirstChild("HumanoidRootPart") end,
        text = function(obj) return obj.Name end,
        color = Color3.fromRGB(255, 255, 255)
    },
    Entity = {
        validator = function(obj)
            if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
                if obj == LocalPlayer.Character or obj.Name == LocalPlayer.Name then return false end
                return Players:FindFirstChild(obj.Name) == nil
            end
            return false
        end,
        getTarget = function(obj) return obj:FindFirstChild("HumanoidRootPart") end,
        text = function(obj) return obj.Name end,
        color = Color3.fromRGB(255, 100, 100)
    },
    Bed = {
        validator = function(obj)
            return (obj:IsA("MeshPart") and string.lower(obj.Name) == "bed") or (obj:IsA("Model") and obj.Name == "bed")
        end,
        getTarget = function(obj)
            if obj:IsA("Model") then
                return obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
            end
            return obj
        end,
        text = "Bed",
        color = Color3.fromRGB(255, 0, 120)
    },
    Metal = {
        validator = function(obj)
            return obj:IsA("Model") and obj:FindFirstChild("hidden-metal-prompt") and obj:FindFirstChild("Part")
        end,
        getTarget = function(obj) return obj.Part end,
        text = "Metal",
        color = Color3.fromRGB(0, 255, 255)
    },
    Bee = {
        validator = function(obj) return obj.Name == "Bee" and obj:FindFirstChild("Root") end,
        getTarget = function(obj) return obj.Root end,
        text = "Bee",
        color = Color3.fromRGB(255, 255, 0)
    },
    Eldertree = {
        validator = function(obj) return obj.Name == "TreeOrb" and obj:FindFirstChild("Spirit") end,
        getTarget = function(obj) return obj.Spirit end,
        text = "Eldertree",
        color = Color3.fromRGB(0, 255, 0)
    },
    Star = {
        validator = function(obj)
            return (obj.Name == "CritStar" or obj.Name == "VitalityStar") and obj:FindFirstChild("RootPart")
        end,
        getTarget = function(obj) return obj.RootPart end,
        text = function(obj) return obj.Name == "CritStar" and "Crit Star" or "Vitality Star" end,
        color = function(obj)
            return obj.Name == "CritStar" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(144, 238, 144)
        end
    },
    iron = {
        validator = function(obj) return obj:IsA("BasePart") and obj.Name == "iron" and obj.Parent and obj.Parent.Name == "ItemDrops" end,
        getTarget = function(obj) return obj end,
        text = "Iron",
        color = Color3.fromRGB(200, 200, 200)
    },
    diamond = {
        validator = function(obj) return obj:IsA("BasePart") and obj.Name == "diamond" and obj.Parent and obj.Parent.Name == "ItemDrops" end,
        getTarget = function(obj) return obj end,
        text = "Diamond",
        color = Color3.fromRGB(0, 191, 255)
    },
    emerald = {
        validator = function(obj) return obj:IsA("BasePart") and obj.Name == "emerald" and obj.Parent and obj.Parent.Name == "ItemDrops" end,
        getTarget = function(obj) return obj end,
        text = "Emerald",
        color = Color3.fromRGB(0, 230, 115)
    }
}

local function getUniqueIdentifier(model)
    return model.Address or tostring(model)
end

local function isVisibleWithCamera(targetPart)
    local camCFrame = Camera.CFrame
    local toTarget = (targetPart.Position - camCFrame.Position).Unit
    local dotProduct = camCFrame.LookVector:Dot(toTarget)
    return dotProduct > 0
end

local function createESP(obj, espType, config)
    local id = getUniqueIdentifier(obj)
    if trackedObjects[id] then return end

    local part = config.getTarget(obj)
    if not part then return end

    local finalColor = type(config.color) == "function" and config.color(obj) or config.color
    local finalText = type(config.text) == "function" and config.text(obj) or config.text

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = finalColor
    box.Thickness = 1.5
    box.Filled = false

    local text = Drawing.new("Text")
    text.Visible = false
    text.Text = finalText
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.Font = 3

    local amountText = Drawing.new("Text")
    amountText.Visible = false
    amountText.Color = Color3.fromRGB(230, 230, 230)
    amountText.Size = 12
    amountText.Center = true
    amountText.Outline = true
    amountText.Font = 3

    local kitText = Drawing.new("Text")
    kitText.Visible = false
    kitText.Color = Color3.fromRGB(255, 215, 0)
    kitText.Size = 12
    kitText.Center = true
    kitText.Outline = true
    kitText.Font = 3

    local equippedText = Drawing.new("Text")
    equippedText.Visible = false
    equippedText.Color = Color3.fromRGB(175, 238, 238)
    equippedText.Size = 12
    equippedText.Center = true
    equippedText.Outline = true
    equippedText.Font = 3

    trackedObjects[id] = {
        box = box,
        text = text,
        amountText = amountText,
        kitText = kitText,
        equippedText = equippedText,
        part = part,
        obj = obj,
        espType = espType
    }
end

local function removeESP(id)
    if trackedObjects[id] then
        trackedObjects[id].box:Remove()
        trackedObjects[id].text:Remove()
        trackedObjects[id].amountText:Remove()
        trackedObjects[id].kitText:Remove()
        trackedObjects[id].equippedText:Remove()
        trackedObjects[id] = nil
    end
end

task.spawn(function()
    while true do
        local currentScanIds = {}
        local workspaceChildren = Workspace:GetChildren()
        for i = 1, #workspaceChildren do
            local child = workspaceChildren[i]
            for espType, config in pairs(espConfigs) do
                if config.validator(child) then
                    createESP(child, espType, config)
                    currentScanIds[getUniqueIdentifier(child)] = true
                    break
                end
            end
        end

        local itemDropsFolder = Workspace:FindFirstChild("ItemDrops")
        if itemDropsFolder then
            local items = itemDropsFolder:GetChildren()
            for i = 1, #items do
                local item = items[i]
                for espType, config in pairs(espConfigs) do
                    if config.validator(item) then
                        createESP(item, espType, config)
                        currentScanIds[getUniqueIdentifier(item)] = true
                        break
                    end
                end
            end
        end

        for id, data in pairs(trackedObjects) do
            if not currentScanIds[id] or not data.obj or not data.obj.Parent then
                removeESP(id)
            end
        end
        task.wait(1.0)
    end
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    for id, data in pairs(trackedObjects) do
        if data.obj == char or data.obj.Name == LocalPlayer.Name then
            data.box.Visible = false
            data.text.Visible = false
            data.amountText.Visible = false
            data.kitText.Visible = false
            data.equippedText.Visible = false
            continue
        end

        if settings[data.espType] and data.part and data.part.Parent and root then
            local distance = (data.part.Position - root.Position).Magnitude

            if distance <= settings.Distance then
                local passVisibility = true
                if settings.Visible then
                    passVisibility = isVisibleWithCamera(data.part)
                end

                if passVisibility then
                    local pos, onScreen = WorldToScreen(data.part.Position)
                    if onScreen then
                        local size = data.part.Size
                        local topLeft, tlOnScreen = WorldToScreen((data.part.CFrame * CFrame.new(-size.X/2, size.Y/2, 0)).Position)
                        local bottomRight, brOnScreen = WorldToScreen((data.part.CFrame * CFrame.new(size.X/2, -size.Y/2, 0)).Position)

                        local width = math.abs(topLeft.X - bottomRight.X)
                        local height = math.abs(topLeft.Y - bottomRight.Y)

                        data.box.Size = Vector2.new(width, height)
                        data.box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                        data.box.Visible = true

                        data.text.Position = Vector2.new(pos.X, pos.Y - height/2 - 16)
                        data.text.Visible = true

                        local currentBottomOffset = height / 2 + 4

                        if settings.Amount and (data.espType == "iron" or data.espType == "diamond" or data.espType == "emerald") then
                            local amount = data.obj:GetAttribute("Amount") or 1
                            data.amountText.Text = "x" .. tostring(amount)
                            data.amountText.Position = Vector2.new(pos.X, pos.Y + currentBottomOffset)
                            data.amountText.Visible = true
                            currentBottomOffset = currentBottomOffset + 14
                        end

                        if settings.ShowKit and data.espType == "Player" then
                            local kitName = getPlayerKit(data.obj)
                            data.kitText.Text = "Kit: " .. string.upper(string.sub(kitName, 1, 1)) .. string.sub(kitName, 2)
                            data.kitText.Position = Vector2.new(pos.X, pos.Y + currentBottomOffset)
                            data.kitText.Visible = true
                            currentBottomOffset = currentBottomOffset + 14
                        end

                        if settings.ShowEquipped and data.espType == "Player" then
                            local itemName = getEquippedItem(data.obj)
                            data.equippedText.Text = "Holding: " .. itemName
                            data.equippedText.Position = Vector2.new(pos.X, pos.Y + currentBottomOffset)
                            data.equippedText.Visible = true
                        end
                    else
                        data.box.Visible = false
                        data.text.Visible = false
                        data.amountText.Visible = false
                        data.kitText.Visible = false
                        data.equippedText.Visible = false
                    end
                else
                    data.box.Visible = false
                    data.text.Visible = false
                    data.amountText.Visible = false
                    data.kitText.Visible = false
                    data.equippedText.Visible = false
                end
            else
                data.box.Visible = false
                data.text.Visible = false
                data.amountText.Visible = false
                data.kitText.Visible = false
                data.equippedText.Visible = false
            end
        else
            data.box.Visible = false
            data.text.Visible = false
            data.amountText.Visible = false
            data.kitText.Visible = false
            data.equippedText.Visible = false
        end
    end
end)

local function getAttackData()
    local weapon = getEquippedWeaponDirect()
    if settings.LimitToItems and not weapon then
        return false
    end
    if not weapon then
        local char = LocalPlayer.Character
        weapon = char and char:FindFirstChildWhichIsA("Tool")
    end
    return weapon
end

task.spawn(function()
    while true do
        if settings.Killaura then
            if settings.RequireMouseDown and not ismouse1pressed() then
                Attacking = false
            else
                local weapon = getAttackData()
                Attacking = false

                if weapon then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")

                    if root then
                        local localfacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
                        local targetsList = {}

                        for _, data in pairs(trackedObjects) do
                            if data.part and data.part.Parent then
                                if data.obj == char or data.obj.Name == LocalPlayer.Name then
                                    continue
                                end

                                local isPlayer = (data.espType == "Player")
                                local isEntity = (data.espType == "Entity")

                                if isPlayer or (isEntity and settings.TargetEntities) then
                                    local humanoid = data.part.Parent:FindFirstChildWhichIsA("Humanoid")
                                    if humanoid and humanoid.Health > 0 then
                                        if isPlayer and settings.TeamCheck then
                                            local targetPlrInstance = Players:FindFirstChild(data.obj.Name)
                                            if targetPlrInstance and targetPlrInstance.Team == LocalPlayer.Team then
                                                continue
                                            end
                                        end

                                        local delta = (data.part.Position - root.Position)
                                        local dist = delta.Magnitude

                                        if dist <= settings.SwingRange then
                                            local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
                                            if angle <= (math.rad(settings.AngleValue) / 2) then
                                                table.insert(targetsList, {
                                                    instance = data.part.Parent,
                                                    part = data.part,
                                                    distance = dist
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        table.sort(targetsList, function(a, b) return a.distance < b.distance end)

                        for _, targetData in ipairs(targetsList) do
                            Attacking = true

                            if settings.FaceTarget then
                                local vec = targetData.part.Position * Vector3.new(1, 0, 1)
                                local targetCFrame = CFrame.lookAt(root.Position, Vector3.new(vec.X, root.Position.Y, vec.Z))
                                root.CFrame = root.CFrame:Lerp(targetCFrame, 0.25)
                            end

                            if targetData.distance <= settings.SwingRange then
                                local dir = CFrame.lookAt(root.Position, targetData.part.Position).LookVector
                                local pos = root.Position + dir * math.max(targetData.distance - 14.399, 0)

                                SwordHitEvent:FireServer({
                                    chargedAttack = { chargeRatio = 0 },
                                    entityInstance = targetData.instance,
                                    validate = {
                                        selfPosition = { value = pos },
                                        targetPosition = { value = targetData.part.Position }
                                    },
                                    weapon = weapon
                                })
                            end
                        end
                    end
                end
            end
        end
        task.wait(1 / 60)
    end
end)

task.spawn(function()
    while true do
        if settings.AutoKit then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                for _, data in pairs(trackedObjects) do
                    if data.part and data.part.Parent then
                        local dist = (data.part.Position - root.Position).Magnitude
                        if dist <= settings.AutoKitRange then
                            if data.espType == "Metal" then
                                local metalId = data.obj:GetAttribute("Id")
                                if metalId then
                                    CollectEvent:FireServer({ id = metalId })
                                end
                            elseif data.espType == "Bee" then
                                local beeId = data.obj:GetAttribute("BeeId")
                                if beeId then
                                    PickUpBeeEvent:FireServer({ beeId = beeId })
                                end
                            elseif data.espType == "Star" then
                                local starId = data.obj:GetAttribute("Id")
                                if starId then
                                    CollectEvent:FireServer({ id = starId, collectableName = data.obj.Name })
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

local cachedLowestPoint = -30
task.spawn(function()
    while true do
        local collections = {Workspace:FindFirstChild("Map"), Workspace:FindFirstChild("MapSpawns")}
        local foundLowest = math.huge

        for _, folder in ipairs(collections) do
            if folder then
                local descendants = folder:GetDescendants()
                for i = 1, #descendants do
                    local v = descendants[i]
                    if v and v:IsA("BasePart") then
                        local success, size = pcall(function() return v.Size end)
                        local successPos, pos = pcall(function() return v.Position end)
                        if success and successPos and size and pos then
                            local point = (pos.Y - (size.Y / 2)) - 15
                            if point < foundLowest then
                                foundLowest = point
                            end
                        end
                    end
                end
            end
        end

        if foundLowest ~= math.huge and foundLowest < 100 then
            cachedLowestPoint = foundLowest
        else
            cachedLowestPoint = -30
        end
        task.wait(10)
    end
end)

task.spawn(function()
    while true do
        if settings.AutoVoidDrop then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                local currentY = root.Position.Y
                local threshold = cachedLowestPoint or -30

                if currentY < threshold then
                    local balloonCount = LocalPlayer:GetAttribute("InflatedBalloons") or 0
                    local hasBalloonInInventory = getInventoryItem("balloon")
                    local hasOwlLift = root:FindFirstChild("OwlLiftForce")

                    if balloonCount > 0 or hasBalloonInInventory then
                    elseif settings.OwlCheck and hasOwlLift then
                    else
                        local itemsToDrop = {"iron", "diamond", "emerald", "gold"}

                        for _, itemName in ipairs(itemsToDrop) do
                            local itemData = getInventoryItem(itemName)
                            if itemData then
                                DropItemRemote:FireServer({ item = itemData.tool, amount = itemData.amount })
                            end
                        end

                        task.wait(2)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)
