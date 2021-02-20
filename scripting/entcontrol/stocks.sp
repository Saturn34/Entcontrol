/* 
	------------------------------------------------------------------------------------------
	EntControl::Stocks
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

// Here could stay something ... Oo

/* 
	------------------------------------------------------------------------------------------
	GETGAMETYPE
	Returns the index of the grabbed entity
	Or is seeks for an entity
	------------------------------------------------------------------------------------------
*/
enum GameType
{
	OTHER = 0,
	CSS = 1,
	TF = 2,
	DOD = 3,
	L4D1 = 4,
	L4D2 = 5,
	DYSTOPIA = 6,
	CSGO = 7,
	OBSIDIAN = 8,
	HL2MP = 9,
	NMRIH = 10
};

stock GameType GetGameType()
{
	char sGameType[20];
	GetGameFolderName(sGameType, sizeof(sGameType));
	
	if (StrEqual(sGameType, "cstrike"))
		return (CSS);
	if (StrEqual(sGameType, "cstrike_beta")) // Workaround for the css beta
		return (CSS);
	if (StrEqual(sGameType, "dod"))
		return (DOD);
	if (StrEqual(sGameType, "tf"))
		return (TF);
	if (StrEqual(sGameType, "dystopia"))
		return (DYSTOPIA);
	if (StrEqual(sGameType, "csgo"))
		return (CSGO);
	if (StrEqual(sGameType, "obsidian"))
		return (OBSIDIAN);
	if (StrEqual(sGameType, "hl2mp"))
		return (HL2MP);
	if (StrEqual(sGameType, "nmrih"))
		return (NMRIH);
		
	return (OTHER);
}

stock char GameTypeToString()
{
	char gameName[9];
	
	if (gameMod == CSS)
		gameName = "cstrike";
	else if (gameMod == TF)
		gameName = "tf";
	else if (gameMod == DOD)
		gameName = "dod";
	else if (gameMod == DYSTOPIA)
		gameName = "dystopia";
	else if (gameMod == CSGO)
		gameName = "csgo";
	else if (gameMod == OBSIDIAN)
		gameName = "obsidian";
	else if (gameMod == HL2MP)
		gameName = "hl2mp";
	else if (gameMod == NMRIH)
		gameName = "nmrih";
	
	return (gameName);
}

/* 
	------------------------------------------------------------------------------------------
	VALIDGRAB
	Do we have a valid grab ?
	------------------------------------------------------------------------------------------
*/
stock bool ValidGrab(int client)
{
	if (IsClientConnectedIngame(client))
	{
		int obj = gObj[client];
		if (obj != -1 && IsValidEntity(obj) && IsValidEdict(obj))
			return (true);
	}
	else
	{
		gObj[client] = -1;
	}

	return (false);
}

/* 
	------------------------------------------------------------------------------------------
	VALIDSELECT
	Do we have a valid selected entity ?
	------------------------------------------------------------------------------------------
*/
stock bool ValidSelect(int ent)
{
	if (ent != -1 && IsValidEdict(ent) && IsValidEntity(ent))
		return (true);

	return (false);
}

