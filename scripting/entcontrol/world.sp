/* put the line below after all of the includes!
#pragma newdecls required
*/

/* 
	------------------------------------------------------------------------------------------
	EntControl::World
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

stock void World_TurnOffLights()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "light")) != INVALID_ENT_REFERENCE)
		if (IsValidEdict(entity) && IsValidEntity(entity))
			AcceptEntityInput(entity, "TurnOff");
}

stock void World_TurnOnLights()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "light")) != INVALID_ENT_REFERENCE)
		if (IsValidEdict(entity) && IsValidEntity(entity))
			AcceptEntityInput(entity, "TurnOn");
}

stock void World_EnableFog()
{
	int fog = -1;
	fog = FindEntityByClassname(fog, "env_fog_controller");
	
	if (fog != -1)
	{
		AcceptEntityInput(fog, "TurnOn");
	}
}

stock void World_DisableFog()
{
	int fog = -1;
	fog = FindEntityByClassname(fog, "env_fog_controller");
	
	if (fog != -1)
	{
		AcceptEntityInput(fog, "TurnOff");
	}
}
