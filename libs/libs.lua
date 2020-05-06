LoadClass = function()
    ---------
    -- Start of slither.lua dependency
    ---------

    local _LICENSE = -- zlib / libpng
    [[
    Copyright (c) 2011-2014 Bart van Strien

    This software is provided 'as-is', without any express or implied
    warranty. In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

      1. The origin of this software must not be misrepresented; you must not
      claim that you wrote the original software. If you use this software
      in a product, an acknowledgment in the product documentation would be
      appreciated but is not required.

      2. Altered source versions must be plainly marked as such, and must not be
      misrepresented as being the original software.

      3. This notice may not be removed or altered from any source
      distribution.
    ]]

    local class =
    {
        _VERSION = "Slither 20140904",
        -- I have no better versioning scheme, deal with it
        _DESCRIPTION = "Slither is a pythonic class library for lua",
        _URL = "http://bitbucket.org/bartbes/slither",
        _LICENSE = _LICENSE,
    }

    local function stringtotable(path)
        local t = _G
        local name

        for part in path:gmatch("[^%.]+") do
            t = name and t[name] or t
            name = part
        end

        return t, name
    end

    local function class_generator(name, b, t)
        local parents = {}
        for _, v in ipairs(b) do
            parents[v] = true
            for _, v in ipairs(v.__parents__) do
                parents[v] = true
            end
        end

        local temp = { __parents__ = {} }
        for i, v in pairs(parents) do
            table.insert(temp.__parents__, i)
        end

        local class = setmetatable(temp, {
            __index = function(self, key)
                if key == "__class__" then return temp end
                if key == "__name__" then return name end
                if t[key] ~= nil then return t[key] end
                for i, v in ipairs(b) do
                    if v[key] ~= nil then return v[key] end
                end
                if tostring(key):match("^__.+__$") then return end
                if self.__getattr__ then
                    return self:__getattr__(key)
                end
            end,

            __newindex = function(self, key, value)
                t[key] = value
            end,

            allocate = function(instance)
                local smt = getmetatable(temp)
                local mt = {__index = smt.__index}

                function mt:__newindex(key, value)
                    if self.__setattr__ then
                        return self:__setattr__(key, value)
                    else
                        return rawset(self, key, value)
                    end
                end

                if temp.__cmp__ then
                    if not smt.eq or not smt.lt then
                        function smt.eq(a, b)
                            return a.__cmp__(a, b) == 0
                        end
                        function smt.lt(a, b)
                            return a.__cmp__(a, b) < 0
                        end
                    end
                    mt.__eq = smt.eq
                    mt.__lt = smt.lt
                end

                for i, v in pairs{
                    __call__ = "__call", __len__ = "__len",
                    __add__ = "__add", __sub__ = "__sub",
                    __mul__ = "__mul", __div__ = "__div",
                    __mod__ = "__mod", __pow__ = "__pow",
                    __neg__ = "__unm", __concat__ = "__concat",
                    __str__ = "__tostring",
                    } do
                    if temp[i] then mt[v] = temp[i] end
                end

                return setmetatable(instance or {}, mt)
            end,

            __call = function(self, ...)
                local instance = getmetatable(self).allocate()
                if instance.__init__ then instance:__init__(...) end
                return instance
            end
            })

        for i, v in ipairs(t.__attributes__ or {}) do
            class = v(class) or class
        end

        return class
    end

    local function inheritance_handler(set, name, ...)
        local args = {...}

        for i = 1, select("#", ...) do
            if args[i] == nil then
                error("nil passed to class, check the parents")
            end
        end

        local t = nil
        if #args == 1 and type(args[1]) == "table" and not args[1].__class__ then
            t = args[1]
            args = {}
        end

        for i, v in ipairs(args) do
            if type(v) == "string" then
                local t, name = stringtotable(v)
                args[i] = t[name]
            end
        end

        local func = function(t)
            local class = class_generator(name, args, t)
            if set then
                local root_table, name = stringtotable(name)
                root_table[name] = class
            end
            return class
        end

        if t then
            return func(t)
        else
            return func
        end
    end

    function class.private(name)
        return function(...)
            return inheritance_handler(false, name, ...)
        end
    end

    class = setmetatable(class, {
        __call = function(self, name)
            return function(...)
                return inheritance_handler(true, name, ...)
            end
        end,
    })


    function class.issubclass(class, parents)
        if parents.__class__ then parents = {parents} end
        for i, v in ipairs(parents) do
            local found = true
            if v ~= class then
                found = false
                for _, p in ipairs(class.__parents__) do
                    if v == p then
                        found = true
                        break
                    end
                end
            end
            if not found then return false end
        end
        return true
    end

    function class.isinstance(obj, parents)
        return type(obj) == "table" and obj.__class__ and class.issubclass(obj.__class__, parents)
    end

    -- Export a Class Commons interface
    -- to allow interoperability between
    -- class libraries.
    -- See https://github.com/bartbes/Class-Commons
    --
    -- NOTE: Implicitly global, as per specification, unfortunately there's no nice
    -- way to both provide this extra interface, and use locals.
    if common_class ~= nil and common_class ~= false then
        common = {}
        function common.class(name, prototype, superclass)
            prototype.__init__ = prototype.init
            return class_generator(name, {superclass}, prototype)
        end

        function common.instance(class, ...)
            return class(...)
        end
    end

    ---------
    -- End of slither.lua dependency
    ---------

    return class;
