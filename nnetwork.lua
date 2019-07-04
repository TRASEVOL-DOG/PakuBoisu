if castle then
  cs = require("https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua")
else
  cs = require("cs")
end

network_t = 0
delay = 0
my_id = nil
connected = false

c_write = nil
c_read  = nil
s_write = nil
s_read  = nil

function init_network()
  if IS_SERVER then
    s_read  = server.homes
    s_write = server.share
    
    s_write[1] = {}
    s_write[2] = {} -- players
    s_write[3] = {} -- pastries
    s_write[4] = reset_id
  else
    
  end
end

function update_network()
  network_t = network_t - dt()
  if network_t > 0 then
    return
  end
  
  if IS_SERVER then
    server_output()
  else
    client_output()
  end
  
  network_t = 0.05
end



function client_input(diff)
  c_read = client.share
  my_id = client.id
  
  if not c_read[1] then return end
  
  local timestamp = c_read[1][client.id]
  
  if not timestamp then return end
  
  delay = (t() - timestamp) / 2
  connected = true
  
  delay = min(delay, 0.5)

  if diff[2] then
    for id,_ in pairs(diff[2]) do    
      if id == my_id then
        players[my_id].color = c_read[2][id][10]
        goto player_sync_end
      end
    
      local d = c_read[2][id]
      local p = players[id]
      
      if not p then
        if not d or #d < 6 then
          goto player_sync_end
        end
        
        p = create_player(id, d[1], d[2], d[10])
        
        add_log((d[12] or "A Boï").." joined the game!")
      elseif not d then
        deregister_object(p)
        players[id] = nil
        
        del_playerui(p)
        add_log((p.name or "A Boï").." left the game!")
        log("Player #"..id.." disconnected.")
        goto player_sync_end
      end
      
      if #d < 6 then goto player_sync_end end
      
      p.diff_x = d[1] + d[3] * delay - p.x
      p.diff_y = d[2] + d[4] * delay - p.y
      
      --p.x      = d[1]
      --p.y      = d[2]
      --p.vx     = d[3]
      --p.vy     = d[4]
      p.cur_x  = d[5]
      p.cur_y  = d[6]
	  
      if not p.puking then
	      if #d[9] > #p.eaten then
	        for i = #p.eaten + 1, #d[9] do
            local od = d[9][i]
            local o
            if od[2] then
              o = pastries[od[1]]
            else
              o = players[-od[1]]
            end
            
            if o then
              player_eats(p, o)
            else
              add(p.eaten, {
                id = od[1],
                type = od[2],
                colors = od[3]
              })
              --p.eating = 0.5
            end
          end
        elseif #d[9] < #p.eaten and #d[9] <= 1 then
          p.eaten = {}
	      end
      end
      
      p.score  = d[11]
      p.eating = d[8]
      p.radius = d[7]
      
      if not p.name then
        p.name = d[12]
        load_user_pic(p, d[13])
      end
      
      p.reset = d[14]
      
      ::player_sync_end::
    end
  end

  if diff[3] then
    for id,_ in pairs(diff[3]) do
      local d = c_read[3][id]
      local p = pastries[id]
      
      if not p then
        if not d or dead_pastries[id] or #d < 5 then
          goto pastry_sync_end
        end
        
        p = create_pastry(id, d[1], d[2], d[4], d[5])
        
      elseif not d then
        deregister_object(p)
        pastries[id] = nil
        log("Removed pastry #"..id..".")
        goto pastry_sync_end
      end
      
      p.diff_x = d[1] - p.x
      p.diff_y = d[2] - p.y
      p.radius = d[3]
      
      ::pastry_sync_end::
    end
  end

  if diff[4] then
    if c_read[4] > reset_id then
      my_player.reset = false
      my_player.score = 0
      my_player.radius = 7
      my_player.invinc = 2
      my_player.eaten = {}

      reset_id = c_read[4]
      
      sfx("reset")
    end
  end
  
  reset_countdown = c_read[5] - delay
end

function client_output()
  c_write = client.home

  c_write[1] = t() -- set timestamp

  if my_player then
    c_write[2] = my_player.x
    c_write[3] = my_player.y
    c_write[4] = my_player.vx
    c_write[5] = my_player.vy
    c_write[6] = my_player.cur_x
    c_write[7] = my_player.cur_y
	  c_write[8] = my_player.eating
    
    if not c_write[9] then
      c_write[9] = {}
    end
	  
    if not my_player.puking then
	    if #my_player.eaten < #c_write[9] then
	      c_write[9] = {}
	      for i,o in pairs(my_player.eaten) do
	        c_write[9][i] = {o.id, o.type, o.colors}
	      end
      else
        for i = #c_write[9]+1, #my_player.eaten do
          local o = my_player.eaten[i]
	        c_write[9][i] = {o.id, o.type, o.colors}
        end
	    end
    end
    
    c_write[10] = my_player.puking
    
    if not my_player.name and castle and castle.user.isLoggedIn then
      local info = castle.user.getMe()
      c_write[11] = info.name or info.username
      c_write[12] = info.photoUrl
      
      my_player.name = c_write[11]
      load_user_pic(my_player, c_write[12])
    end
    
    c_write[13] = my_player.reset
  end
