unit viewCore;

interface

uses Messages, Classes, Dialogs, Winapi.Windows, Vcl.Graphics, u_debug, forms, Menus,SysUtils,Registry,ScktComp,Controls,u_ExceptionForm;

const
  WM_MYTEST = WM_USER + $1000; // 测试用

type
  TviewCore = class
  private
    FHandle: THandle;
    procedure WinProc(var Msg: TMessage);
    procedure WMMyTest(var Msg: TMessage); message WM_MYTEST; // 测试用
    procedure AppMsg(var Msg: TMsg; var Handled: Boolean);
    function MainWindowHook(var Message: TMessage): Boolean;
    procedure OnException(Sender: TObject; E: Exception);
  public
    constructor Create;
    destructor Destroy; override;
    property Handle: THandle read FHandle;
  end;

var
  vCore: TviewCore;

implementation

{ TMyClass }
uses MainFrm, test_chat, test_group, global, VarCoreUnit;

var
  old_appmessage: TMessageEvent;

  // Listens to messages sent to the application and looks if a window is inserted.
function TviewCore.MainWindowHook(var Message: TMessage): Boolean;
begin
  Result := false;
end;

constructor TviewCore.Create;
begin
  if FHandle = 0 then
    FHandle := AllocateHwnd(WinProc);
  old_appmessage := Application.OnMessage;
  Application.OnMessage := AppMsg; // 总消息处理
  Application.HookMainWindow(MainWindowHook); // 窗口消息处理
    Application.OnException :=OnException;
end;
  procedure TviewCore.OnException(Sender: TObject; E: Exception);
begin
    if E = nil then exit;
    if Sender = nil then exit;
    if Debug = nil then exit;
    if E is  ERegistryException then exit;
    if E is ESocketError then exit;
    if E is EAccessViolation then exit;
    if E is EInvalidOperation then exit;

    if E is EFCreateError then
    begin
        Debug.Error('EFCreateError' + e.Message);
        exit;
    end;

    Debug.Error('Exception Source:' +Sender.ClassName);
    if (Sender is TWinControl) then
        if (Sender as TWinControl).Parent <> nil then
            Debug.Error('Exception Parent:' +(Sender as TWinControl).Parent.ClassName);
    Debug.Error('Exception Messag:' +E.Message);
    Debug.Error('Exception Class :' +E.ClassName);
    ExceptionForm :=TExceptionForm.Create(nil);
    ExceptionForm.Addmsg('Source:' +Sender.ClassName);
    if (Sender is TWinControl) then
        if (Sender as TWinControl).Parent <> nil then
            ExceptionForm.Addmsg('Parent:' +(Sender as TWinControl).Parent.ClassName);
    ExceptionForm.Addmsg('Messag:' +E.Message);
    ExceptionForm.Addmsg('Class :' +E.ClassName);
    ExceptionForm.ShowModal;
    Application.Terminate;

end;
destructor TviewCore.Destroy;
begin
  if FHandle <> 0 then
    DeallocateHWnd(FHandle);
  Application.OnMessage := old_appmessage;
end;

procedure TviewCore.WinProc(var Msg: TMessage);
begin
  try
    // if Msg.Msg = WM_MYTEST then
    // ShowMessage('I''m the first get the message "WM_MYTEST"');
    Dispatch(Msg);
  except
    if Assigned(ApplicationHandleException) then
      ApplicationHandleException(Self);
  end;
end;

procedure TviewCore.WMMyTest(var Msg: TMessage);
begin
  ShowMessage('Test OK!' + #10 + 'I''m coming from Class "TMyClass" with message "WM_MYTEST"!');
end;

procedure TviewCore.AppMsg(var Msg: TMsg; var Handled: Boolean);
begin
  if (chat <> nil) and ((Msg.HWND = chat.edtInputBox.Handle) or (Msg.HWND = chat.btn_send.Handle)) then
  begin
    case Msg.Message of
      WM_LBUTTONDOWN:
        begin
          with chat do
          begin
            edtInputBox.Color := clWhite;
            pnlToolBar.Color := clWhite;
            Panel2.Color := clWhite;
            Panel1.Color := clWhite;
          end;
        end;
      WM_KEYDOWN:
        begin
          if Msg.wParam = 13 then
          begin
            chat.btn_sendclick(nil);
            Msg.wParam := VK_CANCEL;
          end
          else
          begin

          end;
        end;
      WM_RBUTTONUP:
        begin
          chat.PopupMenu1.Popup(Msg.pt.X, Msg.pt.Y);
        end;

    end
  end
  else if (chat_group1 <> nil) and ((Msg.HWND = chat_group1.edtInputBox.Handle) or (Msg.HWND = chat_group1.btn_send.Handle)) then
  begin
    case Msg.Message of
      WM_LBUTTONDOWN:
        begin
          with chat_group1 do
          begin
            edtInputBox.Color := clWhite;
            pnlToolBar.Color := clWhite;
            Panel3.Color := clWhite;
            Panel1.Color := clWhite;
          end;
        end;
      WM_KEYDOWN:
        begin
          if Msg.wParam = 13 then
          begin
            chat_group1.btn_sendclick(nil);
            Msg.wParam := VK_CANCEL;
          end
          else
          begin

          end;
        end;
      WM_RBUTTONUP:
        begin
          chat_group1.PopupMenu1.Popup(Msg.pt.X, Msg.pt.Y);
        end;
    end
  end
  else if (frmmain <> nil) and (Msg.Message = WM_KEYDOWN) AND (Msg.wParam = VK_ESCAPE) and (not IsIconic(frmmain.Handle)) then
  begin
    if Assigned(chat) then
      chat.Visible := false;
    if Assigned(chat_group1) then
      chat_group1.Visible := false;
    g_global.im.close_allforms_im;
    frmmain.close;
  end
  else
  begin
    case Msg.Message of
      WM_LBUTTONDOWN:
        begin
          if (chat <> nil) then
          begin
            with chat do
            begin
              edtInputBox.Color := 15790320;
              pnlToolBar.Color := 15790320;
              Panel2.Color := 15790320;
              Panel1.Color := 15790320;
            end;
          end
          else if (chat_group1 <> nil) then
          begin
            with chat_group1 do
            begin
              edtInputBox.Color := 15790320;
              pnlToolBar.Color := 15790320;
              Panel3.Color := 15790320;
              Panel1.Color := 15790320;
            end;
          end;
        end;
    end;

  end;
end;

initialization

vCore := TviewCore.Create;

finalization

vCore.Free;

end.
