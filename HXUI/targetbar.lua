require('common');
require('helpers');
local imgui = require('imgui');
local statusHandler = require('statushandler');
local debuffHandler = require('debuffhandler');
local progressbar = require('progressbar');
local fonts = require('fonts');
local ffi = require("ffi");

-- TODO: Calculate these instead of manually setting them

local bgAlpha = 0.4;
local bgRadius = 3;

local arrowTexture;
local percentText;
local nameText;
local totNameText;
local distText;
local targetbar = {
	interpolation = {}
};

local function UpdateTextVisibility(visible)
	percentText:SetVisible(visible);
	nameText:SetVisible(visible);
	totNameText:SetVisible(visible);
	distText:SetVisible(visible);
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end


local _HXUI_DEV_DEBUG_INTERPOLATION = false;
local _HXUI_DEV_DEBUG_INTERPOLATION_DELAY = 1;
local _HXUI_DEV_DEBUG_HP_PERCENT_PERSISTENT = 100;
local _HXUI_DEV_DAMAGE_SET_TIMES = {};

local colors = T{
	white   = 0xFFFFFFFF,
	gray    = 0xFF808080,
	red     = 0xFFFF0000,
	orange  = 0xFFFF8000,
	yellow  = 0xFFFFFF00,
	green   = 0xFF00FF00,
	cyan    = 0xFF00FFFF,
	blue    = 0xFF0000FF,
	purple  = 0xFF8000FF,
	magenta = 0xFFFF32FA,
};

local jobs = T{
    [1]  = 'WAR',
    [2]  = 'MNK',
    [3]  = 'WHM',
    [4]  = 'BLM',
    [5]  = 'RDM',
    [6]  = 'THF',
    [7]  = 'PLD',
    [8]  = 'DRK',
    [9]  = 'BST',
    [10] = 'BRD',
    [11] = 'RNG',
    [12] = 'SAM',
    [13] = 'NIN',
    [14] = 'DRG',
    [15] = 'SMN',
    [16] = 'BLU',
    [17] = 'COR',
    [18] = 'PUP',
    [19] = 'DNC',
    [20] = 'SCH',
    [21] = 'GEO',
    [22] = 'RUN',
};