/* 
	------------------------------------------------------------------------------------------
	KILLENTITY
	Removes an Entity
	------------------------------------------------------------------------------------------
*/
stock void KillEntity(int entity, float time = 0.0)
{
	if (time == 0.0)
	{
		if (IsValidEntity(entity))
		{
			char edictname[32];
			GetEdictClassname(entity, edictname, 32);

			if (!StrEqual(edictname, "player"))
				AcceptEntityInput(entity, "kill");
		}
	}
	else
	{
		CreateTimer(time, RemoveEntityTimer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action RemoveEntityTimer(Handle Timer, any entityRef)
{
	int entity = EntRefToEntIndex(entityRef);
	if (entity != INVALID_ENT_REFERENCE)
		KillEntity(entity); // KillEntity(...) is capable of handling references
	
	return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	ISCREATURE
	NPC or Human ?
	------------------------------------------------------------------------------------------
*/
stock bool IsCreature(int ent)
{
	char sBuffer[32];
	GetEdictClassname(ent, sBuffer, 32);
	
	if (StrEqual(sBuffer, "player")
		|| StrEqual(sBuffer, "hostage_entity")
		|| StrContains(sBuffer, "npc_") != -1)
		return (true);
		
	return (false);
}

/* 
	------------------------------------------------------------------------------------------
	SPAWNRANDOMNPCS
	Spawns random NPCs on random Map-Locations
	------------------------------------------------------------------------------------------
*/
stock void SpawnRandomNPCs(int count)
{
	float position[3];
	
	if (count == 0)
		return;
	
	if (EC_Nav_Load())
	{
		if (EC_Nav_CachePositions())
		{
			for (int npc = 0; npc < count; npc++)
			{
				if (EC_Nav_GetNextHidingSpot(position))
				{
					position[2] += 20.0;
				
					switch (GetRandomInt(1, 12))
					{
						case 1:
							AntLion_Spawn(position);
						case 2:
							AntLionGuard_Spawn(position);
						case 3:
							Barney_Spawn(position);
						case 4:
							GMan_Spawn(position);
						case 5:
							HeadCrab_Spawn(position);
						case 6:
							Police_Spawn(position);
						case 7:
							Soldier_Spawn(position);
						case 8:
							Sentry_Spawn(position);
						case 9:
							Vortigaunt_Spawn(position);
						case 10:
							Dog_Spawn(position);
						case 11:
							Stalker_Spawn(position);
						case 12:
							Synth_Spawn(position);
					}
				}
				else
				{
					PrintToServer("Unable to receive position!");
				}
			}
		}
		else
		{
			PrintToServer("Unable to cache positions!");
		}
	}
	else
	{
		PrintToServer("No Navigation loaded! Make sure the .nav is not packed in one of the .vpk-files.");
		PrintToServer("It is not possible to spawn NPCs by random, without this file.");
	}
}

/* 
	------------------------------------------------------------------------------------------
	SPAWNENTITIES
	Load entites from file
	------------------------------------------------------------------------------------------
*/
public Action SpawnEntities(Handle timer)
{		
	char path[64], map[32], classname[32], modelname[64], ammo[4];
	float position[3], angle[3];
	
	// +Spawn Random NPCS
	SpawnRandomNPCs(GetConVarInt(gSpawnRandomNPCs));
	// -Spawn Random NPCS
	
	GetCurrentMap(map, 32);
	BuildPath(Path_SM, path, 64, "configs/ec_maps/%s.txt", map);
	
	Handle kvMapConfig = INVALID_HANDLE;
	kvMapConfig = CreateKeyValues(map);
	FileToKeyValues(kvMapConfig, path);
	
	if (!KvGotoFirstSubKey(kvMapConfig))
		return;
	
	char section[9];
	do
	{
		KvGetSectionName(kvMapConfig, section, sizeof(section));
		
		KvGetString(kvMapConfig, "classname", classname, sizeof(classname));
		KvGetVector(kvMapConfig, "position", position);
		
		if (strncmp("prop_", classname, 5, false) == 0)
		{
			KvGetString(kvMapConfig, "modelname", modelname, sizeof(modelname));
			KvGetVector(kvMapConfig, "angle", angle);
			
			LogMessage("Spawning Prop (%s, %s, %s)", section, classname, modelname);
			// Spawn Entity
			PrecacheModel(modelname, true); // Late ... might lag the server -.-
			
			// new ent = CreateEntityByName(classname);
			int ent = CreateEntityByName("prop_physics_override");
			
			DispatchKeyValue(ent, "physdamagescale", "0.0");
			DispatchKeyValue(ent, "model", modelname);
			DispatchSpawn(ent);
			
			//SetEntProp(ent, Prop_Send, "m_damageType", StringToInt(section));

			SetEntityMoveType(ent, MOVETYPE_VPHYSICS);

			TeleportEntity(ent, position, angle, NULL_VECTOR);

			// Little hack to "unique" the entity
			SetEntProp(ent, Prop_Data, "m_iHammerID", StringToInt(section), 4);
		}
		else if (strncmp("weapon_", classname, 7, false) == 0)
		{
			// Create Entity
			int ent = CreateEntityByName(classname);
			
			KvGetString(kvMapConfig, "ammo", ammo, sizeof(ammo));
			
			DispatchKeyValue(ent, "ammo", ammo);
			DispatchSpawn(ent);	

			TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		}
		else if (strncmp("npc_", classname, 4, false) == 0)
		{
			if (StrEqual(classname, "npc_random"))
				BaseNPC_SpawnByName("", position);
			else
				BaseNPC_SpawnByName(classname, position);
		}
		else if (StrEqual("light_dynamic", classname))
		{
			// Create Entity
			int ent = CreateEntityByName(classname);
			
			if (ent != -1)
			{
				char _light[20];
				float brightness;
				
				KvGetString(kvMapConfig, "_light", _light, sizeof(_light));				
				DispatchKeyValue(ent, "_light", _light);
				brightness = KvGetFloat(kvMapConfig, "brightness", 5.0);
				DispatchKeyValueFloat(ent, "brightness", brightness);
				
				DispatchSpawn(ent);

				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
			}
		}
		else
		{
			// Create Entity
			int ent = CreateEntityByName(classname);
			
			if (ent != -1)
			{
				DispatchSpawn(ent);	

				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
			}
		}
	} while (KvGotoNextKey(kvMapConfig));
	
	KvRewind(kvMapConfig);
	delete kvMapConfig;
	
	// Spawn Map-BuildIn-Entites
	char name[128];
	int entCount = GetEntityCount();
	for (int b = 1; b < entCount; b++)
	{
		if (IsValidEntity(b) && IsValidEdict(b))
		{
			GetEntPropString(b, Prop_Data, "m_iClassname", name, sizeof(name)); 
			if (StrEqual(name, "info_target"))
			{
				GetEntPropString(b, Prop_Data, "m_iName", name, sizeof(name));
				GetEntPropVector(b, Prop_Send, "m_vecOrigin", position);
				if (StrEqual(name, "npc_antlion"))
				{
					//This entity - point for spawn NPC
					//new Float:vAngel[3];
					//GetEntPropVector(b, Prop_Send, "m_angRotation", vAngel);
					AntLion_Spawn(position);
				}
				else if (StrEqual(name, "npc_antlionguard"))
					AntLionGuard_Spawn(position);
				else if (StrEqual(name, "npc_barney"))
					Barney_Spawn(position);
				else if (StrEqual(name, "npc_gman"))
					GMan_Spawn(position);
				else if (StrEqual(name, "npc_headcrab"))
					HeadCrab_Spawn(position);
				else if (StrEqual(name, "npc_police"))
					Police_Spawn(position);
				else if (StrEqual(name, "npc_soldier"))
					Soldier_Spawn(position);
				else if (StrEqual(name, "npc_sentrygun"))
					Sentry_Spawn(position);
				else if (StrEqual(name, "npc_vortigaunt"))
					Vortigaunt_Spawn(position);
				else if (StrEqual(name, "npc_zombie"))
					Zombie_Spawn(position);
				else if (StrEqual(name, "npc_random"))
					BaseNPC_SpawnByName("", position);
			}
			/*
			else if (StrEqual(name, "func_hostage_rescue"))  
			{  
				GetEntPropVector(b, Prop_Send, "m_vecOrigin", position);
				new ModelIndex = GetEntProp(b, Prop_Data, "m_nModelIndex");
				decl String:model[255];
				GetEntPropString(b, Prop_Data,"m_ModelName",model,sizeof(model));
				AcceptEntityInput(b, "Kill");
				b = CreateEntityByName("trigger_multiple");
				DispatchKeyValue(b, "spawnflags", "64");
				DispatchSpawn(b);
				ActivateEntity(b);
				TeleportEntity(b, position, NULL_VECTOR, NULL_VECTOR);
				SetEntProp(b, Prop_Send, "m_nModelIndex", ModelIndex);
				SetEntityModel(b, model);
				SetEntProp(b, Prop_Send, "m_nSolidType", 2);
				
				SDKHook(b, SDKHook_StartTouch, OnStartTouch);
				SDKHook(b, SDKHook_EndTouch, OnEndTouch);
			}
			*/
			else if (StrEqual(name, "func_hostage_rescue"))
				SDKHook(b, SDKHook_StartTouch, OnStartTouch);
		}
	}
	/*
	fakeClient = CreateFakeClient("Monster");
	ChangeClientTeam(fakeClient, 2);
	DispatchKeyValue(fakeClient, "classname", "TheDeath");
	DispatchSpawn(fakeClient);
	*/
}

/* 
	------------------------------------------------------------------------------------------
	SAVEENTITY
	Store entity in file
	------------------------------------------------------------------------------------------
*/
stock bool SaveEntity(int ent)
{
	char path[64];
	char map[32];
	char sEnt[32];

	GetCurrentMap(map, 32);
	BuildPath(Path_SM, path, 64, "configs/ec_maps/%s.txt", map);

	Handle kvMapConfig = INVALID_HANDLE;
	kvMapConfig = CreateKeyValues(map, map, "");
	FileToKeyValues(kvMapConfig, path);
	IntToString(ent, sEnt, 32);
	
	KvRewind(kvMapConfig);
	if (KvJumpToKey(kvMapConfig, sEnt, false))
		return (false);
	
	KvJumpToKey(kvMapConfig, sEnt, true);
	
	// Get Classname
	char classname[32];
	GetEdictClassname(ent, classname, 32);
	KvSetString(kvMapConfig, "classname", classname);
	if (strncmp("prop_", classname, 5, false) == 0)
	{
		// Get Modelname
		char modelname[64];
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 64);
		KvSetString(kvMapConfig, "modelname", modelname);
		
		// Get Position
		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		KvSetVector(kvMapConfig, "position", position);
		
		// Get Angle
		float angle[3];
		GetEntPropVector(ent, Prop_Send, "m_angRotation", angle);
		KvSetVector(kvMapConfig, "angle", angle);
	}
	else if (strncmp("weapon_", classname, 6, false) == 0)
	{
		// Get Position
		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		KvSetVector(kvMapConfig, "position", position);
		
		// Get Ammo
		//KvSetNum(kvMapConfig, "ammo", GetEntProp(ent, Prop_Send, "ammo"));
		KvSetNum(kvMapConfig, "ammo", 60);
	}
	else if (strncmp("npc_", classname, 4, false) == 0)
	{
		// Get Position
		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		KvSetVector(kvMapConfig, "position", position);
	}
	
	KvRewind(kvMapConfig);
	KeyValuesToFile(kvMapConfig, path);
	delete kvMapConfig;
	
	return (true);
}

/* 
	------------------------------------------------------------------------------------------
	SPAWNENTITIES
	Load entites from file
	------------------------------------------------------------------------------------------
*/
stock void RemoveEntityFromStore(int ent)
{
	char path[64];
	char map[32];
	char sEnt[32];
	
	GetCurrentMap(map, 32);
	BuildPath(Path_SM, path, 64, "configs/ec_maps/%s.txt", map);
	
	Handle kvMapConfig = INVALID_HANDLE;
	kvMapConfig = CreateKeyValues(map);
	FileToKeyValues(kvMapConfig, path);
	
	if (!KvGotoFirstSubKey(kvMapConfig) || GetEntProp(ent, Prop_Data, "m_iHammerID", 4) == 0)
		return;
	
	IntToString(GetEntProp(ent, Prop_Data, "m_iHammerID", 4), sEnt, 32);

	char buffer[9];
	do
	{
		KvGetSectionName(kvMapConfig, buffer, sizeof(buffer));
		if (StrEqual(buffer, sEnt))
		{
			LogMessage("%s deleted", sEnt);
			KvDeleteThis(kvMapConfig);
			break;
		}
	} while (KvGotoNextKey(kvMapConfig));
	
	KvRewind(kvMapConfig);
	KeyValuesToFile(kvMapConfig, path);
	delete kvMapConfig;
}

/* 
	------------------------------------------------------------------------------------------
	CANUSECMD
	Is our client be able to use the command ?
	------------------------------------------------------------------------------------------
*/
stock bool CanUseCMD(int client, Handle cvarFlag, bool giveFeedback = true)
{
	if (client)
	{
		char sFlag[2];
		GetConVarString(cvarFlag, sFlag, sizeof(sFlag));
		AdminFlag theFlag;

		if (!sFlag[0]) // Allowed to everyone ? -.-
			return (true);	
		
		AdminId clientAdminID = GetUserAdmin(client);
		
		if (clientAdminID != INVALID_ADMIN_ID && FindFlagByChar(sFlag[0], theFlag) 
			&& GetAdminFlag(clientAdminID, theFlag))
			return (true);
		
		// If we are still in the function. The client does not have enough rights.
		if (giveFeedback)
			ReplyToCommand(client, "Insufficient permissions");
	}
	else
	{
		ReplyToCommand(client, "This command is client-side-only. Not accessible through RCON.");
	}
	
	return (false);
}

/* 
	------------------------------------------------------------------------------------------
	GETOBJECT
	Returns the index of the grabbed entity
	Or is seeks for an entity
	------------------------------------------------------------------------------------------
*/
stock int GetObject(int client, bool hitSelf = true)
{
	int ent = -1;
	
	if (IsClientConnectedIngame(client))
	{
		if (ValidGrab(client))
		{
			ent = EntRefToEntIndex(gObj[client]);
			return (ent);
		}

		ent = TraceToEntity(client); // GetClientAimTarget(client);
		
		if (IsValidEntity(ent) && IsValidEdict(ent))
		{
			char edictname[64];
			GetEdictClassname(ent, edictname, 64);
			if (StrEqual(edictname, "worldspawn"))
			{
				if (hitSelf)
					ent = client;
				else
					ent = -1;
			}
		}
		else
		{
			ent = -1;
		}
	}
	
	return (ent);
}

/* 
	------------------------------------------------------------------------------------------
	SENDKEYHINTTEXTTOALL
	Send a KeyHintText to all clients
	------------------------------------------------------------------------------------------
*/
stock void SendKeyHintTextToAll(char[] sMessage, any ...)
{
	char sBuffer[192];
	VFormat(sBuffer, sizeof(sBuffer), sMessage, 2);
	Handle hBuffer = StartMessageAll("KeyHintText");
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, sBuffer);
	EndMessage();
}

/* 
	------------------------------------------------------------------------------------------
	COLORIZE
	Colorize an entity
	This code is based on the code from ... I just cannot remember :(
	------------------------------------------------------------------------------------------
*/
stock void Colorize(int client, int color[4], bool weaponOnly = false)
{
	//new maxents = GetMaxEntities();
	// Colorize player and weapons
	int m_hMyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");	

	for (int i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
	
		if (weapon != -1)
		{
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1],color[2], color[3]);
		}
	}
	
	if (!weaponOnly)
	{
		if (color[3] == 0)
		{
			SetEntityRenderMode(client, RENDER_NONE);	
		}
		else
		{
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
			SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
		}
	}
	
	ChangeEdictState(client);

	return;
}

