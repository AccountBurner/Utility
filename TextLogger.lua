local Maid = loadstring(game:HttpGet("https://raw.githubusercontent.com/AccountBurner/Utility/refs/heads/main/Maid.lua"))();
local Signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/AccountBurner/Utility/refs/heads/main/Signal"))();
local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/AccountBurner/Utility/refs/heads/main/Services"))();

local TweenService, CoreGui, UserInputService, GuiService, HttpService = Services:Get('TweenService', 'CoreGui', 'UserInputService', 'GuiService', 'HttpService');

local LoggerUI = {};
LoggerUI.__index = LoggerUI;

local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out);
local HOVER_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad);

local THEME = {
    Background = Color3.fromRGB(20, 20, 20),
    Secondary = Color3.fromRGB(15, 15, 15),
    Accent = Color3.fromRGB(85, 170, 255),
    Text = Color3.fromRGB(200, 200, 200),
    SubText = Color3.fromRGB(150, 150, 150),
    Hover = Color3.fromRGB(30, 30, 30),
    Success = Color3.fromRGB(85, 170, 127),
    Warning = Color3.fromRGB(245, 179, 66),
    Error = Color3.fromRGB(235, 87, 87),
    Border = Color3.fromRGB(40, 40, 40)
};

function LoggerUI.new(options)
    local self = setmetatable({}, LoggerUI);
    
    options = options or {};
    self.Title = options.Title or "Logger";
    self.Size = options.Size or UDim2.new(0, 400, 0, 300);
    self.Position = options.Position or UDim2.new(0, 10, 0.5, -150);
    self.MaxLogs = options.MaxLogs or 500;
    self.Theme = options.Theme or THEME;
    self.ShowTimestamps = options.ShowTimestamps ~= false;
    self.ShowCopyButtons = options.ShowCopyButtons ~= false;
    self.ShowSearchBar = options.ShowSearchBar ~= false;
    self.AnimationsEnabled = options.AnimationsEnabled ~= false;
    
    self.Logs = {};
    self.FilteredLogs = {};
    self.LogAdded = Signal.new();
    self.LogRemoved = Signal.new();
    self.SearchChanged = Signal.new();
    
    self._maid = Maid.new();
    print(self._maid);
    self._minimized = false;
    self._searchText = "";
    self._selectedLogs = {};
    
    self:_createUI();
    self:_setupConnections();
    
    return self;
end;

function LoggerUI:_createUI()
    self.GUI = Instance.new("ScreenGui");
    self.GUI.Name = "UniversalLogger";
    self.GUI.ResetOnSpawn = false;
    self.GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    
    self.Frame = Instance.new("Frame");
    self.Frame.Size = self.Size;
    self.Frame.Position = self.Position;
    self.Frame.BackgroundColor3 = self.Theme.Background;
    self.Frame.BorderSizePixel = 0;
    self.Frame.ClipsDescendants = true;
    self.Frame.Parent = self.GUI;
    
    local corner = Instance.new("UICorner");
    corner.CornerRadius = UDim.new(0, 6);
    corner.Parent = self.Frame;
    
    local stroke = Instance.new("UIStroke");
    stroke.Color = self.Theme.Border;
    stroke.Thickness = 1;
    stroke.Transparency = 0.5;
    stroke.Parent = self.Frame;
    
    self:_createTitleBar();
    self:_createToolbar();
    self:_createContentArea();
    
    if syn and syn.protect_gui then
        syn.protect_gui(self.GUI);
        self.GUI.Parent = CoreGui;
    elseif gethui then
        self.GUI.Parent = gethui();
    else
        self.GUI.Parent = CoreGui;
    end;
end;

