/* 
	------------------------------------------------------------------------------------------
	EntControl::BaseNPC
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

//#define DEBUG

//new gDebugBeam;
int gBlood1;
int gBloodDrop1;
int player; // Can be global ;)
int gNPCCount;
int gLastKilledNPC;

public void InitBaseNPC()
{
	PrecacheModel("models/blackout.mdl");
	
	//gDebugBeam = PrecacheModel("materials/sprites/laser.vmt");
	gBlood1 = PrecacheModel("sprites/bloodspray.vmt");
	gBloodDrop1 = PrecacheModel("sprites/blood.vmt");
	
	HookEvent("hostage_hurt", OnHostageHurt, EventHookMode_Pre);
	HookEvent("hostage_follows", OnHostageFollows, EventHookMode_Pre);
	HookEvent("hostage_stops_following", OnHostageStopsFollowing, EventHookMode_Pre);
	HookEvent("hostage_killed", OnHostageKilled, EventHookMode_Pre);
	
	// Hook hostage-sound
	AddNormalSoundHook(view_as<NormalSHook>(BaseNPC_HookHostageSound));
	
	#if defined DEBUG
		LogMessage("InitBaseNPC()");
	#endif
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_Spawn
	------------------------------------------------------------------------------------------
*/
stock int BaseNPC_Spawn(float vEntPosition[3], char model[128], Timer func, char classname[32] = "", char[] idleAnimation = "idle", int owner = 0)
{
	char entIndex_tmp[16];
	int health;
	float thinkrate, friction;
	
	BaseNPC_LoadMonsterConfig(classname, thinkrate, friction, health);
	
	int monster = CreateEntityByName("hostage_entity");
	int monster_tmp = CreateEntityByName("prop_dynamic_ornament"); // prop_dynamic_ornament
	
	IntToString(EntIndexToEntRef(monster_tmp), entIndex_tmp, sizeof(entIndex_tmp)-1);
	
	DispatchKeyValue(monster, "classname", classname);
	DispatchKeyValue(monster, "targetname", entIndex_tmp);
	DispatchKeyValue(monster, "disableshadows", "1");
	DispatchKeyValueFloat(monster, "friction", friction);
	DispatchSpawn(monster);
	
	SetEntProp(monster, Prop_Data, "m_iHealth", health);
	
	SetEntityModel(monster, "models/blackout.mdl");
	
	// Create the animated monster
	DispatchKeyValue(monster_tmp, "model", model);
	DispatchKeyValue(monster_tmp, "DefaultAnim", idleAnimation);
	DispatchKeyValue(monster_tmp, "spawnflags", "320");
	DispatchKeyValue(monster_tmp, "parent", entIndex_tmp);
	DispatchSpawn(monster_tmp);
	
	TeleportEntity(monster, vEntPosition, NULL_VECTOR, NULL_VECTOR);
	
	// Parent
	SetVariantString(entIndex_tmp);
	AcceptEntityInput(monster_tmp, "SetAttached");
	
	CreateTimer(thinkrate, func, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.01, BaseNPC_Think, EntIndexToEntRef(monster), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	SDKHook(monster, SDKHook_Touch, BaseNPC_Touch);
	
	if (owner != 0)
		BaseNPC_SetOwner(monster, owner);
	
	gNPCCount++;
	
	#if defined DEBUG
		LogMessage("BaseNPC_Spawn(...,...,...,%s)::Spawn->NPCCount==%i", classname, gNPCCount);
	#endif
	
	return (monster);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SpawnByName
	------------------------------------------------------------------------------------------
*/
public void BaseNPC_SpawnByName(char[] sNPCName, float vEntPosition[3])
{
	if (StrEqual(sNPCName, "npc_antlion"))
		AntLion_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_antlionguard"))
		AntLionGuard_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_barney"))
		Barney_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_dog"))
		Dog_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_gman"))
		GMan_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_headcrab"))
		HeadCrab_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_police"))
		Police_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_soldier"))
		Soldier_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_sentrygun"))
		Sentry_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_vortigaunt"))
		Vortigaunt_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_synth"))
		Synth_Spawn(vEntPosition);
	else if (StrEqual(sNPCName, "npc_zombie"))
		Zombie_Spawn(vEntPosition);
	else
		Zombie_Spawn(vEntPosition);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_IsNPC
	------------------------------------------------------------------------------------------
*/
stock bool BaseNPC_IsNPC(int monster)
{
	if (IsValidEdict(monster) && IsValidEntity(monster))
	{
		char edictname[32];
		GetEdictClassname(monster, edictname, 32);
		
		if (StrContains(edictname, "npc_") == 0)
			return (true);
	}
	
	return (false);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_IsAlive
	------------------------------------------------------------------------------------------
*/
stock bool BaseNPC_IsAlive(int monster)
{
	return (GetEntProp(monster, Prop_Data, "m_iHealth") > 0);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_GetTarget
	------------------------------------------------------------------------------------------
*/
stock int BaseNPC_GetTarget(int monster)
{
	int target = GetEntDataEnt2(monster, gLeaderOffset);
	if (target > 0 && IsClientConnectedIngame(target) && IsPlayerAlive(target))
		return (target);
	
	return (0);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_Think
	------------------------------------------------------------------------------------------
*/
public Action BaseNPC_Think(Handle timer, any monsterRef)
{
	#if defined DEBUG
		LogMessage("BaseNPC_Think()::START");
	#endif

	int monster = EntRefToEntIndex(monsterRef);

	if (monster != INVALID_ENT_REFERENCE)
	{
		if (!BaseNPC_IsAlive(monster) || !notBetweenRounds)
		{
			#if defined DEBUG
				LogMessage("BaseNPC_Think()::HARDSTOP");
			#endif
			
			BaseNPC_Death(monster);
			//RemoveEntity(monster);
			return (Plugin_Stop);
		}
		else
		{
			player = BaseNPC_GetTarget(monster);
			
			if (!player || !BaseNPC_CanSeeEachOther(monster, player))
			{
				int owner = BaseNPC_GetOwner(monster);
				if (owner == player) // Monster cannot go against his owner
					player = 0;
				
				int ownerTeam = -1;
				if (owner)
					ownerTeam = GetClientTeam(owner);
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientConnectedIngame(i) && IsPlayerAlive(i) && (ownerTeam != -1 || (GetClientTeam(i) != ownerTeam)))
					{
						if (BaseNPC_CanSeeEachOther(monster, i))
						{
							if (i != owner)
							{
								SetEntDataEnt2(monster, gLeaderOffset, i);
							
								player = i;
								break;
							}
						}
					}
				}
			}
		}
	}
	else
	{
		#if defined DEBUG
			LogMessage("BaseNPC_Think()::TIMERSTOP");
		#endif
		
		return (Plugin_Stop);
	}
	
	#if defined DEBUG
		LogMessage("BaseNPC_Think()::REPEAT");
	#endif
	
	return (Plugin_Continue);
}

public bool TraceEntityFilterWall(int entity, int contentsMask)
{
	return (entity == 1);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_Touch
	------------------------------------------------------------------------------------------
*/
public Action BaseNPC_Touch(int entity, int other)
{
	#if defined DEBUG
		LogMessage("BaseNPC_Touch()::START");
	#endif
	if (other)
	{
		char edictname[32];
		GetEdictClassname(other, edictname, 32);
		
		if (StrEqual("player", edictname))
		{
			#if defined DEBUG
				char sClientname[32];
				GetClientName(other, sClientname, 32);
				LogMessage("BaseNPC_Touch()::gLeaderOffset==%s", sClientname);
			#endif
			SetEntDataEnt2(entity, gLeaderOffset, other);
		}
	}

	#if defined DEBUG
		LogMessage("BaseNPC_Touch()::END");
	#endif
	
	return (Plugin_Continue);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_Hurt
	------------------------------------------------------------------------------------------
*/
stock bool BaseNPC_Hurt(int monster, int attacker, int damage = 0, char sound[32])
{
	#if defined DEBUG
		LogMessage("BaseNPC_Hurt()::");
		char sClientname[32];
		char sEdictname[32];
		GetClientName(attacker, sClientname, 32);
		GetEdictClassname(monster, sEdictname, 32);
		LogMessage("monster==%s | gLeaderOffset==%s !!!", sEdictname, sClientname);
	#endif
	
	int health = GetEntProp(monster, Prop_Data, "m_iHealth") - damage;
	SetEntProp(monster, Prop_Data, "m_iHealth", health);
	
	float vEntPosition[3];
	float vAngle[3];
	GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
	EmitSoundToAll(sound, monster, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);
	
	if (health <= 0)
	{
		#if defined DEBUG
			LogMessage("BaseNPC_Hurt()::END");
		#endif
		
		return (true);
	}

	char tmp[32];
	GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
	
	vEntPosition[2] += 70.0;
	
	vAngle[0] = GetRandomFloat(-10.0, 10.0);
	vAngle[1] = GetRandomFloat(-10.0, 10.0);
	vAngle[2] = GetRandomFloat(-10.0, 10.0);
	
	// Blood
	TE_SetupBloodSprite(vEntPosition, vAngle, {150, 150, 0, 255}, 5, gBlood1, gBloodDrop1);
	TE_SendToAll();
	TE_SetupBloodSprite(vEntPosition, vAngle, {150, 150, 0, 255}, 6, gBlood1, gBloodDrop1);
	TE_SendToAll();
	TE_SetupBloodSprite(vEntPosition, vAngle, {150, 100, 0, 255}, 7, gBlood1, gBloodDrop1);
	TE_SendToAll();
	TE_SetupBloodSprite(vEntPosition, vAngle, {150, 100, 0, 255}, 8, gBlood1, gBloodDrop1);
	TE_SendToAll();
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	SetVariantString("BloodImpact");
	AcceptEntityInput(StringToInt(tmp), "DispatchEffect"); 
	
	char edictname[32];
	GetEdictClassname(attacker, edictname, 32);
	
	if (StrEqual(edictname, "player") && !GetEntDataEnt2(monster, gLeaderOffset))
		SetEntDataEnt2(monster, gLeaderOffset, attacker);
	
	#if defined DEBUG
		LogMessage("BaseNPC_Hurt()::END");
	#endif
	
	return (false);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_Death
	------------------------------------------------------------------------------------------
*/
stock void BaseNPC_Death(int monster, int attacker = 0, int score = 1)
{
	#if defined DEBUG
		LogMessage("BaseNPC_Death()::START");
	#endif
	
	if (BaseNPC_IsNPC(monster) && monster != gLastKilledNPC)
	{ 
		//SetEntityMoveType(monster, MOVETYPE_VPHYSICS);
		
		//BaseNPC_Dissolve(monster);
		
		char tmp[32];
		GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
		int monster_tmp = EntRefToEntIndex(StringToInt(tmp));
		AcceptEntityInput(monster_tmp, "BecomeRagdoll");
		KillEntity(monster, 1.0);
		
		gNPCCount--;
		gLastKilledNPC = monster;
		
		if (attacker && IsValidEntity(attacker) && IsValidEdict(attacker))
		{
			char monsterClassname[32];
			char attackerClassname[32];
			GetEdictClassname(monster, monsterClassname, 32);
			GetEdictClassname(attacker, attackerClassname, 32);
			
			if (StrEqual(attackerClassname, "player") && IsClientConnected(attacker) && IsClientInGame(attacker))
			{
				SetEntProp(attacker, Prop_Data, "m_iFrags", GetClientFrags(attacker) + score);
				
				int money = GetEntProp(attacker, Prop_Send, "m_iAccount") + 1000 * score;
				if (money <= 16000)
					SetEntProp(attacker, Prop_Send, "m_iAccount", money);
				else
					SetEntProp(attacker, Prop_Send, "m_iAccount", 16000);
				
				char playername[64];
				GetClientName(attacker, playername, 64);
				SendKeyHintTextToAll("%s was killed by %s!\nAround %i NPC(s) left", monsterClassname, playername, gNPCCount);
			}
			else
			{
				if (monster == attacker)
					SendKeyHintTextToAll("%s killed himself!\nAround %i NPC(s) left", monsterClassname, gNPCCount);
				else
					SendKeyHintTextToAll("%s was killed by %s!\nAround %i NPC(s) left", monsterClassname, attackerClassname, gNPCCount);
			}
		}
	}
	#if defined DEBUG
	else
	{
		LogMessage("BaseNPC_Death()::'Is not NPC or was already killed'");
	}
	LogMessage("BaseNPC_Death()::STOP");
	#endif
	
	SDKUnhook(monster, SDKHook_Touch, BaseNPC_Touch);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SetAnimation
	------------------------------------------------------------------------------------------
*/
stock void BaseNPC_SetAnimation(int monster, char animation[32], float animtime = 0.0, float time = 0.0)
{
	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimation()::START");
	#endif
	
	if (time == 0.0)
	{
		char edictname[32];
		GetEdictClassname(monster, edictname, 32);
		if (!IsValidEdict(monster) || !IsValidEntity(monster) || StrContains(edictname, "npc_") == -1)
		{
			LogError("LeGone-NPC-Bug");
			RemoveEntity(monster);
			return;
		}

		if (GetEntPropFloat(monster, Prop_Data, "m_flNextAttack") < GetGameTime())
		{
			char tmp[32];
			GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
			int monster_tmp = EntRefToEntIndex(StringToInt(tmp));
		
			if (IsValidEdict(monster_tmp) && IsValidEntity(monster_tmp))
			{
				SetVariantString(animation);
				AcceptEntityInput(monster_tmp, "SetAnimation");
				
				BaseNPC_SetAnimationTime(monster, GetGameTime() + animtime);
			}
			else
			{
				LogMessage("BaseNPC_SetAnimation->monster_tmp==invalid?!Oo");
				RemoveEntity(monster);
			}
		}
	}
	else
	{
		Handle data;
		CreateDataTimer(time, BaseNPC_SetAnimation_Timer, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, EntIndexToEntRef(monster));
		WritePackFloat(data, animtime);
		WritePackString(data, animation);
	}

	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimation()::END");
	#endif
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SetAnimation_Timer
	------------------------------------------------------------------------------------------
*/
public Action BaseNPC_SetAnimation_Timer(Handle timer, Handle data)
{
	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimation_Timer()::START");
	#endif
	ResetPack(data);
	
	int monster = EntRefToEntIndex(ReadPackCell(data));
	float animtime = ReadPackFloat(data);
	char animation[32];
	ReadPackString(data, animation, sizeof(animation));
	
	if (monster != INVALID_ENT_REFERENCE) 
		BaseNPC_SetAnimation(monster, animation, animtime);
	
	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimation_Timer()::END");
	#endif
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SetAnimationTime
	------------------------------------------------------------------------------------------
*/
stock void BaseNPC_SetAnimationTime(int monster, float time = 0.0)
{
	#if defined DEBUG
		LogMessage("BaseNPC_SetAnimationTime(...)");
	#endif
	SetEntPropFloat(monster, Prop_Data, "m_flNextAttack", time);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_GetOwner
	This will get the owner from the pedmode
	------------------------------------------------------------------------------------------
*/
stock int BaseNPC_GetOwner(int monster)
{
	return (GetEntProp(monster, Prop_Data, "m_iHammerID"));
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_SetOwner
	This will set the owner for the pedmode
	------------------------------------------------------------------------------------------
*/
stock void BaseNPC_SetOwner(int monster, int owner)
{
	#if defined DEBUG
		LogMessage("BaseNPC_SetOwner(...)");
	#endif
	SetEntProp(monster, Prop_Data, "m_iHammerID", owner, 4);
}

/* 
	------------------------------------------------------------------------------------------
	BaseNPC_CanSeeEachOther
	------------------------------------------------------------------------------------------
*/
stock bool BaseNPC_CanSeeEachOther(int monster, int target, float distance = 0.0, float monsterheight = 50.0)
{
	if (IsValidEdict(target) && IsValidEntity(target) && IsClientConnected(target) && IsClientInGame(target) && IsPlayerAlive(target))
	{
		float vMonsterPosition[3];
		float vTargetPosition[3];
		
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vMonsterPosition);
		vMonsterPosition[2] += monsterheight;
		
		GetClientEyePosition(target, vTargetPosition);
		
		if (distance == 0.0 || GetVectorDistance(vMonsterPosition, vTargetPosition, false) < distance)
		{
			Handle trace = TR_TraceRayFilterEx(vMonsterPosition, vTargetPosition, MASK_SOLID_BRUSHONLY, RayType_EndPoint, BaseNPC_TraceFilter);

			if(TR_DidHit(trace))
			{
				CloseHandle(trace);
				return (false);
			}
			
			CloseHandle(trace);

			return (true);
		}
	}
	return (false);
}

public bool BaseNPC_TraceFilter(int entity, int contentsMask, any data)
{
	//if( !entity || entity <= MaxClients || !IsValidEntity(entity) || entity == data) // dont let WORLD, or invalid entities be hit
	if(entity != data)
		return (false);

	return (true);
}

/* 
	------------------------------------------------------------------------------------------
	FindFirstTargetInRange
	------------------------------------------------------------------------------------------
*/
stock int FindFirstTargetInRange(int entity, float vAngle[3], float vEntPosition[3], float entHeight = 60.0)
{
	float vClientPosition[3];
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEntPosition);
	vEntPosition[2] += entHeight;
	
	int owner = BaseNPC_GetOwner(entity);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && owner != i)
		{
			GetClientEyePosition(i, vClientPosition);

			vClientPosition[2] -= 10.0;
			MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
			vClientPosition[2] += 10.0;
			//NormalizeVector(vAngle, vAngle);
			GetVectorAngles(vAngle, vAngle);
			
			Handle trace = TR_TraceRayFilterEx(vEntPosition, vClientPosition, MASK_SHOT, RayType_EndPoint, TraceASDF, entity);
			if(!TR_DidHit(trace))
			{
				CloseHandle(trace);
				
				return (i);
			}
			CloseHandle(trace);
		}
	}
	
	return (-1);
}

/* 
	------------------------------------------------------------------------------------------
	IsTargetInRange
	------------------------------------------------------------------------------------------
*/
stock bool IsTargetInRange(int entity, int client, float vAngle[3], float vEntPosition[3], float entHeight = 60.0)
{
	float vClientPosition[3];
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEntPosition);
	vEntPosition[2] += entHeight;
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{	
		GetClientEyePosition(client, vClientPosition);

		vClientPosition[2] -= 10.0;
		MakeVectorFromPoints(vEntPosition, vClientPosition, vAngle);
		vClientPosition[2] += 10.0;
		//NormalizeVector(vAngle, vAngle);
		GetVectorAngles(vAngle, vAngle);
		
		Handle trace = TR_TraceRayFilterEx(vEntPosition, vClientPosition, MASK_SHOT, RayType_EndPoint, TraceASDF, entity);
		if(!TR_DidHit(trace))
		{
			CloseHandle(trace);
			
			return (true);
		}
		
		CloseHandle(trace);
	}
	
	return (false);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_Dissolve
	------------------------------------------------------------------------------------------
*/
public void BaseNPC_Dissolve(int monster)
{
	#if defined DEBUG
		LogMessage("BaseNPC_Dissolve(...)");
	#endif
	if (BaseNPC_IsNPC(monster))
	{
		char tmp[32];
		GetEntPropString(monster, Prop_Data, "m_iName", tmp, sizeof(tmp));
		int monster_tmp = EntRefToEntIndex(StringToInt(tmp));
		
		int ent = CreateEntityByName("env_entity_dissolver");
		if (ent > 0)
		{
			//DispatchKeyValue(ragdoll, "targetname", tmp);
			DispatchKeyValue(ent, "dissolvetype", "0");
			DispatchKeyValue(ent, "target", tmp);
			AcceptEntityInput(ent, "Dissolve");
			AcceptEntityInput(ent, "kill");
		}
		
		AcceptEntityInput(monster_tmp, "BecomeRagdoll");
		//AcceptEntityInput(monster, "Kill");
		
		KillEntity(monster, 10.0);
		//RemoveEntity(monster_tmp, 0.5);
	}
	#if defined DEBUG
	else
		LogMessage("BaseNPC_Dissolve(...)::BaseNPC_IsNPC(monster)==false");
	#endif
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_HurtPlayer
	------------------------------------------------------------------------------------------
*/
float NULL_FLOAT_VECTOR[3] = {0.0, 0.0, 0.0};
stock void BaseNPC_HurtPlayer(int monster, int target, int damage, float range = 100.0, float vPunchangle[3] = NULL_FLOAT_VECTOR, float time = 0.0)
{
	if (time == 0.0)
	{
		#if defined DEBUG
			LogMessage("BaseNPC_HurtPlayer(...)::time==0.0");
		#endif
		

		if (BaseNPC_IsAlive(monster) && target && IsClientConnected(target) && IsClientInGame(target) && IsPlayerAlive(target))
		{
			float vClientPosition[3];
			float vEntPosition[3];

			GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
			GetClientEyePosition(target, vClientPosition);
			
			if (range <= 10.0 || ((GetVectorDistance(vClientPosition, vEntPosition, false) < range) && BaseNPC_CanSeeEachOther(monster, target)))
			{
				MakeDamage(fakeClient > 0 ? fakeClient : BaseNPC_GetOwner(monster), target, damage, DMG_ACID, 1.0, NULL_FLOAT_VECTOR);
				
				//if (vPunchangle[0] != 0.0 || vPunchangle[1] != 0.0 || vPunchangle[2] != 0.0 )
				//	SetEntPropVector(target, Prop_Send, "m_vecPunchAngle", vPunchangle);
			}
		}
	}
	else
	{
		#if defined DEBUG
			LogMessage("BaseNPC_HurtPlayer(...)::time==%f", time);
		#endif
		
		Handle data;
		CreateDataTimer(time, BaseNPC_HurtPlayer_Timer, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, EntIndexToEntRef(monster));
		WritePackCell(data, target);
		WritePackCell(data, damage);
		WritePackFloat(data, range);
		WritePackFloat(data, vPunchangle[0]);
		WritePackFloat(data, vPunchangle[1]);
		WritePackFloat(data, vPunchangle[2]);
	}
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_HurtPlayer_Timer
	------------------------------------------------------------------------------------------
*/
public Action BaseNPC_HurtPlayer_Timer(Handle timer, Handle data)
{
	ResetPack(data);
	int monster = EntRefToEntIndex(ReadPackCell(data));
	int target = ReadPackCell(data);
	int damage = ReadPackCell(data);
	float range = ReadPackFloat(data);
	
	float vPunchangle[3];
	vPunchangle[0] = ReadPackFloat(data);
	vPunchangle[1] = ReadPackFloat(data);
	vPunchangle[2] = ReadPackFloat(data);

	if (monster != INVALID_ENT_REFERENCE)	
		BaseNPC_HurtPlayer(monster, target, damage, range, vPunchangle);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_PlaySound
	------------------------------------------------------------------------------------------
*/
stock void BaseNPC_PlaySound(int monster, char[] sound, float time = 0.0)
{
	if (time == 0.0)
	{
		#if defined DEBUG
			LogMessage("BaseNPC_PlaySound(...)::time==0.0");
		#endif
		
		float vEntPosition[3];
		GetEntPropVector(monster, Prop_Send, "m_vecOrigin", vEntPosition);
		EmitSoundToAll(sound, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vEntPosition);
	}
	else
	{
		#if defined DEBUG
			LogMessage("BaseNPC_PlaySound(...)::time==%f", time);
		#endif
		
		Handle data;
		CreateDataTimer(time, BaseNPC_PlaySound_Timer, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, EntIndexToEntRef(monster));
		WritePackString(data, sound);
	}
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_PlaySound_Timer
	------------------------------------------------------------------------------------------
*/
public Action BaseNPC_PlaySound_Timer(Handle timer, Handle data)
{
	ResetPack(data);
	
	int monster = EntRefToEntIndex(ReadPackCell(data));
	char sound[32];
	ReadPackString(data, sound, sizeof(sound));
	
	if (monster != INVALID_ENT_REFERENCE)	
		BaseNPC_PlaySound(monster, sound);
}

/*
	------------------------------------------------------------------------------------------
	BaseNPC_LoadMonsterConfig
	------------------------------------------------------------------------------------------
*/
stock void BaseNPC_LoadMonsterConfig(char monstername[32], float& thinkrate, float& friction, int& health)
{
	if (!KvJumpToKey(kv, "NPCs") || !KvGotoFirstSubKey(kv, false))
	{
		LogError("Monster-Config not loaded!");
	}
	else
	{
		char sectionName[32];
		do
		{
			KvGetSectionName(kv, sectionName, sizeof(sectionName));

			if (StrEqual(sectionName, monstername))
			{
				thinkrate = KvGetFloat(kv, "thinkrate", 2.0);
				health = KvGetNum(kv, "health", 100);
				friction = KvGetFloat(kv, "friction", 1.0);
				
				break;
			}
		} while (KvGotoNextKey(kv, false));

		KvRewind(kv);
	}
}

public Action BaseNPC_HookHostageSound(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	char edictname[32];
	GetEdictClassname(entity, edictname, 32);
	if (StrContains(edictname, "npc_") != -1)
		return (Plugin_Stop);
	
	return (Plugin_Continue);
}

public Action OnHostageHurt(Handle event, const char[] name, bool dontBroadcast)
{
	return (Plugin_Handled);
}

public Action OnHostageFollows(Handle event, const char[] name, bool dontBroadcast)
{
	return (Plugin_Handled);
}

public Action OnHostageStopsFollowing(Handle event, const char[] name, bool dontBroadcast)
{
	// new monster = GetEventInt(event, "hostage");
	
	return (Plugin_Handled);
}

public Action OnHostageKilled(Handle event, const char[] name, bool dontBroadcast)
{
	return (Plugin_Handled);
}