/* 
	------------------------------------------------------------------------------------------
	GETPLAYEREYE
	Will return the aim-position
	This code was borrowed from Nican's spraytracer
	------------------------------------------------------------------------------------------
*/
stock bool GetPlayerEye(int client, float pos[3])
{
	float vAngles[3];
	float vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(trace))
	{
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		delete trace;
		return (true);
	}

	delete trace;
	return (false);
}

stock bool GetPlayerEyeWithAngle(int client, float vPos[3], float vAngles[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vPos, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vAngles);
		GetVectorAngles(vAngles, vAngles);
		
		delete trace;
		return (true);
	}

	delete trace;
	return (false);
}

public int TraceToEntity(int client)
{
	float vecClientEyePos[3];
	float vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);    

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceASDF, client);

	if (TR_DidHit(INVALID_HANDLE))
		return (TR_GetEntityIndex(INVALID_HANDLE));

	return (-1);
}

public bool TraceASDF(int entity, int mask, any data)
{
	return (data != entity);
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > MaxClients || !entity);
}

/* 
	------------------------------------------------------------------------------------------
	DRAWBOUNDINGBOX
	Thanks to Mitchell (http://forums.alliedmods.net/showthread.php?t=174743#cl-privacy)
	------------------------------------------------------------------------------------------
*/
stock void DrawBoundingBox_Internal(const float start[3], const float end[3], int client = 0, float time = 10.0)
{
	TE_SetupBeamPoints(start, end, gLaser1, 0, 0, 0, time, 3.0, 3.0, 7, 0.0, {150, 255, 150, 255}, 0);

	if (client)
		TE_SendToClient(client);
	else
		TE_SendToAll();
}

