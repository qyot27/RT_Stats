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

int __cdecl QueryFatVolume(const char *relname) {
	// Return:- 1=FAT. 0 = Not FAT. -1 on error;
	int ret = -1;
	char FullPath[_MAX_PATH];
	if(_fullpath(FullPath, relname, _MAX_PATH ) != NULL ) {
		TCHAR RootPathName[_MAX_PATH];
		_splitpath(FullPath,RootPathName, NULL,NULL,NULL );
		char *p=RootPathName;
		while(*p++);
		--p;
		if(p>RootPathName && p[-1] != '\\') {*p++='\\';*p='\0';}
		TCHAR FileSystemNameBuffer[MAX_PATH+1];
		BOOL result = GetVolumeInformation(RootPathName,NULL,0,NULL,NULL,NULL,FileSystemNameBuffer,MAX_PATH+1);
		if(result) {
			ret = (_strnicmp(FileSystemNameBuffer,"FAT",3)==0) ?1:0;		// Just the 1st 3 characters (FAT/FAT32)
		}
	}
	return ret;
}

__int64 __cdecl QueryDiskFreeSpace(const char *relname) {
	__int64 ret = -1;
	char FullPath[_MAX_PATH];
	if(_fullpath(FullPath, relname, _MAX_PATH ) != NULL ) {
		TCHAR RootPathName[_MAX_PATH];
		_splitpath(FullPath,RootPathName, NULL,NULL,NULL );
		char *p=RootPathName;
		while(*p++);
		--p;
		if(p>RootPathName && p[-1] != '\\') {*p++='\\';*p='\0';}
		ULARGE_INTEGER FreeBytesAvailableToCaller;
		ULARGE_INTEGER TotalNumberOfBytes;
		ULARGE_INTEGER TotalNumberOfFreeBytes;
		BOOL result=GetDiskFreeSpaceEx(RootPathName,&FreeBytesAvailableToCaller,&TotalNumberOfBytes,&TotalNumberOfFreeBytes);
		if(result) {
			ret = __int64(FreeBytesAvailableToCaller.QuadPart);
		}
	}
	return ret;
}

__int64 __cdecl QueryMaxFileSize(const char *relname) {
	__int64 ret = -1;
	char FullPath[_MAX_PATH];
	if(_fullpath(FullPath, relname, _MAX_PATH ) != NULL ) {
		TCHAR RootPathName[_MAX_PATH];
		_splitpath(FullPath,RootPathName, NULL,NULL,NULL );
		char *p=RootPathName;
		while(*p++);
		--p;
		if(p>RootPathName && p[-1] != '\\') {*p++='\\';*p='\0';}
		ULARGE_INTEGER FreeBytesAvailableToCaller;
		ULARGE_INTEGER TotalNumberOfBytes;
		ULARGE_INTEGER TotalNumberOfFreeBytes;
		if(GetDiskFreeSpaceEx(RootPathName,&FreeBytesAvailableToCaller,&TotalNumberOfBytes,&TotalNumberOfFreeBytes)) {
			__int64 dfs = __int64(FreeBytesAvailableToCaller.QuadPart) - 0x100000I64;	// minus 1MB
			if(dfs > 0) {
				TCHAR FileSystemNameBuffer[MAX_PATH+1];
				if(GetVolumeInformation(RootPathName,NULL,0,NULL,NULL,NULL,FileSystemNameBuffer,MAX_PATH+1)) {
					if(_strnicmp(FileSystemNameBuffer,"FAT",3)==0) {	// Just the 1st 3 characters (FAT/FAT32)
						if(dfs>0xFFF00000i64) dfs = 0xFFF00000i64; 		// limit 4GB-1MB on FAT32
					}
					ret = dfs;
				}
			}
		}
	}
	return ret;
}
