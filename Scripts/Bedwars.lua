-- ============================================================
-- Lurk UI v3 - Original Custom UI (No Library)
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
-- Custom UI Framework - Original Design
-- ============================================================
local UI = {}
UI.__index = UI

-- Color palette (purple theme)
local C = {
    bg = Color3.fromRGB(12, 12, 18),
    panel = Color3.fromRGB(20, 20, 28),
    panelHover = Color3.fromRGB(28, 28, 38),
    border = Color3.fromRGB(45, 45, 58),
    accent = Color3.fromRGB(139, 92, 246),    -- Purple
    accentDim = Color3.fromRGB(100, 60, 200),
    accentGlow = Color3.fromRGB(180, 140, 255),
    text = Color3.fromRGB(235, 235, 240),
    textDim = Color3.fromRGB(150, 150, 165),
    textDark = Color3.fromRGB(80, 80, 95),
    shadow = Color3.fromRGB(0, 0, 0),
    success = Color3.fromRGB(80, 220, 150),
    danger = Color3.fromRGB(230, 60, 80),
}

-- Drawing helpers
local function rect(x, y, w, h, color, filled, thick)
    local o = Drawing.new("Square")
    o.Position = Vector2.new(x, y)
    o.Size = Vector2.new(w, h)
    o.Color = color
    o.Filled = filled == nil and true or filled
    o.Thickness = thick or 1
    o.Visible = false
    o.ZIndex = 1
    return o
end

local function txt(x, y, text, size, color, center, outline)
    local o = Drawing.new("Text")
    o.Position = Vector2.new(x, y)
    o.Text = text or ""
    o.Size = size or 12
    o.Color = color or C.text
    o.Center = center or false
    o.Outline = outline or false
    o.Visible = false
    o.ZIndex = 1
    o.Font = 3 -- Smooth
    return o
end

local function line(x1, y1, x2, y2, color, thick)
    local o = Drawing.new("Line")
    o.From = Vector2.new(x1, y1)
    o.To = Vector2.new(x2, y2)
    o.Color = color or C.border
    o.Thickness = thick or 1
    o.Visible = false
    o.ZIndex = 1
    return o
end

local function circ(x, y, r, color, filled, thick)
    local o = Drawing.new("Circle")
    o.Position = Vector2.new(x, y)
    o.Radius = r or 6
    o.Color = color or C.accent
    o.Filled = filled == nil and true or filled
    o.Thickness = thick or 1
    o.Visible = false
    o.ZIndex = 1
    return o
end

local function roundRect(x, y, w, h, r, color, filled)
    -- Simplified: just use a square with border-radius approximation
    -- In drawing library we use square + circles for corners
    local objects = {}
    local main = rect(x + r, y, w - r * 2, h, color, filled)
    local main2 = rect(x, y + r, w, h - r * 2, color, filled)
    local c1 = circ(x + r, y + r, r, color, filled)
    local c2 = circ(x + w - r, y + r, r, color, filled)
    local c3 = circ(x + r, y + h - r, r, color, filled)
    local c4 = circ(x + w - r, y + h - r, r, color, filled)
    table.insert(objects, main)
    table.insert(objects, main2)
    table.insert(objects, c1)
    table.insert(objects, c2)
    table.insert(objects, c3)
    table.insert(objects, c4)
    return objects
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