function LoggerUI:_createTitleBar()
    self.TitleBar = Instance.new("Frame");
    self.TitleBar.Size = UDim2.new(1, 0, 0, 30);
    self.TitleBar.BackgroundColor3 = self.Theme.Secondary;
    self.TitleBar.BorderSizePixel = 0;
    self.TitleBar.Parent = self.Frame;
    
    local titleCorner = Instance.new("UICorner");
    titleCorner.CornerRadius = UDim.new(0, 6);
    titleCorner.Parent = self.TitleBar;
    
    local titleFix = Instance.new("Frame");
    titleFix.Size = UDim2.new(1, 0, 0, 6);
    titleFix.Position = UDim2.new(0, 0, 1, -6);
    titleFix.BackgroundColor3 = self.Theme.Secondary;
    titleFix.BorderSizePixel = 0;
    titleFix.Parent = self.TitleBar;
    
    self.TitleLabel = Instance.new("TextLabel");
    self.TitleLabel.Size = UDim2.new(1, -80, 1, 0);
    self.TitleLabel.Position = UDim2.new(0, 10, 0, 0);
    self.TitleLabel.BackgroundTransparency = 1;
    self.TitleLabel.Text = self.Title;
    self.TitleLabel.TextColor3 = self.Theme.Text;
    self.TitleLabel.TextSize = 14;
    self.TitleLabel.Font = Enum.Font.GothamBold;
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left;
    self.TitleLabel.Parent = self.TitleBar;
    
    local buttonContainer = Instance.new("Frame");
    buttonContainer.Size = UDim2.new(0, 60, 1, 0);
    buttonContainer.Position = UDim2.new(1, -60, 0, 0);
    buttonContainer.BackgroundTransparency = 1;
    buttonContainer.Parent = self.TitleBar;
    
    self.MinButton = self:_createTitleButton("-", UDim2.new(0, 0, 0, 0), buttonContainer);
    self.CloseButton = self:_createTitleButton("×", UDim2.new(0, 30, 0, 0), buttonContainer);
end;

function LoggerUI:_createTitleButton(text, position, parent)
    local button = Instance.new("TextButton");
    button.Size = UDim2.new(0, 30, 1, 0);
    button.Position = position;
    button.BackgroundTransparency = 1;
    button.Text = text;
    button.TextColor3 = self.Theme.SubText;
    button.TextSize = 18;
    button.Font = Enum.Font.Gotham;
    button.Parent = parent;
    
    self._maid:AddTask(button.MouseEnter:Connect(function()
        if self.AnimationsEnabled then
            TweenService:Create(button, HOVER_TWEEN, {TextColor3 = self.Theme.Text}):Play();
        end;
    end));
    
    self._maid:AddTask(button.MouseLeave:Connect(function()
        if self.AnimationsEnabled then
            TweenService:Create(button, HOVER_TWEEN, {TextColor3 = self.Theme.SubText}):Play();
        end;
    end));
    
    return button;
end;

function LoggerUI:_createToolbar()
    self.Toolbar = Instance.new("Frame");
    self.Toolbar.Size = UDim2.new(1, 0, 0, 40);
    self.Toolbar.Position = UDim2.new(0, 0, 0, 30);
    self.Toolbar.BackgroundColor3 = self.Theme.Background;
    self.Toolbar.BorderSizePixel = 0;
    self.Toolbar.Parent = self.Frame;
    
    local toolbarLayout = Instance.new("UIListLayout");
    toolbarLayout.FillDirection = Enum.FillDirection.Horizontal;
    toolbarLayout.Padding = UDim.new(0, 5);
    toolbarLayout.Parent = self.Toolbar;
    
    local toolbarPadding = Instance.new("UIPadding");
    toolbarPadding.PaddingLeft = UDim.new(0, 10);
    toolbarPadding.PaddingRight = UDim.new(0, 10);
    toolbarPadding.PaddingTop = UDim.new(0, 5);
    toolbarPadding.PaddingBottom = UDim.new(0, 5);
    toolbarPadding.Parent = self.Toolbar;
    
    if self.ShowSearchBar then
        self.SearchBar = self:_createSearchBar();
    end;
    
    self.ClearButton = self:_createToolbarButton("Clear", function()
        self:Clear();
    end);
    
    self.CopyAllButton = self:_createToolbarButton("Copy All", function()
        self:CopyAll();
    end);
    
    self.ExportButton = self:_createToolbarButton("Export", function()
        self:Export();
    end);
end;

