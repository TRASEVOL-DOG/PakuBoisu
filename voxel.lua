

local color_ramps = {}
local ramp_maps = {}
local voxel_data = {}

function init_voxels()
  load_voxels()
  load_colorramps()
  load_rampmaps()
end

function get_rampmap_count(s)
  return #ramp_maps[s]
end

function get_map_ramp(s, n, p)
  return color_ramps[ramp_maps[s][n][p]]
end

function draw_voxels(s, x, y, scale, a0, a1, a2, ramp_map_i)
  local coa, sia, cob, sib, coc, sic =
    cos(a0), sin(a0),
    cos(a1), sin(a1),
    cos(a2), sin(a2)

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
  
  local liti = {
    [4]   = -dz_y,
    [8]   =  dz_y,
    [16]  = -dy_y,
    [32]  =  dy_y,
    [64]  = -dx_y,
    [128] =  dx_y
  }
  
  local colors = ramp_maps[s][ramp_map_i]--{[0] = c0, c1, c2, c3}
  
  for i = 0, 3 do
    local ramp = color_ramps[colors[i+1]]
    
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
  
  local data = voxel_data[s]
  
  local hheight = #data/2
  local z_a, z_b, z_c
  if dz_z > 0 then
    z_a, z_b, z_c = -hheight, hheight, 1
  else
    z_a, z_b, z_c = hheight, -hheight, -1
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
  
  if scale > 0.8 then
    local _scale, scale = scale+0.5, scale
    camera_move(0.5*_scale, 0.5*_scale)
  
    for zz = z_a, z_b, z_c do
      local layer = data[zz + hheight]
      
      if layer then
        local zzx, zzy = zz*dz_x, zz*dz_y
      
        for yy = y_a, y_b, y_c do
          local line = layer[yy + 7.5]
          
          if line then
            local yyx, yyy = yy * dy_x + zzx, yy * dy_y + zzy
            
            for xx = x_a, x_b, x_c do
              local v = line[xx + 7.5]
              
              if v then
                --local x, y = 0.8*(xx*dx_x + yyx), 0.8*(xx*dx_y + yyy)
                local x, y = scale*(xx*dx_x + yyx), scale*(xx*dx_y + yyy)
                
                --if not buffer[flr(y+8)*16 + flr(x+8)] then
              
                  rectfill(x, y, x+_scale, y+_scale, v)
                  --pset(x, y, v)
                  
                --  buffer[flr(y+8)*16 + flr(x+8)] = true
                --end
                --pset(x, y, v)
              end
              
            end
          end
          
        end
      end
      
    end
    
    camera_move(-0.5*scale, -0.5*scale)
  else
    for zz = z_a, z_b, z_c do
      local layer = data[zz + hheight]
      
      if layer then
        local zzx, zzy = zz*dz_x, zz*dz_y
      
        for yy = y_a, y_b, y_c do
          local line = layer[yy + 7.5]
          
          if line then
            local yyx, yyy = yy * dy_x + zzx, yy * dy_y + zzy
            
            for xx = x_a, x_b, x_c do
              local v = line[xx + 7.5]
              
              if v then
                --local x, y = 0.8*(xx*dx_x + yyx), 0.8*(xx*dx_y + yyy)
                local x, y = scale*(xx*dx_x + yyx), scale*(xx*dx_y + yyy)
                
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
  end
  
  camera_move(x, y)
end

