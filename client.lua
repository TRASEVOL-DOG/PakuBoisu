if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
    "game.lua",
    "object.lua",
    "voxel.lua",
    "nnetwork.lua",
    "sugarcoat/sugarcoat.lua",
    "assets/layers.png",
    "assets/sheet.png",
    "assets/title1.png",
    "assets/HungryPro.ttf",
    "assets/theme.ogg",
    "assets/sfx/pakuboisu.ogg",
    "assets/sfx/connected.ogg",
    "assets/sfx/crunch.ogg",
    "assets/sfx/eat_you.ogg", 
    "assets/sfx/you_eat.ogg", 
    "assets/sfx/other_eat.ogg",
    "assets/sfx/throw_up_step.ogg",
    "assets/sfx/max_size.ogg",
    "assets/sfx/reset.ogg"
  })
end

require("sugarcoat/sugarcoat")
sugar.utility.using_package(sugar.S, true)

require("nnetwork")
start_client()

require("game")

using_shader = false
function switch_shader()
  using_shader = not using_shader
  if using_shader then
    screen_shader([[
      varying vec2 v_vTexcoord;
      varying vec4 v_vColour;
      
      const float PI = 3.1415926535897932384626433832795;
  
      float power2(float);
      
      vec4 effect(vec4 color, Image texture, vec2 coords, vec2 screen_coords)
      {
        float a = 0.12345;
        vec4 cola = Texel_color(texture, coords + 0.35*vec2(cos(a)/SCREEN_SIZE.x, sin(a)/SCREEN_SIZE.y));
        vec4 colb = Texel_color(texture, coords + 0.35*vec2(cos(a+2.0*PI/3.0)/SCREEN_SIZE.x, sin(a+2.0*PI/3.0)/SCREEN_SIZE.y));
        vec4 colc = Texel_color(texture, coords + 0.35*vec2(cos(a+4.0*PI/3.0)/SCREEN_SIZE.x, sin(a+4.0*PI/3.0)/SCREEN_SIZE.y));
  
        vec3 col = vec3(0.05 + 0.95*cola.r,
                        0.05 + 0.95*colb.g,
                        0.05 + 0.95*colc.b);
  
        vec2 co = 2.0 * (mod(coords * SCREEN_SIZE, 1.0) - 0.5);
        float k = 1.0 - max(power2(co.x), power2(co.y));
  
        vec3 fcol = col;//(0.1*k + 0.95) * col;
        
        k = 1.1 - 0.15 * (power2((coords.x-0.5)*2.0)+power2((coords.y-0.5)*2.0));
  
        return vec4(k * fcol, 1.0);
      }
      
      float power2(float a){
        return a*a;//*a*a;
      }
    ]])
  else
    screen_shader()
  end
end

function client.load()
  init_sugar("Paku~Boisu!", 192, 128, 3)
  
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
    palette[i] = palette[i] or palette[19]
  end
  
  use_palette(palette)
  
  screen_render_integer_scale(false)

  switch_shader()
  
  load_assets()
  
  define_controls()
  
  _init()
  
  _initialized = true
end

function client.update()
  if not _initialized then return end
  
  if ROLE then client.preupdate() end

  _update()
  
  if ROLE then client.postupdate() end
end

function client.draw()
  if not _initialized then return end
  
  _draw()
end