end

function client_connect()
  log("Connected to server!")
  
  sfx("connected")
  
  c_read = client.share
  c_write = client.home
  my_id = client.id
  
  my_player.id = my_id
  players[my_id] = my_player
end

function client_disconnect()
  log("Disconnected from server!")
  disconnected = true
end


local player_colors = {2, 3, 4, 5, 6, 7, 8}
function server_input(id, diff)
  local sc_read = s_read[id]

  if sc_read[2] then
    local player = players[id]
    if not player then
      local n = irnd(#player_colors)+1
      player = create_player(id, sc_read[2], sc_read[3], player_colors[n])
      del_at(player_colors, n)
    end
    
    player.x = sc_read[2]
    player.y = sc_read[3]
    player.vx = sc_read[4]
    player.vy = sc_read[5]
    player.cur_x = sc_read[6]
    player.cur_y = sc_read[7]
    
    player.eating = sc_read[8]
    
	  if sc_read[8] > 0 and #sc_read[9] > #player.eaten and not sc_read[10] then
	    for i = #player.eaten + 1, #sc_read[9] do
        local od = sc_read[9][i]
        local o
        if od[2] then
          o = pastries[od[1]]
        else
          o = players[-od[1]]
        end
        
        if o then
          player_eats(player, o)
        elseif not dead_pastries[od[1]] then
          add(player.eaten, {
            id = od[1],
            type = od[2],
            colors = od[3]
          })
          player.eating = 0.5
          player.radius = player.radius + 1
        end
      end
	  end
    
    player.name  = sc_read[11]
    player.pic   = sc_read[12]
    player.reset = sc_read[13]
  end
end

function server_output()
  for id,ho in pairs(server.homes) do
    s_write[1][id] = ho[1] -- share everyone's timestamps
  end
  
  for id,p in pairs(players) do
    local d = s_write[2][id]
    if not d then
      d = {[9]={}}
      s_write[2][id] = d
    end
    
    d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8] = p.x, p.y, p.vx, p.vy, p.cur_x, p.cur_y, p.radius, p.eating
    
    if not p.puking then
      if #p.eaten < #d[9] then
	      d[9] = {}
	      for i,o in pairs(p.eaten) do
	        d[9][i] = {o.id, o.type, o.colors}
	      end
      else
        for i = #d[9]+1, #p.eaten do
          local o = p.eaten[i]
	        d[9][i] = {o.id, o.type, o.colors}
        end
	    end
    end
    
    d[10] = p.color
    d[11] = p.score
    
    d[12] = p.name
    d[13] = p.pic
    d[14] = p.reset
  end
  
  for id,p in pairs(pastries) do
    s_write[3][id] = {
      p.x,     p.y,
      --p.vx,    p.vy,
      p.radius,
      p.type,  p.colors
    }
  end
  
  s_write[4] = reset_id
  s_write[5] = reset_countdown
end

function server_new_client(id)
  log("New client: #"..id)
end

function server_lost_client(id)
  log("Client #"..id.." disconnected.")
  
  local player = players[id]
  if player then
    deregister_object(player)
    s_write[2][id] = nil
    players[id] = nil
    
    add(player_colors, player.color)
  end
end



-- look-up table

-- client.home = {
--   [1] = timestamp
-- }


-- server.share = {
--   [1] = {
--     [user_id] = timestamp,
--     ...
--   }
-- }



function start_client()
  client = cs.client
  
  if castle then
    client.useCastleConfig()
  else
    start_client = function()
      client.enabled = true
      client.start('127.0.0.1:22122') -- IP address ('127.0.0.1' is same computer) and port of server
      
      love.update, love.draw = client.update, client.draw
      client.load()
      
      ROLE = client
    end
  end
  
  client.changed = client_input
  client.connect = client_connect
  client.disconnect = client_disconnect
end

function start_server(max_clients)
  server = cs.server
  server.maxClients = max_clients
  
  if castle then
    server.useCastleConfig()
  else
    start_server = function()
      server.enabled = true
      server.start('22122') -- Port of server
      
      love.update = server.update
      server.load()
      
      ROLE = server
    end
  end
  
  server.changed = server_input
  server.connect = server_new_client
  server.disconnect = server_lost_client
end