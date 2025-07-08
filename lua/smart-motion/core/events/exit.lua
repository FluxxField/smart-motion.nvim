local M = {}

local EXIT_FLAG = "__smart_motion_exit__"

function M.throw(exit_type)
  error({ [EXIT_FLAG] = true, exit_type = exit_type }, 0)
end

function M.throw_if(cond, exit_type)
  if cond then
    M.throw(exit_type)
  end
end

function M.wrap(fn)
  local ok, result = pcall(fn)

  if not ok and type(result) == 'table' and result[EXIT_FLAG] then
    retun result.exit_type
  elseif not ok then
    error(result)
  end

  return nil
end

return M
