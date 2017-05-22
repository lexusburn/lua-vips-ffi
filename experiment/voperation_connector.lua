-- manage VipsOperation
-- lookup and call operations

local ffi = require("ffi")
local gvalue = require("gvalue_connector")
local vobject = require("vobject_connector")
local bit = require("bit")
local band = bit.band
local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct _VipsOperation {
        VipsObject parent_instance;

        // opaque
    } VipsOperation;

    VipsOperation* vips_operation_new (const char* name);

    typedef void *(*VipsArgumentMapFn) (VipsOperation* object,
        GParamSpec* pspec,
        VipsArgumentClass* argument_class,
        VipsArgumentInstance* argument_instance,
        void* a, void* b);

    void* vips_argument_map (VipsOperation* object,
        VipsArgumentMapFn fn, void* a, void* b);

    VipsOperation* vips_cache_operation_build (VipsOperation* operation);
    void vips_object_unref_outputs (VipsOperation *operation);

]]

function print_r(t)
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if type(t) == "table" then
                for pos, val in pairs(t) do
                    if type(val) == "table" then
                        print(indent ..
                                "[" .. pos .. "] => " ..  tostring(t) .. " {")
                        sub_print_r(val, indent ..
                                string.rep(" ", string.len(pos) + 8))
                        print(indent ..
                                string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif type(val) == "string" then
                        print(indent .. "[ ".. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end
    if type(t) == "table" then
        print(tostring(t) .. " {")
        sub_print_r(t, "  ")
        print("}")
    else
        sub_print_r(t, "  ")
    end
    print()
end

local REQUIRED = 1
local CONSTRUCT = 2
local SET_ONCE = 4
local SET_ALWAYS = 8
local INPUT = 16
local OUTPUT = 32
local DEPRECATED = 64
local MODIFY = 128

local voperation
local voperation_mt = {
    __index = {
        argumentmap_typeof = ffi.typeof("VipsArgumentMapFn"),

        -- cast to an object
        object = function(self)
            return ffi.cast(vobject.typeof, self)
        end,

        -- this is slow ... call as little as possible
        getargs = function (self)
            local args = {}
            local cb = ffi.cast(voperation.argumentmap_typeof,
                function(self, pspec, argument_class, argument_instance, a, b)
                    table.insert(args,
                        {name = ffi.string(pspec.name),
                            flags = tonumber(argument_class.flags)
                        }
                    )
                end
            )
            vips.vips_argument_map(self, cb, nil, nil )
            cb:free()

            return args
        end,

        call = function(name, ...)
            local call_args = {...}

            local operation = vips.vips_operation_new(name)
            if operation == nil then
                print("no such operation", name)
                return
            end
            local object = operation:object()
            object:new()

            local arguments = operation:getargs()

            print(name, "needs:")
            print_r(arguments)

            print("passed:")
            print_r(call_args)

            local n = 0
            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, INPUT) ~= 0 and
                        band(flags, REQUIRED) ~= 0 and
                        band(flags, DEPRECATED) == 0 then
                    n = n + 1
                    if not object:set(arguments[i].name, call_args[n]) then
                        return
                    end
                end
            end

            local last_arg
            if #call_args == n then
                last_arg = nil
            elseif #call_args == n + 1 then
                last_arg = call_args[#call_args]
                if type(last_arg) ~= "table" then
                    error("final argument is not a table")
                end
            else
                print("#call_args =", #call_args)
                print("n =", n)
                error("wrong number of arguments to " .. name)
            end

            if last_arg then
                for k, v in pairs(last_arg) do
                    if not object:set(k, v) then
                        return
                    end
                end
            end

            print("constructing ...")
            local operation2 = vips.vips_cache_operation_build(operation);
            if operation2 == nil then
                vips.vips_object_unref_outputs(operation)
                print("build error", object.get_error())
                return nil
            end
            operation = operation2

            print("getting output ...")
            result = {}
            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, OUTPUT) ~= 0 and
                        band(flags, REQUIRED) ~= 0 and
                        band(flags, DEPRECATED) == 0 then
                    result[arguments[i].name] = object:get(arguments[i].name)
                end
            end

            if type(last_arg) == "table" then
                local optional_output = {}
                for i = 1, #arguments do
                    local flags = arguments[i].flags

                    if band(flags, OUTPUT) ~= 0 and
                            band(flags, REQUIRED) == 0 then
                        optional_output[arguments[i].name] = arguments[i].flags
                    end
                end

                for k, v in pairs(last_arg) do
                    if optional_output[k] then
                        result[k] = object:get(k)
                    end
                end
            end

            -- if there's a single thing in result, return it without the table
            -- wrapper
            local k, v
            k, v = next(result, nil)
            if k then
                local v2

                k, v2 = next(result, k)
                if not k then
                    print("returning singleton result")
                    result = v
                end
            end

            return result
        end,

    }
}

voperation = ffi.metatype("VipsOperation", voperation_mt)
return voperation
