unit uEvent;

interface
//  tpull_msg_unpack = record
//    senderid, // 发送者id
//    nick, // 发送者昵称
//    msgtype, // 视频语音
//    content, sendtime: string;
//    msgid: string;
//  end;
type
  TOnInternalEvent = procedure(AEventID: Integer; AParam0: string; AParam1: Integer; AParam2: Integer { pointer } ) of object;

  TNotifySucc = procedure(Sender: TObject; json: string; thread_index: integer;params:array   of string) of object;
  // 失败 回调
  TNotifyFail = procedure(Sender: TObject; json: string; thread_index: integer) of object;

  TCallPro=procedure () of object;


//     下载
    TNotifySucc_download = procedure(Sender: TObject; params:array   of string) of object;
  // 失败 回调
  TNotifyFail_download = procedure(Sender: TObject; senderid,content: string) of object;
implementation

end.
