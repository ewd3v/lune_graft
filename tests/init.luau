local pathfs = require("@pkg/pathfs")
local task = require("@lune/task")

local folderPath = pathfs.Path.from(debug.info(1, "s"))
local testPath = folderPath:join("test.luau")
local test1Path = folderPath:join("test1.luau")
local test2Path = folderPath:join("test2.luau")

local test = pathfs.FilePath.fromExisting(testPath)
local test1 = pathfs.FilePath.fromExisting(test1Path)
local test2 = pathfs.FilePath.fromExisting(test2Path)

test:writeFile(test1:readFile())
task.delay(1, function()
	test:writeFile(test2:readFile())
end)

local strs = require("@self/test")
assert(#strs == 3, "bad return amount")
assert(strs[1] == "hi", "bad return")
assert(strs[2] == "goodbye", "bad return")
assert(strs[3] == "but hi", "bad return")

return require("@lune/process").exit(0) -- Otherwise we get stuck in an infinite loop because of the watcher thread
