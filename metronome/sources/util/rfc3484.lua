-- * Metronome IM *
--
-- This file is part of the Metronome XMPP server and is released under the
-- ISC License, please see the LICENSE file in this source package for more
-- information about copyright and licensing.
--
-- As per the sublicensing clause, this file is also MIT/X11 Licensed.
-- ** Copyright (c) 2011-2012, Florian Zeitz, Kim Alvefur

local commonPrefixLength = require"util.ip".commonPrefixLength
local new_ip = require"util.ip".new_ip;

local function t_sort(t, comp)
	for i = 1, (#t - 1) do
		for j = (i + 1), #t do
			local a, b = t[i], t[j];
			if not comp(a,b) then
				t[i], t[j] = b, a;
			end
		end
	end
end

local function source(dest, candidates)
	local function comp(ipA, ipB)
		-- Rule 1: Prefer same address
		if dest == ipA then
			return true;
		elseif dest == ipB then
			return false;
		end

		-- Rule 2: Prefer appropriate scope
		if ipA.scope < ipB.scope then
			if ipA.scope < dest.scope then
				return false;
			else
				return true;
			end
		elseif ipA.scope > ipB.scope then
			if ipB.scope < dest.scope then
				return true;
			else
				return false;
			end
		end

		-- Rule 3: Avoid deprecated addresses
		-- XXX: No way to determine this
		-- Rule 4: Prefer home addresses
		-- XXX: Mobility Address related, no way to determine this
		-- Rule 5: Prefer outgoing interface
		-- XXX: Interface to address relation. No way to determine this
		-- Rule 6: Prefer matching label
		if ipA.label == dest.label and ipB.label ~= dest.label then
			return true;
		elseif ipB.label == dest.label and ipA.label ~= dest.label then
			return false;
		end

		-- Rule 7: Prefer public addresses (over temporary ones)
		-- XXX: No way to determine this
		-- Rule 8: Use longest matching prefix
		if commonPrefixLength(ipA, dest) > commonPrefixLength(ipB, dest) then
			return true;
		else
			return false;
		end
	end

	t_sort(candidates, comp);
	return candidates[1];
end

local function destination(candidates, sources)
	local sourceAddrs = {};
	local function comp(ipA, ipB)
		local ipAsource = sourceAddrs[ipA];
		local ipBsource = sourceAddrs[ipB];
		-- Rule 1: Avoid unusable destinations
		-- XXX: No such information
		-- Rule 2: Prefer matching scope
		if ipA.scope == ipAsource.scope and ipB.scope ~= ipBsource.scope then
			return true;
		elseif ipA.scope ~= ipAsource.scope and ipB.scope == ipBsource.scope then
			return false;
		end

		-- Rule 3: Avoid deprecated addresses
		-- XXX: No way to determine this
		-- Rule 4: Prefer home addresses
		-- XXX: Mobility Address related, no way to determine this
		-- Rule 5: Prefer matching label
		if ipAsource.label == ipA.label and ipBsource.label ~= ipB.label then
			return true;
		elseif ipBsource.label == ipB.label and ipAsource.label ~= ipA.label then
			return false;
		end

		-- Rule 6: Prefer higher precedence
		if ipA.precedence > ipB.precedence then
			return true;
		elseif ipA.precedence < ipB.precedence then
			return false;
		end

		-- Rule 7: Prefer native transport
		-- XXX: No way to determine this
		-- Rule 8: Prefer smaller scope
		if ipA.scope < ipB.scope then
			return true;
		elseif ipA.scope > ipB.scope then
			return false;
		end

		-- Rule 9: Use longest matching prefix
		if commonPrefixLength(ipA, ipAsource) > commonPrefixLength(ipB, ipBsource) then
			return true;
		elseif commonPrefixLength(ipA, ipAsource) < commonPrefixLength(ipB, ipBsource) then
			return false;
		end

		-- Rule 10: Otherwise, leave order unchanged
		return true;
	end
	for _, ip in ipairs(candidates) do
		sourceAddrs[ip] = source(ip, sources);
	end

	t_sort(candidates, comp);
	return candidates;
end

return {source = source,
	destination = destination};
