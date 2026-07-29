local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local uiLogLines = {}
local uiLogSink
local maxUiLogLines = 30
local throttledMessages = {}

local function pushUiLog(message)
    table.insert(uiLogLines, tostring(message))

    while #uiLogLines > maxUiLogLines do
        table.remove(uiLogLines, 1)
    end

    if uiLogSink then
        local ok = pcall(uiLogSink, uiLogLines)
        if not ok then
            uiLogSink = nil
        end
    end
end

local function reportError(label, err)
    local message = ("[NavyTycoon:%s] %s"):format(tostring(label), tostring(err))
    warn(message)
    pushUiLog(message)
end

local function reportInfo(message)
    print(("[NavyTycoon] %s"):format(tostring(message)))
end

local function reportThrottled(label, message, cooldown)
    local key = ("%s:%s"):format(tostring(label), tostring(message))
    local now = (tick and tick()) or os.clock()

    if throttledMessages[key] and now - throttledMessages[key] < (cooldown or 3) then
        return
    end

    throttledMessages[key] = now
    reportError(label, message)
end

local function safeCall(label, callback)
    local ok, err = pcall(callback)
    if not ok then
        reportError(label, err)
    end
    return ok
end

local function ownedTycoons()
    local tycoons = {}
    local base = workspace["Tycoon Systems"]["Naval Base"].Tycoons

    for _, item in pairs(base:GetDescendants()) do
        if item.Name == "Owner"
            and item.Value == LocalPlayer
            and item.Parent
            and item.Parent.Parent
            and item.Parent.Parent.Name == "Tycoons" then
            table.insert(tycoons, item.Parent)
        end
    end

    return tycoons
end

local function collectHitEvents(container, remotes)
    remotes = remotes or {}

    if not container then
        return remotes
    end

    if container.Name == "HitEvent" and container:IsA("RemoteEvent") then
        table.insert(remotes, container)
    end

    for _, item in ipairs(container:GetDescendants()) do
        if item.Name == "HitEvent" and item:IsA("RemoteEvent") then
            table.insert(remotes, item)
        end
    end

    return remotes
end

local function characterHitEvents()
    local remotes = {}

    collectHitEvents(LocalPlayer.Backpack, remotes)
    collectHitEvents(LocalPlayer.Character, remotes)

    return remotes
end

local function enemyVehicleHitEvents(vehicle)
    local remotes = {}

    if vehicle then
        return collectHitEvents(vehicle, remotes)
    end

    for _, item in pairs(workspace.Vehicles:GetChildren()) do
        if item:GetAttribute("SpawnerUserId") ~= LocalPlayer.UserId then
            collectHitEvents(item, remotes)
        end
    end

    return remotes
end

local function backpackOrCharacterHitEvent()
    local remotes = characterHitEvents()
    return remotes[1]
end

local function vehicleMainPart(vehicle)
    local body = vehicle and vehicle:FindFirstChild("Body")
    if not body then
        return nil
    end

    local main = body:FindFirstChild("Main") or body:FindFirstChild("Main", true)

    if main and main:IsA("BasePart") then
        return main
    end

    if main and main:IsA("Model") then
        return main.PrimaryPart or main:FindFirstChildWhichIsA("BasePart", true)
    end

    return body:FindFirstChildWhichIsA("BasePart", true)
end

local function isTargetVehicle(vehicle)
    local enabled = vehicle:GetAttribute("Enabled")
    return enabled ~= false and vehicle:GetAttribute("SpawnerUserId") ~= LocalPlayer.UserId
end

local function hitEventsForVehicle(vehicle)
    local remotes = characterHitEvents()

    collectHitEvents(vehicle, remotes)

    if #remotes == 0 then
        remotes = enemyVehicleHitEvents()
    end

    return remotes
end

local function fireVehicleHitEvents(label, hitEvents, targetPart, root, distance, position)
    if not targetPart then
        reportThrottled(label, "No vehicle target part found", 3)
        return
    end

    if #hitEvents == 0 then
        reportThrottled(label, "No HitEvent found in character, backpack, or vehicles", 3)
        return
    end

    local args = {
        targetPart,
        root,
        {
            Normal = Vector3.new(
                -0.09811976552009583,
                0.8896507024765015,
                0.4459754526615143
            ),
            Position = position or root.Position,
            Instance = targetPart,
            Material = Enum.Material.SmoothPlastic,
            Id = 0,
            Distance = distance,
        },
    }

    for _, remote in ipairs(hitEvents) do
        local ok, err = pcall(function()
            remote:FireServer(unpack(args))
        end)

        if not ok then
            reportThrottled(label, err, 3)
        end
    end
