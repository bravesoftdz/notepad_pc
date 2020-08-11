unit frm_main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.Notification, GR32_Image, scrollbar_bas, widgetScrollBar, VirtualTrees,
  widgetree, Vcl.ExtCtrls, Vcl.StdCtrls, utils,
  System.Generics.Collections, Vcl.Imaging.pngimage, Winapi.gdipobj,
  Winapi.gdipapi, Vcl.Buttons, ImgPanel, Vcl.Menus, qjson, global,
  System.Messaging, Vcl.Imaging.jpeg, Vcl.WinXPanels, Vcl.WinXCtrls,
  heads_list, Vcl.AppEvnts, System.IniFiles, Registry, Vcl.ComCtrls;

const
  WM_MyMessage = wm_user + 1220;

type
  taa = record
    ctype, dt, content, token, msg_id: string;
  end;

  lgresult = record
    code: Integer;
    msg: string;
    data: tarray<taa>;
  end;

  TForm1 = class(TForm)
    NotificationCenter1: TNotificationCenter;
    org_board: TWidgetTree;
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    CardPanel1: TCardPanel;
    Card1: TCard;
    Card2: TCard;
    Timer1: TTimer;
    ImgPanel2: TImgPanel;
    PageScroller1: TPageScroller;
    MainPanel: TPanel;
    AbilitiesDemoButton: TSpeedButton;
    PropertiesDemoButton: TSpeedButton;
    QuitButton: TSpeedButton;
    SpeedButton2: TSpeedButton;
    StatusBar: TStatusBar;
    procedure FormShow(Sender: TObject);
    procedure org_boardBeforeItemPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect; var CustomDraw: Boolean);
    procedure pnl_right_topMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure org_boardNodeClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);
    procedure Timer1Timer(Sender: TObject);
    procedure AbilitiesDemoButtonClick(Sender: TObject);
    procedure PropertiesDemoButtonClick(Sender: TObject);
    procedure QuitButtonClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure MainPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    procedure get_fail_state(Sender: TObject; json: string; thread_index: Integer);
    procedure doMyMessage(var msg: TMessage); message WM_MyMessage;
    procedure get_succ_state_login(Sender: TObject; json_value: string; thread_index: Integer; params: array of string);
    procedure callback_succ_dwonload_subscribe_room(Sender: TObject; json_value: string; thread_index: Integer; params: array of string);
    procedure get_data;
    procedure show_设置面板;
  public
    web_err: Boolean;
  end;

var
  Form1: TForm1;

var
  j1, j2, j3, j4: TFrame2;

var
  SIt: ptreenode_struct;
  Node: PVirtualNode;

implementation

{$R *.dfm}

uses
  frm_write_data, VarCoreUnit, frm_data_show;

procedure TForm1.AbilitiesDemoButtonClick(Sender: TObject);
begin
  show_设置面板;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  TrayIcon1.Animate := false;
  TrayIcon1.Visible := false;

end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  windowstate := wsMinimized;
  TrayIcon1.SetDefaultIcon;
  TrayIcon1.Visible := True;
  Visible := false;
  CanClose := false;
end;

procedure TForm1.callback_succ_dwonload_subscribe_room(Sender: TObject; json_value: string; thread_index: Integer; params: array of string);
var
  json: TQJson;
  hh: lgresult;
  t_list: TList<txx>;
begin
  clock_data.Clear;
  json := TQJson.Create;
  json.parse(json_value);
  json.torecord<lgresult>(hh);
  t_list := TList<txx>.Create;
  var X: txx;
  for var pp in hh.data do
  begin

    X.msg_id := pp.msg_id;
    X.title_date := pp.dt;
    X.token := pp.token;
    X.ctype := pp.ctype;
    X.body := pp.content;
    t_list.Add(X);

  end;
  clock_data.Add(X.token, t_list);
  Form1.Perform(WM_MyMessage, 0, 0);

  json.Free;

end;

procedure TForm1.get_data;
var
  tt: record
    token: string;
    ver: Integer;
  end;
  js: TQJson;
