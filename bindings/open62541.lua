local lcpp = require("lcpp")
local ffi = require("ffi")

local types_h = lcpp.compileFile("ua_types.h", {UA_FFI_BINDINGS=true})
ffi.cdef(types_h)
ffi.cdef("void *malloc(size_t size);")
local C = ffi.load("open62541")

local open62541 = {}
open62541.C = C

open62541.string = ffi.metatype("UA_String", {
    __new = function(ct, str)
       local new = ffi.new("UA_String")
       C.UA_String_init(new)
       if type(str) == "string" then
          new.length = string.len(str)
          new.data = ffi.C.malloc(new.length)
          ffi.copy(new.data, str, new.length)
       end
       return new
    end,
    __gc = C.UA_String_deleteMembers,
    __tostring = function(str)
       if str.length < 0 then
          return ""
       else
          return ffi.string(str.data, str.length)
       end
    end
})

                            
return open62541
