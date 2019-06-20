
require("sugarcoat/sugarcoat")
sugar.utility.using_package(sugar.S, true)

local color_ramps = {}
local no_outline = nil

function love.load()
  init_sugar("Cakes!", 128, 128, 5)
  
  local palette = {  -- Lux3K!
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
  }
  
  for i = 1,256 do
    palette[i] = palette[i] or 0
  end
  
  use_palette(palette)
  
  load_png("sheet", "assets/sheet.png", nil, true)
  load_png("layers", "assets/layers.png", nil, true)
  
  define_controls()
  
  spritesheet_grid(16, 16)
  
  load_colorramps()
  load_voxels()
  
  no_outline = new_surface(screen_w(), screen_h())
  
--  palt(37, true)
  palt(0, false)
end

local a1,a2 = 0,0
function love.update()
  if btnp(2) then
    surfshot(nil, 3, "week164.png")
  end
  
  a1 = lerp(a1, btnv(1)/16, 2*dt())
  a2 = lerp(a2, btnv(0)/16, 2*dt())
end

function love.draw()
--  for i = 1,100 do
    _draw()
--  end
  
  camera()
  
  pal()
  print(fps(), 0, -4, 9)
end

function _draw()
  palt(0, false)
  cls(17)
  
  target(no_outline)
  cls(23)
  
  for y = 0,8 do
    for x = 0,7 do
      draw_voxels((x+y)%2+6,
        x*16+8,
        y*16+8 + 3.5*cos(x/8 + 0.3*t()),
        t()*0.4 + y*0.05, --a1,--
        -t()*0.5 + x*0.05 + y*0.05,
        -t()*0.2 + x*0.05, --a2,--
        flr((x+y))%7+5, 2, 1, 0)
    end
  end
  
  target()
  
  for i = 0, 37 do
    pal(i, 16)
  end
  palt(23, true)
  
  spr_sheet(no_outline, -1, 0)
  spr_sheet(no_outline, 1, 0)
  spr_sheet(no_outline, 0, -1)
  spr_sheet(no_outline, 0, 1)
  
  for i = 0, 37 do
    pal(i, i)
  end
  
  spr_sheet(no_outline, 0, 0)
  
  palt(23, false)

--  draw_voxels(0,
--    24,
--    24,
--    t()*0.2,
--    a1,
--    a2,
--    6, 2, 1, 0)
end


local voxel_data = {}
function draw_voxels(s, x, y, a0, a1, a2, c0, c1, c2, c3)
  local coa, sia, cob, sib, coc, sic =
    cos(a0), sin(a0),
    cos(a1), sin(a1),
    cos(a2), sin(a2)
  
--  local coa, sia = cos(a0), sin(a0)
--  local cob, sib = cos(a1), sin(a1)
--  local coc, sic = cos(a2), sin(a2)

  local dx_x, dx_y, dx_z, dy_x, dy_y, dy_z, dz_x, dz_y, dz_z =
    -sia * sib * sic + coa * coc,
    sia * cob,
    -sia * sib * coc - coa * sic,
    -coa * sib * sic + -sia * coc,
    coa * cob,
    -coa * sib * coc - -sia * sic,
    cob * sic,
    sib,
    cob * coc

