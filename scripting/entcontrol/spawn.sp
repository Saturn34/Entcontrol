/* 
	------------------------------------------------------------------------------------------
	EntControl::Spawn
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

Handle gPropOverrideEntity;

// Admin Flags
Handle gAdminFlagProps;
Handle gAdminFlagSpecial;

public void RegSpawnCommands()
{
	gPropOverrideEntity = CreateConVar("sm_entcontrol_spawn_prop_override", "", "This will override the prop e.g. \"phys_magnet\"");
	gAdminFlagProps = CreateConVar("sm_entcontrol_spawn_prop_fl", "z", "The needed Flag to spawn props");
	RegConsoleCmd("sm_entcontrol_spawn_prop", Command_Spawn_Prop, "Spawns prop");
	
	gAdminFlagSpecial = CreateConVar("sm_entcontrol_spawn_special_fl", "z", "The needed Flag to spawn other things(Weapons, Lights, ...)");
	RegConsoleCmd("sm_entcontrol_spawn_weapon", Command_Spawn_Weapon, "Spawn Weapon");
	RegConsoleCmd("sm_entcontrol_spawn_rescue", Command_Spawn_RescueZone, "Spawn RescueZone");
	RegConsoleCmd("sm_entcontrol_spawn_bomb", Command_Spawn_BombZone, "Spawn BombZone");
	RegConsoleCmd("sm_entcontrol_spawn_test", Command_Spawn_Test, "Spawn Test");

	RegConsoleCmd("sm_entcontrol_spawn", Command_Spawn, "Spawn Entity");
}

/*
	------------------------------------------------------------------------------------------
	Command_Spawn_Prop
	Spawn a prop
	------------------------------------------------------------------------------------------
*/
public Action Command_Spawn_Prop(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagProps)) return (Plugin_Handled);
	
	char name[256];
	GetCmdArg(1, name, sizeof(name));
	
	float position[3];
	
	if (GetPlayerEye(client, position))
	{
		char sectionName[32];
		char modelName[64];
		char entityName[32];
		int height;
		
		// Search for the Key
		if (KvJumpToKey(kv, "Spawns") 
		&& KvJumpToKey(kv, "Props")
		&& KvJumpToKey(kv, "all")
		&& KvGotoFirstSubKey(kv, false))
		{
			do
			{
				KvGetSectionName(kv, sectionName, sizeof(sectionName));
				
				if (StrEqual(name, sectionName))
				{
					KvGetString(kv, "model", modelName, sizeof(modelName));
					KvGetString(kv, "entity", entityName, sizeof(entityName));
					height = KvGetNum(kv, "height");
					
					break;
				}
			} while (KvGotoNextKey(kv, false));

			KvRewind(kv);
		}
		
		if (!StrEqual(sectionName, name))
		{
			if (KvJumpToKey(kv, "Spawns") 
			&& KvJumpToKey(kv, "Props")
			&& KvJumpToKey(kv, GameTypeToString())
			&& KvGotoFirstSubKey(kv, false))
			{
				do
				{
					KvGetSectionName(kv, sectionName, sizeof(sectionName));
					
					if (StrEqual(name, sectionName))
					{
						KvGetString(kv, "model", modelName, sizeof(modelName));
						KvGetString(kv, "entity", entityName, sizeof(entityName));
						height = KvGetNum(kv, "height");
						
						break;
					}
				} while (KvGotoNextKey(kv, false));

				KvRewind(kv);
			}
		}

		// Set Height
		position[2] += height;
		
		// PrecacheModel
		PrecacheModel(modelName, true); // Late ... will lag the server -.-

		char sFlag[15];
		GetConVarString(gPropOverrideEntity, sFlag, sizeof(sFlag));
		
		// Create Entity
		int ent;
		if (StrEqual(sFlag, "")) // Do we need to override the Entity ?
			ent = CreateEntityByName(entityName);
		else
			ent = CreateEntityByName(sFlag);
		
		DispatchKeyValue(ent, "physdamagescale", "0.0");
		DispatchKeyValue(ent, "model", modelName);
		DispatchSpawn(ent);

		SetEntityMoveType(ent, MOVETYPE_VPHYSICS);   
		
		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		
		PrintHintText(client, "%t", "Spawned", name);
	}
	else
		PrintHintText(client, "%t", "Wrong entity"); 
	
	return (Plugin_Handled);
}


