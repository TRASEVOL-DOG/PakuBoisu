
require("object")
require("voxel")

GAME_W = 192-16
GAME_H = 128-24
GAME_X = 8
GAME_Y = 0

MAX_RADIUS = 32
RADIUS_STEP = 0.5

gear_x = 192-18 
gear_y = 2
gear_hover = false

PASTRY_MAX = 16

players = {}
player_id = 0
my_player = nil

pastries = {}
dead_pastries = {}
pastry_id = 0

reset_id = 0
reset_countdown = 5.999

voxel_surf = nil

local shkx, shky, shkp = 0, 0, 100

function _init()
  if not IS_SERVER then
    init_voxels()
    load_drk()
    voxel_surf = new_surface(GAME_W, GAME_H)
  else
    load_rampmaps()
  end
  

  init_object_mgr(
    "players",
    "pastries",
    "solids",
    "eatables"
  )

  init_network()
 

  if not IS_SERVER then
    load_settings()
    my_player = create_player(nil, 64, 64)
    
    add_log("You joined the game! Welcome!")
  end
end

local pastry_spawn_t = 0.5
function _update()
  update_shake()
  update_objects()
  update_playerui()
  update_logs()
  
  if IS_SERVER then
    if group_size("pastries") < PASTRY_MAX then
      pastry_spawn_t = pastry_spawn_t - dt()
      if pastry_spawn_t <= 0 then
        create_pastry(nil, (0.25+rnd(0.5))*GAME_W, -8)
      
        pastry_spawn_t = 0.5
      end
    end
  end
  
  local n,m = 0, 0
  for _,p in pairs(players) do
    m = m + 1

    if p.reset then
      n = n + 1
    end
  end
  
  if n == m and m > 0 then
    reset_countdown = reset_countdown - dt()
    
    if IS_SERVER and reset_countdown <= 0 then
      reset_id = reset_id + 1
      
      for p in group("players") do
        p.reset = false
        p.score = 0
        p.radius = 7
        p.invic = 2
        p.eaten = {}
      end
    end
  else
    reset_countdown = 5.999
  end
  
  update_network()
  
  if not IS_SERVER then
    local mx, my = btnv(0), btnv(1)
    if mx >= gear_x and mx < gear_x+16 and my >= gear_y and my < gear_y+16 then
      gear_hover = true
      
      if btnr(2) then
        -- toggle settings panel
        
        castle.uiupdate = not castle.uiupdate and settings_panel
      end
    else
      gear_hover = false
    end
  end
end

function _draw()
  palt(0, false)
  cls(17)
  
  camera(-GAME_X, -GAME_Y)
  apply_shake()
  
  local par_x
  local par_y
  if do_parallax then
    par_x = round((my_player.x - GAME_W/2) / 4)
    par_y = round((my_player.y - GAME_H) / 16)
  else
    par_x = 0
    par_y = 0
  end
  
  clip(-6, -6, GAME_W+12, GAME_H+12)
  color(1)
  rectfill(-6, -6, GAME_W+6, GAME_H+6, 9)
  for y = -32, GAME_H+32, 6 do
    for x = -33, GAME_W+32, 20 do
      spr(24 + (y/6)%3, x + (y/6)%2 * 10 - par_x, y - par_y)
    end
  end
  clip()
  
  draw_logs()
  