local ranged = T{
	[0]     = "N/A",    --Nothing
	[17276] = "BULLET", --Antique Bullet +1
	[17278] = "BULLET", --Gold Bullet
	[17279] = "THROW",  --Moonring Blade +1
	[17280] = "THROW",  --Boomerang
	[17281] = "THROW",  --Wingedge
	[17282] = "THROW",  --Combat Caster's Boomerang
	[17283] = "THROW",  --Junior Musketeer's Chakram
	[17284] = "THROW",  --Chakram
	[17285] = "THROW",  --Moonring Blade
	[17286] = "THROW",  --Rising Sun
	[17287] = "THROW",  --Boomerang +1
	[17288] = "THROW",  --Wingedge +1
	[17289] = "THROW",  --Chakram +1
	[17290] = "THROW",  --Coarse Boomerang
	[17291] = "THROW",  --Flame Boomerang
	[17292] = "THROW",  --Long Boomerang
	[17293] = "THROW",  --Yagudo Freezer
	[17294] = "THROW",  --Comet Tail
	[17295] = "THROW",  --Rising Sun +1
	[17296] = "THROW",  --Pebble
	[17298] = "THROW",  --Tathlum
	[17299] = "THROW",  --Astragalos
	[17300] = "BULLET", --Platinum Bullet
	[17301] = "THROW",  --Shuriken
	[17302] = "THROW",  --Juji Shuriken
	[17303] = "THROW",  --Manji Shuriken
	[17304] = "THROW",  --Fuma Shuriken
	[17305] = "THROW",  --Cluster Arm
	[17306] = "THROW",  --Snoll Arm
	[17307] = "THROW",  --Dart
	[17308] = "THROW",  --Hawkeye
	[17309] = "THROW",  --Pinwheel
	[17310] = "THROW",  --Hyo
	[17311] = "THROW",  --Dart +1
	[17312] = "BULLET", --Iron Bullet
	[17313] = "THROW",  --Grenade
	[17314] = "THROW",  --Quake Grenade
	[17315] = "THROW",  --Riot Grenade
	[17316] = "THROW",  --Bomb Arm
	[17317] = "ARROW",  --Gold Arrow
	[17318] = "ARROW",  --Wooden Arrow
	[17319] = "ARROW",  --Bone Arrow
	[17320] = "ARROW",  --Iron Arrow
	[17321] = "ARROW",  --Silver Arrow
	[17322] = "ARROW",  --Fire Arrow
	[17323] = "ARROW",  --Ice Arrow
	[17324] = "ARROW",  --Lightning Arrow
	[17325] = "ARROW",  --Kabura Arrow
	[17327] = "ARROW",  --Grand Knight's Arrow
	[17328] = "BOLT",   --Gold Musketeeer's Bolt
	[17329] = "ARROW",  --Patriarch Protector's Arrow
	[17330] = "ARROW",  --Stone Arrow
	[17331] = "ARROW",  --Old Arrow
	[17332] = "ARROW",  --Fang Arrow
	[17333] = "ARROW",  --Rune Arrow
	[17334] = "ARROW",  --Platinum Arrow
	[17336] = "BOLT",   --Corssbow Bolt
	[17337] = "BOLT",   --Mythril Bolt
	[17338] = "BOLT",   --Darksteel Bolt
	[17339] = "BOLT",   --Bronze Bolt
	[17340] = "BULLET", --Bullet
	[17341] = "BULLET", --Silver Bullet
	[17342] = "BULLET", --Cannon Shell
	[17343] = "BULLET", --Bronze Bullet
	[18132] = "THROW",  --Combat Caster's Boomerang +1
	[18133] = "THROW",  --Combat Caster's Boomerang +2
	[18134] = "THROW",  --Junior Musketeer's Chakram +1
	[18135] = "THROW",  --Junior Musketeer's Chakram +2
	[18141] = "THROW",  --Ungur Boomerang
	[18148] = "BOLT",   --Acid Bolt
	[18149] = "BOLT",   --Sleep Bolt
	[18150] = "BOLT",   --Blind Bolt
	[18151] = "BOLT",   --Bloody Bolt
	[18152] = "BOLT",   --Venom Bolt
	[18153] = "BOLT",   --Holy Bolt
	[18154] = "ARROW",  --Beetle Arrow
	[18155] = "ARROW",  --Scorpion Arrow
	[18156] = "ARROW",  --Horn Arrow
	[18157] = "ARROW",  --Poison Arrow
	[18158] = "ARROW",  --Sleep Arrow
	[18159] = "ARROW",  --Demon Arrow
	[18160] = "BULLET", --Spartan Bullet
	[18161] = "THROW",  --Arctic Wind
	[18162] = "THROW",  --East Wind
	[18163] = "THROW",  --Zephyr
	[18164] = "THROW",  --Antarctic Wind
	[18170] = "THROW",  --Platoon Edge
	[18171] = "THROW",  --Platoon Disc
	[18172] = "THROW",  --Light Boomerang
	[18173] = "THROW",  --Nokizaru Shuriken
	[18178] = "ARROW",  --Bodkin Arrow
	[18181] = "ARROW",  --Crude Arrow
	[18182] = "ARROW",  --Crude Arrow +1
	[18183] = "ARROW",  --Crude Arrow +2
	[18184] = "ARROW",  --Crude Arrow +3
	[18185] = "ARROW",  --Crude Arrow +4
	[18186] = "ARROW",  --Crude Arrow +5
	[18187] = "ARROW",  --Crude Arrow +6
	[18188] = "ARROW",  --Crude Arrow +7
	[18189] = "BOLT",   --Dogbolt
	[18190] = "BOLT",   --Dogbolt +1
	[18191] = "BOLT",   --Dogbolt +2
	[18192] = "BOLT",   --Dogbolt +3
	[18193] = "BOLT",   --Dogbolt +4
	[18194] = "BOLT",   --Dogbolt +5
	[18195] = "BULLET", --Antique Bullet
	[18231] = "THROW",  --Death Chakram
	[18235] = "BULLET", --Corsair Bullet
	[18245] = "THROW",  --Aureole
	[18246] = "THROW",  --Rogetsurin
	[18255] = "BULLET", --Heavy Shell
	[18681] = "THROW",  --Aht Urhgan Dart
	[18692] = "THROW",  --Mamoolbane
	[18693] = "THROW",  --Lamiabane
	[18694] = "THROW",  --Trollbane
	[18696] = "ARROW",  --Paralysis Arrow
	[18697] = "ARROW",  --Marid Arrow
	[18698] = "ARROW",  --Water Arrow
	[18699] = "ARROW",  --Earth Arrow
	[18700] = "ARROW",  --Wind Arrow
	[18708] = "THROW",  --Snakeeye
	[18709] = "THROW",  --Snakeeye +1
	[18712] = "THROW",  --Koga Shuriken
	[18713] = "BULLET", --Copper Bullet
	[18723] = "BULLET", --Steel Bullet
	[18738] = "ARROW",  --Temple Knight's Arrow
	[18739] = "BOLT",   --Iron Musketeer's Bolt
	[19201] = "BULLET", --Electrum Bullet
};