stock void DrawBoundingBox(int ent, int client = 0, float time = 10.0)
{
    float posMin[4][3];
    float posMax[4][3];
    float orig[3];
    
    GetEntPropVector(ent, Prop_Send, "m_vecMins", posMin[0]);
    GetEntPropVector(ent, Prop_Send, "m_vecMaxs", posMax[0]);
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", orig);

    // Incase the entity is a player i want to make the box fit..
    char edictname[32];
    GetEdictClassname(ent, edictname, 32);
    if (StrEqual(edictname, "player"))
    {
        posMax[0][2] += 16.0;
    }

    posMin[1][0] = posMax[0][0];
    posMin[1][1] = posMin[0][1];
    posMin[1][2] = posMin[0][2];
    posMax[1][0] = posMin[0][0];
    posMax[1][1] = posMax[0][1];
    posMax[1][2] = posMax[0][2];
    posMin[2][0] = posMin[0][0];
    posMin[2][1] = posMax[0][1];
    posMin[2][2] = posMin[0][2];
    posMax[2][0] = posMax[0][0];
    posMax[2][1] = posMin[0][1];
    posMax[2][2] = posMax[0][2];
    posMin[3][0] = posMax[0][0];
    posMin[3][1] = posMax[0][1];
    posMin[3][2] = posMin[0][2];
    posMax[3][0] = posMin[0][0];
    posMax[3][1] = posMin[0][1];
    posMax[3][2] = posMax[0][2];
    
    AddVectors(posMin[0], orig, posMin[0]);
    AddVectors(posMax[0], orig, posMax[0]);
    AddVectors(posMin[1], orig, posMin[1]);
    AddVectors(posMax[1], orig, posMax[1]);
    AddVectors(posMin[2], orig, posMin[2]);
    AddVectors(posMax[2], orig, posMax[2]);
    AddVectors(posMin[3], orig, posMin[3]);
    AddVectors(posMax[3], orig, posMax[3]);
    
    //DrawBoundingBox_Internal(posMin[0], posMax[0], client, time);
    //DrawBoundingBox_Internal(posMin[1], posMax[1], client, time);
    //DrawBoundingBox_Internal(posMin[2], posMax[2], client, time);
    //DrawBoundingBox_Internal(posMin[3], posMax[3], client, time);
    
    //UP & DOWN
    
    //BORDER
    DrawBoundingBox_Internal(posMin[0], posMax[3], client, time);
    DrawBoundingBox_Internal(posMin[1], posMax[2], client, time);
    DrawBoundingBox_Internal(posMin[3], posMax[0], client, time);
    DrawBoundingBox_Internal(posMin[2], posMax[1], client, time);
    //CROSS
    DrawBoundingBox_Internal(posMin[3], posMax[2], client, time);
    DrawBoundingBox_Internal(posMin[1], posMax[0], client, time);
    DrawBoundingBox_Internal(posMin[2], posMax[3], client, time);
    DrawBoundingBox_Internal(posMin[3], posMax[1], client, time);
    DrawBoundingBox_Internal(posMin[2], posMax[0], client, time);
    DrawBoundingBox_Internal(posMin[0], posMax[1], client, time);
    DrawBoundingBox_Internal(posMin[0], posMax[2], client, time);
    DrawBoundingBox_Internal(posMin[1], posMax[3], client, time);
    
    
    //TOP
    
    //BORDER
    DrawBoundingBox_Internal(posMax[0], posMax[1], client, time);
    DrawBoundingBox_Internal(posMax[1], posMax[3], client, time);
    DrawBoundingBox_Internal(posMax[3], posMax[2], client, time);
    DrawBoundingBox_Internal(posMax[2], posMax[0], client, time);
    //CROSS
    DrawBoundingBox_Internal(posMax[0], posMax[3], client, time);
    DrawBoundingBox_Internal(posMax[2], posMax[1], client, time);
    
    //BOTTOM
    
    //BORDER
    DrawBoundingBox_Internal(posMin[0], posMin[1], client, time);
    DrawBoundingBox_Internal(posMin[1], posMin[3], client, time);
    DrawBoundingBox_Internal(posMin[3], posMin[2], client, time);
    DrawBoundingBox_Internal(posMin[2], posMin[0], client, time);
    //CROSS
    DrawBoundingBox_Internal(posMin[0], posMin[3], client, time);
    DrawBoundingBox_Internal(posMin[2], posMin[1], client, time);
}