function LoggerUI:_createSearchBar()
    local searchContainer = Instance.new("Frame");
    searchContainer.Size = UDim2.new(0, 200, 0, 30);
    searchContainer.BackgroundColor3 = self.Theme.Secondary;
    searchContainer.BorderSizePixel = 0;
    searchContainer.Parent = self.Toolbar;
    
    local searchCorner = Instance.new("UICorner");
    searchCorner.CornerRadius = UDim.new(0, 4);
    searchCorner.Parent = searchContainer;
    
    local searchIcon = Instance.new("ImageLabel");
    searchIcon.Size = UDim2.new(0, 16, 0, 16);
    searchIcon.Position = UDim2.new(0, 8, 0.5, -8);
    searchIcon.BackgroundTransparency = 1;
    searchIcon.Image = "rbxassetid://7733956530";
    searchIcon.ImageColor3 = self.Theme.SubText;
    searchIcon.Parent = searchContainer;
    
    local searchBox = Instance.new("TextBox");
    searchBox.Size = UDim2.new(1, -35, 1, 0);
    searchBox.Position = UDim2.new(0, 30, 0, 0);
    searchBox.BackgroundTransparency = 1;
    searchBox.PlaceholderText = "Search logs...";
    searchBox.PlaceholderColor3 = self.Theme.SubText;
    searchBox.Text = "";
    searchBox.TextColor3 = self.Theme.Text;
    searchBox.TextSize = 14;
    searchBox.Font = Enum.Font.Gotham;
    searchBox.TextXAlignment = Enum.TextXAlignment.Left;
    searchBox.ClearTextOnFocus = false;
    searchBox.Parent = searchContainer;
    
    self._maid:AddTask(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self._searchText = searchBox.Text;
        self:_filterLogs();
        self.SearchChanged:Fire(self._searchText);
    end));
    
    return searchContainer;
end;

function LoggerUI:_createToolbarButton(text, callback)
    local button = Instance.new("TextButton");
    button.Size = UDim2.new(0, 80, 0, 30);
    button.BackgroundColor3 = self.Theme.Secondary;
    button.BorderSizePixel = 0;
    button.Text = text;
    button.TextColor3 = self.Theme.Text;
    button.TextSize = 14;
    button.Font = Enum.Font.Gotham;
    button.AutoButtonColor = false;
    button.Parent = self.Toolbar;
    
    local buttonCorner = Instance.new("UICorner");
    buttonCorner.CornerRadius = UDim.new(0, 4);
    buttonCorner.Parent = button;
    
    self._maid:AddTask(button.MouseEnter:Connect(function()
        if self.AnimationsEnabled then
            TweenService:Create(button, HOVER_TWEEN, {BackgroundColor3 = self.Theme.Hover}):Play();
        end;
    end));
    
    self._maid:AddTask(button.MouseLeave:Connect(function()
        if self.AnimationsEnabled then
            TweenService:Create(button, HOVER_TWEEN, {BackgroundColor3 = self.Theme.Secondary}):Play();
        end;
    end));
    
    self._maid:AddTask(button.MouseButton1Click:Connect(callback));
    
    return button;
end;

