-- Hello, new game, let's go!!!!

local simulsim = require("simulsim")
local game = simulsim.defineGame()

local GAME_W = 192-16
local GAME_H = 128-24
local GAME_X = 8
local GAME_Y = 0

function game.update(self, dt)
  for id, s in ipairs(self.entities) do
    local inputs = self:getInputsForClient(s.clientId)
    
    if inputs then
      s.cur_x = inputs.cur_x
      s.cur_y = inputs.cur_y
    end
    
    local col_a, col_k = {}, {}
    
    if s.x - s.radius <= 0 then
      s.x = s.radius
      add(col_a, 0.5)
      add(col_k, 5)
    end
    
    if s.x + s.radius >= GAME_W then
      s.x = GAME_W - s.radius
      add(col_a, 0)
      add(col_k, 5)
    end
    
    if s.y + s.radius >= GAME_H then
      s.y = GAME_H - s.radius
      add(col_a, 0.25)
      add(col_k, 5)
    end
    
    for o_id, o in ipairs(self.entities) do
      if id ~= o_id then
        -- check for collision with s o
        
        local sd = sqrdist(o.x - s.x, o.y - s.y)
        if sd < sqr(o.radius + s.radius) then
          add(col_a, atan2(o.x - s.x, o.y - s.y))
          add(col_k, 1)
        end
      end
    end
    
    local a0, a1, k = 0, 0, 0
    for i, a in pairs(col_a) do
      local ik = col_k[i]
      a0 = ik * (a0 + ((a + 0.5) % 1 - 0.5))
      a1 = ik * (a1 + a - 0.5)
      k = k + ik
    end
    
    if k > 0 then
      s.grounded = true
      
      if abs(a0) < abs(a1) then
        s.ground_a = a0
      else
        s.ground_a = a1+0.5
      end
    else
      s.grounded = false
    end
    
    
    if s.grounded then
      local jump = 50
      s.vx = 0.5 * s.vx - jump * cos(s.ground_a)
      s.vy = 0.5 * s.vy - jump * sin(s.ground_a)
    end
    
    s.x = s.x + s.vx * dt
    s.y = s.y + s.vy * dt
    
    s.vy = s.vy + dt * 100
    s.vx = s.vx + dt * 80 * sgn(s.cur_x - s.x)
    
    
    if abs(s.diff_x)+abs(s.diff_y) > 0 then
       local dx = sgn(s.diff_x) * min(abs(s.diff_x), (5 + abs(s.diff_x)/16) * dt)
       local dy = sgn(s.diff_y) * min(abs(s.diff_y), (5 + abs(s.diff_y)/16) * dt)
       
--       s.x = s.x - dx
--       s.y = s.y - dy
       
       s.diff_x = s.diff_x - dx
       s.diff_y = s.diff_y - dy
    end
    
--    if s.rvx then
--      s.vx = lerp(s.vx, s.rvx)
--      s.vy = lerp(s.vy, s.rvy)
--    end
  end
end

display_entities = {}
function game.handleEvent(self, type, data)
  if type == "spawn_player" then
    local s = self:spawnEntity({
      clientId = data.clientId,
--      isImmuneToClientPredictions = true,
      x = data.x,
      y = data.y,
      vx = 0,
      vy = 0,
      grounded = false,
      ground_a = 0,
      cur_x = data.x,
      cur_y = data.y,
      diff_x = 0,
      diff_y = 0,
      radius = 6
    })
    
    display_entities[s.id] = {
      x = data.x,
      y = data.y
    }
    
    log("Spawned a new player.", "G")
  -- Despawn a player
  elseif type == "despawn_player" then
    self:despawnEntity(self:getEntityWhere({ clientId = data.clientId }))
    log("Despawned a player.", "G")
  end
end


--

local network, server, client = simulsim.createGameNetwork(game, {
  mode = 'development',
  numClients = 2,
  overrideCallbackMethods = true
})

-- client-specific:

for clientIndex, client in ipairs(network.clients) do
  function client.load()
    init_sugar("Paku-Boisu!", 192, 128, 3)
    
    use_palette({  -- Lux3K!
      0xce3b26, 0xf7872a, 0xfcd56b, 0xe7952e, 
      0xf9b857, 0xf0c209, 0xb16e45, 0xf4b27a, 
      0xf0d89d, 0xf9f5d2, 0x8f4349, 0xffa686, 
      0xfdceab, 0x5cac48, 0x8cce6c, 0xc1ec48, 
      0x060329, 0x1c2833, 0x145041, 0x231618, 
      0x521e23, 0x832121, 0xff804a, 0xe16169, 
      0xee8095, 0x7b3781, 0xb64d75, 0xa07385, 
      0x44050b, 0x6d2a41, 0x962c52, 0xe53366, 
      0x6e5657, 0xa7acba, 0xaccdec, 0x1c5c83, 
      0x2ba8b5, 0x46dccd
    })
    
    define_controls()
    
    screen_shader()
    
    _init = true
  end
  
  function client.update(dt)
    if not _init then return end
  
    -- send inputs here
    client.setInputs({
      cur_x = btnv(0) - GAME_X,
      cur_y = btnv(1) - GAME_Y,
      lmb = btn(2)
    })
    
    for id, s in ipairs(display_entities) do
      local rs = client.game:getEntityById(id)
      
      s.x = lerp(s.x, rs.x, 5*dt)
      s.y = lerp(s.y, rs.y, 5*dt)
    end
    
--    for id, s in ipairs(entities) do
--      if s.diff_x then
--         local dx = min(s.diff_x, (20 + s.diff_x) * dt)
--         local dy = min(s.diff_y, (20 + s.diff_y) * dt)
--         
--         s.x = s.x + dx
--         s.y = s.y + dy
--         
--         s.diff_x = s.diff_x - dx
--         s.diff_y = s.diff_y - dy
--      end
--    end
  end
  
  function client.draw()
    if not _init then return end
    
    target()
    clip()
  
    cls(16)
    
    camera(-GAME_X, -GAME_Y)
  
    --for _, s in ipairs(client.game.entities) do
    for id, s in ipairs(display_entities) do
      local rs = client.game:getEntityById(id)
      circfill(rs.x, rs.y, rs.radius, 17)
      circfill(s.x, s.y, rs.radius, 9)
    end
    
    camera()
    
    circfill(btnv(0), btnv(1), 2, 23)
    
    printp(0x0000, 0x0312, 0x0, 0x0)
    printp_color(0,6,12)
    pprint("hi", 16, 16, 4)
    rectfill(36,36,68,68,34)
    pprint("hi", 20, 20, 5)
    
    rectfill(32,32,64,64,32)
    
  --  cls(32)
  --  
  --  half_flip()
  
  --  love.graphics.setColor(0,0,0,0)
  --  love.graphics.clear()
  --  love.graphics.setColor(1,1,1,1)
  --  love.graphics.circle("fill",64,64,32)
  end
  
  function client.syncEntity(game, s, f, is_prediction)
    if not s then
      return f
    end
    
    s.diff_x = s.x - f.x
    s.diff_y = s.y - f.y
    
    s.x = f.x
    s.y = f.y
    s.vx = f.vx
    s.vy = f.vy
    
    s.cur_x = f.cur_x
    s.cur_y = f.cur_y
    
    s.radius = f.radius

  --  log("done?")
  
    return s
  end
end

function define_controls()
  player_assign_ctrlr(0, 0)

  register_btn(0, 0, input_id("mouse_position", "x"))
  register_btn(1, 0, input_id("mouse_position", "y"))
  register_btn(2, 0, input_id("mouse_button", "lb"))
end


-- server-specific:

function server.load()
  init_sugar("Paku-Bois!", 192, 128, 3)
  _init = true
end

function server.update()
  if not _init then return end
end

function server.clientconnected(client)
  log("Client #"..client.clientId.." connected.", "S")
  server.fireEvent('spawn_player', {
    clientId = client.clientId,
    x = rnd(GAME_W),
    y = rnd(GAME_H)
  })
end

function server.clientdisconnected(client)
  log("Client #"..client.clientId.." disconnected.", "S")
  server.fireEvent('despawn_player', { clientId = client.clientId })
end