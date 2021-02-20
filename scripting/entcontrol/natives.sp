/* 
	------------------------------------------------------------------------------------------
	EntControl::Natives
	by Raffael Holz aka. LeGone
	------------------------------------------------------------------------------------------
*/

public void RegisterNatives()
{
	CreateNative("EC_NPC_Spawn", Native_NPC_Spawn);
}

public int Native_NPC_Spawn(Handle plugin, int numParams)
{
	float position[3];
	int npcNameLength;
	
	// Get the npc-name
	GetNativeStringLength(1, npcNameLength);
	if (npcNameLength > 0)
	{
		char[] npcName = new char[npcNameLength + 1];
		GetNativeString(1, npcName, npcNameLength + 1);

		// Get the npc-position
		position[0] = view_as<float>(GetNativeCell(2));
		position[1] = view_as<float>(GetNativeCell(3));
		position[2] = view_as<float>(GetNativeCell(4));
		
		// Try to spawn the npc
		BaseNPC_SpawnByName(npcName, position);
	}
}