function LoggerUI:_createContentArea()
    self.ScrollFrame = Instance.new("ScrollingFrame");
    self.ScrollFrame.Size = UDim2.new(1, -4, 1, -74);
    self.ScrollFrame.Position = UDim2.new(0, 2, 0, 72);
    self.ScrollFrame.BackgroundTransparency = 1;
    self.ScrollFrame.BorderSizePixel = 0;
    self.ScrollFrame.ScrollBarThickness = 4;
    self.ScrollFrame.ScrollBarImageColor3 = self.Theme.Accent;
    self.ScrollFrame.ScrollBarImageTransparency = 0.5;
    self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0);
    self.ScrollFrame.Parent = self.Frame;
    
    self.LogContainer = Instance.new("Frame");
    self.LogContainer.Size = UDim2.new(1, 0, 1, 0);
    self.LogContainer.BackgroundTransparency = 1;
    self.LogContainer.Parent = self.ScrollFrame;
    
    local listLayout = Instance.new("UIListLayout");
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder;
    listLayout.Padding = UDim.new(0, 2);
    listLayout.Parent = self.LogContainer;
    
    self._maid:AddTask(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y);
    end));
    
    self.ResizeHandle = Instance.new("Frame");
    self.ResizeHandle.Size = UDim2.new(0, 20, 0, 20);
    self.ResizeHandle.Position = UDim2.new(1, -20, 1, -20);
    self.ResizeHandle.BackgroundTransparency = 1;
    self.ResizeHandle.Parent = self.Frame;
    
    local resizeIcon = Instance.new("TextLabel");
    resizeIcon.Size = UDim2.new(1, 0, 1, 0);
    resizeIcon.BackgroundTransparency = 1;
    resizeIcon.Text = "◢";
    resizeIcon.TextColor3 = self.Theme.SubText;
    resizeIcon.TextSize = 16;
    resizeIcon.Font = Enum.Font.SourceSans;
    resizeIcon.Parent = self.ResizeHandle;
end;

function LoggerUI:_setupConnections()
    local dragging, dragStart, startPos;
    local resizing, resizeStart, startSize;
    
    self._maid:AddTask(self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true;
            dragStart = input.Position;
            startPos = self.Frame.Position;
        end;
    end));
    
    self._maid:AddTask(self.ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true;
            resizeStart = input.Position;
            startSize = self.Frame.Size;
        end;
    end));
    
    self._maid:AddTask(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart;
            self.Frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            );
        elseif resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart;
            local newWidth = math.max(300, startSize.X.Offset + delta.X);
            local newHeight = math.max(200, startSize.Y.Offset + delta.Y);
            self.Frame.Size = UDim2.new(0, newWidth, 0, newHeight);
            self.Size = self.Frame.Size;
        end;
    end));
    
    self._maid:AddTask(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false;
            resizing = false;
        end;
    end));
    
    self._maid:AddTask(self.CloseButton.MouseButton1Click:Connect(function()
        task.spawn(function()
            self:Destroy();
        end);
    end));
    
    self._maid:AddTask(self.MinButton.MouseButton1Click:Connect(function()
        task.spawn(function()
            self:ToggleMinimize();
        end);
    end));
    
    self._maid:AddTask(self.LogAdded:Connect(function()
        task.spawn(function()
            self:_updateDisplay();
        end);
    end));
end;

