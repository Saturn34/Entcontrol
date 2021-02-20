/* 
	------------------------------------------------------------------------------------------
	EntControl::Weapons
	by Raffael Holz aka. LeGone
	
	mostly ripped from TacticalGunMod2
	------------------------------------------------------------------------------------------
*/

// Admin Flags
Handle gAdminFlagWeapons;

int gExplosive1;
int gMarkerSprite;

float gRocketSpeed;
int gRocketDamage;
float gPlasmaSpeed;
int gPlasmaDamage;
float gBulletSpeed;
int gBulletDamage;
float gMineTimer;
int gMineDamage;

#include "FixedWeapons/BaseFixed.sp"

public void InitWeapons()
{
	gLaser1 = PrecacheModel("materials/sprites/laser.vmt");
	gSmoke1 = PrecacheModel("materials/effects/fire_cloud1.vmt");
	gHalo1 = PrecacheModel("materials/sprites/halo01.vmt");
	gGlow1 = PrecacheModel("sprites/blueglow2.vmt", true);
	gExplosive1 = PrecacheModel("materials/sprites/sprite_fire01.vmt");
	gMarkerSprite = PrecacheModel("materials/effects/rollerglow.vmt");
	
	PrecacheModel("models/props_wasteland/rockgranite03b.mdl");
	PrecacheModel("models/Effects/combineball.mdl");
	
	PrecacheSound("weapons/ar2/fire1.wav");
	PrecacheSound("weapons/rpg/rocketfire1.wav");
	PrecacheSound("weapons/explode3.wav");
	PrecacheSound("weapons/physcannon/energy_disintegrate4.wav");
	PrecacheSound("weapons/physcannon/energy_sing_explosion2.wav");
	PrecacheSound("ambient/explosions/citadel_end_explosion2.wav");
	PrecacheSound("ambient/explosions/citadel_end_explosion1.wav");
	PrecacheSound("ambient/energy/weld1.wav");
	PrecacheSound("weapons/flaregun/fire.wav");
	
	if (KvJumpToKey(kv, "Weapons"))
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			char sectionName[32];
			do
			{
				KvGetSectionName(kv, sectionName, sizeof(sectionName));
				if (StrEqual(sectionName, "rocket"))
				{
					gRocketSpeed = KvGetFloat(kv, "speed", 1500.0);
					gRocketDamage = KvGetNum(kv, "damage", 200);
				}
				else if (StrEqual(sectionName, "plasma"))
				{
					gPlasmaSpeed = KvGetFloat(kv, "speed", 3500.0);
					gPlasmaDamage = KvGetNum(kv, "damage", 200);
				}
				else if (StrEqual(sectionName, "bullet"))
				{
					gBulletSpeed = KvGetFloat(kv, "speed", 2500.0);
					gBulletDamage = KvGetNum(kv, "damage", 25);
				}
				else if (StrEqual(sectionName, "mine"))
				{
					gMineTimer = KvGetFloat(kv, "timer", 10.0);
					gMineDamage = KvGetNum(kv, "damage", 250);
				}
			} while (KvGotoNextKey(kv, false));

			KvRewind(kv);
		}
		else
		{
			LogError("Unable to go to the first subkey in the \"Weapons\"-Node!");
		}
	}
	else
	{
		LogError("\"Weapons\"-Node could not be found!");
	}

	FixedBase_Init();
}

public void RegWeaponsCommands()
{
	gAdminFlagWeapons = CreateConVar("sm_entcontrol_weapons_fl", "z", "The needed Flag to use weapons");
	RegConsoleCmd("sm_entcontrol_weapon_rocket", Command_Rocket, "Shoot Rocket");
	RegConsoleCmd("sm_entcontrol_weapon_plasma", Command_Plasma, "Shoot Plasma");
	RegConsoleCmd("sm_entcontrol_weapon_bullet", Command_Bullet, "Shoot Bullet");
	RegConsoleCmd("sm_entcontrol_weapon_mine", Command_Mine, "Drop Mine");
	RegConsoleCmd("sm_entcontrol_weapon_ion", Command_IonCannon, "Ion-Cannon");
	RegConsoleCmd("sm_entcontrol_weapon_tvmissile", Command_TVMissile, "Shoot TVMissile");
}