local distances = T{
	BULLET = T{
		OptimalMin  = 4.5,
		OptimalMax  = 5.5,
		maxRange    = 25,
		FalloffNear = 1,  --75% of max
		FalloffFar  = 25, --85% of max
	},
	BOLT = T{
		OptimalMin  = 6,
		OptimalMax  = 10,
		maxRange    = 25,
		FalloffNear = 3,  --75% of max
		FalloffFar  = 25, --86% of max
	},
	ARROW = T{
		OptimalMin  = 7.5,
		OptimalMax  = 10.5,
		maxRange    = 25,
		FalloffNear = 4.2, --75% of max
		FalloffFar  = 25,  --87% of max
	},
	THROW = T{
		OptimalMin  = 1,
		OptimalMax  = 1,
		maxRange    = 25,
		FalloffNear = 0,  --Not applicable to thrown
		FalloffFar  = 10, --90% of max
	},
	CASTER = T{
		maxRange = 21,
	},
	RNG = T{
		rangedWSmax  = 15.8,
		detonatorMax = 17.7,
		shadowBind   = 17.5,
	},
	WAR = T{
		Provoke = 17.5,
	},
	BLU = T{
		Blastbomb  = 13.5,
		heatBreath = 15,
		Connonball = 22.5,
	},
	COR = T{
		phantom      = 8,
		rangedWSmax  = 15.8,
		quickDraw    = 17.5,
		detonatorMax = 17.7,
	},
};

local playerJob    = AshitaCore:GetMemoryManager():GetPlayer();
local playerAmmo   = AshitaCore:GetMemoryManager():GetInventory();
local playerWeapon = AshitaCore:GetMemoryManager():GetInventory();
local printedOnce = false;
local printedId = nil;

local function getJob(jobId)
	local job = jobs[jobId];
	if job == nil then
		return "";
	end
	return job;
end;