end

function Cash()
    spawn(function()
        while _G.Cash do
            safeCall("Cash", function()
                for _, tycoon in pairs(ownedTycoons()) do
                    local essentials = tycoon:WaitForChild("Essentials")
                    local args = { "manualpump", {} }

                    for _ = 1, 10 do
                        essentials.CollectorEvent:FireServer(unpack(args))
                    end

                    firetouchinterest(
                        LocalPlayer.Character.HumanoidRootPart,
                        essentials.Giver.GivePart,
                        0
                    )
                    wait()
                    firetouchinterest(
                        LocalPlayer.Character.HumanoidRootPart,
                        essentials.Giver.GivePart,
                        1
                    )
                    wait(1)
                end
            end)
            wait()
        end
    end)
end

function Button()
    spawn(function()
        while _G.Button do
            safeCall("Button", function()
                for _, tycoon in pairs(ownedTycoons()) do
                    for _, button in pairs(tycoon.Buttons:GetChildren()) do
                        if button:GetAttribute("IsPassId") == false then
                            firetouchinterest(
                                LocalPlayer.Character.HumanoidRootPart,
                                button.Head,
                                0
                            )
                            wait(0.2)
                            firetouchinterest(
                                LocalPlayer.Character.HumanoidRootPart,
                                button.Head,
                                1
                            )
                        end
                    end
                end
            end)
            wait()
        end
    end)
end

function Rebirth()
    spawn(function()
        while _G.Rebirth do
            wait()
            safeCall("Rebirth", function()
                game:GetService("ReplicatedStorage")
                    ._ReplicationRemotes
                    .Server["ReplicatedStorage.Modules.TycoonGame.Tycoons.Utils:clientRequestRebirth"]
                    :InvokeServer(LocalPlayer)
                wait(3)
            end)
        end
    end)
end

function Vehicles()
    spawn(function()
        local hitEvents = {}

        for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
            if vehicle:GetAttribute("SpawnerUserId") ~= LocalPlayer.UserId then
                for _, item in pairs(vehicle.Body:GetDescendants()) do
                    if item.Name == "HitEvent" then
                        table.insert(hitEvents, item)
                    end
                end
            end
        end

        while _G.Vehicles do
            wait()
            safeCall("Vehicles", function()
                local root = LocalPlayer.Character.HumanoidRootPart
                local nearest
                local nearestDistance = 3000

                for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
                    if vehicle:GetAttribute("Enabled")
                        and vehicle:GetAttribute("SpawnerUserId") ~= LocalPlayer.UserId
                        and vehicle:FindFirstChild("Body")
                        and vehicle.Body:FindFirstChild("Main") then
                        local main = vehicle.Body.Main
                        local distance = (main.CFrame.Position - root.Position).Magnitude

                        if distance < nearestDistance then
                            nearestDistance = distance
                            nearest = vehicle
                        end
                    end
                end

                if not nearest then
                    return
                end

                local main = nearest.Body.Main
                local args = {
                    main,
                    root,
                    {
                        Normal = Vector3.new(
                            -0.09811976552009583,
                            0.8896507024765015,
                            0.4459754526615143
                        ),
                        Position = root.Position,
                        Instance = main,
                        Material = Enum.Material.SmoothPlastic,
                        Id = 0,
                        Distance = nearestDistance,
                    },
                }

                for _, remote in ipairs(hitEvents) do
                    remote:FireServer(unpack(args))
                end

                wait()
            end)
        end
    end)
end

function all()
    spawn(function()
        while _G.all do
            safeCall("all", function()
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if not root then
                    reportThrottled("all", "No HumanoidRootPart found", 3)
                    return
                end

                local attacked = 0

                for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
                    if isTargetVehicle(vehicle) then
                        local main = vehicleMainPart(vehicle)
                        if main then
                            local distance = (main.Position - root.Position).Magnitude
                            fireVehicleHitEvents(
                                "all",
                                hitEventsForVehicle(vehicle),
                                main,
                                root,
                                distance,
                                Vector3.new(
                                    -10532.2041015625,
                                    2250.1744232177734,
                                    13033.7958984375
                                )
                            )
                            attacked = attacked + 1
                        end
                    end
                end

                if attacked == 0 then
                    reportThrottled("all", "No enemy vehicle found", 3)
                end
            end)
            wait()
        end
    end)