begin
  web_err := false;
  var token_ := g_global.imp.db.kv.getstring('token');

  if (token_ = '') or (token_ = '-1') then
    exit;

  tt.token := token_;
  tt.ver := 1;
  js := TQJson.Create;
  js.FromRecord(tt);
  try
    g_global.imp.http_pools.execute_get('c2c_get?' + js.AsJson, callback_succ_dwonload_subscribe_room, get_fail_state);

  finally
    freeandnil(js);
  end;
end;

procedure TForm1.get_fail_state(Sender: TObject; json: string; thread_index: Integer);
begin
  web_err := True;
end;

procedure SetAutorun(aProgTitle, aCmdLine: string; aRunOnce: boolean);
var
  hKey: string;
  hReg: TRegIniFile;
begin
  if aRunOnce then
  //程序只自动运行一次
    hKey := 'Once'
  else
    hKey := '';
  hReg := TRegIniFile.Create('');
  //TregIniFile类的对象需要创建
  hReg.RootKey := HKEY_LOCAL_MACHINE;
  //设置根键
  hReg.WriteString('Software\Microsoft\Windows\CurrentVersion\Run' + hKey + #0, aProgTitle,                  //程序名称，可以为自定义值
    aCmdLine);
                  //命令行数据，必须为该程序的绝对路径＋程序完整名称
  hReg.destroy;
  //释放创建的hReg
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
//g_global.imp.db.kv.setstring('token','');
  if not TOSVersion.Check(6, 2) then // Windows 8
  begin
    ShowMessage('This demo is designed to show Notification feature in Windows 8 or higher. Bye.');
    Application.Terminate;
  end;
  SetAutorun(Application.Title, application.ExeName, false);                                                  //关闭键
  windowstate := wsMinimized;
  Visible := false;
  org_board.NodeDataSize := SizeOf(ttreenode_struct);
  DoubleBuffered := True;
  org_board.DoubleBuffered := True;
  org_board.Header.Columns[0].Width := Width - 20; // 调试出来的
  get_data();
  Caption := '小树便签';
end;

procedure TForm1.FormShow(Sender: TObject);
begin

  var SubscriptionId: Integer;

  SubscriptionId := message_bus.SubscribeToMessage(TMessage<tmsg_obj>,
    procedure(const Sender: TObject; const M: TMessage)
    begin
      if (M as TMessage<tmsg_obj>).Value.msg_type = 'register' then
      begin
        org_board.Clear;
        StatusBar.SimpleText := '已登录';
        CardPanel1.tag := 1;
        show_设置面板;
      end
      else if (M as TMessage<tmsg_obj>).Value.msg_type = 'outlogin' then
      begin
        StatusBar.SimpleText := '未登录';
        g_global.imp.db.kv.setstring('token', '');
        org_board.Clear;
      end
      else if (M as TMessage<tmsg_obj>).Value.msg_type = 'login' then
      begin

        StatusBar.SimpleText := '已登录';
        get_data();
        CardPanel1.tag := 1;
        show_设置面板;
      end
      else if (M as TMessage<tmsg_obj>).Value.msg_type = '投递成功' then
      begin
        get_data();
      end

    end);
end;

procedure TForm1.MainPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  sendmessage(handle, wm_syscommand, $F011, 0);
end;

procedure TForm1.doMyMessage(var msg: TMessage);
var
  t_list: TList<txx>;
  j: Integer;
begin
  org_board.Clear;
  org_board.DoubleBuffered := True;
  var idx := 0;

  var tttoken := g_global.imp.db.kv.getstring('token');
  clock_data.TryGetValue(tttoken, t_list);
  if t_list = nil then
    exit;

  for j := 0 to t_list.Count - 1 do
  begin

    with org_board do
    begin
      beginupdate;
      Node := addchild(nil);
      nodeheight[Node] := 66;
      SIt := getnodedata(Node);
      with SIt^ do
      begin
        var ggg := t_list.Items[j].title_date.Split([' '])[0];
        if t_list.Items[j].ctype = '1' then
          title_date := ggg + ' (Month)'
        else if t_list.Items[j].ctype = '2' then
          title_date := ggg + ' (Day)'
        else
          title_date := ggg;
        img_No := './icons-30.png';
        body := t_list.Items[j].body + '   ' + t_list.Items[j].title_date.Split([' '])[1];
        node_id := t_list.Items[j].msg_id;
      end;

      endupdate
    end;

  end;

