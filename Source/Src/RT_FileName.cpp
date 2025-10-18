/*
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*/

#include "RT_Stats.h"

AVSValue __cdecl RT_GetWorkingDir(AVSValue args, void* user_data, IScriptEnvironment* env) {
	char *myName="RT_GetWorkingDir: ";
	char Path[MAX_PATH];
	if(_getcwd(Path,MAX_PATH)==NULL) {
		env->ThrowError("%sCannot get cwd",myName);
	}
	char *p;
	for(p=Path;*p++;);
	--p;
	if(Path<p && (p[-1]!='\\' && p[-1]!='/'))
		*p++ ='\\';
	return env->SaveString(Path,int(p-Path));
}



AVSValue __cdecl RT_FilenameSplit(AVSValue args, void* user_data, IScriptEnvironment* env) {
	char *myName="RT_FilenameSplit: ";
	const char *relname	= args[0].AsString();
	const int get	= args[1].AsInt(15);
	if(get<=0 || get>15)									{env->ThrowError("%sget 1 -> 15 Only",myName);}
	char FullPath[MAX_PATH];
	if(_fullpath(FullPath, relname, _MAX_PATH ) == NULL )	{env->ThrowError("%sCannot get full path.",myName);}
	char Drive[_MAX_DRIVE];
	char Dir[_MAX_DIR];
	char Fname[_MAX_FNAME];
	char Ext[_MAX_EXT];
	_splitpath(FullPath, Drive, Dir, Fname, Ext );
	int sz = 0;
	if(get & 0x01)	sz += int(strlen(Drive));
	if(get & 0x02)	sz += int(strlen(Dir));
	if(get & 0x04)	sz += int(strlen(Fname));
	if(get & 0x08)	sz += int(strlen(Ext));
	char *pbf,*p,*s;
	if((pbf= new char [sz+1])==NULL)						{env->ThrowError("%sCannot allocate memory",myName);}
	p=pbf;
	if(get & 0x01) {
		for(s=Drive;*p++=*s++;);
		--p;
	}
	if(get & 0x02) {
		for(s=Dir;*p++=*s++;);
		--p;
	}
	if(get & 0x04) {
		for(s=Fname;*p++=*s++;);
		--p;
	}
	if(get & 0x08) {
		for(s=Ext;*p++=*s++;);
		--p;
	}
	AVSValue ret = env->SaveString(pbf);
	delete [] pbf;
	return ret;
}

AVSValue __cdecl RT_GetFullPathName(AVSValue args, void* user_data, IScriptEnvironment* env) {
	const char *relname	= args[0].AsString();
	AVSValue newargs[2]	=	{relname,15};
	return RT_FilenameSplit(AVSValue(newargs,2),NULL,env);
}

AVSValue __cdecl RT_GetFileExtension(AVSValue args, void* user_data, IScriptEnvironment* env) {
	const char *name	= args[0].AsString();
	char Ext[MAX_PATH];
	_splitpath(name, NULL, NULL, NULL, Ext );
	return env->SaveString(Ext);
}
