-- Defines helpers for character building
--
-- An `attribute` object is defined in the following way:
-- {
-- name: any string,
-- type: "advantage" | "disadvantage" | "skill" | "spell" | "basic_attribute" | "secondary_characteristic" | "attack",
-- level: any positive integer,
-- diceexpr: any string matching [0-9]+d[+-]?[0-9]*
-- basedon: a table matching an attribute (e.g. one only containing name and type)
-- difficulty: "Easy" | "Average" | "Hard" | "Very Hard" | "Wildcard"
-- }

-- Thrust and Swing
-- TODO find out how the lua table serialisation works and use that instead.
require "gurps_tables"
require "etb_extensions"

_GGURPS_CHARACTER_CONFIG = {
  print_points=true,
}

function thrust_or_swing(typ, st)
  if st < 1 then
    return "0"
  end

  if _GTHRUSTSWINGTABLE[typ][st] then
    return _GTHRUSTSWINGTABLE[typ][st]
  else
    return thrust_or_swing(typ, st - 1)
  end
  -- TODO calculate thr and sw if it's too large for the table
end

function thrust(st)
  return thrust_or_swing("thrust", st)
end

function swing(st)
  return thrust_or_swing("swing", st)
end


_GCHARACTERS = {}

function package_error(msg)
  return tex.sprint([[\PackageError{gurps}{]] .. msg .. [[}{}]])
end

-- Creates a new character with that key name
function new_character(character_key)
  _GCHARACTERS[character_key] = {}
end

function get_character(character_key)
  retval = _GCHARACTERS[character_key]
  if retval == nil then
    tex.error("Character '" .. character_key .. "' not found!")
  end
  return retval
end

-- -- Store the character in the global characters table
function set_character(character_key, character)
  _GCHARACTERS[character_key] = character
end

-- TODO assert that I will only access the character via the key interface.
-- Maybe. Decide if this should be the case
--
-- Yes, I do want it that way, because it's the TeX way. Define something and
-- then do something with it

-- insert attribute into a character specified by a key
function insert_attr(character_key, attr)
  table.insert(get_character(character_key), attr)
end

-- Turns an array into a table with identical key/value pairs
function _identity_pairs_tbl(tbl)
  rettbl = {}
  for _,v in ipairs(tbl) do
    rettbl[v] = v
  end

  return rettbl
end

-- Enums for things with allowed values
enums = {}
enums.type = _identity_pairs_tbl({"advantage" ,
                                  "disadvantage" ,
                                  "quirk",
                                  "perk",
                                  "skill" ,
                                  "spell" ,
                                  "basic_attribute" ,
                                  "secondary_characteristic" ,
                                  "melee_attack",
                                  "ranged_attack",
                                  "metadata",
                                  "property"})
enums.difficulty = {
  easy="Easy",
  average="Average",
  hard="Hard",
  very_hard="Very Hard",
  wildcard="Wildcard",
  notset="NotSet"
}

-- Create a function that returns attr if all key=value pairs match (tbl -> attr
-- direction only)
function tbl_to_filter_pred(tbl)
  return function(attr)
    for k,v in pairs(tbl) do
      if attr[k] ~= v then
        return nil
      end
    end
    return attr
  end
end

-- Filter an array. If predicate is a string, filter against the name, if its a
-- table, convert with tbl_to_filter_pred, otherwise assume it's already a
-- function!
function filter(predicate, array)
  if type(predicate) == "string" then
    predicate = {name=predicate}
  end

  if type(predicate) == "table" then
    predicate = tbl_to_filter_pred(predicate)
  end

  ret_array = {}

  if not array then
    tex.error("Array passed to filter is nil...")
  end

  at_least_one_match = false
  for _,v in ipairs(array) do
    if predicate(v) then
      table.insert(ret_array, v)
      at_least_one_match = true
    end
  end

  -- if at_least_one_match has been defined
  if at_least_one_match then
    return ret_array
  else
    return nil
  end
end

-- Filter the character
function cfilter(predicate, character_key)
  character_key = character_key or _GCHARACTERKEY
  c = get_character(character_key)
  return filter(predicate, c)
end

-- Get a value from the character.
function cget(predicate, character_key)
  filter_results = cfilter(predicate, character_key)
  if filter_results then
    return filter_results[1]
  else
    return nil
  end
end

function reduce(f, arr)
  retval = arr[1]
  for i=2,#arr,1 do
    retval = f(retval, arr[i])
  end

  return retval
end

-- Predicates --

function is_valid_attribute(attr)
  return attr.name and attr.type
end

function is_advantage(attr)
  return attr.type == "advantage"
end

function is_perk(attr)
  return attr.type == "perk"
end

function is_quirk(attr)
  return attr.type == "quirk"
