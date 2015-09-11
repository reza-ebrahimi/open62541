local lcpp = require("lcpp")
local ffi = require("ffi")

local types_h = lcpp.compileFile("ua_types.h", {UA_FFI_BINDINGS=true})
ffi.cdef(types_h)
local C = ffi.load("open62541")

local ua = {}

ua.string = ffi.metatype("UA_String", {
    __new = function(ct, str)
       local new = ffi.new("UA_String")
       if type(str) == "string" then
          new = C.UA_String_fromChars(str)
       elseif type(str) == "cdata" and ffi.istype(ua.string, str) then
          C.UA_String_copy(str, new)
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
    end,
    __index = {
       copy = function(from)
          to = ua.string()
          C.UA_String_copy(from, to)
          return to
       end
    }
})

ua.guid = ffi.metatype("UA_Guid", {
    __tostring = function(guid)
       function num2hex(num,minlen)
          if minlen == nil then minlen = 1 end
          local hexstr = "0123456789abcdef"
          local s = ""
          while num > 0 do
             local mod = math.fmod(num, 16)
             s = string.sub(hexstr, mod+1, mod+1) .. s
             num = math.floor(num / 16)
          end
          if s == "" then s = "0" end
          return string.rep("0", minlen-string.len(s)) .. s
       end
       return num2hex(guid.data1,8) .. "-" .. num2hex(guid.data2,4) .. "-" .. num2hex(guid.data3,4) .. "-" ..
          num2hex(guid.data4[0]) .. num2hex(guid.data4[1]) .. num2hex(guid.data4[2]) .. num2hex(guid.data4[3]) ..
          num2hex(guid.data4[4]) .. num2hex(guid.data4[5]) .. num2hex(guid.data4[6]) .. num2hex(guid.data4[7])
    end
})

ua.nodeid = ffi.metatype("UA_NodeId", {
    __new = function(ct, namespaceindex, identifier)
       local new = ffi.new("UA_NodeId")
       C.UA_NodeId_init(new)
       if type(namespaceindex) == "number" then
          new.namespaceIndex = namespaceindex
       end
       if type(identifier) == "number" then
          new.identifier.numeric = identifier
       elseif type(identifier) == "string" then
          new.identifierType = C.UA_NODEIDTYPE_STRING
          new.identifier.string = ua.string(identifier)
       elseif type(identifier) == "cdata" then
          if ffi.istype(ua.string, identifier) then
             new.identifierType = C.UA_NODEIDTYPE_STRING
             new.identifier.string = ffi.gc(identifier:copy(), nil)
          elseif ffi.istype(ua.guid, identifier) then
             new.identifierType = C.UA_NODEIDTYPE_GUID
             new.identifier.guid = identifier
          else
             error("identifier type not yet implemented")
          end
       end
       return new
    end,
    __gc = C.UA_NodeId_deleteMembers,
    __tostring = function(id)
       local s = "nodeid(" .. id.namespaceIndex .. ", "
       if id.identifierType == C.UA_NODEIDTYPE_NUMERIC then
          s = s .. id.identifier.numeric .. ")"
       elseif id.identifierType == C.UA_NODEIDTYPE_STRING then
          s = s .. tostring(id.identifier.string) .. ")"
       elseif id.identifierType == C.UA_NODEIDTYPE_GUID then
          s = s .. tostring(identifier.guid) .. ")"
       else
          error("bytestrings are not yet implemented")
       end
       return s
    end,
})

return ua