/* 
	------------------------------------------------------------------------------------------
	Projectile
	------------------------------------------------------------------------------------------
*/
stock void Projectile(bool homing, int client, float position[3], float direction[3], char model[128], float speed, int damage, char soundFire[128] = "", bool heavyProjectile = false, float color[3] = {1.0, 1.0, 1.0})
{
	float anglevector[3], resultposition[3];
	int entity;
	
	GetAngleVectors(direction, anglevector, NULL_VECTOR, NULL_VECTOR);
	//NormalizeVector(anglevector, anglevector);
	AddVectors(position, anglevector, resultposition);
	ScaleVector(anglevector, speed);

	if (gameMod == CSS || gameMod == CSGO)
	{
		entity = CreateEntityByName("hegrenade_projectile");
	}
	else if (gameMod == TF)
	{
		entity = CreateEntityByName("tf_projectile_rocket");
	}
	else if (gameMod == HL2MP || gameMod == OBSIDIAN)
	{
		entity = CreateEntityByName("rpg_missile");
	}
	else
	{
		entity = CreateEntityByName("rpg_missile");
		//entity = CreateEntityByName("npc_grenade_frag");
	}

	if (client > 0)
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	
	// Set the damage
	SetEntPropFloat(entity, Prop_Send, "m_flDamage", float(damage));
	
	setm_takedamage(entity, DAMAGE_NO);
	
	// Spawn it
	DispatchSpawn(entity);
	
	float vecmax[3] = {4.0, 4.0, 4.0};
	float vecmin[3] = {-4.0, -4.0, -4.0};
	SetEntPropVector(entity, Prop_Send, "m_vecMins", vecmin);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecmax);
	
	TeleportEntity(entity, resultposition, direction, anglevector);
	
	if (gameMod != HL2MP && gameMod != OBSIDIAN)
	{
		SetEntityModel(entity, model);

		if (heavyProjectile)
		{
			int gascloud = CreateEntityByName("env_rockettrail");
			DispatchKeyValueVector(gascloud,"Origin", resultposition);
			DispatchKeyValueVector(gascloud,"Angles", direction);
			SetEntPropVector(gascloud, Prop_Send, "m_StartColor", color);
			SetEntPropFloat(gascloud, Prop_Send, "m_Opacity", 0.5);
			SetEntPropFloat(gascloud, Prop_Send, "m_SpawnRate", 100.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_ParticleLifetime", 0.5);
			SetEntPropFloat(gascloud, Prop_Send, "m_StartSize", 5.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_EndSize", 30.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_SpawnRadius", 0.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_MinSpeed", 0.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_MaxSpeed", 10.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_flFlareScale", 1.0);
			DispatchSpawn(gascloud);

			char entIndex[64];
			IntToString(entity, entIndex, sizeof(entIndex));
			DispatchKeyValue(entity, "targetname", entIndex);
			SetVariantString(entIndex);
			AcceptEntityInput(gascloud, "SetParent");
	
			SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", EntIndexToEntRef(gascloud));
		}

		SDKHook(entity, SDKHook_StartTouch, Projectile_TouchHook);
		SDKHook(entity, SDKHook_OnTakeDamage, Projectile_DamageHook);
	}
	
	if (gameMod == CSS || gameMod == CSGO)
	{
		SetEntityMoveType(entity, MOVETYPE_FLY);
	}
	else if (gameMod == TF)
	{
		SetEntityMoveType(entity, MOVETYPE_FLY);
	}
	else if (gameMod == HL2MP || gameMod == OBSIDIAN)
	{
		//SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	}
	else
	{
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	}
	
	if (homing)
	{
		Handle data;
		CreateDataTimer(0.1, Projectile_Think, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, EntIndexToEntRef(entity));
		WritePackFloat(data, speed);
		WritePackCell(data, client);
		
		if (client > 0)
		{
			// Make Viewpunch
			float angle[3] = {0.0, 0.0, 0.0};

			angle[0] = -6.0;
			angle[1] = GetRandomFloat(-2.0, 2.0);

			makeviewpunch(client, angle);
		}
	}
	
	setm_takedamage(entity, DAMAGE_YES);
	
	if (soundFire[0])
		EmitSoundToAll(soundFire, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, position);
}

public Action Projectile_TouchHook(int entity, int other)
{
	if (other != 0)
	{
		if (other == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))
			return (Plugin_Continue);
		else if (!IsEntityCollidable(other, true, true, true))
			return (Plugin_Continue);
	}
	
	Projectile_Final(entity, other);

	return (Plugin_Continue);
}

public Action Projectile_DamageHook(int entity, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES)
		Projectile_Final(entity, 0);

	return (Plugin_Continue);
}