stock void DrawDissolverBox_Internal(const float pos1[3], const float pos2[3])
{
	TE_SetupEnergySplash(pos1, pos2, true);
	TE_SendToAll();
	
	TE_SetupSparks(pos1, pos2, 255, 255);
	TE_SendToAll();
}

stock void DrawDissolverBox(int ent)
{
    float posMin[4][3];
    float posMax[4][3];
    float orig[3];
    
    GetEntPropVector(ent, Prop_Send, "m_vecMins", posMin[0]);
    GetEntPropVector(ent, Prop_Send, "m_vecMaxs", posMax[0]);
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", orig);

    // Incase the entity is a player i want to make the box fit..
    char edictname[32];
    GetEdictClassname(ent, edictname, 32);
    if (StrEqual(edictname, "player"))
    {
        posMax[0][2] += 16.0;
    }

    posMin[1][0] = posMax[0][0];
    posMin[1][1] = posMin[0][1];
    posMin[1][2] = posMin[0][2];
    posMax[1][0] = posMin[0][0];
    posMax[1][1] = posMax[0][1];
    posMax[1][2] = posMax[0][2];
    posMin[2][0] = posMin[0][0];
    posMin[2][1] = posMax[0][1];
    posMin[2][2] = posMin[0][2];
    posMax[2][0] = posMax[0][0];
    posMax[2][1] = posMin[0][1];
    posMax[2][2] = posMax[0][2];
    posMin[3][0] = posMax[0][0];
    posMin[3][1] = posMax[0][1];
    posMin[3][2] = posMin[0][2];
    posMax[3][0] = posMin[0][0];
    posMax[3][1] = posMin[0][1];
    posMax[3][2] = posMax[0][2];
    
    AddVectors(posMin[0], orig, posMin[0]);
    AddVectors(posMax[0], orig, posMax[0]);
    AddVectors(posMin[1], orig, posMin[1]);
    AddVectors(posMax[1], orig, posMax[1]);
    AddVectors(posMin[2], orig, posMin[2]);
    AddVectors(posMax[2], orig, posMax[2]);
    AddVectors(posMin[3], orig, posMin[3]);
    AddVectors(posMax[3], orig, posMax[3]);
    
    //UP & DOWN
    
    //BORDER
    DrawDissolverBox_Internal(posMin[0], posMax[3]);
    DrawDissolverBox_Internal(posMin[1], posMax[2]);
    DrawDissolverBox_Internal(posMin[3], posMax[0]);
    DrawDissolverBox_Internal(posMin[2], posMax[1]);
    //CROSS
    DrawDissolverBox_Internal(posMin[3], posMax[2]);
    DrawDissolverBox_Internal(posMin[1], posMax[0]);
    DrawDissolverBox_Internal(posMin[2], posMax[3]);
    DrawDissolverBox_Internal(posMin[3], posMax[1]);
    DrawDissolverBox_Internal(posMin[2], posMax[0]);
    DrawDissolverBox_Internal(posMin[0], posMax[1]);
    DrawDissolverBox_Internal(posMin[0], posMax[2]);
    DrawDissolverBox_Internal(posMin[1], posMax[3]);
    
    
    //TOP
    
    //BORDER
    DrawDissolverBox_Internal(posMax[0], posMax[1]);
    DrawDissolverBox_Internal(posMax[1], posMax[3]);
    DrawDissolverBox_Internal(posMax[3], posMax[2]);
    DrawDissolverBox_Internal(posMax[2], posMax[0]);
    //CROSS
    DrawDissolverBox_Internal(posMax[0], posMax[3]);
    DrawDissolverBox_Internal(posMax[2], posMax[1]);
    
    //BOTTOM
    
    //BORDER
    DrawDissolverBox_Internal(posMin[0], posMin[1]);
    DrawDissolverBox_Internal(posMin[1], posMin[3]);
    DrawDissolverBox_Internal(posMin[3], posMin[2]);
    DrawDissolverBox_Internal(posMin[2], posMin[0]);
    //CROSS
    DrawDissolverBox_Internal(posMin[0], posMin[3]);
    DrawDissolverBox_Internal(posMin[2], posMin[1]);
}

