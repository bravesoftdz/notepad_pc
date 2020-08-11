

unit uWindowsDPISet;

interface

uses
  Winapi.Windows, Registry;

type
  NET_API_STATUS = DWORD;

  _SERVER_INFO_101 = record
    sv101_platform_id: DWORD;
    sv101_name: LPWSTR;
    sv101_version_major: DWORD;
    sv101_version_minor: DWORD;
    sv101_type: DWORD;
    sv101_comment: LPWSTR;
  end;

  SERVER_INFO_101 = _SERVER_INFO_101;

  PSERVER_INFO_101 = ^SERVER_INFO_101;

  LPSERVER_INFO_101 = PSERVER_INFO_101;

const
  MAJOR_VERSION_MASK = $0F;

function NetServerGetInfo(servername: LPWSTR; level: DWORD; var bufptr): NET_API_STATUS; stdcall; external 'Netapi32.dll';

function NetApiBufferFree(Buffer: Pointer): NET_API_STATUS; stdcall; external 'Netapi32.dll';

type
  pfnRtlGetVersion = function(var RTL_OSVERSIONINFOEXW): LongInt; stdcall;

function GetWindowsVersion: integer;   //获取windows系统类型    6 为win7    10为win10

procedure SetDPI100(vfilename: string);//设置dpi

implementation


//////////实现/////////

function GetWindowsVersion: integer;

var
  Buffer: PSERVER_INFO_101;
  ver: RTL_OSVERSIONINFOEXW;
  RtlGetVersion: pfnRtlGetVersion;
begin
  Result := -1;
  Buffer := nil;
  // Win32MajorVersion and Win32MinorVersion are populated from GetVersionEx()...


  @RtlGetVersion := GetProcAddress(GetModuleHandle('ntdll.dll'), 'RtlGetVersion');
  if Assigned(RtlGetVersion) then
  begin
    ZeroMemory(@ver, SizeOf(ver));
    ver.dwOSVersionInfoSize := SizeOf(ver);

    if RtlGetVersion(ver) = 0 then
      Result := ver.dwMajorVersion; // shows 10.0
  end;

  if NetServerGetInfo(nil, 101, Buffer) = NO_ERROR then
  try
    result := Buffer.sv101_version_major and MAJOR_VERSION_MASK; // shows 10.0
  finally
    NetApiBufferFree(Buffer);
  end;
end;

procedure SetDPI100(vfilename: string);
var
  reg: TRegistry;
  lfilename: string;
  lwinver: Integer;
begin
  lfilename := vfilename;
  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;
  reg.OpenKey('\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers', true);
  if reg.ValueExists(lfilename) then
  begin
//    reg.DeleteValue(lfilename);
//   这里设置高分辨率 系统重启有效
  end;
  lwinver := GetWindowsVersion;
  case lwinver of
    6:
      begin
        reg.WriteString(lfilename, 'HIGHDPIAWARE');
      end;
    10:
      begin
        reg.WriteString(lfilename, '~ DPIUNAWARE');
      end;
  end;

  reg.Free;
end;

end.
