local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T
local HookAddonOrVariable = ShaguTweaks.HookAddonOrVariable
local GetExpansion = ShaguTweaks.GetExpansion
local AddBorder = ShaguTweaks.AddBorder

local module = ShaguTweaks:register({
  title = T["Darkened UI"],
  description = T["Turns the entire interface into darker colors."],
  expansions = { ["vanilla"] = true, ["tbc"] = true },
  enabled = nil,
  config = {
    ["darkmode.color"] = { r = .3, g = .3, b = .3, a = .9 }
  }
})

local blacklist = {
  ["Solid Texture"] = true,
  ["WHITE8X8"] = true,
  ["StatusBar"] = true,
  ["BarFill"] = true,
  ["Portrait"] = true,
  ["Button"] = true,
  ["Icon"] = true,
  ["AddOns"] = true,
  ["StationeryTest"] = true,
  ["TargetDead"] = true, -- LootFrame Icon
  ["^KeyRing"] = true, -- bag frame
  ["GossipIcon"] = true,
  ["WorldMap\\(.+)\\"] = true,
  ["PetHappiness"] = true,
  ["Elite"] = true,
  ["Rare"] = true,
  ["ColorPickerWheel"] = true,
  ["ComboPoint"] = true,
  ["Skull"] = true,

  -- LFT:
  ["battlenetworking0"] = true,
  ["damage"] = true,
  ["tank"] = true,
  ["healer"] = true,
}

local regionskips = {
  -- colorpicker gradient
  ["ColorPickerFrame"] = { [15] = true }
}

local backgrounds = {
  ["^SpellBookFrame$"] = { 325, 355, 17, -74 },
  ["^ItemTextFrame$"] = { 300, 355, 24, -74 },
  ["^QuestLogDetailScrollFrame$"] = { QuestLogDetailScrollChildFrame:GetWidth(), QuestLogDetailScrollChildFrame:GetHeight(), 0, 0 },
  ["^QuestFrame(.+)Panel$"] = { 300, 330, 24, -82 },
  ["^GossipFrameGreetingPanel$"] = { 300, 330, 24, -82 },
}

local borders = {
  ["ShapeshiftButton"] = 3,
  ["BuffButton"] = 3,
  ["TargetFrameBuff"] = 3,
  ["TempEnchant"] = 3,
  ["SpellButton"] = 3,
  ["SpellBookSkillLineTab"] = 3,
  ["ActionButton%d+$"] = 3,
  ["MultiBar(.+)Button%d+$"] = 3,
  ["KeyRingButton"] = 2,
  ["ActionBarUpButton"] = -3,
  ["ActionBarDownButton"] = -3,
  ["MainMenuBarPerformanceBarFrameButton"] = { -12, -1, -8, 4 },
  ["Character(.+)Slot$"] = 3,
  ["Inspect(.+)Slot$"] = 3,
  ["ContainerFrame(.+)Item"] = 3,
  ["MainMenuBarBackpackButton$"] = 3,
  ["CharacterBag(.+)Slot$"] = 3,
  ["ChatFrame(.+)Button"] = -2,
  ["PetFrameHappiness"] = 2,
  ["MicroButton"] = { -21, 0, 0, 0 },
}

local addonframes = {
  ["Blizzard_TalentUI"] = { "TalentFrame" },
  ["Blizzard_AuctionUI"] = { "AuctionFrame", "AuctionDressUpFrame" },
  ["Blizzard_CraftUI"] = { "CraftFrame" },
  ["Blizzard_InspectUI"] = { "InspectPaperDollFrame", "InspectHonorFrame", "InspectFrameTab1", "InspectFrameTab2" },
  ["Blizzard_MacroUI"] = { "MacroFrame", "MacroPopupFrame" },
  ["Blizzard_RaidUI"] = { "ReadyCheckFrame" },
  ["Blizzard_TalentUI"] = { "TalentFrame" },
  ["Blizzard_TradeSkillUI"] = { "TradeSkillFrame" },
  ["Blizzard_TrainerUI"] = { "ClassTrainerFrame" },
}

-- sizing is a bit different on tbc
if GetExpansion() == "tbc" then
  borders["BuffButton"] = 2
  borders["TempEnchant"] = 2
  borders["MicroButton"] = { -21, 0, 0, 0 }
end

local function IsBlacklisted(texture)
  local name = texture:GetName()
  local texture = texture:GetTexture()
  if not texture then return true end

  if name then
    for entry in pairs(blacklist) do
      if string.find(name, entry, 1) then return true end
    end
  end

  for entry in pairs(blacklist) do
    if string.find(texture, entry, 1) then return true end
  end

  return nil
end

local function AddSpecialBackground(frame, w, h, x, y)
  frame.Material = frame.Material or frame:CreateTexture(nil, "OVERLAY")
  frame.Material:SetTexture("Interface\\Stationery\\StationeryTest1")
  frame.Material:SetWidth(w)
  frame.Material:SetHeight(h)
  frame.Material:SetPoint("TOPLEFT", frame, x, y)
  frame.Material:SetVertexColor(.8, .8, .8)
end