/* 
	------------------------------------------------------------------------------------------
	REPLACEPHYSICSENTITY
	Is going to replace the given entity so, that we can grab it
	------------------------------------------------------------------------------------------
*/
stock int ReplacePhysicsEntity(int ent)
{
	float VecPos_Ent[3];
	float VecAng_Ent[3];

	// Copy Entity
	char model[128];
	GetEntPropString(ent, Prop_Data, "m_ModelName", model, 128);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", VecPos_Ent);
	GetEntPropVector(ent, Prop_Send, "m_angRotation", VecAng_Ent);
	AcceptEntityInput(ent, "Wake");
	AcceptEntityInput(ent, "EnableMotion");
	AcceptEntityInput(ent, "EnableDamageForces");
	DispatchKeyValue(ent, "physdamagescale", "0.0");
	
/*
	RemoveEdict(ent);

	//decl Ent;
	PrecacheModel(model, true);
	ent = CreateEntityByName("prop_physics_override"); 
	
	DispatchKeyValue(ent, "physdamagescale", "0.0");
	DispatchKeyValue(ent, "model", model);
	DispatchSpawn(ent);
*/
	TeleportEntity(ent, VecPos_Ent, VecAng_Ent, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);

	return (ent);
}

// Will modify all prop_physics and prop_dynamic_override that we are able to grab them
public void ReplacePhysics(Handle timer)
{
	LogError("Replacing physics");
	int ents = GetMaxEntities()-100;
	char edictname[128];
	for (int i=MaxClients+1; i<ents; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i)) 
		{
			GetEdictClassname(i, edictname, 128);
			if (StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_physics_multiplayer"))
			{
				LogAction(0, 0, "Replace Entity: %i", i);
				ReplacePhysicsEntity(i);
			}
		}
	}
}

/* 
	------------------------------------------------------------------------------------------
	DRAWENTITYCONNECTIONS
	Draws the entity connections
	------------------------------------------------------------------------------------------
*/
public void DrawEntityConnections(int client, int entity)
{
	int entityCount = GetMaxEntities()-100;
	float vEntity1Pos[3];
	
	if (EntControlExtLoaded)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEntity1Pos);
		
		char sClassname[64];
		GetEdictClassname(entity, sClassname, 64);
		if (KvJumpToKey(kvEnts, sClassname) && KvJumpToKey(kvEnts, "output"))
		{
			KvGotoFirstSubKey(kvEnts, false);
			
			char sectionName[24];
			do
			{
				KvGetSectionName(kvEnts, sectionName, sizeof(sectionName));

				DrawEntityConnections_Internal(entityCount, client, entity, vEntity1Pos, sectionName);

			} while (KvGotoNextKey(kvEnts, false));
			
			KvRewind(kvEnts);
		}
	}
}

public void DrawEntityConnections_Internal(int entityCount, int client, int entity, float vEntity1Pos[3], char sOutput[24])
{
	char sBuffer[64];
	char sTargetName[64];
	float vEntity2Pos[3];
	
	sBuffer = sOutput;
	int count = EC_Entity_GetOutputCount(entity, sBuffer);
	
	if (count != -1 && EC_Entity_GetOutputFirst(entity, sBuffer))
	{
		for (int i = 0; i < count; i++)
		{
			sBuffer = sOutput;
			EC_Entity_GetOutputAt(entity, sBuffer, i);
			
			for (int ent = MaxClients+1; ent < entityCount; ent++)
			{
				if (IsValidEdict(ent) && IsValidEntity(ent)) 
				{
					GetEntPropString(ent, Prop_Data, "m_iName", sTargetName, 64);
					
					if (StrEqual(sBuffer, sTargetName))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vEntity2Pos);
						
						TE_SetupBeamPoints(vEntity1Pos, vEntity2Pos, gLaser1, 0, 0, 0, 5.0, 1.0, 1.0, 0, 0.0, {0, 255, 0, 255}, 0);
						TE_SendToClient(client);
					}
				}
			}
		}
	}
}

