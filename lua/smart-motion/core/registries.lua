local M = {}

function M:init(registries)
	if self.registries then
		return
	end

	self.registries = registries
end

function M:get()
	assert(self.registries, "[smart-motion] Registries not initialized. Call :init() first.")
	return self.registries
end

return M