-- Main UI Object
function UI:CreateWindow(title, width, height)
    local win = {
        title = title or "Lurk",
        w = width or 480,
        h = height or 420,
        x = 120,
        y = 120,
        visible = true,
        drag = false,
        dragOff = Vector2.new(0, 0),
        toggleKey = 0xA1,
        lastKeyState = false,
        scrollOffset = 0,
        maxScroll = 0,
        objects = {},
        sections = {},
        elements = {},
    }

    -- Window frame
    local bgParts = roundRect(win.x, win.y, win.w, win.h, 12, C.bg, true)
    for _, obj in ipairs(bgParts) do
        table.insert(win.objects, obj)
    end
    local borderParts = roundRect(win.x, win.y, win.w, win.h, 12, C.border, false)
    for _, obj in ipairs(borderParts) do
        table.insert(win.objects, obj)
    end

    -- Title bar
    local titleBg = rect(win.x + 12, win.y + 12, win.w - 24, 28, C.panel, true)
    table.insert(win.objects, titleBg)
    win.titleText = txt(win.x + 22, win.y + 18, win.title, 16, C.text, false, true)
    table.insert(win.objects, win.titleText)

    -- Accent line under title
    local accLine = line(win.x + 22, win.y + 40, win.x + win.w - 22, win.y + 40, C.accent, 2)
    table.insert(win.objects, accLine)

    -- Content area background
    local contentBg = rect(win.x + 14, win.y + 48, win.w - 28, win.h - 70, C.panel, true)
    table.insert(win.objects, contentBg)

    -- Footer
    local footerLine = line(win.x + 18, win.y + win.h - 18, win.x + win.w - 18, win.y + win.h - 18, C.border, 1)
    table.insert(win.objects, footerLine)
    local footerText = txt(win.x + 22, win.y + win.h - 26, "Lurk v3", 9, C.textDim, false, true)
    table.insert(win.objects, footerText)

    -- Scroll indicator
    win.scrollBar = rect(win.x + win.w - 20, win.y + 52, 4, win.h - 80, C.border, true)
    win.scrollFill = rect(win.x + win.w - 20, win.y + 52, 4, 40, C.accent, true)
    table.insert(win.objects, win.scrollBar)
    table.insert(win.objects, win.scrollFill)

    -- Section management
    local currentY = 60
    local function addSection(name)
        local sec = {
            name = name,
            y = currentY,
            elements = {},
            objects = {},
        }
        local yPos = win.y + currentY
        -- Section header
        local secTitle = txt(win.x + 26, yPos + 2, name:upper(), 11, C.accent, false, true)
        local secLine = line(win.x + 26, yPos + 18, win.x + 180, yPos + 18, C.accent, 1)
        table.insert(sec.objects, secTitle)
        table.insert(sec.objects, secLine)
        table.insert(win.objects, secTitle)
        table.insert(win.objects, secLine)
        currentY = currentY + 28

        function sec:Toggle(label, default, callback)
            local el = {
                type = "toggle",
                label = label,
                state = default or false,
                displayState = default and 1 or 0,
                callback = callback,
                y = currentY,
                objects = {},
            }
            local yPos = win.y + currentY

            -- Background pill
            local pill = rect(win.x + win.w - 56, yPos + 2, 36, 18, C.bg, true)
            local pillBorder = rect(win.x + win.w - 56, yPos + 2, 36, 18, C.border, false, 1)
            local knob = circ(win.x + win.w - 54, yPos + 11, 7, C.textDim, true)

            -- Label
            local labelObj = txt(win.x + 26, yPos + 4, label, 12, C.text, false, true)

            table.insert(el.objects, pill)
            table.insert(el.objects, pillBorder)
            table.insert(el.objects, knob)
            table.insert(el.objects, labelObj)
            table.insert(win.objects, pill)
            table.insert(win.objects, pillBorder)
            table.insert(win.objects, knob)
            table.insert(win.objects, labelObj)

            el.pill = pill
            el.knob = knob
            el.labelObj = labelObj

            table.insert(sec.elements, el)
            table.insert(win.elements, el)
            currentY = currentY + 26

            function el:Update()
                local target = self.state and 1 or 0
                self.displayState = lerp(self.displayState, target, 0.2)
                local col = lerpColor(C.border, C.accent, self.displayState)
                self.pill.Color = col
                local knobX = self.displayState > 0.5 and (win.x + win.w - 50) or (win.x + win.w - 54)
                self.knob.Position = Vector2.new(knobX, self.knob.Position.Y)
                self.knob.Color = self.displayState > 0.5 and C.text or C.textDim
            end

            return el
        end

        function sec:Slider(label, default, min, step, max, callback)
            local el = {
                type = "slider",
                label = label,
                value = default or min,
                min = min or 0,
                max = max or 100,
                step = step or 1,
                callback = callback,
                y = currentY,
                dragging = false,
                objects = {},
            }
            local yPos = win.y + currentY

            local labelObj = txt(win.x + 26, yPos + 2, label .. ": " .. tostring(el.value), 12, C.text, false, true)
            local track = rect(win.x + 26, yPos + 20, win.w - 70, 4, C.border, true)
            local fill = rect(win.x + 26, yPos + 20, 0, 4, C.accent, true)
            local thumb = circ(win.x + 26, yPos + 22, 7, C.text, true)
            local thumbRing = circ(win.x + 26, yPos + 22, 9, C.accent, false, 2)

            table.insert(el.objects, labelObj)
            table.insert(el.objects, track)
            table.insert(el.objects, fill)
            table.insert(el.objects, thumb)
            table.insert(el.objects, thumbRing)
            table.insert(win.objects, labelObj)
            table.insert(win.objects, track)
            table.insert(win.objects, fill)
            table.insert(win.objects, thumb)
            table.insert(win.objects, thumbRing)

            el.labelObj = labelObj
            el.track = track
            el.fill = fill
            el.thumb = thumb
            el.thumbRing = thumbRing

            table.insert(sec.elements, el)
            table.insert(win.elements, el)
            currentY = currentY + 42

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

        table.insert(win.sections, sec)
        currentY = currentY + 8
        win.maxScroll = math.max(win.maxScroll, currentY - win.h + 80)
        return sec
    end

    -- ============================================================
    -- Build UI Sections
    -- ============================================================

    -- Combat
    local combatSec = addSection("Combat")
    local kaCat = {}
    kaCat.elements = {}
    -- We'll add Kill Aura elements directly under Combat
    local kaLabel = txt(win.x + 28, win.y + currentY + 2, "Kill Aura", 12, C.textDim, false, true)
    table.insert(win.objects, kaLabel)
    currentY = currentY + 20
    kaCat.label = kaLabel
    kaCat.y = currentY

    -- Toggles and sliders inside Kill Aura
    local function addToCat(cat, label, default, cb, isSlider, min, step, max)
        if isSlider then
            local sec = { elements = {} }
            local el = sec:Slider(label, default, min, step, max, cb)
            table.insert(cat.elements, el)
            return el
        else
            local sec = { elements = {} }
            local el = sec:Toggle(label, default, cb)
            table.insert(cat.elements, el)
            return el
        end
    end

    -- Kill Aura toggles
    local kaToggle1 = combatSec:Toggle("Enabled", settings.Killaura, function(v) settings.Killaura = v; saveConfig() end)
    local kaToggle2 = combatSec:Toggle("Target Entities", settings.TargetEntities, function(v) settings.TargetEntities = v; saveConfig() end)
    local kaToggle3 = combatSec:Toggle("Team Check", settings.TeamCheck, function(v) settings.TeamCheck = v; saveConfig() end)
    local kaSlider1 = combatSec:Slider("Swing Range", settings.SwingRange, 1, 1, 28, function(v) settings.SwingRange = v; saveConfig() end)
    local kaSlider2 = combatSec:Slider("Max Angle", settings.AngleValue, 1, 1, 360, function(v) settings.AngleValue = v; saveConfig() end)
    local kaToggle4 = combatSec:Toggle("Require Mouse Down", settings.RequireMouseDown, function(v) settings.RequireMouseDown = v; saveConfig() end)
    local kaToggle5 = combatSec:Toggle("No Swing", settings.NoSwing, function(v) settings.NoSwing = v; saveConfig() end)
    local kaToggle6 = combatSec:Toggle("Face Target", settings.FaceTarget, function(v) settings.FaceTarget = v; saveConfig() end)
    local kaToggle7 = combatSec:Toggle("Limit to Items", settings.LimitToItems, function(v) settings.LimitToItems = v; saveConfig() end)
    local kaToggle8 = combatSec:Toggle("SwingOnly", settings.SwingOnly, function(v) settings.SwingOnly = v; saveConfig() end)

    -- ESP
    local espSec = addSection("ESP")
    local espGame = espSec:Toggle("Player ESP", settings.Player, function(v) settings.Player = v; saveConfig() end)
    local espBed = espSec:Toggle("Bed ESP", settings.Bed, function(v) settings.Bed = v; saveConfig() end)
    local espEntity = espSec:Toggle("Entity ESP", settings.Entity, function(v) settings.Entity = v; saveConfig() end)
    local espKit = espSec:Toggle("Show Kit", settings.ShowKit, function(v) settings.ShowKit = v; saveConfig() end)
    local espEquipped = espSec:Toggle("Show Equipped", settings.ShowEquipped, function(v) settings.ShowEquipped = v; saveConfig() end)

    -- Kit ESP
    local kitEspLabel = txt(win.x + 30, win.y + currentY + 2, "─ Kit ESP", 11, C.textDim, false, true)
    table.insert(win.objects, kitEspLabel)
    currentY = currentY + 20
    local metalEsp = espSec:Toggle("Metal ESP", settings.Metal, function(v) settings.Metal = v; saveConfig() end)
    local beeEsp = espSec:Toggle("Bee ESP", settings.Bee, function(v) settings.Bee = v; saveConfig() end)
    local elderEsp = espSec:Toggle("Eldertree ESP", settings.Eldertree, function(v) settings.Eldertree = v; saveConfig() end)
    local starEsp = espSec:Toggle("Star ESP", settings.Star, function(v) settings.Star = v; saveConfig() end)

    -- Items ESP
    local itemsEspLabel = txt(win.x + 30, win.y + currentY + 2, "─ Items ESP", 11, C.textDim, false, true)
    table.insert(win.objects, itemsEspLabel)
    currentY = currentY + 20
    local ironEsp = espSec:Toggle("Iron ESP", settings.iron, function(v) settings.iron = v; saveConfig() end)
    local diamondEsp = espSec:Toggle("Diamond ESP", settings.diamond, function(v) settings.diamond = v; saveConfig() end)
    local emeraldEsp = espSec:Toggle("Emerald ESP", settings.emerald, function(v) settings.emerald = v; saveConfig() end)
    local showAmount = espSec:Toggle("Show Amount", settings.Amount, function(v) settings.Amount = v; saveConfig() end)

    -- ESP Options
    local espOptLabel = txt(win.x + 30, win.y + currentY + 2, "─ Options", 11, C.textDim, false, true)
    table.insert(win.objects, espOptLabel)
    currentY = currentY + 20
    local visibleOnly = espSec:Toggle("Visible Only", settings.Visible, function(v) settings.Visible = v; saveConfig() end)
    local distSlider = espSec:Slider("Distance", settings.Distance, 100, 10, 2000, function(v) settings.Distance = v; saveConfig() end)

    -- Automation
    local autoSec = addSection("Automation")
    local autoKit = autoSec:Toggle("Auto Kit", settings.AutoKit, function(v) settings.AutoKit = v; saveConfig() end)
    local kitRange = autoSec:Slider("Collection Range", settings.AutoKitRange, 5, 1, 20, function(v) settings.AutoKitRange = v; saveConfig() end)
    local autoVoid = autoSec:Toggle("Auto Void Drop", settings.AutoVoidDrop, function(v) settings.AutoVoidDrop = v; saveConfig() end)
    local owlCheck = autoSec:Toggle("Owl Check", settings.OwlCheck, function(v) settings.OwlCheck = v; saveConfig() end)

    -- Store elements for update loop
    win.allElements = {}
    for _, sec in ipairs(win.sections) do
        for _, el in ipairs(sec.elements) do
            table.insert(win.allElements, el)
        end
    end

    -- ============================================================
    -- Main Render Loop
    -- ============================================================
    task.spawn(function()
        local lastMouse = false
        while true do
            local keyPressed = iskeypressed(win.toggleKey)
            if keyPressed and not win.lastKeyState then
                win.visible = not win.visible
                for _, obj in ipairs(win.objects) do
                    obj.Visible = win.visible
                end
            end
            win.lastKeyState = keyPressed

            if not win.visible then
                task.wait()
                continue
            end

            local mx, my = getMousePos()
            local mouseDown = ismouse1pressed()
            local clicked = mouseDown and not lastMouse

            -- Drag
            if clicked and isInRect(mx, my, win.x, win.y, win.w, 40) then
                win.drag = true
                win.dragOff = Vector2.new(mx - win.x, my - win.y)
            end
            if not mouseDown then
                win.drag = false
            end
            if win.drag then
                win.x = mx - win.dragOff.X
                win.y = my - win.dragOff.Y
                -- Update positions of all objects
                -- We'll just let the loop update them
            end

            -- Update UI positions and interactions
            local offsetY = win.scrollOffset
            local contentY = win.y + 48

            -- Update all elements
            for _, el in ipairs(win.allElements) do
                if el.type == "toggle" then
                    local yPos = win.y + el.y + offsetY
                    -- Check if visible
                    if yPos > win.y + 40 and yPos < win.y + win.h - 30 then
                        -- Update toggle visuals
                        el:Update()
                        -- Check interaction
                        if clicked and isInRect(mx, my, win.x + win.w - 56, yPos, 36, 18) then
                            el.state = not el.state
                            if el.callback then el.callback(el.state) end
                            saveConfig()
                        end
                    end
                elseif el.type == "slider" then
                    local yPos = win.y + el.y + offsetY
                    if yPos > win.y + 40 and yPos < win.y + win.h - 30 then
                        el:Update()
                        local trackX = el.track.Position.X
                        local trackW = el.track.Size.X
                        if mouseDown and isInRect(mx, my, trackX, yPos + 14, trackW, 16) then
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
                end
            end

            -- Scroll
            local sUp = iskeypressed(0x21)
            local sDown = iskeypressed(0x22)
            if sUp then win.scrollOffset = math.max(win.scrollOffset - 20, -win.maxScroll) end
            if sDown then win.scrollOffset = math.min(win.scrollOffset + 20, 0) end

            -- Update scroll bar
            local scrollPct = math.abs(win.scrollOffset) / math.max(win.maxScroll, 1)
            local scrollY = win.y + 52 + (win.h - 80 - 40) * scrollPct
            win.scrollFill.Position = Vector2.new(win.x + win.w - 20, scrollY)
            win.scrollFill.Size = Vector2.new(4, 40)

            -- Update window position
            -- (all objects are drawn relative to win.x/win.y)

            lastMouse = mouseDown
            task.wait()
        end
    end)

    return win
end

-- ============================================================
-- Executor stubs (overridden by actual executor)
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
    return false
end

local function ismouse1pressed()
    return false
end

-- ============================================================
-- Create and Show UI
-- ============================================================
local win = UI:CreateWindow("Lurk", 480, 420)

-- ============================================================
-- GAME LOGIC (from your original script - unchanged)
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