end

local class = LoadClass();

--- GTA:MTA Lua async thread scheduler.
-- @author Inlife
-- @license MIT
-- @url https://github.com/Inlife/mta-lua-async
-- @dependency slither.lua https://bitbucket.org/bartbes/slither
class "_async" {
    __init__ = function(self)

        self.threads = {};
        self.resting = 50;
        self.maxtime = 500;
        self.current = 0;
        self.state = "suspended";
        self.debug = false;
        self.priority = {
            low = {500, 50},
            normal = {200, 200},
            high = {50, 500},
            realtime = {0, 1000}
        };

        self:setPriority("realtime");
    end,

    switch = function(self, istimer)
        self.state = "running";

        if (self.current + 1  <= #self.threads) then
            self.current = self.current + 1;
            self:execute(self.current);
        else
            self.current = 0;

            if (#self.threads <= 0) then
                self.state = "suspended";
                return;
            end

            Citizen.SetTimeout(self.resting, function()
                self:switch();
            end);
        end
    end,

    execute = function(self, id)
        local thread = self.threads[id];

        if (thread == nil or coroutine.status(thread) == "dead") then
            table.remove(self.threads, id);
            self:switch();
        else
            coroutine.resume(thread);
            self:switch();
        end
    end,

    add = function(self, func)
        local thread = Citizen.CreateThread(func);
        table.insert(self.threads, thread);
    end,

    setPriority = function(self, param1, param2)
        if (type(param1) == "string") then
            if (self.priority[param1] ~= nil) then
                self.resting = self.priority[param1][1];
                self.maxtime = self.priority[param1][2];
            end
        else
            self.resting = param1;
            self.maxtime = param2;
        end
    end,

    setDebug = function(self, value)
        self.debug = value;
    end,

    iterate = function(self, from, to, func, callback)
        self:add(function()
            local a = GetGameTimer();
            local lastresume = GetGameTimer();
            for i = from, to do
                func(i); 

                if GetGameTimer() > lastresume + self.maxtime then
                    coroutine.yield()
                    lastresume = GetGameTimer()
                end
            end

            if (self.debug) then
                print("[DEBUG]async iterate: " .. (GetGameTimer() - a) .. "ms");
            end

            if (callback) then
                callback();
            end
        end);

        self:switch();
    end,

    foreach = function(self, array, func, callback)
        self:add(function()
            local a = GetGameTimer();
            local lastresume = GetGameTimer();
            local hasNumerikKey = #array > 0

            if (hasNumerikKey) then
                for i = 1, #array do
                    func(array[i],i);

                    if GetGameTimer() > lastresume + self.maxtime then
                        coroutine.yield()
                        lastresume = GetGameTimer()
                    end
                end
            else
                for k,v in pairs(array) do
                    func(v,k);

                    if GetGameTimer() > lastresume + self.maxtime then
                        coroutine.yield()
                        lastresume = GetGameTimer()
                    end
                end
            end

            if (self.debug) then
                print("[DEBUG]async foreach: " .. (GetGameTimer() - a) .. "ms");
            end

            if (callback) then
                callback();
            end
        end);

        self:switch();
    end,
}

async = {
    instance = nil,
};

local function getInstance()
    if async.instance == nil then
        async.instance = _async()
    end

    if (async.instance.state ~= 'suspended') then
        local resting = async.instance.resting
        local maxtime = async.instance.maxtime
        local debug = async.instance.debug
        local newAsync = _async()

        newAsync:setDebug(debug)
        newAsync:setPriority(resting, maxtime)

        async.instance = newAsync
    end

    return async.instance;
end

function async:setDebug(...)
    getInstance():setDebug(...)
end

function async:setPriority(...)
    getInstance():setPriority(...)
end

function async:iterate(...)
    getInstance():iterate(...)
end

function async:foreach(...)
    getInstance():foreach(...)
end

function foreach(array, func)
    local hasNumerikKey = #array > 0

    if (hasNumerikKey) then
        for i = 1, #array do
            local result = func(array[i],i)

            if (result ~= nil and result) then
                return result
            end
        end
    else
        for k,v in pairs(array) do
            local result = func(v,k);

            if (result ~= nil and result) then
                return result
            end
        end
    end
end

check = {
    _loaded = {}
}

function check:isLoaded(key)
    key = key or nil

    if (key == nil or type(key) ~= 'string') then
        return false
    end

    return check._loaded[key] ~= nil and check._loaded[key]
end

function check:loaded(key)
    key = key or nil

    if (key == nil or type(key) ~= 'string') then
        return
    end

    check._loaded[key] = true
end

function check:unloaded(key)
    key = key or nil

    if (key == nil or type(key) ~= 'string' or check._loaded[key] == nil) then
        return
    end

    check._loaded[key] = nil
end