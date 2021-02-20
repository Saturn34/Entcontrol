/* 
	------------------------------------------------------------------------------------------
	EntControl::NativeSamples::WebInterface
	by Raffael Holz aka. LeGone
	
	Example of using the webserver-module
	------------------------------------------------------------------------------------------
*/

#undef REQUIRE_EXTENSIONS
#include <entcontrol>

#pragma newdecls required
#pragma semicolon 1

// We NEED to increase the stack-space! About 131072 bytes (131072/4=32768 cells).
// Otherwise it´s not possible to use the webserverforward-function
#pragma dynamic 32768

public Action EC_OnWebserverCallFunction(const int userID, const char[] func, const char[] arg, char[] result)
{
	PrintToServer("EC_OnWebserverCallFunction->Call to function %s(%s)", func, arg);

	strcopy(result, EC_MAXHTTPRESULT, "");
	
	if (StrEqual(func, "CreateHTMLTest"))
	{
		strcopy(result, EC_MAXHTTPRESULT, "<font color=\"0xffff66\">TEST</font>");
	}
	else if (StrEqual(func, "CreateHTMLTestTable"))
	{
		strcopy(result, EC_MAXHTTPRESULT, "<table border=\"1\"><tr><th>Berlin</th><th>Hamburg</th></tr><tr><td>Milj&ouml;h</td><td>Kiez</td></tr><tr><td>Buletten</td><td>Frikadellen</td></tr></table>");
	}
	else if (StrEqual(func, "GetHTTPIP"))
	{
		char ipaddy[32];
		EC_Web_GetIP(ipaddy);
		
		strcopy(result, EC_MAXHTTPRESULT, ipaddy);
	}
	else if (StrEqual(func, "GetHTTPPort"))
	{
		Format(result, EC_MAXHTTPRESULT, "%d", EC_Web_GetPort());
	}
	else if (StrEqual(func, "CRC32"))
	{
		char crc32[32];
		strcopy(crc32, strlen(arg), arg);
		EC_Dlib_CRC32(crc32);
		
		strcopy(result, EC_MAXHTTPRESULT, crc32);
	}
	else if (StrEqual(func, "MD5"))
	{	
		char md5[32];
		strcopy(md5, strlen(arg), arg);
		EC_Dlib_MD5(md5);
		
		strcopy(result, EC_MAXHTTPRESULT, md5);
	}
	else if (StrEqual(func, "HammingDistance"))
	{
		Format(result, EC_MAXHTTPRESULT, "%d", EC_Dlib_HammingDistance(100011, 101101));
	}
	else if (StrEqual(func, "Hash"))
	{	
		char hash[32];
		strcopy(hash, strlen(arg), arg);
		EC_Dlib_Hash(hash);
		
		strcopy(result, EC_MAXHTTPRESULT, hash);		
	}
	else if (StrEqual(func, "GaussianRandomHash"))
	{
		Format(result, EC_MAXHTTPRESULT, "%f", EC_Dlib_GaussianRandomHash(0, 0, 1));	
	}
	else
	{
		return Plugin_Continue;
	}
	
	PrintToServer("OnWebserverCallFunction->%s", result);
	
	return Plugin_Stop;
}
