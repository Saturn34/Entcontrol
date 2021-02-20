/* 
	------------------------------------------------------------------------------------------
	EntControl::NativeSamples::SpawnNPC
	by Raffael Holz aka. LeGone
	Idea by Franc1sco
	
	Spawn zombie-NPC on the position the caller is looking at.
	------------------------------------------------------------------------------------------
*/

#include <sourcemod>
#include <sdktools>
#include <entcontrol>

#pragma newdecls required
#pragma semicolon 1

public void OnPluginStart()
{
	RegAdminCmd("sm_spawn_zombie", Command_Spawn_Zombie, ADMFLAG_GENERIC);
}

/* 
	------------------------------------------------------------------------------------------
	COMMAND_SPAWN_ZOMBIE
	THis function will spawn a zombie on the players-aim-position
	------------------------------------------------------------------------------------------
*/
public Action Command_Spawn_Zombie(int client, int args)
{
	float position[3];

	if (GetPlayerEye(client, position))
		EC_NPC_Spawn("npc_zombie", position[0], position[1], position[2]);
	else
		PrintHintText(client, "Wrong Position!"); 

	return Plugin_Handled;
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
		TR_GetEndPosition(pos, trace);
		delete trace;
		return true;
	}

	delete trace;
	return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}
