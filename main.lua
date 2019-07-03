
-- `main.lua` is only to test with Love2D.
-- The Castle entry points are `client.lua` and `server.lua`.

--require("sugarcoat/sugarcoat")
--sugar.utility.using_package(sugar.S, true)



local castle_log = {}
local function get_logs(str)
  add(castle_log, str)
end

function love.load(args)
  if args[1] == "server" then
    love.event.push("keyreleased", '1')
  elseif args[1] == "client" then
    love.event.push("keyreleased", '2')
  end
end

function love.draw()
  if ROLE then
    love.graphics.clear()
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Running server.", 32, 16)
    --cls()
    --color(3)
    --print("Running server.", 8, 8)
    
    local y = 40
    local n = #castle_log
    while n > 0 do
      love.graphics.print(castle_log[n], 48, y)
      --print(castle_log[n], 4, y, 3)
      n = n-1
      y = y+24
    end
    
    --love.graphics.present()
  else
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Press 1 to launch local server.", 32, 32)
    love.graphics.print("Press 2 to launch local client.", 32, 64)
  end
end

function love.keyreleased(key)
  if key == '1' then
    local oldraw = love.draw

    love.keyreleased = nil
    require("server")
    start_server()
    
    catch_logs(get_logs)
    love.draw = oldraw
    
    love.graphics.setFont(love.graphics.newFont("sugarcoat/TeapotPro.ttf", 32))
  elseif key == '2' then
    love.keyreleased = nil
    require("client")
    start_client()
  end
end
