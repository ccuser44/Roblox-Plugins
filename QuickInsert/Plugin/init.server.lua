--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @ MaximumADHD, 2018-2022
--   Quick Insert Plugin
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local PluginGuiService = game:GetService("PluginGuiService")
local InsertService = game:GetService("InsertService")
local AssetService = game:GetService("AssetService")
local Selection = game:GetService("Selection")
local Players = game:GetService("Players")
local Studio = settings().Studio

local PLUGIN_TITLE = "Quick Insert"
local PLUGIN_DESC  = "Toggles the Quick Insert widget, which lets you paste any assetid and insert an asset."
local PLUGIN_ICON  = "rbxassetid://425778638"

local WIDGET_ID = "QuickInsertGui"
local WIDGET_INFO = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Left, true, false)

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Interface
--------------------------------------------------------------------------------------------------------------------------------------------------------------

if plugin.Name:find(".rbxm") then
	WIDGET_ID ..= "_Local"
	PLUGIN_TITLE ..= " (LOCAL)"
end

local old = PluginGuiService:FindFirstChild(WIDGET_ID)

if old then
	old:Destroy()
end

local ui = script.UI
local input = ui.Input
local errorLbl = ui.Error

local modules = script.Modules
local assetMap = require(modules.AssetMap)
local themeConfig = require(modules.ThemeConfig)


local toolbar: PluginToolbar do
	if not _G.Toolbar2032622 then
		_G.Toolbar2032622 = plugin:CreateToolbar("MaximumADHD")
	end

	toolbar = _G.Toolbar2032622
end

local button: PluginToolbarButton = toolbar:CreateButton(PLUGIN_TITLE, PLUGIN_DESC, PLUGIN_ICON)
local pluginGui = plugin:CreateDockWidgetPluginGui(WIDGET_ID, WIDGET_INFO)

pluginGui.Title = PLUGIN_TITLE
pluginGui.Name = WIDGET_ID

ui.Parent = pluginGui

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------

local function onThemeChanged()
	local theme: StudioTheme = Studio.Theme
	
	for name, config in pairs(themeConfig) do
		local element = ui:FindFirstChild(name)
		
		if element then
			for prop, guideColor in pairs(config) do
				element[prop] = theme:GetColor(guideColor)
			end
		end
	end
end

local function onEnabledChanged()
	button:SetActive(pluginGui.Enabled)
end

local function onButtonClick()
	pluginGui.Enabled = not pluginGui.Enabled
end

local function setError(e)
	errorLbl.Text = e
	warn(e)
end

local function onErrorTextChanged()
	local text = errorLbl.Text
	task.wait(2)
	
	if errorLbl.Text == text then
		errorLbl.Text = ""
	end
end

local function isHeadAsset(assetType: Enum.AssetType)
	return assetType.Name:sub(-4) == "Head"
end

local function isAccessoryAsset(assetType: Enum.AssetType)
	return assetType.Name:sub(-9) == "Accessory"
end

local function onFocusLost(enterPressed)
	if enterPressed then
		local success, errorMsg = pcall(function ()
			local assetId = tonumber(input.Text:match("%d+"))
			ChangeHistoryService:SetWaypoint("Insert")
			
			if not (assetId and assetId > 770) then
				error("Invalid AssetId!", 2)
			end

			local info = MarketplaceService:GetProductInfo(assert(assetId))
			local assetType = assetMap[info.AssetTypeId]

			local isHead = isHeadAsset(assetType)
			local isAccessory = isAccessoryAsset(assetType)
			
			local success, errorMsg = pcall(function ()
				local asset: Instance
				
				if isHead or isAccessory then
					local hDesc = Instance.new("HumanoidDescription")
					
					if isHead then
						hDesc.Head = assetId
					elseif isAccessory then
						hDesc.HatAccessory = tostring(assetId)
					end

					local dummy = Players:CreateHumanoidModelFromDescription(hDesc, Enum.HumanoidRigType.R15)
					asset = Instance.new("Folder")

					if isHead then
						local head = dummy:FindFirstChild("Head")

						if head and head:IsA("BasePart") then
							head.BrickColor = BrickColor.Gray()
							head.Parent = asset
						end
					elseif isAccessory then
						local accessory = dummy:FindFirstChildWhichIsA("Accoutrement", true)

						if accessory then
							accessory.Parent = asset
						end
					end
					
					for i, desc in asset:GetDescendants() do
						if desc:IsA("Vector3Value") then
							local parent = desc.Parent

							if parent and desc.Name:sub(1, 8) == "Original" then
								if parent:IsA("Attachment") then
									parent.Position = desc.Value
								elseif parent:IsA("BasePart") then
									parent.Size = desc.Value
								end
							end
						end
					end
				else
					asset = InsertService:LoadAsset(assetId)
				end

				local everything = asset:GetChildren()

				for i, item in everything do
					item.Parent = workspace
				end

				Selection:Set(everything)
			end)
			
			if not success then
				setError(errorMsg)
			end
		end)
		
		if success then
			ChangeHistoryService:SetWaypoint("Inserted")
		else
			setError(errorMsg)
		end
	end
	
	input.Text = ""
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Connections
--------------------------------------------------------------------------------------------------------------------------------------------------------------

local pluginGuiEnabled = pluginGui:GetPropertyChangedSignal("Enabled")
local errorTextChanged = errorLbl:GetPropertyChangedSignal("Text")

onEnabledChanged()
onThemeChanged()

pluginGuiEnabled:Connect(onEnabledChanged)
Studio.ThemeChanged:Connect(onThemeChanged)

errorTextChanged:Connect(onErrorTextChanged)
input.FocusLost:Connect(onFocusLost)

button.Click:Connect(onButtonClick)

--------------------------------------------------------------------------------------------------------------------------------------------------------------