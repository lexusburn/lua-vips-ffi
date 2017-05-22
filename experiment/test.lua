-- experiment with inheritance


local BaseClass = {}

function BaseClass:new()
    print("in BaseClass:new")
    instance = {}
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function BaseClass:a()
    print("in BaseClass:a")
end

local x = BaseClass:new()
x:a()

local SubClass = BaseClass:new()

function SubClass:b()
    print("in SubClass:b")
end

local y = SubClass:new()
y:a()
y:b()