function load_voxels()
  local v_table = {
    [16] = 0,
    [9]  = 1,
    [1]  = 2,
    [31] = 3
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
  
  load_rampmaps()
end

function load_rampmaps()
  -- 0 : black
  -- 1 : white
  -- 2 : cream / light dough
  -- 3 : dough
  -- 4 : dark dough
  -- 5 : chocolate
  -- 6 : macha frosting
  -- 7 : blueberry frosting
  -- 8 : plum frosting
  -- 9 : raspberry frosting
  -- 10: strawberry frosting
  -- 11: orange frosting
  -- 12: banana frosting

  ramp_maps = {
[0]={ -- shortcake
      {0, 2, 3, 10},
      {0, 2, 3, 9}
    },
    { -- flan
      {5, 12, 3, 11}
    },
    { -- chocolate cake
      {5, 0, 0, 9},
      {5, 0, 0, 10},
      {5, 0, 0, 7}
    },
    { -- donut (no frosting)
      {0, 0, 2, 0},
      {0, 0, 3, 0},
      {0, 0, 4, 0}
    },
    { -- donut (w/ frosting)
      {0, 0, 3, 1},
      {0, 0, 3, 5},
      {0, 0, 3, 6},
      {0, 0, 3, 7},
      {0, 0, 3, 8},
      {0, 0, 3, 9},
      {0, 0, 3, 10},
      {0, 0, 3, 11},
      {0, 0, 3, 12},
      {0, 0, 2, 1},
      {0, 0, 2, 5},
      {0, 0, 2, 6},
      {0, 0, 2, 7},
      {0, 0, 2, 8},
      {0, 0, 2, 9},
      {0, 0, 2, 10},
      {0, 0, 2, 11},
      {0, 0, 2, 12},
      {0, 0, 4, 1},
      {0, 0, 4, 5},
      {0, 0, 4, 6},
      {0, 0, 4, 7},
      {0, 0, 4, 8},
      {0, 0, 4, 9},
      {0, 0, 4, 10},
      {0, 0, 4, 11},
      {0, 0, 4, 12}
    },
    { -- waffle
      {0, 0, 2, 0},
      {0, 0, 3, 0},
      {0, 0, 4, 0}
    },
    { -- dorayaki
      {0, 2, 3, 5}
    },
    { -- cupcake (mini-mashmallows)
      {0, 1, 3, 2},
      {0, 1, 3, 5},
      {0, 1, 3, 6},
      {0, 1, 3, 7},
      {0, 1, 3, 8},
      {0, 1, 3, 9},
      {0, 1, 3, 10},
      {0, 1, 3, 11},
      {0, 1, 3, 12},
      {0, 1, 2, 2},
      {0, 1, 2, 5},
      {0, 1, 2, 6},
      {0, 1, 2, 7},
      {0, 1, 2, 8},
      {0, 1, 2, 9},
      {0, 1, 2, 10},
      {0, 1, 2, 11},
      {0, 1, 2, 12},
      {0, 1, 4, 2},
      {0, 1, 4, 5},
      {0, 1, 4, 6},
      {0, 1, 4, 7},
      {0, 1, 4, 8},
      {0, 1, 4, 9},
      {0, 1, 4, 10},
      {0, 1, 4, 11},
      {0, 1, 4, 12}
    },
    { -- cupcake (twisty)
      {0, 2, 3, 1},
      {0, 2, 3, 5},
      {0, 2, 3, 6},
      {0, 2, 3, 7},
      {0, 2, 3, 8},
      {0, 2, 3, 9},
      {0, 2, 3, 10},
      {0, 2, 3, 11},
      {0, 2, 3, 12},
      {0, 2, 2, 1},
      {0, 2, 2, 5},
      {0, 2, 2, 6},
      {0, 2, 2, 7},
      {0, 2, 2, 8},
      {0, 2, 2, 9},
      {0, 2, 2, 10},
      {0, 2, 2, 11},
      {0, 2, 2, 12},
      {0, 2, 4, 1},
      {0, 2, 4, 5},
      {0, 2, 4, 6},
      {0, 2, 4, 7},
      {0, 2, 4, 8},
      {0, 2, 4, 9},
      {0, 2, 4, 10},
      {0, 2, 4, 11},
      {0, 2, 4, 12}
    },
    { -- croissant
      {0, 0, 3, 0},
      {0, 0, 4, 0}
    },
    { -- pain au chocolat
      {5, 0, 3, 0},
      {5, 0, 4, 0}
    },
    { -- macaron
      {0, 2, 0, 1},
      {0, 2, 0, 5},
      {0, 2, 0, 6},
      {0, 2, 0, 7},
      {0, 2, 0, 8},
      {0, 2, 0, 9},
      {0, 2, 0, 10},
      {0, 2, 0, 11},
      {0, 2, 0, 12}
    },
    { -- mille-feuille
      {0, 2, 3, 0},
      {0, 2, 4, 0}
    },
    { -- trois-chocolats
      {0, 2, 0, 5},
      {0, 2, 5, 5},
    },
    { -- lollipop
      {1, 1, 0, 5},
      {1, 1, 0, 6},
      {1, 1, 0, 7},
      {1, 1, 0, 8},
      {1, 1, 0, 9},
      {1, 1, 0, 10},
      {1, 1, 0, 11},
      {1, 1, 0, 12}
    },
    { -- candy
      {0, 1, 0, 5},
      {0, 1, 0, 6},
      {0, 1, 0, 7},
      {0, 1, 0, 8},
      {0, 1, 0, 9},
      {0, 1, 0, 10},
      {0, 1, 0, 11},
      {0, 1, 0, 12}
    },
    
[26]={ -- PakuBoi
      {0, 0, 0, 1},
      {0, 0, 0, 6},
      {0, 0, 0, 7},
      {0, 0, 0, 8},
      {0, 0, 0, 9},
      {0, 0, 0, 10},
      {0, 0, 0, 11},
      {0, 0, 0, 12}
    },
[27]={ -- PakuBoi
      {0, 0, 0, 1},
      {0, 0, 0, 6},
      {0, 0, 0, 7},
      {0, 0, 0, 8},
      {0, 0, 0, 9},
      {0, 0, 0, 10},
      {0, 0, 0, 11},
      {0, 0, 0, 12}
    },
[28]={ -- PakuBoi
      {0, 0, 0, 1},
      {0, 0, 0, 6},
      {0, 0, 0, 7},
      {0, 0, 0, 8},
      {0, 0, 0, 9},
      {0, 0, 0, 10},
      {0, 0, 0, 11},
      {0, 0, 0, 12}
    },
[29]={ -- PakuBoi
      {0, 0, 0, 1},
      {0, 0, 0, 6},
      {0, 0, 0, 7},
      {0, 0, 0, 8},
      {0, 0, 0, 9},
      {0, 0, 0, 10},
      {0, 0, 0, 11},
      {0, 0, 0, 12}
    },
[30]={ -- PakuBoi
      {0, 0, 0, 1},
      {0, 0, 0, 6},
      {0, 0, 0, 7},
      {0, 0, 0, 8},
      {0, 0, 0, 9},
      {0, 0, 0, 10},
      {0, 0, 0, 11},
      {0, 0, 0, 12}
    },
[31]={ -- PakuBoi
      {0, 0, 0, 1},
      {0, 0, 0, 6},
      {0, 0, 0, 7},
      {0, 0, 0, 8},
      {0, 0, 0, 9},
      {0, 0, 0, 10},
      {0, 0, 0, 11},
      {0, 0, 0, 12}
    },
  }
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
