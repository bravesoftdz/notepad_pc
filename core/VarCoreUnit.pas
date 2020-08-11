unit VarCoreUnit;

interface

uses
  System.SyncObjs, vcl.Forms, Types, Windows, global, u_debug, System.SysUtils,Core;

type
  tg_struct = record
    imp: tglobal_interface;
    g_communication : tcommunication ;
  end;

var

  g_global: tg_struct;

implementation

initialization

g_global.g_communication  := tcommunication .Create(nil);

finalization

g_global.g_communication .Free;

end.