end;

procedure TForm1.N1Click(Sender: TObject);
begin
  Application.Terminate();
end;

procedure TForm1.org_boardBeforeItemPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect; var CustomDraw: Boolean);
var
  node_data: ptreenode_struct;
  bscolor, oldfontcolor: tcolor;
  rt: TRect;
begin
  rt := ItemRect;
  node_data := Sender.getnodedata(Node);

  begin
    oldfontcolor := TargetCanvas.font.color;

    if (Node = Sender.FocusedNode) then
    begin
      bscolor := 12895429; // $00AEECFC;   5591889; //
    end
    else
    begin
      if (Sender.hotnode = Node) then
      begin
        bscolor := $00DEF1EB; //6974058 14211031; //14277598 14211031 $00DEF1EB;
      end
      else
      begin
        bscolor := TVirtualDrawTree(Sender).color;
      end;

    end;

    TargetCanvas.brush.color := bscolor;
    TargetCanvas.fillrect(ItemRect);


    var rr: string;
//    标题
    rr := node_data^.title_date;
    OffsetRect(rt, 44, ItemRect.Top-15 );
    TargetCanvas.Font.Name := 'Tahoma';
    TargetCanvas.Font.Size := 8;
    TargetCanvas.Font.Style := [fsBold];
    DrawTextW(TargetCanvas.Handle, PWideChar(rr), Length(rr), rt, DT_TOP or DT_LEFT or DT_VCENTER or DT_SINGLELINE);

//    主体内容
    TargetCanvas.Font.Name := 'Tahoma'; //'Trebuchet MS';
    TargetCanvas.Font.Size := 10;
    TargetCanvas.Font.Style := [];
    rr := node_data^.body;

    var NodeWidth := TargetCanvas.TextWidth(rr) + 2 * TVirtualDrawTree(Sender).TextMargin;
    OffsetRect(rt, 0, ItemRect.Top+25 );
    with rt do
    begin
      if (NodeWidth - 2 * TVirtualDrawTree(Sender).Margin) > (Right - Left - 100) then
        rr := ShortenString(TargetCanvas.Handle, rr, Right - Left - 100);
    end;
    DrawTextW(TargetCanvas.Handle, PWideChar(rr), Length(rr), rt, DT_TOP or DT_LEFT or DT_VCENTER or DT_SINGLELINE);



    //画横线
    TargetCanvas.Pen.Color := clBlue;
    TargetCanvas.Pen.Width := 2;
    TargetCanvas.MoveTo(44, (ItemRect.height - 2));   //线段起始坐标
    TargetCanvas.LineTo(Width, (ItemRect.height - 2));

    if (Sender.hotnode = Node) or (Sender.FocusedNode = Node) then
    begin
      var Png: TPngObject;
      Png := TPngObject.Create;

      Png.LoadFromFile('./xx.png');
      var pt: TPoint;
      GetBrushOrgEx(TargetCanvas.Handle, pt);
      SetStretchBltMode(TargetCanvas.Handle, HALFTONE);
      SetBrushOrgEx(TargetCanvas.Handle, pt.x, pt.y, @pt);
      StretchBlt(TargetCanvas.Handle, 0, (ItemRect.height - 20) div 2, Png.Width+5, Png.Height+5, Png.Canvas.Handle, 0, 0, Png.Width, Png.Height, SRCCOPY);
      Png.Free;

    end;

    TargetCanvas.font.color := oldfontcolor;
    CustomDraw := True;

  end
end;

procedure TForm1.get_succ_state_login(Sender: TObject; json_value: string; thread_index: Integer; params: array of string);
type
  lgresult = record
    code: Integer;
    msg: string;
    data: array[0..0] of string;
  end;