end

function Listening()
    spawn(function()
        local hitEvent = backpackOrCharacterHitEvent()

        safeCall("Listening:Sit", function()
            if LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.Sit = true
            end
        end)

        while _G.Listening do
            safeCall("Listening", function()
                hitEvent = hitEvent or backpackOrCharacterHitEvent()
                if not hitEvent then
                    return
                end

                for _, post in pairs(workspace.ListeningPosts:GetChildren()) do
                    if post:GetAttribute("Health") > 0 then
                        local args = {
                            post,
                            {
                                Normal = vector.create(
                                    -0.09811976552009583,
                                    0.8896507024765015,
                                    0.4459754526615143
                                ),
                                Position = vector.create(
                                    -10532.2041015625,
                                    2250.1744232177734,
                                    13033.7958984375
                                ),
                                Instance = post.Main,
                                Material = Enum.Material.SmoothPlastic,
                                Id = 0,
                                Distance = 9999,
                            },
                        }

                        hitEvent:FireServer(unpack(args))
                    end
                end
            end)
            wait()
        end
    end)
end

local coreGui = game:GetService("CoreGui")

local function createInHouseLibrary()
    local UserInputService = game:GetService("UserInputService")
    local TextService = game:GetService("TextService")
    local library = {}

    local function create(className, properties)
        local object = Instance.new(className)

        for property, value in pairs(properties or {}) do
            object[property] = value
        end

        return object
    end

    local function addCorner(parent, radius)
        create("UICorner", {
            CornerRadius = UDim.new(0, radius),
            Parent = parent,
        })
    end

    local function addStroke(parent, color, transparency)
        create("UIStroke", {
            Color = color,
            Transparency = transparency or 0,
            Thickness = 1,
            Parent = parent,
        })
    end

    local function getUiParent()
        local ok, hiddenUi = pcall(function()
            if gethui then
                return gethui()
            end
        end)

        if ok and hiddenUi then
            return hiddenUi
        end

        local probe = Instance.new("Folder")
        local canUseCoreGui = pcall(function()
            probe.Parent = coreGui
        end)
        probe:Destroy()

        if canUseCoreGui then
            return coreGui
        end

        return LocalPlayer:WaitForChild("PlayerGui")
    end

    local function destroyExisting(parent, name)
        local existing = parent and parent:FindFirstChild(name)
        if existing then
            existing:Destroy()
        end
    end

    local function destroyExistingEverywhere(parent, name)
        destroyExisting(parent, name)
        destroyExisting(coreGui, name)

        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            or LocalPlayer:FindFirstChild("PlayerGui")
        destroyExisting(playerGui, name)
    end

    function library:CreateWindow(title)
        local parent = getUiParent()

        destroyExistingEverywhere(parent, "ToraScript")
        destroyExistingEverywhere(parent, "NavyTycoonUI")

        local screenGui = create("ScreenGui", {
            Name = "NavyTycoonUI",
            ResetOnSpawn = false,
            Parent = parent,
        })

        pcall(function()
            screenGui.IgnoreGuiInset = true
            screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        end)

        local root = create("Frame", {
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 24, 0.5, -225),
            Size = UDim2.new(0, 330, 0, 450),
            Parent = screenGui,
        })
        addCorner(root, 8)
        addStroke(root, Color3.fromRGB(68, 66, 62), 0.2)

        local header = create("Frame", {
            BackgroundColor3 = Color3.fromRGB(31, 31, 30),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 44),
            Parent = root,
        })
        addCorner(header, 8)

        create("Frame", {
            BackgroundColor3 = Color3.fromRGB(31, 31, 30),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -8),
            Size = UDim2.new(1, 0, 0, 8),
            Parent = header,
        })

        local titleLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSemibold,
            Position = UDim2.new(0, 14, 0, 0),
            Size = UDim2.new(1, -70, 1, 0),
            Text = title or "Window",
            TextColor3 = Color3.fromRGB(242, 240, 234),
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header,
        })

        local minimizeButton = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Color3.fromRGB(48, 48, 45),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamSemibold,
            Position = UDim2.new(1, -68, 0, 10),
            Size = UDim2.new(0, 24, 0, 24),
            Text = "-",
            TextColor3 = Color3.fromRGB(240, 237, 230),
            TextSize = 16,
            Parent = header,
        })
        addCorner(minimizeButton, 6)

        local closeButton = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Color3.fromRGB(95, 42, 48),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamSemibold,
            Position = UDim2.new(1, -36, 0, 10),
            Size = UDim2.new(0, 24, 0, 24),
            Text = "x",
            TextColor3 = Color3.fromRGB(255, 235, 235),
            TextSize = 14,
            Parent = header,
        })
        addCorner(closeButton, 6)

        local body = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 54),
            Size = UDim2.new(1, -20, 1, -64),
            Parent = root,
        })

        local controls = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 250),
            Parent = body,
        })

        local controlsLayout = create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = controls,
        })

        local errorPanel = create("Frame", {
            BackgroundColor3 = Color3.fromRGB(24, 24, 23),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 260),
            Size = UDim2.new(1, 0, 1, -260),
            Parent = body,
        })
        addCorner(errorPanel, 8)
        addStroke(errorPanel, Color3.fromRGB(72, 69, 63), 0.35)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSemibold,
            Position = UDim2.new(0, 10, 0, 6),
            Size = UDim2.new(1, -20, 0, 20),
            Text = "Errors",
            TextColor3 = Color3.fromRGB(238, 227, 190),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = errorPanel,
        })

        local errorScroll = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, 8, 0, 30),
            ScrollBarImageColor3 = Color3.fromRGB(112, 107, 98),
            ScrollBarThickness = 4,
            Size = UDim2.new(1, -16, 1, -38),
            Parent = errorPanel,
        })

        local errorText = create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.Code,
            Size = UDim2.new(1, -8, 0, 0),
            Text = "No errors",
            TextColor3 = Color3.fromRGB(164, 160, 151),
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = errorScroll,
        })

        local refreshVersion = 0
        local function refreshErrorLog(lines)
            if #lines == 0 then
                errorText.Text = "No errors"
                errorText.TextColor3 = Color3.fromRGB(164, 160, 151)
            else
                errorText.Text = table.concat(lines, "\n")
                errorText.TextColor3 = Color3.fromRGB(255, 204, 204)
            end

            refreshVersion = refreshVersion + 1
            local expectedVersion = refreshVersion

            spawn(function()
                wait()

                if expectedVersion ~= refreshVersion or not screenGui.Parent then
                    return
                end

                local textHeight = errorScroll.AbsoluteSize.Y
                local ok, textSize = pcall(function()
                    return TextService:GetTextSize(
                        errorText.Text,
                        errorText.TextSize,
                        errorText.Font,
                        Vector2.new(math.max(20, errorScroll.AbsoluteSize.X - 8), math.huge)
                    )
                end)

                if ok then
                    textHeight = math.max(textSize.Y + 6, errorScroll.AbsoluteSize.Y)
                else
                    textHeight = math.max((#lines * 16) + 6, errorScroll.AbsoluteSize.Y)
                end

                errorText.Size = UDim2.new(1, -8, 0, textHeight)
                errorScroll.CanvasSize = UDim2.new(
                    0,
                    0,
                    0,
                    textHeight
                )
                errorScroll.CanvasPosition = Vector2.new(
                    0,
                    math.max(0, textHeight - errorScroll.AbsoluteSize.Y)
                )
            end)
        end

        uiLogSink = refreshErrorLog
        refreshErrorLog(uiLogLines)

        local window = {
            flags = {},
        }
        local toggleSetters = {}

        local dragging = false
        local dragInput
        local dragStart
        local startPosition

        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPosition = root.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                local delta = input.Position - dragStart
                root.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end)

        local minimized = false
        local expandedSize = root.Size
        minimizeButton.MouseButton1Click:Connect(function()
            minimized = not minimized
            body.Visible = not minimized
            root.Size = minimized and UDim2.new(0, 330, 0, 44) or expandedSize
            minimizeButton.Text = minimized and "+" or "-"
        end)

        function window:AddToggle(options)
            options = options or {}

            local row = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(29, 29, 28),
                BorderSizePixel = 0,
                LayoutOrder = #toggleSetters + 1,
                Size = UDim2.new(1, 0, 0, 34),
                Parent = controls,
            })
            addCorner(row, 7)
            addStroke(row, Color3.fromRGB(61, 58, 53), 0.5)

            local track = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Color3.fromRGB(66, 64, 59),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 10, 0.5, -10),
                Size = UDim2.new(0, 42, 0, 20),
                Text = "",
                Parent = row,
            })
            addCorner(track, 10)

            local knob = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(235, 240, 248),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 2, 0, 2),
                Size = UDim2.new(0, 16, 0, 16),
                Parent = track,
            })
            addCorner(knob, 8)

            local labelButton = create("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Position = UDim2.new(0, 60, 0, 0),
                Size = UDim2.new(1, -68, 1, 0),
                Text = options.text or options.flag or "Toggle",
                TextColor3 = Color3.fromRGB(232, 229, 220),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local state = options.state == true
            local flag = options.flag
            local callback = options.callback

            local function paint()
                if state then
                    track.BackgroundColor3 = Color3.fromRGB(42, 173, 119)
                    knob.Position = UDim2.new(1, -18, 0, 2)
                    row.BackgroundColor3 = Color3.fromRGB(24, 35, 30)
                else
                    track.BackgroundColor3 = Color3.fromRGB(66, 64, 59)
                    knob.Position = UDim2.new(0, 2, 0, 2)
                    row.BackgroundColor3 = Color3.fromRGB(29, 29, 28)
                end
            end

            local function setState(nextState)
                nextState = nextState == true

                if state == nextState then
                    return
                end

                state = nextState

                if flag then
                    window.flags[flag] = state
                end

                paint()

                if callback then
                    local ok, err = pcall(callback, state)
                    if not ok then
                        reportError("Toggle:" .. tostring(labelButton.Text), err)
                    end
                end
            end

            paint()
            if flag then
                window.flags[flag] = state
            end

            track.MouseButton1Click:Connect(function()
                setState(not state)
            end)

            labelButton.MouseButton1Click:Connect(function()
                setState(not state)
            end)

            table.insert(toggleSetters, setState)
            return row
        end

        function window:AddLabel(options)
            options = options or {}

            local label = create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                LayoutOrder = #toggleSetters + 20,
                Size = UDim2.new(1, 0, 0, 24),
                Text = options.text or "",
                TextColor3 = Color3.fromRGB(149, 160, 176),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = controls,
            })

            return label
        end

        function window:LogError(message)
            pushUiLog(message)
        end

        function window:Init()
            refreshErrorLog(uiLogLines)
        end

        closeButton.MouseButton1Click:Connect(function()
            for _, setState in ipairs(toggleSetters) do
                setState(false)
            end

            uiLogSink = nil
            screenGui:Destroy()
        end)

        return window
    end

    return library
