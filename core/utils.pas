unit utils;

interface

uses
  classes, winapi.windows, zlib, system.sysutils, vcl.graphics, winapi.gdipapi,
  winapi.gdipobj, idglobal, httpapp, vcl.extctrls, syncobjs, contnrs, vcl.forms,
  vcl.imaging.pngimage, shlobj, shellapi, variants, tlhelp32, ioutils,
  system.net.httpclient,  generics.collections;

procedure draw_polgo(canv: tcanvas; x1, y1, x2, y2, x3, y3: integer);

procedure text_outa(txt: string; canvas: tcanvas; x, y, fontsize: integer; fontname: string; r, g, b: byte);

implementation

procedure text_outa(txt: string; canvas: tcanvas; x, y, fontsize: integer; fontname: string; r, g, b: byte);
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

  font := tgpfont.create(fontname, fontsize, 0);

  brush := tgpsolidbrush.create(makecolor(255, r, g, b));

  stringformat := tgpstringformat.create();

  pt := makepoint(x, y * 0.1 * 10);
  graphics.drawstring(txt, length(txt), font, pt, stringformat, brush);

  graphics.free;
  font.free;
  brush.free;
end;

procedure textout(txt: string; canvas: tcanvas; x, y: integer; r, g, b: byte);
var
  graphics: tgpgraphics;
  fontfamily: tgpfontfamily;
  path: tgpgraphicspath;
  strformat: tgpstringformat;
  pen: tgppen;
begin

  graphics := tgpgraphics.create(canvas.handle);
  graphics.setsmoothingmode(smoothingmodeantialias);
  graphics.setinterpolationmode(interpolationmodehighqualitybicubic);

  fontfamily := tgpfontfamily.create('Î¢ÈíÑÅºÚ');

  strformat := tgpstringformat.create();
  path := tgpgraphicspath.create();

  path.addstring(txt, length(txt), fontfamily, 0, 80, makepoint(x, y), strformat);

  pen := tgppen.create(makecolor(155, r, g, b), 3);
  graphics.drawpath(pen, path);

  graphics.free;
  strformat.free;
  path.free;

end;

procedure draw_polgo(canv: tcanvas; x1, y1, x2, y2, x3, y3: integer);
var
  g: tgpgraphics;
  p: tgppen;
var
  ptarr: array of tgppoint;
begin

  setlength(ptarr, 3);
  g := tgpgraphics.create(canv.handle);
  g.setsmoothingmode(smoothingmodeantialias);
  g.setinterpolationmode(interpolationmodehighqualitybicubic);

  p := tgppen.create(makecolor(255, 117, 136, 154), 2);

  g.clear(makecolor(255, 245, 245, 245));
  ptarr[0].x := x1;
  ptarr[0].y := y1;
  ptarr[1].x := x2;
  ptarr[1].y := y2;
  ptarr[2].x := x3;
  ptarr[2].y := y3;

  g.drawpolygon(p, pgppoint(ptarr), length(ptarr));
  g.free;
  p.free;
end;

end.