var
  bb: lgresult;
  json: TQJson;
var
  v1: TQJson;
  txt: string;
begin
  json := TQJson.Create;
  try
    json.parse(json_value);
    json.torecord<lgresult>(bb);
    if bb.code = -1 then
      exit;

    var Message: TMessage;

    ttx.msg_type := '投递成功';
    ttx.msg_value := 'ok';
    Message := TMessage<tmsg_obj>.Create(ttx);
    message_bus.SendMessage(nil, Message, True);

  finally
    if json <> nil then
      freeandnil(json);
  end;

end;

procedure TForm1.org_boardNodeClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);
var
  node_data: ptreenode_struct;
var
  json: TQJson;
var
  vS: TStringStream;
type
  tlogn_ = record
    token: string;
    msg_id: string;
    ver: Integer;
  end;
var
  logn_: tlogn_;
begin

  if HitInfo.HitNode <> nil then
  begin
//    if Integer(HitInfo.HitPositions) = 1032 then // body
//    begin
//      node_data := Sender.getnodedata(HitInfo.HitNode);
//      if not Assigned(frmCardContact) then
//        frmCardContact := TfrmCardContact.Create(Self);
//      frmCardContact.Memo1.Text := node_data.body;
//      frmCardContact.Show;
//    end
//    else if (Integer(HitInfo.HitPositions) = 4104) or (Integer(HitInfo.HitPositions) = 264) then // 尾部
//    begin
//      node_data := Sender.getnodedata(HitInfo.HitNode);
//      var token_ := g_global.imp.db.kv.getstring('token');
//      var t_list: TList<txx>;
//      clock_data.TryGetValue(token_, t_list);
//      var i: Integer;
//      for i := t_list.Count - 1 downto 0 do
//      begin
//        if t_list[i].msg_id = node_data.node_id then
//        begin
//
//          t_list.Delete(i);
//          break;
//        end;
//      end;
//
//    end
//    else
    if (Integer(HitInfo.HitPositions) = 8) or (Integer(HitInfo.HitPositions) = 4 )then // 头
    begin
      node_data := Sender.getnodedata(HitInfo.HitNode);

      json := TQJson.Create;
      vS := TStringStream.Create('', TEncoding.UTF8);
      var token_ := g_global.imp.db.kv.getstring('token');
      try
        logn_.msg_id := node_data.node_id;

        logn_.token := g_global.imp.db.kv.getstring('token');
        logn_.ver := 1;

        json.FromRecord(logn_);

        vS.WriteString(json.AsJson);
        vS.Position := 0;
        g_global.imp.http_pools.execute_post('api_msg_del', vS, get_succ_state_login, nil, []);
      finally

        if json <> nil then
          freeandnil(json);
      end;
    end
    else if Integer(HitInfo.HitPositions) = 1032 then // body
    begin
      node_data := Sender.getnodedata(HitInfo.HitNode);
      if not Assigned(frmCardContact) then
        frmCardContact := TfrmCardContact.Create(Self);
      frmCardContact.Memo1.Text := node_data.body;
      frmCardContact.Show;
    end
  end;
end;

procedure TForm1.pnl_right_topMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  SendMessage(handle, wm_syscommand, $F011, 0);
end;

procedure TForm1.PropertiesDemoButtonClick(Sender: TObject);
begin
  var bb := g_global.imp.db.kv.getstring('token');
  if (bb = '-1') or (bb = '') then
  begin
    CardPanel1.tag := 0;
    show_设置面板;
  end
  else
  begin
    if web_err then
      exit;

    CardPanel1.tag := 1;
    show_设置面板;
    if set_frm = nil then
      set_frm := Tset_frm.Create(nil);
    set_frm.Memo1.Clear;
    set_frm.Show;
  end;
end;