public Action Projectile_Think(Handle Timer, Handle data)
{
	int entity, client;
	float speed;
	
	ResetPack(data);
	entity = EntRefToEntIndex(ReadPackCell(data));
	speed = ReadPackFloat(data);
	client = ReadPackCell(data);

	if (entity != INVALID_ENT_REFERENCE)
	{
		if (IsClientConnectedIngame(client) && IsPlayerAlive(client))
		{
			float cleyepos[3];
			float cleyeangle[3];
			float resultposition[3];
			float entPosition[3];
			float vecangle[3];
			float angle[3];

			GetClientEyePosition(client, cleyepos);
			GetClientEyeAngles(client, cleyeangle);

			Handle traceresulthandle = INVALID_HANDLE;

			traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterrocket, client);

			if (TR_DidHit(traceresulthandle) == true)
			{
				TR_GetEndPosition(resultposition, traceresulthandle);
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entPosition);

				MakeVectorFromPoints(entPosition, resultposition, vecangle);
				NormalizeVector(vecangle, vecangle);
				GetVectorAngles(vecangle, angle);
				ScaleVector(vecangle, speed);
				TeleportEntity(entity, NULL_VECTOR, angle, vecangle);
			}

			CloseHandle(traceresulthandle);
		}
		return (Plugin_Continue);
	}

	return (Plugin_Stop);
}