--  rectfill(0, 0, GAME_W-1, GAME_H-1, 16)
  
  target(voxel_surf)
  camera()
  cls(64)
  draw_objects()
  
  target()
  
  if my_player and do_parallax then
    camera(-round((my_player.x - GAME_W/2) / 16) -GAME_X, -round((my_player.y - GAME_H) / 16) -GAME_Y)
  else
    camera(-GAME_X, -GAME_Y)
  end
  apply_shake()
  
  palt(64, true)
  for i = 0, 37 do pal(i, 19) end
  spr_sheet(voxel_surf, -1, 0)
  spr_sheet(voxel_surf, 1, 0)
  spr_sheet(voxel_surf, 0, -1)
  spr_sheet(voxel_surf, 0, 1)
  
  spr_sheet(voxel_surf, -1, 1)
  spr_sheet(voxel_surf, 1, 1)
  spr_sheet(voxel_surf, 0, 2)
  
  for i = 0, 37 do pal(i, i) end
  spr_sheet(voxel_surf, 0, 0)
  
  if my_player and do_parallax then
    camera(-round((my_player.x - GAME_W/2) / 16), -round((my_player.y - GAME_H) / 16))
  else
    camera()
  end
  apply_shake()
  
  rectfill(-8, -8, GAME_X-1, GAME_H+8, 17)
  rectfill(GAME_X+GAME_W, -8, GAME_X+GAME_W+16, GAME_H+8, 17)
  rectfill(0, GAME_Y+GAME_H, GAME_X+GAME_W, GAME_Y+GAME_H+16, 17)
  
  for x = GAME_X, GAME_X+GAME_W, 8 do
    spr(8, x, GAME_Y-8)
    spr(9, x, GAME_Y+GAME_H)
  end
  
  for y = GAME_Y, GAME_Y+GAME_H, 8 do
    spr(10, GAME_X-8, y)
    spr(11, GAME_X+GAME_W, y)
  end
  
  spr(12, GAME_X-8, GAME_Y-8)
  spr(13, GAME_X+GAME_W, GAME_Y-8)
  spr(14, GAME_X-8, GAME_Y+GAME_H)
  spr(15, GAME_X+GAME_W, GAME_Y+GAME_H)

  camera()
  apply_shake()
  
  palt(37, true)
  
  local s = 32 + ( (castle and castle.uiupdate and 3 or 0)
                 + (gear_hover and (btn(2) and 2 or 1) or 0))*2
  spr(s, gear_x, gear_y + (gear_hover and btn(2) and 2 or 0), 2, 2)
  
  draw_playerui()
  draw_connection()
  
  
  if btn(2) then
    spr(7, btnv(0), btnv(1), 1, 2)
  else
    spr(6, btnv(0), btnv(1), 1, 2)
  end
  palt(37, false)
  
end


-- updates

