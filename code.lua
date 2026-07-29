local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function safeCall(label, callback)
    local ok, err = pcall(callback)
    if not ok then
        warn(("[NavyTycoon:%s] %s"):format(label, tostring(err)))
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

local function enemyVehicleHitEvents()
    local remotes = {}

    for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
        if vehicle:GetAttribute("SpawnerUserId") ~= LocalPlayer.UserId
            and vehicle:FindFirstChild("Body") then
            for _, item in pairs(vehicle.Body:GetDescendants()) do
                if item.Name == "HitEvent" then
                    table.insert(remotes, item)
                end
            end
        end
    end

    return remotes
end

local function backpackOrCharacterHitEvent()
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:FindFirstChild("HitEvent") then
            return item.HitEvent
        end
    end

    for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
        if item:FindFirstChild("HitEvent") then
            return item.HitEvent
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
        while _G.Vehicles do
            safeCall("Vehicles", function()
                local root = LocalPlayer.Character.HumanoidRootPart
                local nearest
                local nearestDistance = 10000

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

                local hitEvents = enemyVehicleHitEvents()
                if #hitEvents == 0 then
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
            end)
            wait()
        end
    end)
end

function all()
    spawn(function()
        while _G.all do
            safeCall("all", function()
                local hitEvents = enemyVehicleHitEvents()
                if #hitEvents == 0 then
                    return
                end

                local root = LocalPlayer.Character.HumanoidRootPart

                for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
                    if vehicle:GetAttribute("Enabled")
                        and vehicle:GetAttribute("SpawnerUserId") ~= LocalPlayer.UserId
                        and vehicle:FindFirstChild("Body")
                        and vehicle.Body:FindFirstChild("Main") then
                        local main = vehicle.Body.Main
                        local distance = (main.Position - root.Position).Magnitude
                        local args = {
                            main,
                            root,
                            {
                                Normal = Vector3.new(
                                    -0.09811976552009583,
                                    0.8896507024765015,
                                    0.4459754526615143
                                ),
                                Position = Vector3.new(
                                    -10532.2041015625,
                                    2250.1744232177734,
                                    13033.7958984375
                                ),
                                Instance = main,
                                Material = Enum.Material.SmoothPlastic,
                                Id = 0,
                                Distance = distance,
                            },
                        }

                        for _, remote in ipairs(hitEvents) do
                            remote:FireServer(unpack(args))
                        end
                    end
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
local existing = coreGui:FindFirstChild("ToraScript")
if existing then
    existing:Destroy()
end

local libraryUrl = "https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew"
local librarySource

if not safeCall("UI:Download", function()
    librarySource = game:HttpGet(libraryUrl)
end) then
    return
end

if type(librarySource) ~= "string" or librarySource == "" then
    warn("[NavyTycoon:UI:Download] empty library source")
    return
end

local libraryFactory
local compileError
if not safeCall("UI:Compile", function()
    libraryFactory, compileError = loadstring(librarySource)
end) then
    return
end

if not libraryFactory then
    warn(("[NavyTycoon:UI:Compile] %s"):format(tostring(compileError)))
    return
end

local library
if not safeCall("UI:Initialize", function()
    library = libraryFactory()
end) then
    return
end

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
        print("Cash: " .. tostring(state))
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
        print("Button: " .. tostring(state))
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
        print("Rebirth: " .. tostring(state))
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
        print("Listening: " .. tostring(state))
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
        print("Vehicles: " .. tostring(state))
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
        print("all: " .. tostring(state))
        if state then
            all()
        end
    end,
})

window:AddLabel({
    text = "YouTube: Tora IsMe",
})

window:Init()