function LoggerUI:_createLogEntry(log, index)
    local entry = Instance.new("Frame");
    entry.Size = UDim2.new(1, -4, 0, 24);
    entry.BackgroundColor3 = index % 2 == 0 and self.Theme.Background or self.Theme.Secondary;
    entry.BorderSizePixel = 0;
    entry.Parent = self.LogContainer;
    entry.LayoutOrder = index;
    
    local entryCorner = Instance.new("UICorner");
    entryCorner.CornerRadius = UDim.new(0, 4);
    entryCorner.Parent = entry;
    
    local entryPadding = Instance.new("UIPadding");
    entryPadding.PaddingLeft = UDim.new(0, 8);
    entryPadding.PaddingRight = UDim.new(0, 8);
    entryPadding.PaddingTop = UDim.new(0, 2);
    entryPadding.PaddingBottom = UDim.new(0, 2);
    entryPadding.Parent = entry;
    
    local textLabel = Instance.new("TextLabel");
    textLabel.Size = UDim2.new(1, self.ShowCopyButtons and -30 or 0, 1, 0);
    textLabel.BackgroundTransparency = 1;
    textLabel.Text = log.display or log.text;
    textLabel.TextColor3 = log.color or self.Theme.Text;
    textLabel.TextSize = 14;
    textLabel.Font = Enum.Font.SourceSans;
    textLabel.TextXAlignment = Enum.TextXAlignment.Left;
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd;
    textLabel.Parent = entry;
    
    if self.ShowCopyButtons then
        local copyButton = Instance.new("ImageButton");
        copyButton.Size = UDim2.new(0, 20, 0, 20);
        copyButton.Position = UDim2.new(1, -22, 0.5, -10);
        copyButton.BackgroundColor3 = self.Theme.Secondary;
        copyButton.BackgroundTransparency = 0.8;
        copyButton.BorderSizePixel = 0;
        copyButton.Image = "rbxassetid://7733919682"; -- Copy icon
        copyButton.ImageColor3 = self.Theme.SubText;
        copyButton.ImageTransparency = 0.3;
        copyButton.ScaleType = Enum.ScaleType.Fit;
        copyButton.Parent = entry;
        
        local copyCorner = Instance.new("UICorner");
        copyCorner.CornerRadius = UDim.new(0, 3);
        copyCorner.Parent = copyButton;
        
        self._maid:AddTask(copyButton.MouseEnter:Connect(function()
            TweenService:Create(copyButton, HOVER_TWEEN, {
                BackgroundTransparency = 0.6,
                ImageTransparency = 0
            }):Play();
        end));
        
        self._maid:AddTask(copyButton.MouseLeave:Connect(function()
            TweenService:Create(copyButton, HOVER_TWEEN, {
                BackgroundTransparency = 0.8,
                ImageTransparency = 0.3
            }):Play();
        end));
        
        self._maid:AddTask(copyButton.MouseButton1Click:Connect(function()
            setclipboard(log.text);
            
            -- Quick flash animation
            copyButton.ImageColor3 = self.Theme.Success;
            TweenService:Create(copyButton, TweenInfo.new(0.2), {
                ImageColor3 = self.Theme.SubText
            }):Play();
            
            self:_showNotification("Copied to clipboard!");
        end));
    end;
    
    self._maid:AddTask(entry.MouseEnter:Connect(function()
        if self.AnimationsEnabled then
            TweenService:Create(entry, HOVER_TWEEN, {BackgroundColor3 = self.Theme.Hover}):Play();
        end;
    end));
    
    self._maid:AddTask(entry.MouseLeave:Connect(function()
        if self.AnimationsEnabled then
            local targetColor = index % 2 == 0 and self.Theme.Background or self.Theme.Secondary;
            TweenService:Create(entry, HOVER_TWEEN, {BackgroundColor3 = targetColor}):Play();
        end;
    end));
    
    return entry;
end;

function LoggerUI:AddLog(text, options)
    options = options or {};
    
    local timestamp = os.date("%H:%M:%S");
    local log = {
        text = text,
        timestamp = timestamp,
        color = options.color,
        type = options.type or "info",
        data = options.data,
        display = self.ShowTimestamps and string.format("[%s] %s", timestamp, text) or text
    };
    
    table.insert(self.Logs, log);
    
    if #self.Logs > self.MaxLogs then
        local removed = table.remove(self.Logs, 1);
        task.spawn(function()
            self.LogRemoved:Fire(removed);
        end);
    end;
    
    if self._searchText ~= "" then
        local searchLower = self._searchText:lower();
        if log.text:lower():find(searchLower, 1, true) then
            table.insert(self.FilteredLogs, log);
        end;
    end;
    
    task.spawn(function()
        self.LogAdded:Fire(log);
    end);
    
    return log;
end;

function LoggerUI:_filterLogs()
    self.FilteredLogs = {};
    
    if self._searchText == "" then
        self.FilteredLogs = self.Logs;
    else
        local searchLower = self._searchText:lower();
        for _, log in ipairs(self.Logs) do
            if log.text:lower():find(searchLower, 1, true) then
                table.insert(self.FilteredLogs, log);
            end;
        end;
    end;
    
    self:_updateDisplay();
end;

