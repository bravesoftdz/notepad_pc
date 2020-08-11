program Project1;

uses
  Vcl.Forms,
  Winapi.Windows,
  frm_main in 'frm_main.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles,
  utils in 'utils.pas',
  frm_write_data in 'frm_write_data.pas' {set_frm},
  frm_reg in 'frm_reg.pas' {reg_fm},
  frm_login in 'frm_login.pas' {login_fm},
  frm_data_show in 'frm_data_show.pas' {frmCardContact};

{$R *.res}
Var Hwnd:Thandle;
begin


　　
　　 Hwnd:=FindWindow('TForm1','msg_single');
　　 If Hwnd=0 then
　　 Begin
　　   Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '弌峯宴禰';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
　　 End;
　




end.