end

local library = createInHouseLibrary()

local window
if not safeCall("UI:CreateWindow", function()
    window = library:CreateWindow("Navy Tycoon")
end) then
    return
end

window:AddToggle({
    text = "Collect Cash",
    flag = "cash_toggle",
    state = false,
    callback = function(state)
        _G.Cash = state
        reportInfo("Cash: " .. tostring(state))
        if state then
            Cash()
        end
    end,
})

window:AddToggle({
    text = "Auto Buttons",
    flag = "button_toggle",
    state = false,
    callback = function(state)
        _G.Button = state
        reportInfo("Button: " .. tostring(state))
        if state then
            Button()
        end
    end,
})

window:AddToggle({
    text = "Auto Rebirth",
    flag = "rebirth_toggle",
    state = false,
    callback = function(state)
        _G.Rebirth = state
        reportInfo("Rebirth: " .. tostring(state))
        if state then
            Rebirth()
        end
    end,
})

window:AddToggle({
    text = "Destroy ListeningPosts",
    flag = "listening_toggle",
    state = false,
    callback = function(state)
        _G.Listening = state
        reportInfo("Listening: " .. tostring(state))
        if state then
            Listening()
        end
    end,
})

window:AddToggle({
    text = "Attack Nearest Vehicles",
    flag = "vehicles_toggle",
    state = false,
    callback = function(state)
        _G.Vehicles = state
        reportInfo("Vehicles: " .. tostring(state))
        if state then
            Vehicles()
        end
    end,
})

window:AddToggle({
    text = "Attack all Vehicles",
    flag = "all_vehicles_toggle",
    state = false,
    callback = function(state)
        _G.all = state
        reportInfo("all: " .. tostring(state))
        if state then
            all()
        end
    end,
})

window:AddLabel({
    text = "UI: In-house",
})

window:Init()
