-- youtube-stats.lua
--
-- This script shows youtube video stats
-- using data from https://returnyoutubedislike.com

-- Press the 'H' key to show video stats

-- Also check out this amazing plugin 'https://codeberg.org/jouni/mpv_sponsorblock_minimal'

server = "https://returnyoutubedislikeapi.com/votes?"

function print_stats()
	local video_path = mp.get_property("path", "")
	local video_referer = string.match(mp.get_property("http-header-fields", ""), "Referer:([^,]+)") or ""

	local urls = {
		"https?://youtu%.be/([%w-_]+).*",
		"https?://w?w?w?%.?youtube%.com/v/([%w-_]+).*",
		"/watch.*[?&]v=([%w-_]+).*",
		"/embed/([%w-_]+).*",
		"-([%w-_]+)%."
	}
	youtube_id = nil
	local purl = mp.get_property("metadata/by-key/PURL", "")
	for i,url in ipairs(urls) do
		youtube_id = youtube_id or string.match(video_path, url) or string.match(video_referer, url) or string.match(purl, url)
	end

	if not youtube_id or string.len(youtube_id) < 11 then return end
	youtube_id = string.sub(youtube_id, 1, 11)

	local luacurl_available, cURL = pcall(require,'cURL')
	local vstr = ("videoID=%s"):format(youtube_id)

	if not(luacurl_available) then -- if Lua-cURL is not available on this system
		local API = server .. vstr
		local curl_cmd = {
			"curl",
			"-L",
			"-s",
			"-G",
			API
		}
		print("Requesting:", API)
		local call = mp.command_native{
			name = "subprocess",
			capture_stdout = true,
			playback_only = false,
			args = curl_cmd
		}
		res = call.stdout

	-- NEEDS TESTING IF LUA-CURL IS AVAILABLE!
	else -- otherwise use Lua-cURL (binding to libcurl)
		local API = server .. vstr
		print("Requesting: ", API)
		local buf={}
		local c = cURL.easy_init()
		c:setopt_followlocation(1)
		c:setopt_url(API)
		c:setopt_writefunction(function(chunk) table.insert(buf,chunk); return true; end)
		c:perform()
		res = table.concat(buf)
	end
	-- TO HERE

	L = "return "..res:gsub('("[^"]-"):','[%1]=')
	data = loadstring(L)()
	
    mp.osd_message("Likes: " .. numformat(data.likes) .. "\nDislikes: " .. numformat(data.dislikes) .. "\nRatio: " .. string.sub(data.rating,1,3) .. "/5\nViews: " .. numformat(data.viewCount), 5)
end

mp.add_key_binding("h", "print_stats", print_stats)


-- Thank you "https://authors.curseforge.com/forums/world-of-warcraft/general-chat/lua-code-discussion/225712-number-format-with-commas?comment=6"
function numformat(number)
    if number < 0 or number == 0 or not number then
        return 0
    elseif number > 0 and number < 1000000 then 
        local t = {}
        thousands = '.'
        decimal = ','
        local int = math.floor(number)
        local rest = number % 1
        if int == 0 then
            t[#t+1] = 0
        else
            local digits = math.log10(int)
            local segments = math.floor(digits / 3)
            t[#t+1] = math.floor(int / 1000^segments)
            for i = segments-1, 0, -1 do
                t[#t+1] = thousands
                t[#t+1] = ("%03d"):format(math.floor(int / 1000^i) % 1000)
            end
        end
        if rest ~= 0 then
            t[#t+1] = decimal
            rest = math.floor(rest * 10^6)
            while rest % 10 == 0 do
                rest = rest / 10
            end
            t[#t+1] = rest
        end
        local s = table.concat(t)
        return s
    elseif number >= 1000000 and number < 1000000000 then
        return format("%.1f|cff93E74F%s|r", number * 0.000001, "m")
    elseif number >= 1000000000 then 
        return format("%.1f|cff93E74F%s|r", number * 0.000000001, "bil")
    else
        return number
    end
end
