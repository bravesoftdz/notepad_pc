unit uEvent;

interface
//  tpull_msg_unpack = record
//    senderid, // ������id
//    nick, // �������ǳ�
//    msgtype, // ��Ƶ����
//    content, sendtime: string;
//    msgid: string;
//  end;
type
  TOnInternalEvent = procedure(AEventID: Integer; AParam0: string; AParam1: Integer; AParam2: Integer { pointer } ) of object;

  TNotifySucc = procedure(Sender: TObject; json: string; thread_index: integer;params:array   of string) of object;
  // ʧ�� �ص�
  TNotifyFail = procedure(Sender: TObject; json: string; thread_index: integer) of object;

  TCallPro=procedure () of object;


//     ����
    TNotifySucc_download = procedure(Sender: TObject; params:array   of string) of object;
  // ʧ�� �ص�
  TNotifyFail_download = procedure(Sender: TObject; senderid,content: string) of object;
implementation

end.
