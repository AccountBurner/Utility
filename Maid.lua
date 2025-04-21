local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({
        _tasks = {},
        _features = {},
        _indices = {}
    }, Maid)
end

function Maid:AddTask(task, feature)
    assert(task ~= nil, "Task cannot be nil")
    
    if feature then
        assert(type(feature) == "string" or type(feature) == "number", "Feature must be a string or number")
        self._features[feature] = self._features[feature] or {}
        table.insert(self._features[feature], task)
    end
    
    table.insert(self._tasks, task)
    return task
end

function Maid:Add(task)
    return self:AddTask(task)
end

function Maid:GiveTask(task)
    return self:AddTask(task)
end

function Maid:GivePromise(promise)
    if not promise or promise.Status == "Rejected" or promise.Status == "Resolved" then
        return promise
    end
    
    local connection = promise:Finally(function()
        self:Remove(connection)
    end)
    
    return self:AddTask(connection)
end

function Maid:__newindex(index, task)
    if task == nil then
        self:Remove(self._indices[index])
        self._indices[index] = nil
        return
    end
    
    self._indices[index] = task
    self:AddTask(task)
end

function Maid:Remove(task)
    if not task then return end
    
    for i, v in ipairs(self._tasks) do
        if v == task then
            local taskToClean = table.remove(self._tasks, i)
            self:_cleanupTask(taskToClean)
            return
        end
    end
    
    for _, tasks in pairs(self._features) do
        for i, v in ipairs(tasks) do
            if v == task then
                local taskToClean = table.remove(tasks, i)
                self:_cleanupTask(taskToClean)
                return
            end
        end
    end
end

function Maid:_cleanupTask(task)
    if not task then return end
    
    local taskType = typeof(task)
    
    if taskType == "function" then
        task()
    elseif taskType == "RBXScriptConnection" then
        task:Disconnect()
    elseif taskType == "Instance" then
        task:Destroy()
    elseif taskType == "table" then
        if task.Destroy then
            task:Destroy()
        elseif task.Disconnect then
            task:Disconnect()
        elseif task.destroy then
            task:destroy()
        elseif task.disconnect then
            task:disconnect()
        elseif task.Clean then
            task:Clean()
        end
    end
end

function Maid:Clean()
    for _, task in ipairs(self._tasks) do
        self:_cleanupTask(task)
    end
    table.clear(self._tasks)
    table.clear(self._features)
    table.clear(self._indices)
end

function Maid:Cleanup(feature)
    if feature then
        assert(type(feature) == "string" or type(feature) == "number", "Feature must be a string or number")
        for _, task in ipairs(self._features[feature] or {}) do
            self:_cleanupTask(task)
        end
        self._features[feature] = {}
        return
    end
    
    self:Clean()
end

function Maid:Destroy()
    self:Cleanup()
end

function Maid:DoCleaning()
    self:Cleanup()
end

function Maid:AddFeature(featureName)
    if not self._features[featureName] then
        self._features[featureName] = {}
    end
    return featureName
end

function Maid:TasksForFeature(featureName)
    return self._features[featureName] or {}
end

function Maid:HasFeature(featureName)
    return self._features[featureName] ~= nil and #self._features[featureName] > 0
end

function Maid:CreateDependencyBox(featureName, dependencies)
    self:AddFeature(featureName)
    
    local depBox = {
        _maid = self,
        _featureName = featureName,
        _dependencies = dependencies or {},
        _enabled = false
    }
    
    function depBox:SetupDependencies(deps)
        self._dependencies = deps or {}
        return self
    end
    
    function depBox:AddToggle(id, options)
        options = options or {}
        options.Callback = function(value)
            if options.OriginalCallback then
                options.OriginalCallback(value)
            end
            self:_checkState()
        end
        
        local toggle = self._maid:Add(id)
        toggle.Value = options.Default or false
        toggle.OnChanged = function(callback)
            callback(toggle.Value)
        end
        
        self._maid:AddTask(toggle, self._featureName)
        return toggle
    end
    
    function depBox:AddDependencyBox()
        local subDepBox = self._maid:CreateDependencyBox(self._featureName .. ".sub")
        subDepBox._parentBox = self
        
        function subDepBox:_checkState()
            local parentEnabled = self._parentBox and self._parentBox._enabled or true
            local allConditionsMet = parentEnabled
            
            if not allConditionsMet then
                self._enabled = false
                return false
            end
            
            for _, dep in ipairs(self._dependencies) do
                local toggle, expectedState = dep[1], dep[2]
                if toggle and toggle.Value ~= expectedState then
                    allConditionsMet = false
                    break
                end
            end
            
            self._enabled = allConditionsMet
            return allConditionsMet
        end
        
        return subDepBox
    end
    
    function depBox:_checkState()
        local allConditionsMet = true
        
        for _, dep in ipairs(self._dependencies) do
            local toggle, expectedState = dep[1], dep[2]
            if toggle and toggle.Value ~= expectedState then
                allConditionsMet = false
                break
            end
        end
        
        self._enabled = allConditionsMet
        return allConditionsMet
    end
    
    function depBox:IsEnabled()
        return self._enabled
    end
    
    function depBox:AddTask(task)
        return self._maid:AddTask(task, self._featureName)
    end
    
    return depBox
end

function Maid:Connect(signal, callback, feature)
    local connection = signal:Connect(callback)
    return self:AddTask(connection, feature)
end

function Maid:BindToRenderStep(name, priority, callback, feature)
    game:GetService("RunService"):BindToRenderStep(name, priority, callback)
    
    local unbind = function()
        game:GetService("RunService"):UnbindFromRenderStep(name)
    end
    
    return self:AddTask(unbind, feature)
end

function Maid:AddHeartbeat(callback, feature)
    return self:Connect(game:GetService("RunService").Heartbeat, callback, feature)
end

function Maid:CreateLoop(interval, callback, feature)
    local running = true
    
    task.spawn(function()
        while running and task.wait(interval) do
            callback()
        end
    end)
    
    local stop = function()
        running = false
    end
    
    return self:AddTask(stop, feature)
end

return Maid