local function DarkenFrame(frame, r, g, b, a)
  -- dont't do anything if disabled
  if not ShaguTweaks.DarkMode then return end

  -- set defaults
  if not r and not g and not b then
    r, g, b, a = module.config["darkmode.color"].r, module.config["darkmode.color"].g, module.config["darkmode.color"].b, module.config["darkmode.color"].a
  end

  -- iterate through all subframes
  if frame and frame.GetChildren then
    for _, frame in pairs({frame:GetChildren()}) do
      DarkenFrame(frame, r, g, b, a)
    end
  end

  -- set vertex on all regions
  if frame and frame.GetRegions then
    -- read name
    local name = frame.GetName and frame:GetName()

    -- set a dark backdrop border color everywhere
    frame:SetBackdropBorderColor(module.config["darkmode.color"].r, module.config["darkmode.color"].g, module.config["darkmode.color"].b, module.config["darkmode.color"].a)

    -- add special backgrounds to quests and such
    for pattern, inset in pairs(backgrounds) do
      if name and string.find(name, pattern) then AddSpecialBackground(frame, inset[1], inset[2], inset[3], inset[4]) end
    end

    -- add black borders around specified buttons
    for pattern, inset in pairs(borders) do
      if name and string.find(name, pattern) then AddBorder(frame, inset, module.config["darkmode.color"]) end
    end

    -- scan through all regions (textures)
    for id, region in pairs({frame:GetRegions()}) do
      if region.SetVertexColor and region:GetObjectType() == "Texture" then
        if region:GetTexture() and string.find(region:GetTexture(), "UI%-Panel%-Button%-Up") then
          -- monochrome buttons
          -- region:SetDesaturated(true)
        elseif name and id and regionskips[name] and regionskips[name][id] then
          -- skip special regions
        elseif IsBlacklisted(region) then
          -- skip blacklisted texture names
        else
          region:SetVertexColor(r,g,b,a)
        end
      end
    end
  end
end

-- register darken frame to global
ShaguTweaks.DarkenFrame = DarkenFrame

module.enable = function(self)
  ShaguTweaks.DarkMode = true

  local name, original, r, g, b
  local hookBuffButton_Update = BuffButton_Update
  function BuffButton_Update(buttonName, index, filter)
    hookBuffButton_Update(buttonName, index, filter)

    -- tbc passes buttonName and index arguments, vanilla uses "this" context
    name = buttonName and index and buttonName .. index or this:GetName()
    original = _G[name.."Border"]

    if original and this.ShaguTweaks_border then
      r, g, b = original:GetVertexColor()
      this.ShaguTweaks_border:SetBackdropBorderColor(r, g, b, 1)
      original:SetAlpha(0)
    elseif not original and _G[name] then
      -- tbc buff buttons don't have borders, so we
      -- need to manually add a dark one.
      AddBorder(_G[name], 2, module.config["darkmode.color"])
    end
  end

  TOOLTIP_DEFAULT_COLOR.r = module.config["darkmode.color"].r
  TOOLTIP_DEFAULT_COLOR.g = module.config["darkmode.color"].g
  TOOLTIP_DEFAULT_COLOR.b = module.config["darkmode.color"].b

  TOOLTIP_DEFAULT_BACKGROUND_COLOR.r = module.config["darkmode.color"].r
  TOOLTIP_DEFAULT_BACKGROUND_COLOR.g = module.config["darkmode.color"].g
  TOOLTIP_DEFAULT_BACKGROUND_COLOR.b = module.config["darkmode.color"].b

  DarkenFrame(UIParent)
  DarkenFrame(WorldMapFrame)
  DarkenFrame(DropDownList1)
  DarkenFrame(DropDownList2)
  DarkenFrame(DropDownList3)

  -- align all actionbutton textures
  local bars = { "Action", "BonusAction", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight", "Shapeshift" }
  for _, prefix in pairs(bars) do
    for i = 1, NUM_ACTIONBAR_BUTTONS do
      local button = _G[prefix .. "Button" .. i]
      local texture = _G[prefix.."Button"..i.."NormalTexture"]

      if button and texture then
        texture:SetWidth(60)
        texture:SetHeight(60)
        texture:SetPoint("CENTER", 0, 0)
        ShaguTweaks.AddBorder(button, 3)
      end
    end
  end

  for _, button in pairs({ MinimapZoomOut, MinimapZoomIn }) do
    for _, func in pairs({ "GetNormalTexture", "GetDisabledTexture", "GetPushedTexture" }) do
      if button[func] then
        local tex = button[func](button)
        if tex then
          tex:SetVertexColor(module.config["darkmode.color"].r+.2, module.config["darkmode.color"].g+.2, module.config["darkmode.color"].b+.2, 1)
        end
      end
    end
  end

  HookAddonOrVariable("Blizzard_AuctionUI", function()
    for i = 1, 15 do
      local tex = _G["AuctionFilterButton"..i]:GetNormalTexture()
      tex:SetVertexColor(module.config["darkmode.color"].r, module.config["darkmode.color"].g, module.config["darkmode.color"].b, 1)
    end

    for i = 1, 8 do
      _G["BrowseButton"..i.."Left"]:SetVertexColor(module.config["darkmode.color"].r, module.config["darkmode.color"].g, module.config["darkmode.color"].b, 1)
      _G["BrowseButton"..i.."Right"]:SetVertexColor(module.config["darkmode.color"].r, module.config["darkmode.color"].g, module.config["darkmode.color"].b, 1)
    end
  end)

  for addon, data in pairs(addonframes) do
    for _, frame in pairs(data) do
      local frame = frame
      HookAddonOrVariable(frame, function()
        DarkenFrame(_G[frame])
      end)
    end
  end

  HookAddonOrVariable("Blizzard_TimeManager", function()
    DarkenFrame(TimeManagerClockButton)
  end)

  HookAddonOrVariable("GameTooltipStatusBarBackdrop", function()
    DarkenFrame(_G["GameTooltipStatusBarBackdrop"])
  end)

  table.insert(ShaguTweaks.libnameplate.OnUpdate, function()
    if not this.darkened then
      this.darkened = true
      DarkenFrame(this)
    end
  end)
end