--  local dx_x = -sia * sib * sic + coa * coc
--  local dx_y = sia * cob
--  local dx_z = -sia * sib * coc - coa * sic
--  
--  local dy_x = -coa * sib * sic + -sia * coc
--  local dy_y = coa * cob
--  local dy_z = -coa * sib * coc - -sia * sic
--  
--  local dz_x = cob * sic
--  local dz_y = sib
--  local dz_z = cob * coc
  
  
  local liti = {
    [4]   = -dz_y,
    [8]   =  dz_y,
    [16]  = -dy_y,
    [32]  =  dy_y,
    [64]  = -dx_y,
    [128] =  dx_y
  }
  
  local colors = {[0] = c0, c1, c2, c3}
  
  for i = 0, 3 do
    local ramp = color_ramps[colors[i]]
    
    pal(i, ramp[50])
    
    local na = 4
    while na < 206 do
      local v = liti[na]
      local n = na + i
      
      pal(n, ramp[flr(50 - v * 25)])
    
      local nb = 4
      while nb < na do
        local v = v+liti[nb]
        local n = n + nb
        pal(n, ramp[flr(50 - v * 25)])
        
        local nc = 4
        while nc < nb do
          local v = v+liti[nc]
          local n = n + nc
          pal(n, ramp[flr(50 - v * 25)])
          
          local nd = 4
          while nd < nc do
            local v = v+liti[nd]
            local n = n + nd
            pal(n, ramp[flr(50 - v * 25)])
          
            local ne = 4
            while ne < nd do
              local v = v+liti[ne]
              local n = n + ne
              pal(n, ramp[flr(50 - v * 25)])
            
              ne = ne*2
            end
            
            nd = nd*2
          end
          
          nc = nc*2
        end
        
        nb = nb*2
      end
    
      na = na*2
    end
  end
  
  
  local z_a, z_b, z_c
  if dz_z > 0 then
    z_a, z_b, z_c = -7.5, 7.5, 1
  else
    z_a, z_b, z_c = 7.5, -7.5, -1
  end
  
  local y_a, y_b, y_c
  if dy_z > 0 then
    y_a, y_b, y_c = -7.5, 7.5, 1
  else
    y_a, y_b, y_c = 7.5, -7.5, -1
  end
  
  local x_a, x_b, x_c
  if dx_z > 0 then
    x_a, x_b, x_c = -7.5, 7.5, 1
  else
    x_a, x_b, x_c = 7.5, -7.5, -1
  end
  
  
  camera_move(-x, -y)
  
  buffer = {}
  local data = voxel_data[s]
  for zz = z_a, z_b, z_c do
    local layer = data[zz + 7.5]
    
    if layer then
      local zzx, zzy = zz*dz_x, zz*dz_y
    
      for yy = y_a, y_b, y_c do
        local line = layer[yy + 7.5]
        
        if line then
          local yyx, yyy = yy * dy_x + zzx, yy * dy_y + zzy
          
          for xx = x_a, x_b, x_c do
            local v = line[xx + 7.5]
            
            if v then
              local x, y = 0.8*(xx*dx_x + yyx), 0.8*(xx*dx_y + yyy)
              
              if not buffer[flr(y+8)*16 + flr(x+8)] then
            
                pset(x, y, v)
                
                buffer[flr(y+8)*16 + flr(x+8)] = true
              end
              --pset(x, y, v)
              --rectfill(1.5*x, 1.5*y, 1.5*x+1, 1.5*y+1, v)
            end
            
          end
        end
        
      end
    end
    
  end
  
  camera_move(x, y)
end

function load_voxels()
  local v_table = {
    [31] = 0,
    [1]  = 1,
    [9]  = 2,
    [16] = 3
  }

  spritesheet("layers")

  local s = 0
  while s do
    local data, zn = {}
    
    for z = 0, 15 do
      local layer, yn = {}
      
      for y = 0, 15 do
        local line, xn = {}
        for x = 0,15 do
          local v = v_table[sget(z*16 + x, s*16 + y)]
          line[x] = v
          xn = xn or v
        end
        
        if xn then
          layer[y], yn = line, true
        end
      end
      
      if yn then
        data[z], zn = layer, true
      end
    end
    
    if zn then
      voxel_data[s] = data
    end
    s = zn and (s+1)
  end
  
  for s,data in pairs(voxel_data) do
    local n_data = {}
    for z,layer in pairs(data) do
      local n_layer = {}
      for y,line in pairs(layer) do
        local n_line = {}
        for x,v in pairs(line) do
          local sides = {
            [-1]={ [-1]={}, [0]={}, [1]={}},
            [0] ={ [-1]={}, [0]={}, [1]={}},
            [1] ={ [-1]={}, [0]={}, [1]={}}
          }
          
          local _layer = data[z-1]
          if _layer then
            local _line = _layer[y-1]
            if _line then
              sides[-1][-1] =
                { [0] = _line[x] }
            end
            
            local _line = _layer[y]
            if _line then
              sides[-1][0] =
                { [-1] = _line[x-1],
                  [0]  = _line[x],
                  [1]  = _line[x+1] }
            end
            
            local _line = _layer[y+1]
            if _line then
              sides[-1][1] =
                { [0] = _line[x] }
            end
          end
          
          local _layer = data[z]
          if _layer then
            local _line = _layer[y-1]
            if _line then
              sides[0][-1] =
                { [-1] = _line[x-1],
                  [0]  = _line[x],
                  [1]  = _line[x+1] }
            end
            
            local _line = _layer[y]
            if _line then
              sides[0][0] =
                { [-1] = _line[x-1],
                  [1]  = _line[x+1] }
            end
            
            local _line = _layer[y+1]
            if _line then
              sides[0][1] =
                { [-1] = _line[x-1],
                  [0]  = _line[x],
                  [1]  = _line[x+1] }
            end
          end
          
          local _layer = data[z+1]
          if _layer then
            local _line = _layer[y-1]
            if _line then
              sides[1][-1] =
                { [0] = _line[x] }
            end
            
            local _line = _layer[y]
            if _line then
              sides[1][0] =
                { [-1] = _line[x-1],
                  [0]  = _line[x],
                  [1]  = _line[x+1] }
            end
            
            local _line = _layer[y+1]
            if _line then
              sides[1][1] =
                { [0] = _line[x] }
            end
          end
          
          local n = 0
          for _,z in pairs(sides) do
            for _,y in pairs(z) do
              for _,x in pairs(y) do
                n = n + 1
              end
            end
          end

          if n < 18 then
            --n_line[x] = line[x]
            
            local v = line[x] +
              (not sides[-1][ 0][ 0]  and 4   or 0) +
              (not sides[ 1][ 0][ 0]  and 8   or 0) +
              (not sides[ 0][-1][ 0]  and 16  or 0) +
              (not sides[ 0][ 1][ 0]  and 32  or 0) +
              (not sides[ 0][ 0][-1]  and 64  or 0) +
              (not sides[ 0][ 0][ 1]  and 128 or 0)
            
            n_line[x] = v
          end
        end
        n_layer[y] = n_line
      end
      n_data[z] = n_layer
    end
    
    voxel_data[s] = n_data
  end