end

function is_disadvantage(attr)
  return attr.type == "disadvantage"
end

-- A trait is an advantage or a disadvantage
function is_trait(attr)
  return is_advantage(attr) or is_disadvantage(attr) or is_quirk(attr) or is_perk(attr)
end

function is_advantageordisadvantage(attr)
  return is_advantage(attr) or is_disadvantage(attr)
end

function is_perkorquirk(attr)
  return is_perk(attr) or is_quirk(attr)
end

function is_skill(attr)
  return attr.type == "skill"
end

function is_spell(attr)
  return attr.type == "spell"
end

function is_basic_attribute(attr)
  return attr.type == "basic_attribute"
end

function is_secondary_characteristic(attr)
  return attr.type == "secondary_characteristic"
end

function is_property(attr)
  return attr.type == "property"
end

function is_melee_attack(attr)
  return attr.type == enums.type.melee_attack
end
function is_ranged_attack(attr)
  return attr.type == enums.type.ranged_attack
end
function is_attack(attr)
  return is_ranged_attack(attr) or is_melee_attack(attr)
end


_GPREDICATES = {
  advantages=is_advantage,
  disadvantages=is_disadvantage,
  traits=is_trait,
  perks=is_perk,
  quirks=is_quirk,
  skills=is_skill,
  spells=is_spell,
  basic_attributes=is_basic_attribute,
  secondary_characteristics=is_secondary_characteristic,
  properties=is_property,
  attacks=is_attack
}

-- Quickly test the predicates are all valid
for k,v in pairs(_GPREDICATES) do
  if v == nil then
    tex.error(k .. "has no predicate attached! This is a bug; contact the package author.")
  end
end

function get_predicate(name)
  local predicate = _GPREDICATES[name]
  if predicate == nil then
    tex.error(name .. " predicate could not be got! This is a bug; contact the package author.")
  end
  return predicate
end

-- End of predicates --


function is_valid_type(t)
  for k,v in pairs(enums.type) do
    if t == v then
      return v
    end
  end

  return false
end

function is_valid_difficulty(t)
  for k,v in pairs(enums.difficulty) do
    if t == v then
      return v
    end
  end

  return false
end

function is_valid_points(p)
  if tonumber(p) or p == nil or p == "-" then
    return true
  end

  return false
end

function if_else_packageerror(pred, message)
  if pred() then
    return true
  else
    tex.sprint([[\PackageError{gurps}{]] .. message .. [[}{}]])
  end
end

function attr_to_tex(attr)
  s = [[\GCPrintAttr]]
  level_str = ""
  if attr.level or attr.diceexpr ~= "NotSet" then
    level_str = "[" .. (attr.level or attr.diceexpr) .. "]"
  end

  points_str = ""
  if etb_is_toggletrue("GCPrintPointsToggle") then
    if not is_property(attr) and not is_attack(attr) then
      if attr.points then
        points_str = "[" .. attr.points .. "]"
      elseif attr.type ~= enums.type.property then
        points_str = "[?]"
      end
    end
  end

  s = s .. level_str .. "{" .. attr.name .. "}" .. points_str

  return s
end

function basic_attributes_sorter(a, b)
  x = {}
  x['ST'] = 1
  x['DX'] = 2
  x['IQ'] = 3
  x['HT'] = 4
  return x[a.name] < x[b.name]
end

function secondary_characteristics_sorter(a, b)
  x = {}
  x['HP'] = 1
  x['Per'] = 2
  x['Will'] = 3
  x['FP'] = 4
  x['Basic Speed'] = 5
  x['Basic Move'] = 6
  return x[a.name] < x[b.name]
end

-- predicate to filter by
-- character_key to get character with get_character()
-- sortby function to sort by
function traitlistmaker(predicate, character_key, sortby)
  s = [[\begin{charactertraitlist}]]

  array = cfilter(predicate, character_key)
  if array then
    if sortby then
      table.sort(array, sortby)
    end

    for _,v in ipairs(array) do
      s = s .. [[ \item ]] .. attr_to_tex(v)
    end
  else
    s = s .. [[\item ...]]
  end
  s = s .. [[ \end{charactertraitlist}]]
  tex.sprint(s)
end

function attacklist(character_key)
  attacks = cfilter(is_attack, character_key)
  if attacks then
    s = [[\begin{GCAttackList}]]
    for _,attack in ipairs(attacks) do
      if attack.range and attack.range ~= "NotSet" then
        range_or_reach = "range"
      else
        range_or_reach = "reach"
      end
      s = s .. [[ \item \GCPrintAttack]]
        .. "{" .. attack.name .. "}"
        .. "{" .. tostring(attack.level) .. "}"
        .. "{" .. attack.damage .. "}"
        .. "[" .. range_or_reach:gsub("^%l", string.upper) .. "]"
        .. "{" .. attack[range_or_reach] .. "}"
        .. "{" .. attack.notes .. "}"
    end
    s = s .. [[ \end{GCAttackList}]]
    tex.sprint(s)
  end