procedure TForm1.QuitButtonClick(Sender: TObject);
begin
  windowstate := wsMinimized;
  TrayIcon1.SetDefaultIcon;
  TrayIcon1.Visible := True;
  Visible := false;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  var t_list: TList<txx>;
  var tttoken := g_global.imp.db.kv.getstring('token');
  clock_data.TryGetValue(tttoken, t_list);
  var i: Integer;
  for i := 0 to t_list.Count - 1 do
  begin
    if t_list[i].ctype = '1' then
    begin
      var sMonth: string;

      sMonth := FormatDateTime('dd', Now); // 每月几号提醒

      if sMonth = t_list[i].title_date.Split(['-'])[2] then
      begin

        var MyNotification: TNotification;

        MyNotification := NotificationCenter1.CreateNotification;
        try

          MyNotification.Name := '提醒';
          MyNotification.Title := '事件提醒';
          MyNotification.AlertBody := t_list[i].body;

          NotificationCenter1.PresentNotification(MyNotification);
        finally
          MyNotification.Free;
        end;

      end;
    end
    else if t_list[i].ctype = '2' then // 每天都提醒
    begin

      var MyNotification: TNotification;

      MyNotification := NotificationCenter1.CreateNotification;
      try

        MyNotification.Name := '提醒';
        MyNotification.Title := '事件提醒';
        MyNotification.AlertBody := t_list[i].body;

        NotificationCenter1.PresentNotification(MyNotification);
      finally
        MyNotification.Free;
      end;

    end;
    // else
    // if t_list[i].ctype = '3' then   //每天都提醒
    // begin
    // sMonth := FormatDateTime('hh', Now); //每月几号提醒
    //
    // if sMonth =t_list[i].title_date.Split(['-'])[2] then
    //
    //
    // var MyNotification: TNotification;
    //
    // MyNotification := NotificationCenter1.CreateNotification;
    // try
    //
    // MyNotification.Name := '提醒';
    // MyNotification.Title := '事件提醒';
    // MyNotification.AlertBody := t_list[i].body;
    //
    // NotificationCenter1.PresentNotification(MyNotification);
    // finally
    // MyNotification.Free;
    // end;
    //
    //
    // end;

  end;
end;

procedure TForm1.show_设置面板;
begin
  if CardPanel1.tag = 1 then
  begin
    CardPanel1.ActiveCard := Card1;
    CardPanel1.tag := 0;
  end
  else if CardPanel1.tag = 0 then
  begin
    CardPanel1.tag := 1;
    CardPanel1.ActiveCard := Card2;

    if Assigned(j1) then
      freeandnil(j1);

    if Assigned(j2) then
      freeandnil(j2);

    if Assigned(j3) then
      freeandnil(j3);
    if Assigned(j4) then
      freeandnil(j4);
    var bb := g_global.imp.db.kv.getstring('token');
    if (bb = '-1') or (bb = '') then
    begin
      StatusBar.SimpleText := '未登录';
    end
    else
      StatusBar.SimpleText := '已登录';

    if not Assigned(j1) then
      j1 := TFrame2.Create(nil);
    j1.nickname.Caption := '注册';
    j1.user_id := '101';
    j1.Left := 6;
    j1.Top := 10;
    j1.vv('./img_msg2.png');
    j1.Parent := Card2; // FlowPanel1;
    j1.Cursor := crHandPoint;

    if not Assigned(j2) then
      j2 := TFrame2.Create(nil);
    j2.Top := j1.Top;
    j2.nickname.Caption := '登录';
    j2.user_id := '102';
    j2.Left := j1.Left + j1.Width + 10;
    j2.vv('./img_msg2.png');
    j2.Parent := Card2; // FlowPanel1;
    j2.Cursor := crHandPoint;

    if not Assigned(j3) then
      j3 := TFrame2.Create(nil);
    j3.nickname.Caption := '退出';
    j3.user_id := '103';
    j3.Top := j1.Top;
    j3.Left := j2.Left + j2.Width + 10;

    j3.vv('./img_msg2.png');
    j3.Parent := Card2; // FlowPanel1;
    j3.Cursor := crHandPoint;

  end;

end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
begin
  get_data;
  show_设置面板;
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  // trayicon1.Visible := false;
  windowstate := twindowstate(tag);
  Show;

  Visible := True;

  setforegroundwindow(handle);
end;

end.

