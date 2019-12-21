
stub = stub or {}


function on_player_send_chat_message(msg)
	local player = actor_manager_fetch_local_player()
	player:Say(msg)
	clear_chat_text_cache()

	local req = {}
	req.pid = player:GetID()
	req.msg = msg
	net_send_message(PTO_C2C_CHAT, cjson.encode(req))
end


stub[PTO_C2C_PLAYER_ENTER] = function(req)
	for i,actor_info in ipairs(req.actors) do
		local actor = actor_manager_create_actor(actor_info[tostring(PROP_ID)])
		actor:SetProperties(actor_info)

		actor_reg_event(actor, ACTOR_EV_ON_CLICK, actor_ev_on_click)
		actor_reg_event(actor, ACTOR_EV_ON_HOVER, function(actor, x, y)
			
		end)
	end
	if req.local_pid then
		actor_manager_set_local_player(req.local_pid)
		local player = actor_manager_fetch_player_by_id(req.local_pid)
		scene_manager_switch_scene_by_id(player:GetProperty(PROP_SCENE_ID))	
	end
end

stub[PTO_C2C_CHAT] = function(req)
	local player = actor_manager_fetch_player_by_id(req.pid)
	if not player:IsLocal() then
		player:Say(req.msg)
	end
end

stub[PTO_C2C_MOVE_TO_POS] = function(req)
	local player = actor_manager_fetch_player_by_id(req.pid)
	if not player:IsLocal() then
		player:MoveTo(req.x,req.y)
	end
end

stub[PTO_S2C_SYNC_PROPS] = function(req)
	for i, dirty_prop in ipairs(req) do
		local pid = dirty_prop[1]
		local p = actor_manager_fetch_player_by_id(pid)
		if p then
			p:SetProperty(dirty_prop[2] ,dirty_prop[3])
			cxlog_info(' p ',p, ' propid ', prop_id_to_name( dirty_prop[2]) ,dirty_prop[3])
		end
	end
end


function game_dispatch_message(pt)
	local type = pt:ReadAsInt()
	local js = pt:ReadAllAsString()
	local req = cjson.decode(js)
	cxlog_info('game_dispatch_message', type, js)
	if stub[type] then
		stub[type](req)
	end
end

function net_manager_stub()
	return stub
end

