

objs = {}
function init_object_mgr(...)
  objs={
    to_update={},
    to_draw0={},
    to_draw1={},
    to_draw2={},
    to_draw3={},
    to_draw4={}
  }
  
  local args={...}
  for v in all(args) do
    objs[v]={}
  end
end


--collision stuff

function collide_objgroup(obj,groupname)
  for obj2 in group(groupname) do
    if obj2~=obj then
      local bl = collide_objobj(obj,obj2)
      if bl then
        return obj2
      end
    end
  end
  
  return false
end

function all_collide_objgroup(obj,groupname)
 local list={}
 for obj2 in group(groupname) do
  if obj2 ~= obj and collide_objobj(obj,obj2) then
   add(list,obj2)
  end
 end
 
 return list
end

function collide_objobj(obj1, obj2)
  return (abs(obj1.x-obj2.x) < (obj1.w+obj2.w)/2
      and abs(obj1.y-obj2.y) < (obj1.h+obj2.h)/2)
end


--object managing
function update_objects(dt)
  local uobjs = objs.to_update
  
  for obj in all(uobjs) do
    obj:update(dt)
  end
end

function draw_objects(layer_start, layer_end)
  layer_end = layer_end or layer_start or 4
  layer_start = layer_start or 0
  
  for i = layer_start, layer_end do
    DRAWING_LAYER = i
  
    local dobjs = objs["to_draw"..i]
    
    --sorting objects by depth
--    for i=2,#dobjs do
--     if dobjs[i-1].y>dobjs[i].y then
--      local k=i
--      while(k>1 and dobjs[k-1].y>dobjs[k].y) do
--       local s=dobjs[k]
--       dobjs[k]=dobjs[k-1]
--       dobjs[k-1]=s
--       k=k-1
--      end
--     end
--    end
    
    --actually drawing
    for obj in all(dobjs) do
      obj:draw()
    end
  end
end


function register_object(o)
  for reg in all(o.regs) do
    if not objs[reg] then
      objs[reg] = {}
    end
    add(objs[reg],o)
  end

  o.__registered = true
end

function deregister_object(o)
  for reg in all(o.regs) do
    del(objs[reg],o)
  end
  o.__registered = false
end

function group_add(group,o)
  add(o.regs,group)
  add(objs[group],o)
end

function group_del(group,o)
  del(o.regs,group)
  del(objs[group],o)
end

function clear_group(group)
  objs[group] = {}
end

function clear_all_groups()
  for n,v in pairs(objs) do
    clear_group(n)
  end
end

function eradicate_group(grp)
  --local a = objs[group]
  --if a then
    while #objs[grp] > 0 do
      deregister_object(objs[grp][1])
    end
  --end
  
--  for o in group(grp) do
--    deregister_object(o)
--  end
end

function new_group(name) objs[name] = {} end

function get_group_copy(grp)
  return copy_table(objs[grp])
end

function group_exists(name) return objs[name] ~= nil end

function group(name) return all(objs[name]) end
function group_size(name) return #objs[name] end
function group_member(grp,pos) return objs[grp][pos] end


