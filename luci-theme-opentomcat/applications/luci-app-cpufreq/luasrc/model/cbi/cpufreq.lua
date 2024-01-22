local fs = require "nixio.fs"

string.split = require ("luci.util").split

mp = Map("cpufreq", translate("CPU Freq Settings"))
mp.description = translate("Set CPU Scaling Governor to Max Performance or Balance Mode")

s = mp:section(NamedSection, "cpufreq", "settings")

local policy_nums = luci.sys.exec("echo -n $(find /sys/devices/system/cpu/cpufreq/policy* -maxdepth 0 | grep -Eo '[0-9]+')")
for _, policy_num in ipairs(policy_nums:split(" ")) do
	if not fs.access("/sys/devices/system/cpu/cpufreq/policy" .. policy_num .. "/scaling_available_frequencies") then return end

	cpu_freqs = fs.readfile("/sys/devices/system/cpu/cpufreq/policy" .. policy_num .. "/scaling_available_frequencies")
	cpu_freqs = string.sub(cpu_freqs, 1, -3)

	cpu_governors = fs.readfile("/sys/devices/system/cpu/cpufreq/policy" .. policy_num .. "/scaling_available_governors")
	cpu_governors = string.sub(cpu_governors, 1, -3)


	freq_array = cpu_freqs:split(" ")
	governor_array = cpu_governors:split(" ")

	s:tab(policy_num, translate("Policy " .. policy_num))

	governor = s:taboption(policy_num, ListValue, "governor" .. policy_num, translate("CPU Scaling Governor"))
	for _, e in ipairs(governor_array) do
		if e ~= "" then governor:value(e, translate(e, string.upper(e))) end
	end

	minfreq = s:taboption(policy_num, ListValue, "minfreq" .. policy_num, translate("Min Idle CPU Freq"))
	for _, e in ipairs(freq_array) do
		if e ~= "" then minfreq:value(e) end
	end

	maxfreq = s:taboption(policy_num, ListValue, "maxfreq" .. policy_num, translate("Max Turbo Boost CPU Freq"))
	for _, e in ipairs(freq_array) do
		if e ~= "" then maxfreq:value(e) end
	end

	sdfactor = s:taboption(policy_num, Value, "sdfactor" .. policy_num, translate("CPU Switching Sampling rate"))
	sdfactor.datatype="range(1,100000)"
	sdfactor.description = translate("The sampling rate determines how frequently the governor checks to tune the CPU (ms)")
	sdfactor.placeholder = 10
	sdfactor.default = 10
	sdfactor:depends("governor" .. policy_num, "ondemand")

	upthreshold = s:taboption(policy_num, Value, "upthreshold" .. policy_num, translate("CPU Switching Threshold"))
	upthreshold.datatype="range(1,99)"
	upthreshold.description = translate("Kernel make a decision on whether it should increase the frequency (%)")
	upthreshold.placeholder = 50
	upthreshold.default = 50
	upthreshold:depends("governor" .. policy_num, "ondemand")
end

return mp