end

function check_and_fix_attrs(character_key)
  function get(name)
    arr = cfilter({name=name}, character_key)
    if arr then
      return arr[1]
    else
      return nil
    end
  end

  function create_if_missing(name, attr)
    if not get(name) then
      insert_attr(character_key, attr)
    end
  end

  -- Check for properties
  create_if_missing("SM", {name="SM", level=1, type=enums.type.property})
  create_if_missing("DR", {name="DR", level=0, type=enums.type.property})

  -- Check for basic attributes
  for _,v in ipairs({"ST", "DX", "IQ", "HT"}) do
    create_if_missing(v, {name=v,
                          type=enums.type.basic_attribute,
                          points=0,
                          level=10})
  end

  -- Check for secondary attributes
  create_if_missing("HP", {name="HP",
                           level=get("ST").level,
                           points=0,
                           type=enums.type.secondary_characteristic})
  create_if_missing("Per", {name="Per",
                           level=get("IQ").level,
                           points=0,
                           type=enums.type.secondary_characteristic})
  create_if_missing("Will", {name="Will",
                             level=get("IQ").level,
                             points=0,
                             type=enums.type.secondary_characteristic})
  create_if_missing("FP", {name="FP",
                           level=get("HT").level,
                           points=0,
                           type=enums.type.secondary_characteristic})
  create_if_missing("Basic Speed", {name="Basic Speed",
                                   level=(get("DX").level+get("HT").level)/4.0,
                                   points=0,
                                   type=enums.type.secondary_characteristic})
  create_if_missing("Basic Move", {name="Basic Move",
                                  level=math.floor(get("Basic Speed").level),
                                  points=0,
                                  type=enums.type.secondary_characteristic})
  -- NOTE dodge here is technically a property as it has no points assigned to
  -- it. It can be made better with advantages (just like DR), but this should
  -- be handled manually (i.e. by setting dodge higher).
  create_if_missing("Dodge", {name="Dodge",
                              level=math.floor(get("Basic Speed").level+3),
                              type=enums.type.property})
  create_if_missing("thr", {name="thr",
                            diceexpr=thrust(get("ST").level),
                            type=enums.type.property})
  create_if_missing("sw", {name="sw",
                           diceexpr=swing(get("ST").level),
                           type=enums.type.property})
end

function check_and_fix_points(character_key)
  local get = function(name)
    arr = cfilter({name=name}, character_key)
    if arr then
      return arr[1]
    else
      return nil
    end
  end

  function add_stat_points_if_needed(name, default, multiplier)
    if not get(name).points then
      get(name).points = (get(name).level - default)*multiplier
    end
  end

  add_stat_points_if_needed("ST", 10, 10)
  add_stat_points_if_needed("DX", 10, 20)
  add_stat_points_if_needed("IQ", 10, 20)
  add_stat_points_if_needed("HT", 10, 10)

  add_stat_points_if_needed("HP", get("ST").level, 2)
  add_stat_points_if_needed("Per", get("IQ").level, 5)
  add_stat_points_if_needed("Will", get("IQ").level, 5)
  add_stat_points_if_needed("FP", get("HT").level, 2)

  -- I can't calculate dis/advantages so straight on to skills and spells

  -- Skills
  --
  -- TODO tidy up this section. Maybe move functions out? Or make more pure
  -- (i.e. separate into several functions which are used in the function that
  -- changes `attr`)?
  function add_skill_points_if_possible(attr)
    if attr.difficulty == enums.difficulty.notset then
      return
    end
    points_multiplier = 1
    if attr.difficulty == enums.difficulty.easy then
      difficulty_modifier = 0
    elseif attr.difficulty == enums.difficulty.average then
      difficulty_modifier = 1
    elseif attr.difficulty == enums.difficulty.hard then
      difficulty_modifier = 2
    elseif attr.difficulty == enums.difficulty.very_hard then
      difficulty_modifier = 3
    elseif attr.difficulty == enums.difficulty.wildcard then
      points_multiplier = 3
      difficulty_modifier = 3
    else
      tex.error("Difficulty '" .. attr.difficulty .. "' not recognised! (For"
                  .. " skill '" .. attr.name .. "'.)")
    end

    if get(attr.basedon) == nil then
      tex.error("Unable to base '" .. attr.name .. "' on '" .. attr.basedon 
                  .. "'! Does '" .. attr.basedon .. "' exist?")
    end
    relative_level = attr.level - get(attr.basedon).level
    if relative_level == (0 - difficulty_modifier) then
      attr.points = 1*points_multiplier
    elseif relative_level == (1 - difficulty_modifier) then
      attr.points = 2*points_multiplier
    elseif relative_level == (2 - difficulty_modifier) then
      attr.points = 4*points_multiplier
    elseif relative_level > (2 - difficulty_modifier) then
      attr.points = (relative_level-1+difficulty_modifier)*4 * points_multiplier
    end
  end

  skills_and_spells = filter(
    function(v) return is_skill(v) or is_spell(v) end,
    get_character(character_key)
  )
  if skills_and_spells then
    for _,v in ipairs(skills_and_spells) do
      add_skill_points_if_possible(v)
    end
  end

