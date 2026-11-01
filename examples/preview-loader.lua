-- Paste into an environment that provides Roblox client APIs, HttpGet and loadstring.
-- Opens the full interactive component gallery. Re-running replaces its previous UI.
local source=game:HttpGet("https://raw.githubusercontent.com/Cybersize/MattLib/main/Preview.lua")
local chunk,reason=loadstring(source,"@MattLib/Preview.lua")
assert(chunk,reason)
return chunk()