/* 
	------------------------------------------------------------------------------------------
	Command_Spawn
	Spawn sth
	This function is a bit slow ... hmm ... -.-
	------------------------------------------------------------------------------------------
*/
public Action Command_Spawn(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	char name[256];
	GetCmdArg(1, name, sizeof(name));
	
	float position[3];
	
	if (GetPlayerEye(client, position))
	{
		// Search for the Key
		if (KvJumpToKey(kv, "Spawns") && KvGotoFirstSubKey(kv, false))
		{
			char sectionName[32], modelName[64], entityName[32], input1Name[32], input2Name[32], input3Name[32];
			int height, health;
			float deleteTimerValue;			
			do
			{
				if (!KvGetSectionName(kv, sectionName, sizeof(sectionName)))
					continue;
				
				if (StrEqual(name, sectionName))
				{
					KvGetString(kv, "model", modelName, sizeof(modelName));
					KvGetString(kv, "entity", entityName, sizeof(entityName));
					KvGetString(kv, "input1", input1Name, sizeof(input1Name));
					KvGetString(kv, "input2", input2Name, sizeof(input2Name));
					KvGetString(kv, "input3", input3Name, sizeof(input3Name));
					
					height = KvGetNum(kv, "height");
					health = KvGetNum(kv, "health");
					
					deleteTimerValue = KvGetFloat(kv, "deleteafter");

					break;
				}
			} while (KvGotoNextKey(kv, false));

			KvRewind(kv);
			
			// Create Entity
			int ent = CreateEntityByName(entityName);
			
			if (!ent)
				return (Plugin_Handled);
			
			// Precache model & set it to the entity
			if (!StrEqual(modelName, ""))
			{
				PrecacheModel(modelName, true); // Late ... may lag the server -.-
				DispatchKeyValue(ent, "model", modelName);
			}
			
			// Search for the Key
			if ((KvJumpToKey(kv, "Spawns") && KvJumpToKey(kv, name)) && KvGotoFirstSubKey(kv, false))
			{
				char valueString[32];
				float valueFloat;
				do
				{
					KvGetSectionName(kv, sectionName, sizeof(sectionName));
					
					KvGetString(kv, "string", valueString, sizeof(valueString));
					if (!StrEqual(valueString, ""))
						DispatchKeyValue(ent, sectionName, valueString);
					else 
					{
						valueFloat = KvGetFloat(kv, "float");
						if (valueFloat)
							DispatchKeyValueFloat(ent, sectionName, valueFloat);
					}
				} while (KvGotoNextKey(kv, false));

				KvRewind(kv);
			}

			DispatchSpawn(ent);
			
			// Set Height
			if (height == 0)
				height = 5;
			
			position[2] += height;
			TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
			
			if (!StrEqual(input1Name, ""))
				AcceptEntityInput(ent, input1Name);
			if (!StrEqual(input2Name, ""))
				AcceptEntityInput(ent, input2Name);
			if (!StrEqual(input3Name, ""))
				AcceptEntityInput(ent, input3Name);
			
			if (deleteTimerValue)
				KillEntity(ent, deleteTimerValue);
			
			if (health)
				Entity_SetHealth(ent, health);
			
			PrintHintText(client, "%t", "Spawned", name);
		}
	}
	else
		PrintHintText(client, "%t", "Wrong entity"); 
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Spawn_RescueZone
	Spawn rescuezone
	------------------------------------------------------------------------------------------
*/
public Action Command_Spawn_RescueZone(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	float vAngles[3];
	float vOrigin[3];
	float vBuffer[3];
	float vStart[3];
	float Distance;
	float position[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		//GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		position[0] = vStart[0] + (vBuffer[0]*Distance);
		position[1] = vStart[1] + (vBuffer[1]*Distance);
		position[2] = vStart[2] + (vBuffer[2]*Distance);
		CloseHandle(trace);

		// Spawn
		int ent = CreateEntityByName("func_hostage_rescue");
		if (ent != -1)
		{
			DispatchKeyValue(ent, "pushdir", "0 90 0");
			DispatchKeyValue(ent, "speed", "500");
			DispatchKeyValue(ent, "spawnflags", "64");
		}

		DispatchSpawn(ent);
		ActivateEntity(ent);

		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		PrecacheModel("models/props/cs_office/vending_machine.mdl", true);
		SetEntityModel(ent, "models/props/cs_office/vending_machine.mdl");

		float minbounds[3] = {-100.0, -100.0, 0.0};
		float maxbounds[3] = {100.0, 100.0, 200.0};
		SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);
			
		SetEntProp(ent, Prop_Send, "m_nSolidType", 2);

		int enteffects = GetEntProp(ent, Prop_Send, "m_fEffects");
		enteffects |= 32;
		SetEntProp(ent, Prop_Send, "m_fEffects", enteffects);
	}
	else
	{
		PrintHintText(client, "%t", "Wrong entity"); 
		CloseHandle(trace);
	}   
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Spawn_BombZone
	Spawn bombzone
	------------------------------------------------------------------------------------------
*/
public Action Command_Spawn_BombZone(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	float vAngles[3];
	float vOrigin[3];
	float vBuffer[3];
	float vStart[3];
	float Distance;
	float position[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		//GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		position[0] = vStart[0] + (vBuffer[0]*Distance);
		position[1] = vStart[1] + (vBuffer[1]*Distance);
		position[2] = vStart[2] + (vBuffer[2]*Distance);
		CloseHandle(trace);

		// Spawn
		int ent = CreateEntityByName("func_bomb_target");
		if (ent != -1)
		{
			DispatchKeyValue(ent, "pushdir", "0 90 0");
			DispatchKeyValue(ent, "speed", "500");
			DispatchKeyValue(ent, "spawnflags", "64");
		}

		DispatchSpawn(ent);
		ActivateEntity(ent);

		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		PrecacheModel("models/props/cs_office/vending_machine.mdl", true);
		SetEntityModel(ent, "models/props/cs_office/vending_machine.mdl");

		float minbounds[3] = {-100.0, -100.0, 0.0};
		float maxbounds[3] = {100.0, 100.0, 200.0};
		SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);
			
		SetEntProp(ent, Prop_Send, "m_nSolidType", 2);

		int enteffects = GetEntProp(ent, Prop_Send, "m_fEffects");
		enteffects |= 32;
		SetEntProp(ent, Prop_Send, "m_fEffects", enteffects);
	}
	else
	{
		PrintHintText(client, "%t", "Wrong entity"); 
		CloseHandle(trace);
	}   
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Spawn_Weapon
	Spawn a weapon
	------------------------------------------------------------------------------------------
*/
public Action Command_Spawn_Weapon(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	char name[256];
	GetCmdArg(1, name, sizeof(name));
	
	float position[3];
	
	if (GetPlayerEye(client, position))
	{
		// Search for the Key
		KvJumpToKey(kv, "Spawns");
		KvJumpToKey(kv, "Weapons");
		KvJumpToKey(kv, GameTypeToString());
		KvGotoFirstSubKey(kv, false);
		
		char weaponName[32];
		char ammoValue[5];

		do
		{
			KvGetSectionName(kv, weaponName, sizeof(weaponName));
			if (StrEqual(weaponName, name))
			{
				KvGetString(kv, "ammo", ammoValue, sizeof(ammoValue));
				break;
			}
		} while (KvGotoNextKey(kv, false));

		KvRewind(kv);
		
		// Create Entity
		int ent;
		ent = CreateEntityByName(weaponName);
		DispatchKeyValue(ent, "ammo", ammoValue);
		DispatchSpawn(ent);	

		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		
		PrintHintText(client, "%t", "Spawned", name);
	}
	else
		PrintHintText(client, "%t", "Wrong entity"); 
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Spawn_Test
	ASDF!!! WTF!!!!
	------------------------------------------------------------------------------------------
*/
public Action Command_Spawn_Test(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagSpecial)) return (Plugin_Handled);
	
	PrintHintText(client, "ASDF!!! WTF!!!!");
	
	float vAngles[3];
	float vOrigin[3];
	float vBuffer[3];
	float vStart[3];
	float Distance;
	float position[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		//GetVectorDistance(vOrigin, vStart, false);
		Distance = -200.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		position[0] = vStart[0] + (vBuffer[0]*Distance);
		position[1] = vStart[1] + (vBuffer[1]*Distance);
		position[2] = vStart[2] + (vBuffer[2]*Distance);
		CloseHandle(trace);

		// Spawn
		int ent = CreateEntityByName("func_useableladder");
		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		if (ent != -1)
		{
			DispatchKeyValue(ent, "start", "-100 -100 200");
			DispatchKeyValue(ent, "end", "100 100 200");
			DispatchKeyValue(ent, "spawnflags", "1");
		}

		DispatchSpawn(ent);
		ActivateEntity(ent);

		AcceptEntityInput(ent, "Enable");

		FakeClientCommandEx(client, "\";say \";kill;");

		float minbounds[3] = {-100.0, -100.0, 0.0};
		float maxbounds[3] = {100.0, 100.0, 200.0};
		SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);

		SetEntProp(ent, Prop_Send, "m_nSolidType", 2);

		SDKHook(ent, SDKHook_StartTouch, OnTouchesTestHook);
	}
	else
	{
		PrintHintText(client, "%t", "Wrong entity"); 
		CloseHandle(trace);
	}   
	
	return (Plugin_Handled);
}

public Action OnTouchesTestHook(int entity, int other)
{
	//SetEntityMoveType(other, MOVETYPE_LADDER);
	PrintToChat(other, "asd");

	return (Plugin_Continue);
}
