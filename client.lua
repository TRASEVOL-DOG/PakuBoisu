if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
    "main.lua",
    "sugarcoat/sugarcoat.lua"
  })
end

require("sugarcoat/sugarcoat")
sugar.utility.using_package(sugar.S, true)
require("main")