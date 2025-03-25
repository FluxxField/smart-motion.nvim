local log = require("smart-motion.core.log")

local M = {}

function M.validate_module(name, module, trigger_key)
	if not module or type(module.run) ~= "function" then
		log.error("Invalid or missing module '" .. name .. "' for motion: " .. trigger_key)
		return false
	end

	return true
end

function M.validate_pipeline(motion, trigger_key, registries)
	if not motion.pipeline then
		log.error("Missing pipeline for motion: " .. trigger_key)
		return false
	end

	local p = motion.pipeline

	-- Required pipeline fields
	local required = {
		collector = "collector",
		extractor = "extractor",
		visualizer = "visualizer",
	}

	for key, label in pairs(required) do
		if not p[key] then
			log.error("Missing pipeline property '" .. key .. "' for motion: " .. trigger_key)
			return false
		end
	end

	-- Lookup from registries and validate .run
	local collector = registries.collectors.get_by_name(p.collector)
	if not M.validate_module("collector", collector, trigger_key) then
		return false
	end

	local extractor = registries.extractors.get_by_name(p.extractor)
	if not M.validate_module("extractor", extractor, trigger_key) then
		return false
	end

	local visualizer = registries.visualizers.get_by_name(p.visualizer)
	if not M.validate_module("visualizer", visualizer, trigger_key) then
		return false
	end

	if p.filter then
		local filter = registries.filters.get_by_name(p.filter)
		if not M.validate_module("filter", filter, trigger_key) then
			log.warn("Falling back to default filter for motion: " .. trigger_key)
		end
	end

	if motion.pipeline_wrapper then
		local wrapper = registries.wrappers.get_by_name(motion.pipeline_wrapper)
		if not M.validate_module("wrapper", wrapper, trigger_key) then
			log.warn("Falling back to default wrapper for motion: " .. trigger_key)
		end
	end

	return true
end

return M