function LoggerUI:_updateDisplay()
    for _, child in ipairs(self.LogContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy();
        end;
    end;
    
    local logsToDisplay = self._searchText == "" and self.Logs or self.FilteredLogs;
    
    for i, log in ipairs(logsToDisplay) do
        self:_createLogEntry(log, i);
    end;
    
    task.defer(function()
        if self.ScrollFrame and self.ScrollFrame.Parent then
            self.ScrollFrame.CanvasPosition = Vector2.new(0, math.max(0, self.ScrollFrame.CanvasSize.Y.Offset - self.ScrollFrame.AbsoluteSize.Y));
        end;
    end);
end;

function LoggerUI:_showNotification(text)
    local notification = Instance.new("Frame");
    notification.Size = UDim2.new(0, 200, 0, 40);
    notification.Position = UDim2.new(0.5, -100, 1, 20);
    notification.BackgroundColor3 = self.Theme.Success;
    notification.BorderSizePixel = 0;
    notification.Parent = self.Frame;
    
    local notifCorner = Instance.new("UICorner");
    notifCorner.CornerRadius = UDim.new(0, 4);
    notifCorner.Parent = notification;
    
    local notifText = Instance.new("TextLabel");
    notifText.Size = UDim2.new(1, 0, 1, 0);
    notifText.BackgroundTransparency = 1;
    notifText.Text = text;
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255);
    notifText.TextSize = 14;
    notifText.Font = Enum.Font.GothamBold;
    notifText.Parent = notification;
    
    TweenService:Create(notification, TWEEN_INFO, {Position = UDim2.new(0.5, -100, 1, -50)}):Play();
    
    task.wait(2);
    
    local fade = TweenService:Create(notification, TWEEN_INFO, {BackgroundTransparency = 1});
    TweenService:Create(notifText, TWEEN_INFO, {TextTransparency = 1}):Play();
    fade:Play();
    
    fade.Completed:Connect(function()
        notification:Destroy();
    end);
end;

function LoggerUI:Clear()
    self.Logs = {};
    self.FilteredLogs = {};
    self:_updateDisplay();
end;

function LoggerUI:CopyAll()
    local text = "";
    for _, log in ipairs(self.Logs) do
        text = text .. log.display .. "\n";
    end;
    setclipboard(text);
    self:_showNotification("All logs copied!");
end;

function LoggerUI:Export()
    local data = {
        title = self.Title,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        logs = self.Logs
    };
    
    local json = HttpService:JSONEncode(data);
    setclipboard(json);
    self:_showNotification("Exported as JSON!");
end;

function LoggerUI:ToggleMinimize()
    self._minimized = not self._minimized;
    
    if self._minimized then
        if self.AnimationsEnabled then
            TweenService:Create(self.Frame, TWEEN_INFO, {Size = UDim2.new(0, 200, 0, 30)}):Play();
        else
            self.Frame.Size = UDim2.new(0, 200, 0, 30);
        end;
        self.ScrollFrame.Visible = false;
        self.Toolbar.Visible = false;
        self.MinButton.Text = "+";
    else
        if self.AnimationsEnabled then
            TweenService:Create(self.Frame, TWEEN_INFO, {Size = self.Size}):Play();
        else
            self.Frame.Size = self.Size;
        end;
        self.ScrollFrame.Visible = true;
        self.Toolbar.Visible = true;
        self.MinButton.Text = "-";
    end;
end;

function LoggerUI:SetTheme(theme)
    self.Theme = theme;
    self.Frame.BackgroundColor3 = theme.Background;
    self.TitleBar.BackgroundColor3 = theme.Secondary;
end;

function LoggerUI:Show()
    self.GUI.Enabled = true;
    if self.AnimationsEnabled then
        self.Frame.Position = UDim2.new(self.Position.X.Scale, self.Position.X.Offset, self.Position.Y.Scale, self.Position.Y.Offset - 50);
        TweenService:Create(self.Frame, TWEEN_INFO, {Position = self.Position}):Play();
    end;
end;

function LoggerUI:Hide()
    if self.AnimationsEnabled then
        local hidePos = UDim2.new(self.Position.X.Scale, self.Position.X.Offset, self.Position.Y.Scale, self.Position.Y.Offset - 50);
        local tween = TweenService:Create(self.Frame, TWEEN_INFO, {Position = hidePos});
        tween:Play();
        tween.Completed:Connect(function()
            self.GUI.Enabled = false;
        end);
    else
        self.GUI.Enabled = false;
    end;
end;

function LoggerUI:Destroy()
    self._maid:Clean();
    self.GUI:Destroy();
end;
return LoggerUI;
