local httpService = game:GetService("HttpService")

local SaveManager = {} do
	SaveManager.Folder = "RayfieldConfigs"
	SaveManager.Ignore = {}
	SaveManager.Window = nil
	SaveManager.Rayfield = nil
	
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, flagValue, element)
				local timestamp = tick()
				return { type = "Toggle", idx = idx, value = flagValue, Timestamp = timestamp }
			end,
			Load = function(idx, data)
				if not SaveManager.Window then return end
				
				pcall(function()
					if SaveManager.Window.SetFlagValue then
						SaveManager.Window:SetFlagValue(idx, data.value)
					end
				end)
				
				pcall(function()
					if SaveManager.Window.GetFlag then
						local element = SaveManager.Window:GetFlag(idx)
						if element then
							if element.Set then
								element:Set(data.value)
							elseif element.SetValue then
								element:SetValue(data.value)
							end
						end
					end
				end)
			end,
		},
		Slider = {
			Save = function(idx, flagValue, element)
				local timestamp = tick()
				return { type = "Slider", idx = idx, value = flagValue, Timestamp = timestamp }
			end,
			Load = function(idx, data)
				if not SaveManager.Window then return end
				
				pcall(function()
					if SaveManager.Window.SetFlagValue then
						SaveManager.Window:SetFlagValue(idx, data.value)
					end
				end)
				
				pcall(function()
					if SaveManager.Window.GetFlag then
						local element = SaveManager.Window:GetFlag(idx)
						if element then
							if element.Set then
								element:Set(data.value)
							elseif element.SetValue then
								element:SetValue(data.value)
							end
						end
					end
				end)
			end,
		},
		Dropdown = {
			Save = function(idx, flagValue, element)
				local timestamp = tick()
				local multi = type(flagValue) == "table"
				return { type = "Dropdown", idx = idx, value = flagValue, multi = multi, Timestamp = timestamp }
			end,
			Load = function(idx, data)
				if not SaveManager.Window then return end
				
				pcall(function()
					if SaveManager.Window.SetFlagValue then
						SaveManager.Window:SetFlagValue(idx, data.value)
					end
				end)
				
				pcall(function()
					if SaveManager.Window.GetFlag then
						local element = SaveManager.Window:GetFlag(idx)
						if element then
							if element.Set then
								element:Set(data.value)
							elseif element.SetValue then
								element:SetValue(data.value)
							end
						end
					end
				end)
			end,
		},
		Colorpicker = {
			Save = function(idx, flagValue, element)
				local timestamp = tick()
				local hex = flagValue:ToHex()
				local transparency = 0
				if element and element.Transparency then
					transparency = element.Transparency
				end
				return { type = "Colorpicker", idx = idx, value = hex, transparency = transparency, Timestamp = timestamp }
			end,
			Load = function(idx, data)
				if not SaveManager.Window then return end
				
				local color = Color3.fromHex(data.value)
				local transparency = data.transparency or 0
				
				pcall(function()
					if SaveManager.Window.SetFlagValue then
						SaveManager.Window:SetFlagValue(idx, color)
					end
				end)
				
				pcall(function()
					if SaveManager.Window.GetFlag then
						local element = SaveManager.Window:GetFlag(idx)
						if element then
							if element.Set then
								element:Set(color)
							elseif element.SetValue then
								element:SetValue(color)
							end
							if element.SetTransparency then
								element:SetTransparency(transparency)
							end
						end
					end
				end)
			end,
		},
		Keybind = {
			Save = function(idx, flagValue, element)
				local timestamp = tick()
				local mode = "Toggle"
				if element and element.Mode then
					mode = element.Mode
				end
				return { type = "Keybind", idx = idx, mode = mode, key = flagValue, Timestamp = timestamp }
			end,
			Load = function(idx, data)
				if not SaveManager.Window then return end
				
				pcall(function()
					if SaveManager.Window.SetFlagValue then
						SaveManager.Window:SetFlagValue(idx, data.key)
					end
				end)
				
				pcall(function()
					if SaveManager.Window.GetFlag then
						local element = SaveManager.Window:GetFlag(idx)
						if element then
							if element.SetKeybind then
								element:SetKeybind(data.key, data.mode)
							elseif element.Set then
								element:Set(data.key)
							elseif element.SetValue then
								element:SetValue(data.key)
							end
						end
					end
				end)
			end,
		},
		Input = {
			Save = function(idx, flagValue, element)
				local timestamp = tick()
				return { type = "Input", idx = idx, text = tostring(flagValue or ""), Timestamp = timestamp }
			end,
			Load = function(idx, data)
				if not SaveManager.Window then return end
				if type(data.text) ~= "string" then return end
				
				pcall(function()
					if SaveManager.Window.SetFlagValue then
						SaveManager.Window:SetFlagValue(idx, data.text)
					end
				end)
				
				pcall(function()
					if SaveManager.Window.GetFlag then
						local element = SaveManager.Window:GetFlag(idx)
						if element then
							if element.Set then
								element:Set(data.text)
							elseif element.SetValue then
								element:SetValue(data.text)
							end
						end
					end
				end)
			end,
		},
	}

	function SaveManager:GetElementType(flagName, flagValue, element)
		if element then
			if element.Type == "Toggle" then return "Toggle"
			elseif element.Type == "Slider" then return "Slider"
			elseif element.Type == "Dropdown" then return "Dropdown"
			elseif element.Type == "ColorPicker" then return "Colorpicker"
			elseif element.Type == "Input" then return "Input"
			elseif element.Type == "Keybind" then return "Keybind"
			end
		end
		
		if typeof(flagValue) == "boolean" then return "Toggle"
		elseif typeof(flagValue) == "number" then return "Slider"
		elseif typeof(flagValue) == "Color3" then return "Colorpicker"
		elseif typeof(flagValue) == "string" then
			if element and element.Options then
				return "Dropdown"
			end
			return "Input"
		elseif type(flagValue) == "table" then
			return "Dropdown"
		end
		
		return "Input"
	end

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:SetWindow(window)
		self.Window = window
	end

	function SaveManager:SetRayfield(rayfield)
		self.Rayfield = rayfield
		_G.Rayfield = rayfield
	end

	function SaveManager:Save(name): (boolean, string?)
		if (not name) then
			return false, "No config file is selected"
		end

		local fullPath = self.Folder .. "/settings/" .. name .. ".json"

		local data = {
			objects = {}
		}

		if not self.Window then
			return false, "Window not set"
		end

		if self.Window.Flags then
			for idx, flagValue in pairs(self.Window.Flags) do
				if self.Ignore[idx] then continue end
				
				local element = self.Window:GetFlag and self.Window:GetFlag(idx) or nil
				local elementType = self:GetElementType(idx, flagValue, element)
				
				if self.Parser[elementType] then
					local saved = self.Parser[elementType].Save(idx, flagValue, element)
					table.insert(data.objects, saved)
				end
			end
		end

		table.sort(data.objects, function(v1, v2)
			return (v1.Timestamp or 0) < (v2.Timestamp or 0)
		end)

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return false, "Failed to JSON-Encode data"
		end

		writefile(fullPath, encoded)
		return true
	end

	function SaveManager:Load(name): (boolean, string?)
		if (not name) then
			return false, "No config file is selected"
		end
		
		local file = self.Folder .. "/settings/" .. name .. ".json"
		if not isfile(file) then return false, "invalid file" end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success then return false, "decode error" end

		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				task.spawn(self.Parser[option.type].Load, option.idx, option)
			end
		end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({ 
			"InterfaceManager_InterfaceTheme", "InterfaceManager_AcrylicToggle", "InterfaceManager_TransparentToggle", "InterfaceManager_MenuKeybind"
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {
			self.Folder,
			self.Folder .. "/settings"
		}

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function SaveManager:RefreshConfigList()
		local list = listfiles(self.Folder .. "/settings")

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == ".json" then
				local pos = file:find(".json", 1, true)
				local start = pos

				if typeof(pos) == "number" and typeof(start) == "number" then
					local char = file:sub(pos, pos)
					while char ~= "/" and char ~= "\\" and char ~= "" do
						pos = pos - 1
						char = file:sub(pos, pos)
					end

					if char == "/" or char == "\\" then
						local name = file:sub(pos + 1, start - 1)
						if name ~= "options" then
							out[#out + 1] = name
						end
					end
				end
			end
		end
		
		return out
	end

	function SaveManager:LoadAutoloadConfig()
		if isfile(self.Folder .. "/settings/autoload.txt") then
			local name = readfile(self.Folder .. "/settings/autoload.txt")

			local success, err = self:Load(name)
			if not success then
				if self.Rayfield then
					return self.Rayfield:Notify({
						Title = "Interface",
						Content = "Config loader",
						SubContent = "Failed to load autoload config: " .. tostring(err),
						Duration = 7
					})
				end
				return
			end

			if self.Rayfield then
				return self.Rayfield:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = string.format("Auto loaded config %q", name),
					Duration = 7
				})
			end
		end

		return nil
	end

	function SaveManager:BuildConfigSection(tab)
		if not self.Window then
			error("Must set SaveManager.Window")
		end
		if not self.Rayfield then
			error("Must set SaveManager.Rayfield")
		end

		local configName = "default"
		local configsList = self:RefreshConfigList()
		
		local configNameInput = tab:CreateInput({
			Name = "Config name",
			PlaceholderText = "default",
			RemoveTextAfterFocusLost = false,
			Flag = "SaveManager_ConfigName",
			Callback = function(Text)
				configName = tostring(Text or ""):gsub("[%c\\/:*?\"<>|]+", ""):gsub("^%s+", ""):gsub("%s+$", "")
				if configName == "" then configName = "default" end
			end,
		})

		local configsDropdown = tab:CreateDropdown({
			Name = "Config list",
			Options = configsList,
			CurrentOption = configsList[1] or nil,
			Flag = "SaveManager_ConfigList",
			Callback = function(Option)
				if Option then
					configName = tostring(Option)
					if configNameInput then
						pcall(function()
							if configNameInput.Set then
								configNameInput:Set(configName)
							elseif configNameInput.SetValue then
								configNameInput:SetValue(configName)
							end
						end)
					end
				end
			end,
		})

		tab:CreateButton({
			Name = "Create config",
			Callback = function()
				local name = configName or "default"
				local cleanName = name:gsub("[%c\\/:*?\"<>|]+", ""):gsub("^%s+", ""):gsub("%s+$", "")

				if name:gsub(" ", "") == "" then 
					return self.Rayfield:Notify({
						Title = "Interface",
						Content = "Config loader",
						SubContent = "Invalid config name (empty)",
						Duration = 7
					})
				end

				local success, err = self:Save(cleanName)
				if not success then
					return self.Rayfield:Notify({
						Title = "Interface",
						Content = "Config loader",
						SubContent = "Failed to save config: " .. tostring(err),
						Duration = 7
					})
				end

				self.Rayfield:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = string.format("Created config %q", cleanName),
					Duration = 7
				})

				configsList = self:RefreshConfigList()
				if configsDropdown then
					pcall(function()
						if configsDropdown.Refresh then
							configsDropdown:Refresh(configsList, true)
						elseif configsDropdown.SetOptions then
							configsDropdown:SetOptions(configsList)
						end
						if configsDropdown.Set then
							configsDropdown:Set(nil)
						elseif configsDropdown.SetValue then
							configsDropdown:SetValue(nil)
						end
					end)
				end

				return nil
			end
		})

		tab:CreateButton({
			Name = "Load config",
			Callback = function()
				local name = configName or "default"
				local cleanName = name:gsub("[%c\\/:*?\"<>|]+", ""):gsub("^%s+", ""):gsub("%s+$", "")

				local success, err = self:Load(cleanName)
				if not success then
					return self.Rayfield:Notify({
						Title = "Interface",
						Content = "Config loader",
						SubContent = "Failed to load config: " .. tostring(err),
						Duration = 7
					})
				end

				return self.Rayfield:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = string.format("Loaded config %q", cleanName),
					Duration = 7
				})
			end
		})

		tab:CreateButton({
			Name = "Overwrite config",
			Callback = function()
				local name = configName or "default"
				local cleanName = name:gsub("[%c\\/:*?\"<>|]+", ""):gsub("^%s+", ""):gsub("%s+$", "")

				local success, err = self:Save(cleanName)
				if not success then
					return self.Rayfield:Notify({
						Title = "Interface",
						Content = "Config loader",
						SubContent = "Failed to overwrite config: " .. tostring(err),
						Duration = 7
					})
				end

				return self.Rayfield:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = string.format("Overwrote config %q", cleanName),
					Duration = 7
				})
			end
		})

		tab:CreateButton({
			Name = "Refresh list",
			Callback = function()
				configsList = self:RefreshConfigList()
				if configsDropdown then
					pcall(function()
						if configsDropdown.Refresh then
							configsDropdown:Refresh(configsList, true)
						elseif configsDropdown.SetOptions then
							configsDropdown:SetOptions(configsList)
						end
						if configsDropdown.Set then
							configsDropdown:Set(nil)
						elseif configsDropdown.SetValue then
							configsDropdown:SetValue(nil)
						end
					end)
				end
			end
		})

		local autoloadDesc = "Current autoload config: none"
		if isfile(self.Folder .. "/settings/autoload.txt") then
			local name = readfile(self.Folder .. "/settings/autoload.txt")
			autoloadDesc = "Current autoload config: " .. name
		end

		local autoloadButton = tab:CreateButton({
			Name = "Set as autoload",
			Description = autoloadDesc,
			Callback = function()
				local name = configName or "default"
				local cleanName = name:gsub("[%c\\/:*?\"<>|]+", ""):gsub("^%s+", ""):gsub("%s+$", "")
				
				writefile(self.Folder .. "/settings/autoload.txt", cleanName)
				
				if autoloadButton then
					pcall(function()
						if autoloadButton.SetDescription then
							autoloadButton:SetDescription("Current autoload config: " .. cleanName)
						elseif autoloadButton.SetDesc then
							autoloadButton:SetDesc("Current autoload config: " .. cleanName)
						end
					end)
				end
				
				self.Rayfield:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = string.format("Set %q to auto load", cleanName),
					Duration = 7
				})
			end
		})

		SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