end

-- Sum the points for the character
function sum_points(character_key)
  local points = 0
  for _,v in ipairs(get_character(character_key)) do
    points = points + (v.points or 0)
  end
  return points
end

function check_and_fix_attrs_and_points(character_key)
  check_and_fix_attrs(character_key)
  check_and_fix_points(character_key)


  -- Sort the character
  function compare_only_alphanumeric(a, b)
    if not a or not b then
      tex.error("Looks like there's a problem with character ordering..."
                  .. " problems with a: " .. tostring(a) .. " and b: "
                  .. tostring(b) .. ".")
    end
    return a.name:gsub('%W', '') < b.name:gsub('%W', '')
  end
  table.sort(
    get_character(character_key),
    compare_only_alphanumeric
  )
end

-- the function for \GCGet
-- TODO rename this function! It gets dice expressions too!
function tex_get_value_or_level(character_key, name, macro)
  tbl = cget(name, character_key)
  if tbl then
    if tbl.level then
      tex.sprint([[\edef]] .. macro .. "{" .. tbl.level .. "}")
    elseif tbl.value and tbl.value ~= "NotSet"  then
      tex.sprint([[\edef]] .. macro .. "{" .. tbl.value .. "}")
    elseif tbl.diceexpr and tbl.diceexpr ~= "NotSet" then
      tex.sprint([[\edef]] .. macro .. "{" .. tbl.diceexpr .. "}")
    else
      tex.error([[Got name ']] .. name .. [[' but it doesn't have a value or level!]])
    end
  else
    tex.error([[Unable to get ']] .. name .. "'")
  end
end

function tex_add_to_level(name, amount_to_add, character_key)
  character_key = character_key or _GCHARACTERKEY
  attr = cget(name, character_key)
  if not attr then
    tex.error("Unable to find attribute with name '"
                .. name .. [[' in macro \GCAddToLevel.]])
  end
  if not attr.level then
    tex.error("Attribute '" .. name .. "' found but has no level!")
  end
  attr.level = attr.level + amount_to_add
end


function tex_getcharacterfromfile(basenamepath, character_key)
  local exec_string = [[gcs ]] .. basenamepath
    .. [[.gcs -text -text_template=$(kpsewhich gurps-gcs-template.gcx)]]
  local retval = os.execute(exec_string)
  if not retval then
    tex.error([[Uh oh. Trying to run  ']] .. exec_string .. "' returned " .. tostring(retval))
  end
end


function create_list_predicate(tex_input)
  if not tex_input:gmatch("%w+") then
    tex.error("No matches found! Were any arguments passed to create_list_predicate?\n\nHere they are: " .. tex_input)
  end

  local predicates = {}
  for v,p in pairs(_GPREDICATES) do
    print("v: " .. v)
    for match in tex_input:gmatch("[a-z_]+") do
      print("match: " .. match)
      if match:find("^" .. v .. "$") then
        print("Match found!")
        if get_predicate(v) == nil then
          tex.error("The predicate for " .. v .. " could not be found.")
        end
        table.insert(predicates, get_predicate(v))
      else
        print("Match not found :(")
      end
    end
  end

  -- Return the newly formed OR predicate
  retfunc = function(x)
    print("Entering anonymous function for predicating")
    for _,predicate in ipairs(predicates) do
      print("predicate: " .. tostring(debug.getinfo(predicate).name))
      if predicate(x) then
        return true
      end
    end

    return false
  end

  return retfunc
end

-- You know what, I'm going to test this function right now
function test_create_list_predicate()
  print("Testing create_list_predicate")
  local x = "advantages,disadvantages"
  local f = create_list_predicate(x)

  -- This should pass every time
  print("Created create_list_predicate('" .. x .. "'): " .. tostring(f))
  local attr = {type="advantage"}
  if f(attr) == false then
    tex.error("We have serious problems.")
  end
end

test_create_list_predicate()

function tex_if_list_not_empty(listname, evalstring)
  if cfilter(get_predicate(listname)) then
    tex.sprint(evalstring)
  end
end