end

function load_colorramps()
  spritesheet("sheet")
  
  color_ramps = {}
  
  local x = 0
  local i = 0
  while sget(x, 1) ~= 37 do
    local ramp = {}
    
    for y = 1,9 do
      ramp[y] = sget(x, y)
    end
    
    color_ramps[i] = ramp
    i = i + 1
    x = x + 3
  end
  
  for i = 0,#color_ramps do
    local ramp = color_ramps[i]
    local nramp = {}
    for j = 0,100 do
      local jv = (j-50)/50
      local cv = (jv*jv*jv)*7+6
      
      nramp[j] = ramp[mid(flr(cv), 1, 9)]
    end
    
    color_ramps[i] = nramp
  end
end


function define_controls()
  player_assign_ctrlr(0, 0)

  register_btn(0, 0, input_id("mouse_position", "x"))
  register_btn(1, 0, input_id("mouse_position", "y"))
  register_btn(2, 0, input_id("mouse_button", "lb"))
end



function _o_draw()
  cls(16)
  
  local x = 16
  local y = 16
  
  local h = 10
  
  local a = 0--t()*0.25
  local co = cos(a)
  local si = sin(a)
  
  x = x + co*h*0.5
  y = y + si*h*0.5
  
  local a2 = t()*0.25
  local co2 = cos(a2)
  local si2 = sin(a2)
  
--  for i = 0, h do
--    aspr(i, x-i*co*co2, y-i*si*si2, a+t()*0.25, 1, 1, 0.5, 0.5, 1, si2)
--    --aspr(i, x, y-i, t()*0.25, 1, 1, 0.5, 0.5, 1, 0.5)
--  end
  
  local _a,_b,_c
  if si2 < 0 then
    _a, _b, _c = h, 0, -1
  else
    _a, _b, _c = 0, h, 1
  end
  
  local scale_y
  if abs(si2) < 3/16 then
    scale_y = 3/16
  else
    scale_y = si2
  end
  
  for i = _a, _b, _c do
    aspr(i, x, y-i*co2, 0, 1, 1, 0.5, 0.5, 1, scale_y)
    --aspr(i, x, y-i, t()*0.25, 1, 1, 0.5, 0.5, 1, 0.5)
  end
end

do
--  dx_x = coa
--  dx_y = sia
--  dx_z = 0
--  
--  dy_x = -sia
--  dy_y = coa
--  dy_z = 0
--  
--  dz_x = 0
--  dz_y = 0
--  dz_z = 1
--  
--  
--  dx_x = dx_x
--  dx_y = dx_z * sib + dx_y * cob
--  dx_z = dx_z * cob - dx_y * sib
--  
--  dy_x = dy_x
--  dy_y = dy_z * sib + dy_y * cob
--  dy_z = dy_z * cob - dy_y * sib
--  
--  dz_x = dz_x
--  dz_y = dz_z * sib + sz_y * cob
--  dz_z = dz_z * cob - dz_y * sib
--  
--  
--  dx_x = coa
--  dx_y = 0 * sib + sia * cob
--  dx_z = 0 * cob - sia * sib
--  
--  dy_x = -sia
--  dy_y = 0 * sib + coa * cob
--  dy_z = 0 * cob - coa * sib
--  
--  dz_x = 0
--  dz_y = 1 * sib + 0 * cob
--  dz_z = 1 * cob - 0 * sib
  

--  dx_x =  coa
--  dx_y =  sia * cob
--  dx_z = -sia * sib
--  
--  dy_x = -sia
--  dy_y =  coa * cob
--  dy_z = -coa * sib
--  
--  dz_x = 0
--  dz_y = sib
--  dz_z = cob
  
  
--  dx_x = dx_z * sic + dx_x * coc
--  dx_y = dx_y
--  dx_z = dx_z * coc - dx_x * sic
--  
--  dy_x = dy_z * sic + dy_x * coc
--  dy_y = dy_y
--  dy_z = dy_z * coc - dy_x * sic
--  
--  dz_x = dz_z * sic + dz_x * coc
--  dz_y = dz_y
--  dz_z = dz_z * coc - dz_x * sic


--  dx_x = -sia * sib * sic + coa * coc
--  dx_y = sia * cob
--  dx_z = -sia * sib * coc - coa * sic
--  
--  dy_x = -coa * sib * sic + -sia * coc
--  dy_y = coa * cob
--  dy_z = -coa * sib * coc - -sia * sic
--  
--  dz_x = cob * sic
--  dz_y = sib
--  dz_z = cob * coc
end