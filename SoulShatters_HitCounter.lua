-- CombatTracker.lua
local CombatTracker = {}
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local function createLabel(parent, text, position)
	local label = Instance.new("TextLabel")
	label.Font = Enum.Font.Arcade
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = UDim2.new(0.1, 0, 0.1, 0)
	label.Text = text
	label.Visible = true
	label.Parent = parent
	return label
end

function CombatTracker:new(character, enemyFinder)
	local self = setmetatable({}, { __index = CombatTracker })

	self.Character = character
	self.EnemyFinder = enemyFinder
	self.LastHitTime = os.clock()
	self.Timeout = 5
	self.Damage = 0
	self.Hits = 0
	self.OldHealth = nil
	self.ComboActive = false

	local gui = Instance.new("ScreenGui")
	gui.Name = "CombatUI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.Parent = game:GetService("CoreGui")

	self.Frame = Instance.new("Frame", gui)
	self.Frame.BackgroundTransparency = 1
	self.Frame.Position = UDim2.new(0.93, 0, 0.4, 0)
	self.Frame.Size = UDim2.new(0.3, 0, 0.1, 0)

	self.HitLabel = createLabel(self.Frame, "0 Hits!", UDim2.new(0, 0, 0, 0))
	self.DmgLabel = createLabel(self.Frame, "0 Damage!", UDim2.new(-0.05, 0, 0.25, 0))

	self:hook()

	return self
end

function CombatTracker:hook()
	local hum = self.Character:WaitForChild("Humanoid")
	local hrp = self.Character:WaitForChild("HumanoidRootPart")

	self.Connection = self.Character:GetAttributeChangedSignal("LastDamageDone"):Connect(function()
		self.LastHitTime = os.clock()

		local enemy = self.EnemyFinder(self.Character)
		if not enemy or not enemy:FindFirstChild("Humanoid") then return end

		local hp = enemy.Humanoid.Health
		if self.OldHealth and hp < self.OldHealth then
			local dmg = self.OldHealth - hp
			self.Damage += dmg
			self.Hits += 1
			self.ComboActive = true

			self:updateUI()
			self:spawnVFX()
		end
		self.OldHealth = hp
	end)

	-- Combo timeout
	task.spawn(function()
		while true do
			if self.ComboActive and (os.clock() - self.LastHitTime >= self.Timeout) then
				self.ComboActive = false
				self.HitLabel.Visible = false
				self.DmgLabel.Visible = false
				self.Hits = 0
				self.Damage = 0
			end
			task.wait(0.2)
		end
	end)
end

function CombatTracker:updateUI()
	self.HitLabel.Text = self.Hits .. " Hits!"
	self.DmgLabel.Text = math.floor(self.Damage) .. " Damage!"
	self.HitLabel.Visible = true
	self.DmgLabel.Visible = true

	self.HitLabel.TextColor3 = Color3.new(1, 1, 1 - self.Hits / 35)
	self.DmgLabel.TextColor3 = Color3.new(1, 1 - self.Damage / 100, 1 - self.Damage / 100)

	-- Animate UI bounce
	self.HitLabel.TextSize = 155
	self.DmgLabel.TextSize = 155
	TweenService:Create(self.HitLabel, TweenInfo.new(0.2), { TextSize = 35 }):Play()
	TweenService:Create(self.DmgLabel, TweenInfo.new(0.2), { TextSize = 35 }):Play()
end

function CombatTracker:spawnVFX()
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Material = Enum.Material.Neon
	part.Color = Color3.new(1, 1 - self.Damage / 100, 1 - self.Damage / 100)
	part.CFrame = Camera.CFrame * CFrame.new(4 + math.random(-5,5)/5, 0.5 + math.random(-5,5)/25, -4)
	part.Parent = workspace
	Debris:AddItem(part, 0.5)

	local highlight = Instance.new("Highlight", part)
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1

	local mesh = Instance.new("SpecialMesh", part)
	mesh.MeshType = Enum.MeshType.Sphere

	TweenService:Create(part, TweenInfo.new(0.2), {
		Size = Vector3.new(1 + self.Damage / 50, 1, 1),
		Transparency = 1
	}):Play()
end

function CombatTracker:destroy()
	if self.Connection then self.Connection:Disconnect() end
	if self.Frame and self.Frame.Parent then self.Frame.Parent:Destroy() end
end

return CombatTracker
