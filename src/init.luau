local Graft = require("@luau_pkg/graft")
local pathfs = require("@pkg/pathfs")

local luau = require("@lune/luau")
local task = require("@lune/task")

local fs = pathfs.fs

--[=[
	@class GraftExtension

	@external Graft https://github.com/ewd3v/luau_graft
	@external Interface https://github.com/ewd3v/luau_graft/blob/main/src/interface.luau

	An extension class for [Graft].
	Inherits from [Graft].
]=]

local GraftExtension = setmetatable({}, Graft) :: impl
GraftExtension.__index = GraftExtension

export type proto = {
	_watchThread: thread,
} & Graft.proto
export type impl = typeof(setmetatable(
	{} :: {
		__index: impl,

		new: (source: string?, module: pathfs.AsPath?) -> GraftExtension,
	},
	Graft
))

export type GraftExtension = typeof(setmetatable({} :: proto, GraftExtension)) & Graft.Graft

local function getModuleFromSource(source: pathfs.AsPath): pathfs.FilePath?
	local path = pathfs.Path.from(source)
	if fs.isDir(path) then
		path:push("init")
	end

	for _, extension in { "luau", "lua" } do
		path:setExtension(extension)
		if fs.isFile(path) then
			return pathfs.FilePath.fromExisting(path)
		end
	end

	return nil
end

local function getFileLastModifiedUnixTimestampMillis(file: pathfs.FilePath): number
	return fs.metadata(file.path).modifiedAt.unixTimestampMillis
end

local function fileWatcher(self: GraftExtension, file: pathfs.FilePath)
	local lastModifiedAt = getFileLastModifiedUnixTimestampMillis(file)
	while task.wait(1) do
		local modifiedAt = getFileLastModifiedUnixTimestampMillis(file)
		if modifiedAt <= lastModifiedAt then
			continue
		end

		lastModifiedAt = modifiedAt
		self:Patch()
	end
end

--[=[
	Creates a new [Graft] object with an [Interface] that works for Lune.

	Also sets up a watcher thread that will automatically hot reload the Luau module when changes are detected.

	@external AsPath https://github.com/seaofvoices/luau-path/blob/main/src/Path.luau#L72
	@param module string | AsPath

	@error "Failed to get module." -- Is thrown when the constructor is unable to automatically determine the path to the current Luau module.
]=]
function GraftExtension.new(source: string?, module: pathfs.AsPath?): GraftExtension
	local file = assert(getModuleFromSource(module or debug.info(2, "s")), "Failed to get module.")

	local self = setmetatable(
		Graft.new({
			GetBytecode = function()
				return buffer.fromstring(luau.compile(file:readFile()))
			end,
		}, source or debug.info(2, "s")) :: any,
		GraftExtension
	)

	--[=[
		@within GraftExtension
		@prop _watchThread thread
		@private

		The thread that's watching for file changes.
	]=]
	self._watchThread = task.defer(fileWatcher, self, file)

	return self :: any
end

return GraftExtension
