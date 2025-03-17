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
        self._features[feature] = self._features[feature] or {}
        table.insert(self._features[feature], task)
    end
    
    table.insert(self._tasks, task)
    return task
end

function Maid:Add(task)
    assert(task ~= nil, "Task cannot be nil")
    return self:AddTask(task)
end

function Maid:GiveTask(task)
    assert(task ~= nil, "Task cannot be nil")
    return self:AddTask(task)
end

function Maid:GivePromise(promise)
    assert(promise ~= nil, "Promise cannot be nil")
    
    if promise.Status == "Rejected" or promise.Status == "Resolved" then
        return promise
    end
    
    local connection
    connection = promise:Finally(function()
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
    if task == nil then
        return
    end
    
    for i, v in ipairs(self._tasks) do
        if v == task then
            local taskToClean = table.remove(self._tasks, i)
            self:_cleanupTask(taskToClean)
            return
        end
    end
    
    for feature, tasks in pairs(self._features) do
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
    if task == nil then
        return
    end
    
    if typeof(task) == "function" then
        task()
    elseif typeof(task) == "RBXScriptConnection" then
        task:Disconnect()
    elseif typeof(task) == "table" and task.Destroy then
        task:Destroy()
    elseif typeof(task) == "table" and task.Disconnect then
        task:Disconnect()
    elseif typeof(task) == "table" and task.destroy then
        task:destroy()
    elseif typeof(task) == "table" and task.disconnect then
        task:disconnect()
    end
end

function Maid:Cleanup(feature)
    if feature then
        for _, task in ipairs(self._features[feature] or {}) do
            self:_cleanupTask(task)
        end
        self._features[feature] = {}
        return
    end
    
    for _, task in ipairs(self._tasks) do
        self:_cleanupTask(task)
    end
    
    self._tasks = {}
    self._features = {}
    self._indices = {}
end

function Maid:Destroy()
    self:Cleanup()
end

function Maid:DoCleaning()
    self:Cleanup()
end

return Maid