public void Projectile_Final(int entity, int other)
{
	SDKUnhook(entity, SDKHook_StartTouch, Projectile_TouchHook);
	SDKUnhook(entity, SDKHook_OnTakeDamage, Projectile_DamageHook);

	if (GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES)
	{
		setm_takedamage(entity, DAMAGE_NO);
		float entityposition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
		float damage;
		if (gameMod == HL2MP)
			damage = 100.0;
		else
			damage = GetEntPropFloat(entity, Prop_Send, "m_flDamage");
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

		int gasentity = EntRefToEntIndex(GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity"));
		if (gasentity != INVALID_ENT_REFERENCE)
		{
			RemoveEntity(gasentity);
			
			// Make explosion
			entityposition[2] = entityposition[2] + 15.0;
			makeexplosion(IsClientConnectedIngame(client) ? client : 0, -1, entityposition, "", RoundToZero(damage));
			EmitSoundToAll("weapons/explode3.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition);
		}
		else
		{
			if (other)
				MakeDamage(IsClientConnectedIngame(client) ? client : 0, other, RoundToZero(damage), DMG_BULLET, 50.0, entityposition);
		}
			
		RemoveEntity(entity);
	}
}

/* 
	------------------------------------------------------------------------------------------
	Command_Rocket
	Rocketlauncher
	------------------------------------------------------------------------------------------
*/
public Action Command_Rocket(int client, int args)
{
	if (CanUseCMD(client, gAdminFlagWeapons))
	{
		float clienteyeangle[3];
		float clienteyeposition[3];
		GetClientEyeAngles(client, clienteyeangle);
		GetClientEyePosition(client, clienteyeposition);
		
		Projectile(true, client, clienteyeposition, clienteyeangle, "models/weapons/w_missile_launch.mdl", gRocketSpeed, gRocketDamage, "weapons/rpg/rocketfire1.wav", true);
	}

	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Plasma
	Plasma
	------------------------------------------------------------------------------------------
*/
public Action Command_Plasma(int client, int args)
{
	if (CanUseCMD(client, gAdminFlagWeapons))
	{
		float clienteyeangle[3];
		float clienteyeposition[3];
		GetClientEyeAngles(client, clienteyeangle);
		GetClientEyePosition(client, clienteyeposition);
		
		Projectile(true, client, clienteyeposition, clienteyeangle, "models/Effects/combineball.mdl", gPlasmaSpeed, gPlasmaDamage, "weapons/Irifle/irifle_fire2.wav", true, view_as<float>({0.4, 1.0, 1.0}));
	}

	return (Plugin_Handled);
}

// - Mine
public Action Command_Mine(int client, int args)
{
	if (CanUseCMD(client, gAdminFlagWeapons))
		MineAttack(client);

	return (Plugin_Handled);
}

stock void MineAttack(int client)
{
	float cleyepos[3];
	float cleyeangle[3];
	
	GetClientEyePosition(client, cleyepos);
	GetClientEyeAngles(client, cleyeangle);

	int entity;
	if (gameMod == CSS || gameMod ==CSGO)
	{
		entity = CreateEntityByName("hegrenade_projectile");
	}
	else if (gameMod == TF)
	{
		entity = CreateEntityByName("tf_projectile_pipe");
	}
	else if (gameMod == HL2MP || gameMod ==OBSIDIAN)
	{
		entity = CreateEntityByName("grenade_helicopter");
		DispatchKeyValue(entity, "spawnflags", "65536");
	}
	
	DispatchSpawn(entity);
	
	setm_takedamage(entity, DAMAGE_YES);
	
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	SetEntityModel(entity, "models/items/battery.mdl");
	TeleportEntity(entity, cleyepos, cleyeangle, cleyeangle);

	SetEntProp(entity, Prop_Data, "m_iHealth", 1);
	
	CreateTimer(gMineTimer, StartMine, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	
	SDKHook(entity, SDKHook_StartTouch, MineTouchHook);				
	SDKHook(entity, SDKHook_OnTakeDamage, MineDamageHook);
}

public Action StartMine(Handle Timer, any entityRef)
{
	int mine = EntRefToEntIndex(entityRef);
	
	if (mine != INVALID_ENT_REFERENCE)
		MineActive(mine);
}

public Action MineTouchHook(int entity, int other)
{
	float entityposition[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);	
	
	int laserent = CreateEntityByName("point_tesla");
	DispatchKeyValue(laserent, "m_flRadius", "100.0");
	DispatchKeyValue(laserent, "m_SoundName", "DoSpark");
	DispatchKeyValue(laserent, "beamcount_min", "42");
	DispatchKeyValue(laserent, "beamcount_max", "62");
	DispatchKeyValue(laserent, "texture", "sprites/physbeam.vmt");
	DispatchKeyValue(laserent, "m_Color", "255 255 255");
	DispatchKeyValue(laserent, "thick_min", "10.0");
	DispatchKeyValue(laserent, "thick_max", "11.0");
	DispatchKeyValue(laserent, "lifetime_min", "0.3");
	DispatchKeyValue(laserent, "lifetime_max", "0.3");
	DispatchKeyValue(laserent, "interval_min", "0.1");
	DispatchKeyValue(laserent, "interval_max", "0.2");
	DispatchSpawn(laserent);
	
	TeleportEntity(laserent, entityposition, NULL_VECTOR, NULL_VECTOR);
	
	AcceptEntityInput(laserent, "TurnOn");  
	AcceptEntityInput(laserent, "DoSpark");    
		
	if(other != 0)
	{
		if(other == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))
			return (Plugin_Continue);
		else if(!IsEntityCollidable(other, true, true, true))
			return (Plugin_Continue);
			
		MineActive(entity);
	}

	return (Plugin_Continue);
}

public Action MineDamageHook(int entity, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	MineActive(entity);
	
	return (Plugin_Handled);
}

stock void MineActive(int entity)
{
	SDKUnhook(entity, SDKHook_StartTouch, MineTouchHook);
	SDKUnhook(entity, SDKHook_OnTakeDamage, MineDamageHook);

	if(IsValidEntity(entity) && IsValidEdict(entity))
	{ 
		setm_takedamage(entity, DAMAGE_NO);
		float entityposition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

		AcceptEntityInput(entity, "Kill");
		
		DrawIonBeam(entityposition);
		TE_SetupBeamRingPoint(entityposition, 0.0, 500.0, gGlow1, gHalo1, 0, 0, 0.5, 10.0, 2.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(entityposition, 0.0, 500.0, gGlow1, gHalo1, 0, 0, 0.7, 10.0, 2.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(entityposition, 0.0, 500.0, gGlow1, gHalo1, 0, 0, 0.9, 10.0, 2.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(entityposition, 0.0, 500.0, gGlow1, gHalo1, 0, 0, 1.4, 10.0, 2.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();

		// Light
		int ent = CreateEntityByName("light_dynamic");

		DispatchKeyValue(ent, "_light", "120 120 255 255");
		DispatchKeyValue(ent, "brightness", "5");
		DispatchKeyValueFloat(ent, "spotlight_radius", 500.0);
		DispatchKeyValueFloat(ent, "distance", 500.0);
		DispatchKeyValue(ent, "style", "6");
		
		// SetEntityMoveType(ent, MOVETYPE_NOCLIP); 
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "TurnOn");
		
		TeleportEntity(ent, entityposition, NULL_VECTOR, NULL_VECTOR);
		
		KillEntity(ent, 1.0);
		
		entityposition[2] += 15.0;
		makeexplosion(IsClientConnectedIngame(client) ? client : 0, -1, entityposition, "", gMineDamage);
		
		env_shake(entityposition, 120.0, 1000.0, 3.0, 250.0);
		
		EmitSoundToAll("weapons/physcannon/energy_disintegrate4.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition);
		
		// Knockback
		float vReturn[3];
		float vClientPosition[3];
		float dist;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			{	
				GetClientEyePosition(i, vClientPosition);

				dist = GetVectorDistance(vClientPosition, entityposition, false);
				if (dist < 1000.0)
				{
					MakeVectorFromPoints(entityposition, vClientPosition, vReturn);
					NormalizeVector(vReturn, vReturn);
					ScaleVector(vReturn, -5000.0);

					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vReturn);
				}
			}
		}
	}
}

/*
	------------------------------------------------------------------------------------------
	Command_IonCannon
	Shoots the ioncannon
	Thanks to Peace-Maker
	------------------------------------------------------------------------------------------
*/
public Action Command_IonCannon(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagWeapons)) return (Plugin_Handled);
	
	float vAngles[3];
	float vOrigin[3];
	float vStart[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);

		CloseHandle(trace);

		Handle data = CreateDataPack();
		WritePackFloat(data, vStart[0]);
		WritePackFloat(data, vStart[1]);
		WritePackFloat(data, vStart[2]);
		WritePackCell(data, 320); // Distance
		WritePackFloat(data, 0.0); // nphi
		ResetPack(data);

		IonAttack(data);
	}
	else
	{
		PrintHintText(client, "%t", "Wrong entity"); 
		CloseHandle(trace);
	}

	return (Plugin_Handled);
}

public void DrawIonBeam(float startPosition[3])
{
	float position[3];
	position[0] = startPosition[0];
	position[1] = startPosition[1];
	position[2] = startPosition[2] + 1500.0;	

	TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 0.15, 25.0, 25.0, 0, 1.0, {0, 150, 255, 255}, 3 );
	TE_SendToAll();
	position[2] -= 1490.0;
	TE_SetupSmoke(startPosition, gSmoke1, 10.0, 2);
	TE_SendToAll();
	TE_SetupGlowSprite(startPosition, gGlow1, 1.0, 1.0, 255);
	TE_SendToAll();
}

public void IonAttack(Handle data)
{	
	float startPosition[3];
	float position[3];
	
	ResetPack(data);
	startPosition[0] = ReadPackFloat(data);
	startPosition[1] = ReadPackFloat(data);
	startPosition[2] = ReadPackFloat(data);
	int distance = ReadPackCell(data);
	float nphi = ReadPackFloat(data);
	
	if (distance > 0)
	{
		EmitSoundToAll("ambient/energy/weld1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);
		
		// Stage 1
		float s=Sine(nphi/360*6.28)*distance;
		float c=Cosine(nphi/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[2] = startPosition[2];
		
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);

		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);
		
		// Stage 2
		s=Sine((nphi+45.0)/360*6.28)*distance;
		c=Cosine((nphi+45.0)/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);
		
		// Stage 3
		s=Sine((nphi+90.0)/360*6.28)*distance;
		c=Cosine((nphi+90.0)/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);
		
		// Stage 4
		s=Sine((nphi+135.0)/360*6.28)*distance;
		c=Cosine((nphi+135.0)/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);

		if (nphi >= 360)
			nphi = 0.0;
		else
			nphi += 5.0;
	}
	distance -= 5;
	
	if (distance > -50)
	{
		Handle ndata;
		CreateDataTimer(0.1, DrawIon, ndata, TIMER_FLAG_NO_MAPCHANGE);	
		WritePackFloat(ndata, startPosition[0]);
		WritePackFloat(ndata, startPosition[1]);
		WritePackFloat(ndata, startPosition[2]);
		WritePackCell(ndata, distance);
		WritePackFloat(ndata, nphi);
	}
	else
	{
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[2] += 1500.0;
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 5.0, 30.0, 30.0, 0, 1.0, {255, 255, 255, 255}, 3);
		TE_SendToAll();
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 4.0, 50.0, 50.0, 0, 1.0, {200, 255, 255, 255}, 3);
		TE_SendToAll();
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 3.0, 80.0, 80.0, 0, 1.0, {100, 255, 255, 255}, 3);
		TE_SendToAll();
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.0, 100.0, 100.0, 0, 1.0, {0, 255, 255, 255}, 3);
		TE_SendToAll();
		
		TE_SetupSmoke(startPosition, gSmoke1, 350.0, 15);
		TE_SendToAll();
		TE_SetupGlowSprite(startPosition, gGlow1, 3.0, 15.0, 255);
		TE_SendToAll();

		makeexplosion(0, -1, startPosition, "", 500);

		position[2] = startPosition[2] + 50.0;
		float fDirection[3] = {-90.0,0.0,0.0};
		env_shooter(fDirection, 25.0, 0.1, fDirection, 800.0, 120.0, 120.0, position, "models/props_wasteland/rockgranite03b.mdl");

		env_shake(startPosition, 120.0, 10000.0, 15.0, 250.0);

		TE_SetupExplosion(startPosition, gExplosive1, 10.0, 1, 0, 0, 5000);
		TE_SendToAll();
		
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 0.5, 100.0, 5.0, {150, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 5.0, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 2.5, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 6.0, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();

		// Light
		int ent = CreateEntityByName("light_dynamic");

		DispatchKeyValue(ent, "_light", "255 255 255 255");
		DispatchKeyValue(ent, "brightness", "5");
		DispatchKeyValueFloat(ent, "spotlight_radius", 500.0);
		DispatchKeyValueFloat(ent, "distance", 500.0);
		DispatchKeyValue(ent, "style", "6");

		// SetEntityMoveType(ent, MOVETYPE_NOCLIP); 
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "TurnOn");
	
		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		
		KillEntity(ent, 3.0);
		
		// Sound
		EmitSoundToAll("ambient/explosions/citadel_end_explosion1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);
		EmitSoundToAll("ambient/explosions/citadel_end_explosion2.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);	

		// Blend
		sendfademsg(0, 10, 200, FFADE_OUT, 255, 255, 255, 150);
		
		// Knockback
		float vReturn[3];
		float vClientPosition[3];
		float dist;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			{	
				GetClientEyePosition(i, vClientPosition);

				dist = GetVectorDistance(vClientPosition, position, false);
				if (dist < 1000.0)
				{
					MakeVectorFromPoints(position, vClientPosition, vReturn);
					NormalizeVector(vReturn, vReturn);
					ScaleVector(vReturn, 10000.0 - dist*10);

					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vReturn);
				}
			}
		}
	}
}

