unit utils;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.Notification, GR32_Image, scrollbar_bas, widgetScrollBar, VirtualTrees,
  widgetree, Vcl.ExtCtrls,  Vcl.StdCtrls, Vcl.Imaging.pngimage, System.Messaging,
  winapi.gdipobj, System.Generics.Collections, winapi.gdipapi;

type
  txx = record
    msg_id: string;
    title_date: string;
    body: string;
    ctype:string;
    token:string;
  end;
  tmsg_obj=record
    msg_type:string;
    msg_value:string;
  end;


  var ttx: tmsg_obj;


var
  clock_data: TObjectDictionary<string, TList<txx>>;
var
  message_bus: TMessageManager;

procedure text_out(txt: string; canvas: tcanvas; x, y, fontsize: integer;style:Integer; fontname: string; r, g, b: byte);
function GetGUID: string;
implementation

procedure text_out(txt: string; canvas: tcanvas; x, y, fontsize: integer;style:Integer; fontname: string; r, g, b: byte);
var
  font: tgpfont;
  pt: tgppointf;
  stringformat: tgpstringformat;
  brush: tgpsolidbrush;
  graphics: tgpgraphics;
begin

  graphics := tgpgraphics.create(canvas.handle);
  graphics.setsmoothingmode(smoothingmodeantialias);
  graphics.setinterpolationmode(interpolationmodehighqualitybicubic);

  font := tgpfont.create(fontname, fontsize, style);

  brush := tgpsolidbrush.create(makecolor(255, r, g, b));

  stringformat := tgpstringformat.create();

  pt := makepoint(x, y * 0.1 * 10);
  graphics.drawstring(txt, length(txt), font, pt, stringformat, brush);

  graphics.free;
  font.free;
  brush.free;
end;

function GetGUID: string;
var
LTep: TGUID;
sGUID: string;
begin
 CreateGUID(LTep);//更新GUID
 sGUID := GUIDToString(LTep);
 sGUID := StringReplace(sGUID, '-', '', [rfReplaceAll]); //去掉-线
 sGUID := Copy(sGUID, 2, Length(sGUID) - 2);//去掉大括号
 Result := sGUID;
 end;

initialization
  clock_data := TObjectDictionary<string, TList<txx>>.Create([doOwnsValues]);
   message_bus := TMessageManager.DefaultManager;
finalization
  clock_data.Free;

end.