/* 
	------------------------------------------------------------------------------------------
	STOCKLIB-FUNCTIONS
	------------------------------------------------------------------------------------------
*/
// settings for m_takedamage
#define	DAMAGE_NO				0
#define DAMAGE_EVENTS_ONLY		1		// Call damage functions, but don't modify health
#define	DAMAGE_YES				2
#define	DAMAGE_AIM				3

#define FFADE_IN 	0x0001        // Just here so we don't pass 0 into the function
#define FFADE_OUT	0x0002        // Fade out (not in)
#define FFADE_MODULATE	0x0004        // Modulate (don't blend)
#define FFADE_STAYOUT	0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE	0x0010        // Purges all other fades, replacing them with this one


stock bool MakeDamage(int client, int target, int damage, int damagetype, float damageradius, const float attackposition[3], const char[] weaponname = "", bool kill = true)
{
	int pointhurt = CreateEntityByName("point_hurt");
	
	if (pointhurt != -1)
	{
		if (target != -1)
		{
			char targetname[64];
			Format(targetname, 128, "%f%f", GetEngineTime(), GetRandomFloat());
			DispatchKeyValue(target, "TargetName", targetname);
			DispatchKeyValue(pointhurt, "DamageTarget", targetname);
		}
		else
			DispatchKeyValue(pointhurt, "DamageTarget", "");

		DispatchKeyValueVector(pointhurt, "Origin", attackposition);
		
		char number[64];
		IntToString(damage, number, 64);
		DispatchKeyValue(pointhurt,"Damage", number);
		
		IntToString(damagetype, number, 64);
		DispatchKeyValue(pointhurt,"DamageType", number);
		
		DispatchKeyValueFloat(pointhurt, "DamageRadius", damageradius);
		
		if (!StrEqual(weaponname, "", false))
			DispatchKeyValue(pointhurt,"classname", weaponname);
		
		DispatchSpawn(pointhurt);
		
		if (IsClientConnectedIngame(client))
			AcceptEntityInput(pointhurt, "Hurt", client);
		else
			AcceptEntityInput(pointhurt, "Hurt", 0);
		
		if (kill)
			AcceptEntityInput(pointhurt, "Kill");
		
		return (true);
	}
	else
		return (false);
}

stock bool makeexplosion(int attacker = 0, int inflictor = -1, const float attackposition[3], const char[] weaponname = "", int magnitude = 100, int radiusoverride = 0, float damageforce = 0.0, int flags = 0){
	
	int explosion = CreateEntityByName("env_explosion");
	
	if (explosion != -1)
	{
		DispatchKeyValueVector(explosion, "Origin", attackposition);
		
		char intbuffer[64];
		IntToString(magnitude, intbuffer, 64);
		DispatchKeyValue(explosion,"iMagnitude", intbuffer);
		if (radiusoverride > 0)
		{
			IntToString(radiusoverride, intbuffer, 64);
			DispatchKeyValue(explosion,"iRadiusOverride", intbuffer);
		}
		
		if (damageforce > 0.0)
			DispatchKeyValueFloat(explosion,"DamageForce", damageforce);

		if (flags != 0)
		{
			IntToString(flags, intbuffer, 64);
			DispatchKeyValue(explosion,"spawnflags", intbuffer);
		}

		if (!StrEqual(weaponname, "", false))
			DispatchKeyValue(explosion,"classname", weaponname);

		DispatchSpawn(explosion);
		if (IsClientConnectedIngame(attacker))
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", attacker);

		if (inflictor != -1)
			SetEntPropEnt(explosion, Prop_Data, "m_hInflictor", inflictor);
			
		AcceptEntityInput(explosion, "Explode");
		AcceptEntityInput(explosion, "Kill");
		
		return (true);
	}
	else
		return (false);
}

stock bool IsClientConnectedIngame(int client)
{
	if (client > 0 && client <= MaxClients)
		if (IsClientInGame(client))
			return (true);

	return (false);
}

stock void setm_takedamage(int entity, int type)
{
	SetEntProp(entity, Prop_Data, "m_takedamage", type);
}

