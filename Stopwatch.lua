-- Stopwatch TBC backport to 1.12 by Zerf

-- speed optimizations (mostly so update functions are faster)
local _G = getfenv(0);
local date = _G.date;
local abs = _G.abs;
local min = _G.min;
local max = _G.max;
local floor = _G.floor;
local mod = _G.mod;
local tonumber = _G.tonumber;
local gsub = _G.gsub;
local GetGameTime = _G.GetGameTime;

local STOPWATCH_TIME_UNIT = "%02d";

-- private data
local SEC_TO_MINUTE_FACTOR = 1/60;
local SEC_TO_HOUR_FACTOR = SEC_TO_MINUTE_FACTOR*SEC_TO_MINUTE_FACTOR;
MAX_TIMER_SEC = 99*3600 + 59*60 + 59;	-- 99:59:59

function Stopwatch_Toggle()
	if ( StopwatchFrame:IsShown() ) then
		StopwatchFrame:Hide();
	else
		StopwatchFrame:Show();
	end
end

function Stopwatch_ShowCountdown(hour, minute, second)
	local sec = 0;
	if ( hour ) then
		sec = hour * 3600;
	end
	if ( minute ) then
		sec = sec + minute * 60;
	end
	if ( second ) then
		sec = sec + second;
	end
	if ( sec == 0 ) then
		Stopwatch_Toggle();
		return;
	end
	if ( sec > MAX_TIMER_SEC ) then
		StopwatchTicker.timer = MAX_TIMER_SEC;
	elseif ( sec < 0 ) then
		StopwatchTicker.timer = 0;
	else
		StopwatchTicker.timer = sec;
	end
	StopwatchTicker_Update();
	StopwatchTicker.reverse = sec > 0;
	StopwatchFrame:Show();
end

function Stopwatch_FinishCountdown()
	Stopwatch_Clear();
end

function StopwatchCloseButton_OnClick()
	StopwatchFrame:Hide();
end

function Stopwatch_Command(msg)
	if (msg == "reset-position") then
		StopwatchFrame:ClearAllPoints();
		StopwatchFrame:SetPoint("TOPRIGHT", "UIParent", "TOPRIGHT", -250, -300);
		StopwatchFrame:Show();
	elseif (msg == "reset") then
		Stopwatch_Pause();
		Stopwatch_Clear();
	elseif (msg == "play") then
		StopwatchFrame:Show();
		Stopwatch_Clear();
		Stopwatch_Play();
	elseif (msg == "pause") then
		StopwatchFrame:Show();
		Stopwatch_Pause();
	else -- check for countdown
		local found,_, hour, minute, second = string.find(msg, "(%d+):(%d+):(%d+)");
		if(found) then
			Stopwatch_ShowCountdown(tonumber(hour), tonumber(minute), tonumber(second));
			Stopwatch_Play();
		else
			local found,_, minute, second = string.find(msg, "(%d+):(%d+)");
			if(found) then
				Stopwatch_ShowCountdown(0, tonumber(minute), tonumber(second));
				Stopwatch_Play();
			else
				local found,_, second = string.find(msg, "(%d+)");
				if(found) then
					Stopwatch_ShowCountdown(0, 0, tonumber(second));
					Stopwatch_Play();
				else
					Stopwatch_Toggle();
				end
			end
		end
	end
end


function StopwatchFrame_OnLoad()
	SLASH_STOPWATCH1 = "/stopwatch";
	SLASH_STOPWATCH2 = "/timer";
	SlashCmdList["STOPWATCH"] = Stopwatch_Command;

	this:RegisterForDrag("LeftButton");
	Stopwatch_Clear();
end

function StopwatchFrame_OnDragStart()
	StopwatchFrame:StartMoving();
end

function StopwatchFrame_OnDragStop()
	StopwatchFrame:StopMovingOrSizing();
end

function StopwatchTicker_OnUpdate()
	if ( StopwatchTicker.reverse ) then
		StopwatchTicker.timer = StopwatchTicker.timer - arg1;
		if ( StopwatchTicker.timer <= 0 ) then
			Stopwatch_FinishCountdown();
			return;
		end
	else
		StopwatchTicker.timer = StopwatchTicker.timer + arg1;
	end
	StopwatchTicker_Update();
end

function StopwatchTicker_Update()
	local timer = StopwatchTicker.timer;
	local hour = min(floor(timer*SEC_TO_HOUR_FACTOR), 99);
	local minute = mod(timer*SEC_TO_MINUTE_FACTOR, 60);
	local second = mod(timer, 60);
	
	StopwatchTickerHour:SetText(string.format(STOPWATCH_TIME_UNIT, hour));
	StopwatchTickerMinute:SetText(string.format(STOPWATCH_TIME_UNIT, minute));
	StopwatchTickerSecond:SetText(string.format(STOPWATCH_TIME_UNIT, second));
end

function Stopwatch_Play()
	StopwatchPlayPauseButton.playing = true;
	StopwatchTicker:SetScript("OnUpdate", StopwatchTicker_OnUpdate);
	StopwatchPlayPauseButton:SetNormalTexture("Interface\\AddOns\\Stopwatch\\textures\\PauseButton");
end

function Stopwatch_Pause()
	StopwatchPlayPauseButton.playing = false;
	StopwatchTicker:SetScript("OnUpdate", nil);
	StopwatchPlayPauseButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
end

function Stopwatch_IsPlaying()
	return StopwatchPlayPauseButton.playing;
end

function Stopwatch_Clear()
	StopwatchTicker.timer = 0;
	StopwatchTicker.reverse = false;
	StopwatchTicker:SetScript("OnUpdate", nil);
	StopwatchTicker_Update();
	StopwatchPlayPauseButton.playing = false;
	StopwatchPlayPauseButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
end

function StopwatchResetButton_OnClick()
	Stopwatch_Clear();
end

function StopwatchPlayPauseButton_OnClick()
	if ( StopwatchPlayPauseButton.playing ) then
		Stopwatch_Pause();
	else
		Stopwatch_Play();
	end
end