function update_player(s)
  s.animt = s.animt + dt()

  if s.id == my_id and not s.puking then
    s.cur_x = btnv(0)
    s.cur_y = btnv(1)
	
	  if s.eating <= 0 then
      local cd = dist(s.x, s.y, s.cur_x, s.cur_y)
      local x = s.x + s.radius * 0.5 * (s.cur_x-s.x)/cd
      local y = s.y + s.radius * 0.5 * (s.cur_y-s.y)/cd
    
	    for o in group("eatables") do
        if o ~= s and o.type or (s.radius > o.radius and not o.puking and o.invinc <= 0) then
	        local d = sqr(x-o.x) + sqr(y-o.y)
	        
	        if d < sqr(s.radius + 0.6*o.radius) then
	          player_eats(s, o)
	    	    break
	        end
        end
	    end
	  end
  end
  
  if s.puking then
    s.cur_x = lerp(s.cur_x, s.x, 8*dt())
    s.cur_y = lerp(s.cur_y, s.y - 8, 8*dt())
    
    if s.animt >= 0.5 then
      s.animt = s.animt - 0.1
      
      -- puke one item
      local o_d = s.eaten[#s.eaten]
      
      if not o_d.type then -- is player
        local o = players[-o_d.id]
      
        if o then
          o.being_eaten = false
          
          local a = -0.2 - rnd(0.1)
          o.x  = s.x + 0.5 * s.radius * cos(a)
          o.y  = s.y + 0.5 * s.radius * sin(a)
          o.vx = 64 * cos(a)
          o.vy = 64 * sin(a)
          
          o.invinc = 2
          
          if not o.__registered then
            register_object(o)
          end
        end
      elseif not IS_SERVER then
        local o = create_puked_pastry(o_d.type, o_d.colors)
        
        local a = -0.2 - rnd(0.1)
        o.x  = s.x + 0.5 * s.radius * cos(a)
        o.y  = s.y + 0.5 * s.radius * sin(a)
        o.vx = 128 * cos(a)
        o.vy = 128 * sin(a)
      end
      
      s.radius = s.radius - RADIUS_STEP
      s.eaten[#s.eaten] = nil
      
      if #s.eaten == 0 then
        -- not puking anymore!
        s.puking = false
        s.radius = 7
        s.invinc = 2
      end
    end
  end
  
  if s.eating > 0 then
    s.eating = s.eating - dt()

    if s.eating <= 0 and #s.eaten > 0 and s.eaten[#s.eaten].id < 0 then
      -- spit it all out!
    
      s.puking = true
      s.animt = 0
    end
  end
  
  if s.invinc > 0 then
    s.invinc = s.invinc - dt()
  end
  
  if s.diff_x then
    local dx = sgn(s.diff_x) * min(abs(s.diff_x), (10 + abs(s.diff_x)/8) * dt())
    local dy = sgn(s.diff_y) * min(abs(s.diff_y), (10 + abs(s.diff_y)/8) * dt())
    
    s.x = s.x + dx
    s.y = s.y + dy
    
    s.diff_x = s.diff_x - dx
    s.diff_y = s.diff_y - dy
  end
  
  if not s.puking then
    update_movement(s)
  end
end

function player_eats(s, o)
  local d = {
    id     = o.id,
	  type   = o.type,
	  colors = o.colors
  }
  
  if not o.type then -- is player
    d.id = -d.id
    d.colors = d.color
    o.being_eaten = true
    log("Player #"..(s.id or "ME").." ate player #"..o.id.."!")
    s.score = s.score + 1
    s.eating = 0.5
    
    add_log((s.name or "Somebody").." ate "..(o.name or "someone else").."!!")
    
    create_crumbs(o.x, o.y, 3, 31, o.color or 1)
    if o.id == my_id then
      add_shake(12)
    else
      add_shake(4)
    end
  else
    log("Player #"..(s.id or "ME").." ate pastry #"..o.id.."!")
    pastries[o.id] = nil
    dead_pastries[o.id] = true
    s.eating = 0.5
    
    create_crumbs(o.x, o.y, 3, o.type, o.colors)
    if s.id == my_id then
      add_shake(1)
    end
  end

  add(s.eaten, d)
  
  if s.radius < MAX_RADIUS then
    s.radius = s.radius + RADIUS_STEP
    if s.radius >= MAX_RADIUS then
      add_log((s.name or "This Boi").." reached their maximum size!!")
    end
  end
  
  deregister_object(o)
end

function update_pastry(s)
  s.animt = s.animt + dt()

  if s.diff_x then
    local dx = sgn(s.diff_x) * min(abs(s.diff_x), (10 + abs(s.diff_x)/8) * dt())
    local dy = sgn(s.diff_y) * min(abs(s.diff_y), (10 + abs(s.diff_y)/8) * dt())
    
    s.x = s.x + dx
    s.y = s.y + dy
    
    s.diff_x = s.diff_x - dx
    s.diff_y = s.diff_y - dy
  end

  if s.puked then
    if s.x - s.radius <= 0 then
      s.x = s.radius
      s.vx = abs(s.vx)
    end
    
    if s.x + s.radius >= GAME_W then
      s.x = GAME_W - s.radius
      s.vx = -abs(s.vx)
    end
    
    s.x = s.x + s.vx * dt()
    s.y = s.y + s.vy * dt()
    
    if s.y < -s.radius - 2 then
      deregister_object(s)
    end
  else
    update_movement(s)
  end
end

function update_movement(s)
  local col_a, col_k, col_o = {}, {}, {}
  
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
    
    s.vy = s.vy - 32
  end
  
  for o in group("solids") do
    if s ~= o then
      -- check for collision with o
      
      local sd = sqrdist(o.x - s.x, o.y - s.y)
      if sd < sqr(o.radius + s.radius) then
        add(col_a, atan2(o.x - s.x, o.y - s.y))
        add(col_k, 1)
        add(col_o, o)
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
  
  local grounded, ground_a
  if k > 0 then
    grounded = true
    
    if abs(a0) < abs(a1) then
      ground_a = a0
    else
      ground_a = a1+0.5
    end
  else
    grounded = false
  end
  
  
  if grounded then
    local jump = s.mass/2
    s.vx = 0.5 * s.vx - jump * cos(ground_a)
    s.vy = 0.5 * s.vy - jump * sin(ground_a)
    
    for _,o in pairs(col_o) do
      local power = (s.mass + o.mass)/4
      local a = atan2(o.x - s.x, o.y - s.y)
      o.vx = 0.5 * o.vx + power * cos(a)
      o.vy = 0.5 * o.vy + power * sin(a)
    end
  end
  
  s.x = s.x + s.vx * dt()
  s.y = s.y + s.vy * dt()
  
  s.vy = min(s.vy + dt() * s.mass, s.mass * 2)
  
  if s.cur_x then
    s.vx = s.vx + dt() * 80 * sgn(s.cur_x - s.x)
  end
end

function update_crumb(s)
  s.x = s.x + s.vx * dt()
  s.y = s.y + s.vy * dt()
  
  if s.y >= GAME_H then
    s.y = GAME_H - 1
    s.vy = -s.vy
  end
  
  s.vy = s.vy + 100 * dt()
  
  if s.x <= 0 or s.x >= GAME_W then
    s.vx = -s.vx
  end
  
  s.a = s.a + s.va * dt()
  
  s.l = s.l - dt()
  if s.l <= 0 then
    deregister_object(s)
  end
end


local players_ui = {}
function update_playerui()
  for i = 2, #players_ui do
    if players_ui[i].s.score > players_ui[i-1].s.score then
      players_ui[i], players_ui[i-1] = players_ui[i-1], players_ui[i]
    end
  end

  for i,u in pairs(players_ui) do
    u.x = lerp(u.x, i*32-32, 3*dt())
  end
end

function add_playerui(s)
  if IS_SERVER then return end
  add(players_ui, {
    x = screen_w(), s = s
  })
end

function del_playerui(s)
  if IS_SERVER then return end
  for i,u in pairs(players_ui) do
    if u.s == s then
      del_at(players_ui, i)
      return
    end
  end
end

local bg_logs = {}
function update_logs()
  for i,l in pairs(bg_logs) do
    l.y = lerp(l.y, i*12-12, 3*dt())
  end
end

local bg_logs_i = 0
local bg_logs_ca = {14, 36, 23}
local bg_logs_cb = {15, 37, 11}
function add_log(str)
  if IS_SERVER then return end
  
  local ca, cb = bg_logs_ca[bg_logs_i % 3 + 1], bg_logs_cb[bg_logs_i % 3 + 1]
  bg_logs_i = bg_logs_i + 1
  
  local n = 23
  function cut(str, f)
    if #str > n then
      local s = str:sub(1, n)
      
      local k, m = s:find("%s"), n
      while k do
        m, k = k, s:find("%s", k+1)
      end
      
      str, s = str:sub(1, m), str:sub(m+1)
    
      cut(s, false)
    end
    
    table.insert(bg_logs, 1, {
      y = -16,
      str = str,
      pref = f and ">" or "  ",
      ca = ca,
      cb = cb
    })
  end
  
  cut(str, true)
  
  while #bg_logs > 9 do
    bg_logs[#bg_logs] = nil
  end
end


function add_shake(p)
  local a = rnd(1)
  shkx = shkx + p * cos(a)
  shky = shky + p * sin(a)
end

function update_shake()
  if abs(shkx)+abs(shky) < 0.5 then
    shkx, shky = 0, 0
  else
    shkx = -shkx * (0.5 + rnd(0.2))
    shky = -shky * (0.5 + rnd(0.2))
  end
end

function apply_shake()
  camera_move(shkp/100 * shkx, shkp/100 * shky)
end


-- draws

function draw_player(s)
--  if s.eating > 0 then
--    circfill(s.x, s.y, s.radius + 2, 9 + (s.id or 0))
--  else
--    circfill(s.x, s.y, s.radius, 9 + (s.id or 0))
--  end

--  circ(s.x, s.y, s.radius, 9)
  
  local v
  local dx,dy = 0,0
  if s.puking then
    v = 29
    dx,dy = rnd(3)-1.5, rnd(3)-1.5
  elseif s.eating > 0 then
    local anim = {30, 31, 30, 26, 27, 28, 29}
    v = anim[flr(-s.eating / 0.06) % #anim + 1]
  else
    local anim = {26, 26, 27, 28, 29, 29, 28, 27}
    v = anim[flr(s.animt / 0.06) % #anim + 1]
  end
  
  local aim = atan2(s.cur_x - s.x, s.cur_y - s.y)
  
  local color
  if (s.invinc > 0 and s.animt % 0.5 < 0.25) or not s.color then
    color = 1
  else
    color = s.color
  end
  
  --draw_voxels(v, s.x, s.y, s.radius/8, s.animt, -0.5*s.animt, aim, color)
  draw_voxels(v, s.x+dx, s.y+dy, s.radius/6, aim, 0.08*cos(s.animt), -cos(aim)*0.03+0.08*sin(s.animt), color)
  pal()
end

function draw_pastry(s)
--  circ(s.x, s.y, s.radius, 30)
  
  draw_voxels(s.type, s.x, s.y, s.radius/8, 0.5*s.animt, -0.25*s.animt, 0.33*s.animt, s.colors)
  pal()
end

function draw_crumb(s)
  if s.l < 0.5 and s.l % 0.1 > 0.05 then return end

  palt(37, true)
  pal(0, s.ramp[20])
  pal(1, s.ramp[50])
  pal(2, s.ramp[80])
  
  aspr(s.s, s.x, s.y, s.a)
  
  pal(0, 0)
  pal(1, 1)
  pal(2, 2)
  palt(37, false)
end

function draw_connection()
  if not client.connected then
    local str
    if castle and not castle.user.isLoggedIn then
      str = "Log-in to play!"
    elseif disconnected then
      str = "Disconnected :("
    else
      str = "Connecting"
      for i = 1,flr(t()/0.25)%4 do
        str = str.."."
      end
    end
    
    printp(0x0300, 0x3130, 0x0300, 0x0000)
    printp_color(19, 9, 9)
    local w = str_px_width(str)
    pprint(str, (screen_w() - w)/2, GAME_H/2 - 8)
  end
end

function draw_playerui()
  palt(0, false)
  palt(38, true)
  
  local max_score = 0
  for _,u in pairs(players_ui) do
    max_score = max(max_score, u.s.score)
  end

  local x = 1
  local y = screen_h() - 17
  for _,u in pairs(players_ui) do
    local x = x + round(u.x)
    
    local ramp = get_map_ramp(31, u.s.color or 1, 4)
    
    pal(1, ramp[50])
    pal(0, ramp[20])
    
    palt(37, true)
    
    if u.s.id == my_id then
      pal(19, 9)
      spr(68, x, y, 4, 2)
      pal(19, 19)
      spr(68, x, y-1, 4, 2)
    else
      spr(68, x, y, 4, 2)
    end
    
    pal(1, 1)
    pal(0, 0)
    
    local pic = u.s.pic
    if pic and surface_exists(pic) then
      palt(37, false)
      spr_sheet(u.s.pic, x+1, y - (u.s.id == my_id and 1 or 0), 16, 16)
    end

    printp(0x0300, 0x3130, 0x3230, 0x0300)
    printp_color(9, 19, ramp[20])
    
    local str = ""..u.s.score
    pprint(str, x+21 - str_px_width(str)/2, y-3)
    
    if u.s.score == max_score and max_score > 0 then
      palt(37, true)
      spr(100, x+1, y - 6 + 1.5 * cos(t() + x/128) - (u.s.id == my_id and 1 or 0), 2, 2)
    end
    
    if btnv(1) > y and btnv(0) > x and btnv(0) < x + 32 then
      printp(0x0300, 0x3130, 0x0300, 0x0)
      printp_color(9, 19, 19)
      
      local str = u.s.name or "Guest"
      local w = str_px_width(str)
      local x = mid(x + 16 - w/2, 1, screen_w()-1-w)
      pprint(str, x, y - 16)
    end
  end
  
  palt(12, false)
  palt(37, true)
end

function draw_logs()
  printp(0x3330, 0x3130, 0x3230, 0x3330)
  
  for i,l in ipairs(bg_logs) do
    printp_color(l.ca, l.cb, 9)
    pprint(l.pref..l.str, (l.pref == ">" and 0 or -4), l.y)
  end
end


-- creates

function create_player(id, x, y, color)
--  if not id then id,player_id = player_id,player_id+1 end

  local s = {
    id     = id,
    x      = x,
    y      = y,
    vx     = 0,
    vy     = 0,
    cur_x  = x,
    cur_y  = y,
    radius = 7,
    mass   = 100,
	  eating = 0,
	  eaten  = {},
    invinc = 2,
    animt  = 0,
    color  = color or 1,
    score  = 0,
    update = update_player,
    draw   = draw_player,
    regs   = {"to_update", "to_draw2", "players", "solids", "eatables"}
  }
  
  if id then
    players[id] = s
  end
  
  register_object(s)
  
  add_playerui(s)
  
  log("Created new player #"..(id or "me"))
  return s
end

function create_pastry(id, x, y, typ, colors)
  if not id then id,pastry_id = pastry_id,pastry_id+1 end

  local s = {
    id     = id,
    x      = x,
    y      = y,
    vx     = 0,
    vy     = 0,
    radius = 5+rnd(2),
    mass   = 20,
    animt  = rnd(1),
    update = update_pastry,
    draw   = draw_pastry,
    regs   = {"to_update", "to_draw1", "pastries", "eatables", "solids"}
  }
  
  if typ then
    s.type = typ
    s.colors = colors
  else
    s.type = irnd(16)
    s.colors = irnd(get_rampmap_count(s.type))+1
  end
  
  pastries[id] = s
  dead_pastries[id] = nil
  register_object(s)
  
  log("New pastry!")
  return s
end

function create_puked_pastry(typ, colors)
  local s = {
    x      = 0,
    y      = 0,
    vx     = 0,
    vy     = 0,
    radius = 4+rnd(3),
    mass   = 20,
    type   = typ,
    colors = colors,
    animt  = rnd(1),
    puked  = true,
    update = update_pastry,
    draw   = draw_pastry,
    regs   = {"to_update", "to_draw1"}
  }

  register_object(s)
  
  return s
end

function create_crumbs(x, y, n, p_typ, p_colors)
  if IS_SERVER then return end

  local cols = {}
  for i = 1,4 do
    local c = get_map_ramp(p_typ, p_colors, i)
    if c[50] ~= 17 then
      add(cols, c)
    end
  end
  
  for i = 1,n do
    local a = rnd(1)
    local spd = 10 + rnd(40)
  
    local s = {
      x      = x + give_or_take(2.5),
      y      = y + give_or_take(2.5),
      vx     = spd * cos(a),
      vy     = spd * sin(a) - 20,
      a      = rnd(1),
      va     = give_or_take(3),
      ramp   = pick(cols),
      s      = 28 + irnd(4),
      l      = 1 + rnd(0.5),
      update = update_crumb,
      draw   = draw_crumb,
      regs   = {"to_update", "to_draw2"}
    }
    
    register_object(s)
  end
end


-- misc

local ui = castle and castle.ui
function settings_panel()
  -- game title
  ui.markdown("*Trasevol_Dog presents...*")
  ui.image("assets/title.png")
  
  
  
  -- game description + controls
  ui.markdown([[
### Goal:
Eat food to get bigger, then eat other players that are smaller than you!

### Controls:
Use the cursor to direct your Pac-Boi!
]])
  
  -- Reset scores vote
  local n,m = 0, 0
  for _,p in pairs(players) do
    m = m + 1

    if p.reset then
      n = n + 1
    end
  end
  
  ui.markdown("### Reset scores:"..(n > 0 and (t() % 1 < 0.5 and " ( . )" or " ( ! )") or ""))
  ui.markdown(n.."/"..m.." want to reset"..(n > 0 and "!" or "."))
  my_player.reset = ui.toggle("No reset", "Let's reset!", my_player.reset or false)
  
  if n == m then
    ui.markdown("Reset in "..max(flr(reset_countdown), 0).."...")
  end
  
  -- settings
  ui.markdown([[&#160;
### Settings:]])
  
  -- setters:
  --  sfx volume
  --  music volume
  --  shake
  --  parallax
  --  shader
  
  local v = sfx_volume() * 100
  local nv = ui.slider("SFX Volume", v, 0, 100, { step = 1, minLabel = "%", maxLabel = "%" })
  if v ~= nv then
    sfx_volume(nv / 100)
    network.async(castle.storage.set, nil, "sfx_volume", nv)
  end
  
  local v = music_volume() * 100
  local nv = ui.slider("Music Volume", v, 0, 100, { step = 1, minLabel = "%", maxLabel = "%" })
  if v ~= nv then
    music_volume(nv / 100)
    network.async(castle.storage.set, nil, "music_volume", nv)
  end
  
  local v = shkp
  local nv = ui.slider("Screenshake", v, 0, 200, { step = 1, minLabel = "%", maxLabel = "%" })
  if v ~= nv then
    shkp = nv
    add_shake(2)
    network.async(castle.storage.set, nil, "shkp", shkp)
  end
  
  ui.toggle("Parallax OFF", "Parallax ON", do_parallax, { onToggle = function()
    do_parallax = not do_parallax
    network.async(castle.storage.set, nil, "do_parallax", do_parallax)
  end})
  
  ui.toggle("Shader OFF", "Shader ON", using_shader, { onToggle = function()
    switch_shader()
    network.async(castle.storage.set, nil, "using_shader", using_shader)
  end})
  
  
  -- credits
  ui.markdown([[&#160;
### Credits:
This game was made by [Trasevol_Dog](https://twitter.com/trasevol_dog), for Castle, using [Sugarcoat](https://github.com/TRASEVOL-DOG/sugarcoat) and [Share.lua](https://github.com/castle-games/share.lua).

**Thank you to the whole Castle team!**

**Thank you Elodie for all the pastry ideas!**

**Thank you to my supporters on [Patreon](https://www.patreon.com/trasevol_dog)!** Here are some:

***Joseph White***, ***Spaceling***, *rotatetranslate, Anne Le Clech, LadyLeia, bbsamurai, HJS, Paul Nguyen, Dan Lewis, Dan Rees-Jones, Reza Esmaili, Joel Jorgensen, Marty Kovach, Flo Devaux, Thomas Wright, HERVAN, berkfrei, Tim and Alexandra Swast, Jearl, Dan Fries, Michael Leonardi, Johnathan Roatch, Raphael Gaschignard, Eiyeron, Sam Loeschen, Andrew Reitano, amy, Andrea D'Amico, Simon Stålhandske, yunowadidis-musik, slono, Max Cahill, hushcoil, Gruber, Pierre B., Sean S. LeBlanc, Andrew Reist, Paul Nicholas, vaporstack, Jakub Wasilewski*

**Special thanks to my cats and also Eliott!**

**And thank *you* for playing!** *:D*
]])
end
if castle then
  castle.uiupdate = false
end

function load_drk()
  c_drk = {}
  for i = 0,37 do
    c_drk[i] = sget(i, 13)
  end
end

function load_user_pic(s, url)
  if not url then return end

  network.async(function()
    local pic = load_png(nil, url, nil, false)
    local npic = new_surface(16,16)
    
    target(npic)
    spr_sheet(pic, 0, 0, 16, 16)
    
    delete_surface(pic)
    scan_surface(npic)
    
    for y = 0, 15 do
      for x = 0, 15 do
        local m = sget(64+x, 32+y)
        if m == 0 then
          pset(x, y, 38)
        elseif m == 1 then
          local c = pget(x, y)
          pset(x, y, c_drk[c])
        end
      end
    end
    target()
    
    s.pic = npic
  end)
end

function load_settings()
  if not castle then return end
  
  music_volume(castle.storage.get("music_volume") or 80)
  sfx_volume(castle.storage.get("sfx_volume") or 80)
  
  shkp = castle.storage.get("shkp") or 100
  
  do_parallax = not (castle.storage.get("do_parallax") == false)
  
  using_shader = (castle.storage.get("using_shader") == false)
  switch_shader()
end

function define_controls()
  player_assign_ctrlr(0, 0)

  register_btn(0, 0, input_id("mouse_position", "x"))
  register_btn(1, 0, input_id("mouse_position", "y"))
  register_btn(2, 0, input_id("mouse_button", "lb"))
end



function give_or_take(n)
  return rnd(n*2)-n
end