stock void makeviewpunch(int client, float angle[3])
{
	float oldangle[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
	
	oldangle[0] = oldangle[0] + angle[0];
	oldangle[1] = oldangle[1] + angle[1];
	oldangle[2] = oldangle[2] + angle[2];
	
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", angle);
}


// Thanks to V0gelz
stock void env_shooter(float Angles[3], float iGibs, float Delay, float GibAngles[3], float Velocity, float Variance, float Giblife, float Location[3], char[] ModelType)
{
	//decl Ent;

	//Initialize:
	int Ent = CreateEntityByName("env_shooter");
		
	//Spawn:

	if (Ent == -1)
		return;

  	//if (Ent>0 && IsValidEdict(Ent))

	if (Ent>0 && IsValidEntity(Ent) && IsValidEdict(Ent))
  	{

		//Properties:
		//DispatchKeyValue(Ent, "targetname", "flare");

		// Gib Direction (Pitch Yaw Roll) - The direction the gibs will fly. 
		DispatchKeyValueVector(Ent, "angles", Angles);
	
		// Number of Gibs - Total number of gibs to shoot each time it's activated
		DispatchKeyValueFloat(Ent, "m_iGibs", iGibs);

		// Delay between shots - Delay (in seconds) between shooting each gib. If 0, all gibs shoot at once.
		DispatchKeyValueFloat(Ent, "delay", Delay);

		// <angles> Gib Angles (Pitch Yaw Roll) - The orientation of the spawned gibs. 
		DispatchKeyValueVector(Ent, "gibangles", GibAngles);

		// Gib Velocity - Speed of the fired gibs. 
		DispatchKeyValueFloat(Ent, "m_flVelocity", Velocity);

		// Course Variance - How much variance in the direction gibs are fired. 
		DispatchKeyValueFloat(Ent, "m_flVariance", Variance);

		// Gib Life - Time in seconds for gibs to live +/- 5%. 
		DispatchKeyValueFloat(Ent, "m_flGibLife", Giblife);
		
		// <choices> Used to set a non-standard rendering mode on this entity. See also 'FX Amount' and 'FX Color'. 
		DispatchKeyValue(Ent, "rendermode", "5");

		// Model - Thing to shoot out. Can be a .mdl (model) or a .vmt (material/sprite). 
		DispatchKeyValue(Ent, "shootmodel", ModelType);

		// <choices> Material Sound
		DispatchKeyValue(Ent, "shootsounds", "-1"); // No sound

		// <choices> Simulate, no idea what it realy does tbh...
		// could find out but to lazy and not worth it...
		//DispatchKeyValue(Ent, "simulation", "1");

		SetVariantString("spawnflags 4");
		AcceptEntityInput(Ent,"AddOutput");

		ActivateEntity(Ent);

		//Input:
		// Shoot!
		AcceptEntityInput(Ent, "Shoot", 0);
			
		//Send:
		TeleportEntity(Ent, Location, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		//AcceptEntityInput(Ent, "kill");
		KillEntity(Ent, 1.0);
	}
}

stock void env_shake(float Origin[3], float Amplitude, float Radius, float Duration, float Frequency)
{
	int Ent;

	//Initialize:
	Ent = CreateEntityByName("env_shake");
		
	//Spawn:
	if (DispatchSpawn(Ent))
	{
		//Properties:
		DispatchKeyValueFloat(Ent, "amplitude", Amplitude);
		DispatchKeyValueFloat(Ent, "radius", Radius);
		DispatchKeyValueFloat(Ent, "duration", Duration);
		DispatchKeyValueFloat(Ent, "frequency", Frequency);

		SetVariantString("spawnflags 8");
		AcceptEntityInput(Ent,"AddOutput");

		//Input:
		AcceptEntityInput(Ent, "StartShake", 0);
		
		//Send:
		TeleportEntity(Ent, Origin, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		KillEntity(Ent, 30.0);
	}
}

stock bool IsEntityCollidable(int entity, bool includeplayer = true, bool includehostage = true, bool includeprojectile = true)
{
	char classname[64];
	GetEdictClassname(entity, classname, 64);
	
	if ((StrEqual(classname, "player", false) && includeplayer) || (StrEqual(classname, "hostage_entity", false) && includehostage)
		|| StrContains(classname, "physics", false) != -1 || StrContains(classname, "prop", false) != -1
		|| StrContains(classname, "door", false)  != -1 || StrContains(classname, "weapon", false)  != -1
		|| StrContains(classname, "break", false)  != -1 || ((StrContains(classname, "projectile", false)  != -1) && includeprojectile)
		|| StrContains(classname, "brush", false)  != -1 || StrContains(classname, "button", false)  != -1
		|| StrContains(classname, "physbox", false)  != -1 || StrContains(classname, "plat", false)  != -1
		|| StrEqual(classname, "func_conveyor", false) || StrEqual(classname, "func_fish_pool", false)
		|| StrEqual(classname, "func_guntarget", false) || StrEqual(classname, "func_lod", false)
		|| StrEqual(classname, "func_monitor", false) || StrEqual(classname, "func_movelinear", false)
		|| StrEqual(classname, "func_reflective_glass", false) || StrEqual(classname, "func_rotating", false)
		|| StrEqual(classname, "func_tanktrain", false) || StrEqual(classname, "func_trackautochange", false)
		|| StrEqual(classname, "func_trackchange", false) || StrEqual(classname, "func_tracktrain", false)
		|| StrEqual(classname, "func_train", false) || StrEqual(classname, "func_traincontrols", false)
		|| StrEqual(classname, "func_vehicleclip", false) || StrEqual(classname, "func_traincontrols", false)
		|| StrEqual(classname, "func_water", false) || StrEqual(classname, "func_water_analog", false))
	{
		return (true);
	}
	
	return (false);
}

stock void sendfademsg(int client, int duration, int holdtime, int fadeflag, int r, int g, int b, int a)
{
	Handle fademsg;
	
	if (client == 0)
		fademsg = StartMessageAll("Fade");
	else
		fademsg = StartMessageOne("Fade", client);
	
	BfWriteShort(fademsg, duration);
	BfWriteShort(fademsg, holdtime);
	BfWriteShort(fademsg, fadeflag);
	BfWriteByte(fademsg, r);
	BfWriteByte(fademsg, g);
	BfWriteByte(fademsg, b);
	BfWriteByte(fademsg, a);
	EndMessage();
}

public bool tracerayfilterrocket(int entity, int mask, any data)
{
	if (entity != data && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != data)
		return (true);
	else
		return (false);
}