public Action DrawIon(Handle Timer, any data)
{
	IonAttack(data);
	
	return (Plugin_Stop);
}

/* 
	------------------------------------------------------------------------------------------
	Command_Bullet
	Shoots the sentrygun projectile
	------------------------------------------------------------------------------------------
*/
public Action Command_Bullet(int client, int args)
{
	if (!CanUseCMD(client, gAdminFlagWeapons)) return (Plugin_Handled);

	float clienteyeangle[3];
	float clienteyeposition[3];
	GetClientEyePosition(client, clienteyeposition);
	GetClientEyeAngles(client, clienteyeangle);
	
	Projectile(false, client, clienteyeposition, clienteyeangle, "models/weapons/w_missile_launch.mdl", gBulletSpeed, gBulletDamage, "weapons/ar2/fire1.wav");
	
	return (Plugin_Handled);
}

/* 
	------------------------------------------------------------------------------------------
	Command_TVMissile
	Thanks to Thrawn2
	------------------------------------------------------------------------------------------
*/
public Action Command_TVMissile(int client, int args)
{
	if (CanUseCMD(client, gAdminFlagWeapons))
		TVMissile(client);

	return (Plugin_Handled);
}

int gTV[MAXPLAYERS+1], gTVMissile[MAXPLAYERS+1];
stock void TVMissile(int client)
{
	float clienteyeangle[3], anglevector[3], clienteyeposition[3], resultposition[3];
	int entity;
	char steamid[64];
	GetClientEyeAngles(client, clienteyeangle);
	GetClientEyePosition(client, clienteyeposition);
	GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	//ScaleVector(anglevector, 10.0);
	AddVectors(clienteyeposition, anglevector, resultposition);
	NormalizeVector(anglevector, anglevector);
	ScaleVector(anglevector, 1500.0);
	
	GetClientAuthId(client, AuthId_Steam2, steamid, 64);
	Format(steamid, 64, "%s%f", steamid, GetGameTime());

	if (gameMod == CSS || gameMod ==CSGO)
	{
		entity = CreateEntityByName("hegrenade_projectile");
		SetEntityMoveType(entity, MOVETYPE_FLY);
	}
	else if (gameMod == TF)
	{
		entity = CreateEntityByName("tf_projectile_rocket");
		SetEntityMoveType(entity, MOVETYPE_FLY);
	}
	else if (gameMod == HL2MP || gameMod ==OBSIDIAN)
	{
		entity = CreateEntityByName("rpg_missile");
		//SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	}
	else
	{
		entity = CreateEntityByName("npc_grenade_frag");
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	}
	
	if (entity != -1)
	{
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		setm_takedamage(entity, DAMAGE_NO);
		DispatchSpawn(entity);
		
		TeleportEntity(entity, resultposition, clienteyeangle, anglevector);
		
		if (gameMod != HL2MP && gameMod != OBSIDIAN)
		{
			float vecmax[3] = {4.0, 4.0, 4.0};
			float vecmin[3] = {-4.0, -4.0, -4.0};
			SetEntPropVector(entity, Prop_Send, "m_vecMins", vecmin);
			SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecmax);
			
			SetEntityModel(entity, "models/weapons/w_missile_launch.mdl");

			int gascloud = CreateEntityByName("env_rockettrail");
			DispatchKeyValueVector(gascloud,"Origin", resultposition);
			DispatchKeyValueVector(gascloud,"Angles", clienteyeangle);
			float smokecolor[3] = {1.0, 1.0, 1.0};
			SetEntPropVector(gascloud, Prop_Send, "m_StartColor", smokecolor);
			SetEntPropFloat(gascloud, Prop_Send, "m_Opacity", 0.5);
			SetEntPropFloat(gascloud, Prop_Send, "m_SpawnRate", 100.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_ParticleLifetime", 0.5);
			SetEntPropFloat(gascloud, Prop_Send, "m_StartSize", 5.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_EndSize", 30.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_SpawnRadius", 0.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_MinSpeed", 0.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_MaxSpeed", 10.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_flFlareScale", 1.0);
			DispatchSpawn(gascloud);
			
			DispatchKeyValue(entity, "targetname", steamid);
			SetVariantString(steamid);
			AcceptEntityInput(gascloud, "SetParent");
			SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", gascloud);
			
			SDKHook(entity, SDKHook_StartTouch, TVMissileTouchHook);
			SDKHook(entity, SDKHook_OnTakeDamage, TVMissileDamageHook);
		}
		
		EmitSoundToAll("weapons/rpg/rocketfire1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, clienteyeposition);
		
		setm_takedamage(entity, DAMAGE_YES);
	 
		float angle[3] = {0.0, 0.0, 0.0};

		angle[0] = -6.0;
		angle[1] = GetRandomFloat(-2.0, 2.0);

		makeviewpunch(client, angle);
		SetEntProp(client, Prop_Send, "m_iFOV", 60);
		
		// TV Missile
		char entIndex[6];
		IntToString(client, entIndex, sizeof(entIndex)-1);
		
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		
		int tv = CreateEntityByName("point_viewcontrol");
		DispatchKeyValue(tv, "spawnflags", "72");
		DispatchKeyValue(client, "targetname", entIndex);
		DispatchSpawn(tv);
		
		SetVariantString(steamid);
		AcceptEntityInput(tv, "Enable", client, tv, 0);
		
		gTVMissile[client] = entity;
		gTV[client] = tv;
		
		SDKHook(client, SDKHook_PreThink, OnPreThink);
	}
	else
		LogError("TVMissile(...)->Unable to create TV-Missile");
}

public void OnPreThink(int client)
{
	if(IsClientConnectedIngame(client))
	{
		if(IsPlayerAlive(client))
		{
			if (IsValidEdict(gTVMissile[client]) && IsValidEntity(gTVMissile[client]))
			{
				float cleyeangle[3];
				float rocketposition[3];
				float vecangle[3];

				GetClientEyeAngles(client, cleyeangle);
				GetEntPropVector(gTVMissile[client], Prop_Send, "m_vecOrigin", rocketposition);
				
				vecangle[0] = cleyeangle[0];
				vecangle[1] = cleyeangle[1];
				vecangle[2] = cleyeangle[2];
				
				GetAngleVectors(vecangle, vecangle, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(vecangle, vecangle);
				ScaleVector(vecangle, 800.0);
				AddVectors(rocketposition, vecangle, rocketposition);
				
				TeleportEntity(gTVMissile[client], NULL_VECTOR, cleyeangle, vecangle);
				
				// Just to be sure ...
				GetEntPropVector(gTVMissile[client], Prop_Send, "m_vecOrigin", rocketposition);
				TeleportEntity(gTV[client], rocketposition, cleyeangle, NULL_VECTOR);
				
				if (gNextPickup[client] < GetGameTime())
				{
					gNextPickup[client] = GetGameTime() + 0.5;
					
					for (int i=1; i <= MaxClients; i++)
					{
						if (IsClientConnectedIngame(i) && !IsFakeClient(i))
						{
							GetClientEyePosition(i, rocketposition);
							
							TE_SetupGlowSprite(rocketposition, gMarkerSprite, 0.5, 1.0, 255);
							TE_SendToClient(client);
						}
					}
				}
			}
			else
			{
				SDKUnhook(client, SDKHook_PreThink, OnPreThink);
				TVMissileResetClientView(client);
			}
		}
		else
		{
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);
			TVMissileResetClientView(client);
			TVMissileActive(gTVMissile[client]);
		}
	}
}

public Action TVMissileTouchHook(int entity, int other)
{
	if(other != 0)
	{
		if(!IsEntityCollidable(other, true, true, true))
			return (Plugin_Continue);
	}

	TVMissileActive(entity);

	return (Plugin_Continue);
}

public Action TVMissileDamageHook(int entity, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES)
		TVMissileActive(entity);

	return (Plugin_Continue);
}

stock void TVMissileResetClientView(int client)
{
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	
	if (IsValidEdict(gTV[client]) && IsValidEntity(gTV[client]))
	{
		AcceptEntityInput(gTV[client], "Disable");
		RemoveEntity(gTV[client]);
	}
}

stock void TVMissileActive(int entity)
{
	SDKUnhook(entity, SDKHook_StartTouch, TVMissileTouchHook);
	SDKUnhook(entity, SDKHook_OnTakeDamage, TVMissileDamageHook);

	if (IsValidEdict(entity) && IsValidEntity(entity))
	{
		float entityposition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

		int gasentity = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
		AcceptEntityInput(gasentity, "kill");
		AcceptEntityInput(entity, "Kill");
		entityposition[2] = entityposition[2] + 15.0;

		makeexplosion(IsClientConnectedIngame(client) ? client : 0, -1, entityposition, "", gRocketDamage);
		EmitSoundToAll("weapons/explode3.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition);
		
		TVMissileResetClientView(client);
	}
}