local function getRanged(slot)
    local inventory = AshitaCore:GetMemoryManager():GetInventory(); 
    local equipment = inventory:GetEquippedItem(slot);
    if equipment == nil then
        return ranged[0]
    else
        local iitem = inventory:GetContainerItem(bit.band(equipment.Index, 0xFF00) / 0x0100, equipment.Index % 0x0100);

        -- Handles equipment/ammunition in different inventories (i.e. backpack, mog wardrobes)
        -- Error checks for nil values and passes "N/A" instead if an entry is not found in the equipment array
        if(iitem == nil or T{ nil, 0, -1, 65535 }:hasval(iitem.Id)) then return ranged[0]; end
        
        return ranged[iitem.Id] or 'N/A';
    end
end;

targetbar.DrawWindow = function(settings)
    -- Obtain the player entity..
    local playerEnt = GetPlayerEntity();
	local player = AshitaCore:GetMemoryManager():GetPlayer();
    if (playerEnt == nil or player == nil) then
		UpdateTextVisibility(false);
        return;
    end

    -- Obtain the player target entity (account for subtarget)
	local playerTarget = AshitaCore:GetMemoryManager():GetTarget();
	local targetIndex;
	local targetEntity;
	if (playerTarget ~= nil) then
		targetIndex, _ = GetTargets();
		targetEntity = GetEntity(targetIndex);
	end
    if (targetEntity == nil or targetEntity.Name == nil) then
		UpdateTextVisibility(false);
        for i=1,32 do
            local textObjName = "debuffText" .. tostring(i)
            textObj = AshitaCore:GetFontManager():Get(textObjName)
            if textObj then
                textObj:SetVisible(false)
            end
        end
		targetbar.interpolation.interpolationDamagePercent = 0;

        return;
    end

	local currentTime = os.clock();

	local hppPercent = targetEntity.HPPercent;

	-- Mimic damage taken
	if _HXUI_DEV_DEBUG_INTERPOLATION then
		if _HXUI_DEV_DAMAGE_SET_TIMES[1] and currentTime > _HXUI_DEV_DAMAGE_SET_TIMES[1][1] then
			_HXUI_DEV_DEBUG_HP_PERCENT_PERSISTENT = _HXUI_DEV_DAMAGE_SET_TIMES[1][2];

			table.remove(_HXUI_DEV_DAMAGE_SET_TIMES, 1);
		end

		if #_HXUI_DEV_DAMAGE_SET_TIMES == 0 then
			local previousHitTime = currentTime + 1;
			local previousHp = 100;

			local totalDamageInstances = 10;

			for i = 1, totalDamageInstances do
				local hitDelay = math.random(0.25 * 100, 1.25 * 100) / 100;
				local damageAmount = math.random(1, 20);

				if i > 1 and i < totalDamageInstances then
					previousHp = math.max(previousHp - damageAmount, 0);
				end

				if i < totalDamageInstances then
					previousHitTime = previousHitTime + hitDelay;
				else
					previousHitTime = previousHitTime + _HXUI_DEV_DEBUG_INTERPOLATION_DELAY;
				end

				_HXUI_DEV_DAMAGE_SET_TIMES[i] = {previousHitTime, previousHp};
			end
		end

		hppPercent = _HXUI_DEV_DEBUG_HP_PERCENT_PERSISTENT;
	end

	-- If we change targets, reset the interpolation
	if targetbar.interpolation.currentTargetId ~= targetIndex then
		targetbar.interpolation.currentTargetId = targetIndex;
		targetbar.interpolation.currentHpp = hppPercent;
		targetbar.interpolation.interpolationDamagePercent = 0;
	end

	-- If the target takes damage
	if hppPercent < targetbar.interpolation.currentHpp then
		local previousInterpolationDamagePercent = targetbar.interpolation.interpolationDamagePercent;

		local damageAmount = targetbar.interpolation.currentHpp - hppPercent;

		targetbar.interpolation.interpolationDamagePercent = targetbar.interpolation.interpolationDamagePercent + damageAmount;

		if previousInterpolationDamagePercent > 0 and targetbar.interpolation.lastHitAmount and damageAmount > targetbar.interpolation.lastHitAmount then
			targetbar.interpolation.lastHitTime = currentTime;
			targetbar.interpolation.lastHitAmount = damageAmount;
		elseif previousInterpolationDamagePercent == 0 then
			targetbar.interpolation.lastHitTime = currentTime;
			targetbar.interpolation.lastHitAmount = damageAmount;
		end

		if not targetbar.interpolation.lastHitTime or currentTime > targetbar.interpolation.lastHitTime + (settings.hitFlashDuration * 0.25) then
			targetbar.interpolation.lastHitTime = currentTime;
			targetbar.interpolation.lastHitAmount = damageAmount;
		end

		-- If we previously were interpolating with an empty bar, reset the hit delay effect
		if previousInterpolationDamagePercent == 0 then
			targetbar.interpolation.hitDelayStartTime = currentTime;
		end
	elseif hppPercent > targetbar.interpolation.currentHpp then
		-- If the target heals
		targetbar.interpolation.interpolationDamagePercent = 0;
		targetbar.interpolation.hitDelayStartTime = nil;
	end

	targetbar.interpolation.currentHpp = hppPercent;

	-- Reduce the HP amount to display based on the time passed since last frame
	if targetbar.interpolation.interpolationDamagePercent > 0 and targetbar.interpolation.hitDelayStartTime and currentTime > targetbar.interpolation.hitDelayStartTime + settings.hitDelayDuration then
		if targetbar.interpolation.lastFrameTime then
			local deltaTime = currentTime - targetbar.interpolation.lastFrameTime;

			local animSpeed = 0.1 + (0.9 * (targetbar.interpolation.interpolationDamagePercent / 100));

			-- animSpeed = math.max(settings.hitDelayMinAnimSpeed, animSpeed);

			targetbar.interpolation.interpolationDamagePercent = targetbar.interpolation.interpolationDamagePercent - (settings.hitInterpolationDecayPercentPerSecond * deltaTime * animSpeed);

			-- Clamp our percent to 0
			targetbar.interpolation.interpolationDamagePercent = math.max(0, targetbar.interpolation.interpolationDamagePercent);
		end
	end

	if gConfig.healthBarFlashEnabled then
		if targetbar.interpolation.lastHitTime and currentTime < targetbar.interpolation.lastHitTime + settings.hitFlashDuration then
			local hitFlashTime = currentTime - targetbar.interpolation.lastHitTime;
			local hitFlashTimePercent = hitFlashTime / settings.hitFlashDuration;

			local maxAlphaHitPercent = 20;
			local maxAlpha = math.min(targetbar.interpolation.lastHitAmount, maxAlphaHitPercent) / maxAlphaHitPercent;

			maxAlpha = math.max(maxAlpha * 0.6, 0.4);

			targetbar.interpolation.overlayAlpha = math.pow(1 - hitFlashTimePercent, 2) * maxAlpha;
		end
	end

	targetbar.interpolation.lastFrameTime = currentTime;

	local color = GetColorOfTarget(targetEntity, targetIndex);
	local isMonster = GetIsMob(targetEntity);

	-- Draw the main target window
	local windowFlags = bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav, ImGuiWindowFlags_NoBackground, ImGuiWindowFlags_NoBringToFrontOnFocus);
	if (gConfig.lockPositions) then
		windowFlags = bit.bor(windowFlags, ImGuiWindowFlags_NoMove);
	end
    if (imgui.Begin('TargetBar', true, windowFlags)) then
        
		-- Obtain and prepare target information..
        local dist  = ('%.1f'):fmt(math.sqrt(targetEntity.Distance));
		local targetNameText = targetEntity.Name;
		local targetHpPercent = targetEntity.HPPercent..'%';

		if (gConfig.showEnemyId and isMonster) then
			local targetServerId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);
			local targetServerIdHex = string.format('0x%X', targetServerId);

			targetNameText = targetNameText .. " [".. string.sub(targetServerIdHex, -3) .."]";
		end

		local hpGradientStart = '#e26c6c';
		local hpGradientEnd = '#fb9494';

		local hpPercentData = {{targetEntity.HPPercent / 100, {hpGradientStart, hpGradientEnd}}};

		if _HXUI_DEV_DEBUG_INTERPOLATION then
			hpPercentData[1][1] = targetbar.interpolation.currentHpp / 100;
		end

		if targetbar.interpolation.interpolationDamagePercent > 0 then
			local interpolationOverlay;

			if gConfig.healthBarFlashEnabled then
				interpolationOverlay = {
					'#FFFFFF', -- overlay color,
					targetbar.interpolation.overlayAlpha -- overlay alpha,
				};
			end

			table.insert(
				hpPercentData,
				{
					targetbar.interpolation.interpolationDamagePercent / 100, -- interpolation percent
					{'#cf3437', '#c54d4d'},
					interpolationOverlay
				}
			);
		end
		
		local startX, startY = imgui.GetCursorScreenPos();
		progressbar.ProgressBar(hpPercentData, {settings.barWidth, settings.barHeight}, {decorate = gConfig.showTargetBarBookends});

		local nameSize = SIZE.new();
		nameText:GetTextSize(nameSize);

		nameText:SetPositionX(startX + settings.barHeight / 2 + settings.topTextXOffset);
		nameText:SetPositionY(startY - settings.topTextYOffset - nameSize.cy);
		nameText:SetColor(color);
		nameText:SetText(targetNameText);
		nameText:SetVisible(true);

		local distSize = SIZE.new();
		distText:GetTextSize(distSize);

		distText:SetPositionX(startX + settings.barWidth - settings.barHeight / 2 - settings.topTextXOffset);
		distText:SetPositionY(startY - settings.topTextYOffset - distSize.cy);
        
        local distnum = tonumber(dist)
        
        if (distnum < 20.7) then
            distText:SetColor(4284177919)
        elseif (distnum < 21.7) then
            distText:SetColor(4294967151)
        else
            distText:SetColor(colors.white)
        end
        
        local mainJob = getJob(playerJob:GetMainJob());
        
        -- Get the player's current sub job..
        local subJob = getJob(playerJob:GetSubJob());
        
        -- Get the player's currently equipped ranged type..
        local rangedEq = getRanged(3);
        if (rangedEq == 'N/A') then
            rangedEq = getRanged(2);
        end
        
        if (rangedEq ~= 'N/A') then
            if (distnum < distances[rangedEq].FalloffNear) then
                distText:SetColor(colors.orange);
            elseif (distnum < distances[rangedEq].OptimalMin) then
                distText:SetColor(colors.yellow);
            elseif (distnum < distances[rangedEq].OptimalMax) then
                distText:SetColor(colors.green);
            elseif (distnum < distances[rangedEq].FalloffFar) then
                distText:SetColor(colors.yellow);
            elseif (distnum < distances[rangedEq].maxRange) then
                distText:SetColor(colors.orange);
            elseif (distnum > distances[rangedEq].maxRange) then
                distText:SetColor(colors.gray);
            else
                distText:SetColor(colors.white);
            end
        end
        
        distText:GetBackground():SetColor(4278190080);
        distText:GetBackground():SetVisible(true);
		distText:SetText(tostring(dist));
		distText:SetVisible(true);

		if (isMonster or gConfig.alwaysShowHealthPercent) then
			percentText:SetPositionX(startX + settings.barWidth - settings.barHeight / 2 - settings.bottomTextXOffset);
			percentText:SetPositionY(startY + settings.barHeight + settings.bottomTextYOffset);
			percentText:SetText(tostring(targetHpPercent));
			percentText:SetVisible(true);
			local hpColor, _ = GetHpColors(targetEntity.HPPercent / 100);
			percentText:SetColor(hpColor);
		else
			percentText:SetVisible(false);
		end

		-- Draw buffs and debuffs
		imgui.SameLine();
		local preBuffX, preBuffY = imgui.GetCursorScreenPos();
		local buffIds;
        local buffTimes = nil;
		if (targetEntity == playerEnt) then
			buffIds = player:GetBuffs();
		elseif (IsMemberOfParty(targetIndex)) then
			buffIds = statusHandler.get_member_status(playerTarget:GetServerId(0));
		else
			buffIds, buffTimes = debuffHandler.GetActiveDebuffs(playerTarget:GetServerId(0));
		end
		imgui.NewLine();
		imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, {1, 3});
        for i=1,32 do
            local textObjName = "debuffText" .. tostring(i)
            textObj = AshitaCore:GetFontManager():Get(textObjName)
            if textObj then
                textObj:SetVisible(false)
            end
        end
		DrawStatusIcons(buffIds, settings.iconSize, settings.maxIconColumns, 3, false, settings.barHeight/2, buffTimes, settings.distance_font_settings);
		imgui.PopStyleVar(1);

		-- Obtain our target of target (not always accurate)
		local totEntity;
		local totIndex
		if (targetEntity == playerEnt) then
			totIndex = targetIndex
			totEntity = targetEntity;
		end
		if (totEntity == nil) then
			totIndex = targetEntity.TargetedIndex;
			if (totIndex ~= nil) then
				totEntity = GetEntity(totIndex);
			end
		end
		if (totEntity ~= nil and totEntity.Name ~= nil) then

			imgui.SetCursorScreenPos({preBuffX, preBuffY});
			local totX, totY = imgui.GetCursorScreenPos();
			local totColor = GetColorOfTarget(totEntity, totIndex);
			imgui.SetCursorScreenPos({totX, totY + settings.barHeight/2 - settings.arrowSize/2});
			imgui.Image(tonumber(ffi.cast("uint32_t", arrowTexture.image)), { settings.arrowSize, settings.arrowSize });
			imgui.SameLine();

			totX, _ = imgui.GetCursorScreenPos();
			imgui.SetCursorScreenPos({totX, totY - (settings.totBarHeight / 2) + (settings.barHeight/2) + settings.totBarOffset});

			local totStartX, totStartY = imgui.GetCursorScreenPos();
			progressbar.ProgressBar({{totEntity.HPPercent / 100, {'#e16c6c', '#fb9494'}}}, {settings.barWidth / 3, settings.totBarHeight}, {decorate = gConfig.showTargetBarBookends});

			local totNameSize = SIZE.new();
			totNameText:GetTextSize(totNameSize);

			totNameText:SetPositionX(totStartX + settings.barHeight / 2);
			totNameText:SetPositionY(totStartY - totNameSize.cy);
			totNameText:SetColor(totColor);
			totNameText:SetText(totEntity.Name);
			totNameText:SetVisible(true);
		else
			totNameText:SetVisible(false);
		end
    end
	local winPosX, winPosY = imgui.GetWindowPos();
    imgui.End();
end

targetbar.Initialize = function(settings)
    percentText = fonts.new(settings.percent_font_settings);
	nameText = fonts.new(settings.name_font_settings);
	totNameText = fonts.new(settings.totName_font_settings);
	distText = fonts.new(settings.distance_font_settings);
    -- debuffTimeText = fonts.new(settings.distance_font_settings);
	arrowTexture = 	LoadTexture("arrow");
end

targetbar.UpdateFonts = function(settings)
    percentText:SetFontHeight(settings.percent_font_settings.font_height);
	nameText:SetFontHeight(settings.name_font_settings.font_height);
	distText:SetFontHeight(settings.distance_font_settings.font_height);
	totNameText:SetFontHeight(settings.totName_font_settings.font_height);
end

targetbar.SetHidden = function(hidden)
	if (hidden == true) then
		UpdateTextVisibility(false);
	end
end



return targetbar;