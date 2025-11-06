local Graft = require("../src")
if not Graft.IsGrafted() then
	-- selene: allow(undefined_variable)
	return Graft.new():Run(...)
end

local task = require("@lune/task")

local strs = {}
local function work()
	table.insert(strs, "goodbye")
	table.insert(strs, "but hi")
end
work()
task.wait(3)
work()

return strs
