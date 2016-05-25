unit uMyClientContext;

interface

uses
  diocp_coder_tcpServer, SysUtils, Classes, Windows, Math, SimpleMsgPack,
  diocp_tcp_server, diocp.session;

type
  TChatSession = class(TSessionItem)
  private
    FContext: TIocpClientContext;
    //FOwnerTcpServer: TDiocpTcpServer;
    FData: TSimpleMsgPack;
    FState: Integer;
    FUserID: String;
    FVerified: Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
    /// <summary>
    ///   ��Ӧ����
    /// </summary>
    property Context: TIocpClientContext read FContext write FContext;
    property Data: TSimpleMsgPack read FData;
    /// <summary>
    ///   ״̬ (0,����, 1:����, 2:����)
    /// </summary>
    property State: Integer read FState write FState;
    property UserID: String read FUserID write FUserID;
    /// <summary>
    ///   ��֤״̬
    /// </summary>
    property Verified: Boolean read FVerified write FVerified;
    //property OwnerTcpServer: TDiocpTcpServer read FOwnerTcpServer write FOwnerTcpServer;
  end;

  TMyClientContext = class(TIOCPCoderClientContext)
  private
    procedure ChatExecute(pvCMDObject: TSimpleMsgPack);

    procedure SendCMDObject(pvCMDObject: TSimpleMsgPack; pvContext: TObject);  // ������Ϣ
    procedure DispatchCMDObject(pvCMDObject: TSimpleMsgPack);  // �㲥
    procedure ExecuteHeart(pvCMDObject: TSimpleMsgPack);  // ������
    procedure ExecuteAllUsers(pvCMDObject: TSimpleMsgPack);  // ��ȡ���������û�
    procedure ExecuteLogin(pvCMDObject: TSimpleMsgPack);  // �û�����
    procedure ExecuteSendMessage(pvCMDObject: TSimpleMsgPack);  // ������Ϣ
  protected
    procedure OnDisconnected; override;
    procedure OnConnected; override;
  public
    /// <summary>
    /// ���ݴ���
    /// </summary>
    /// <param name="pvObject"> (TObject) </param>
    procedure DoContextAction(const pvObject: TObject); override;
  end;

implementation

uses
  utils_safeLogger;

var
  ChatSessions: TSessions;

/// <summary>
///   ���й㲥
/// </summary>
procedure TMyClientContext.ChatExecute(pvCMDObject: TSimpleMsgPack);
var
  lvCMDIndex:Integer;
begin
  lvCMDIndex := pvCMDObject.ForcePathObject('cmdIndex').AsInteger;
  case lvCMDIndex of
    0: ExecuteHeart(pvCMDObject);        // ����
    3: ExecuteAllUsers(pvCMDObject);     // ��ȡ�����û�
    5: ExecuteSendMessage(pvCMDObject);  // ������Ϣ
    11: ExecuteLogin(pvCMDObject);       // ��½/����
  else
    begin
      raise exception.CreateFmt('δ֪������[%d]', [lvCMDIndex]);
    end;
  end;
end;

procedure TMyClientContext.DispatchCMDObject(pvCMDObject: TSimpleMsgPack);
var
  lvMS:TMemoryStream;
  i:Integer;
  lvList:TList;
  lvContext:TIOCPCoderClientContext;
begin
  lvMS := TMemoryStream.Create;
  lvList := TList.Create;
  try
    pvCMDObject.EncodeToStream(lvMS);
    lvMS.Position := 0;

    Self.Owner.GetOnlineContextList(lvList);
    for i := 0 to lvList.Count - 1 do
    begin
      lvContext := TIOCPCoderClientContext(lvList[i]);
      if lvContext <> Self then
      begin
        lvContext.LockContext('������Ϣ', nil);
        try
          lvContext.WriteObject(lvMS);
        finally
          lvContext.UnLockContext('������Ϣ', nil);
        end;
      end;
    end;
  finally
    lvMS.Free;
    lvList.Free;
  end;
end;

procedure TMyClientContext.DoContextAction(const pvObject: TObject);
var
  lvCMDObj: TSimpleMsgPack;
begin
  lvCMDObj := TSimpleMsgPack.Create;
  try
    try
      TMemoryStream(pvObject).Position := 0;
      lvCMDObj.DecodeFromStream(TMemoryStream(pvObject));

      ChatExecute(lvCMDObj);

      if lvCMDObj.O['cmdIndex'] <> nil then
      begin
        if lvCMDObj.O['result.code'] = nil then
          lvCMDObj.I['result.code'] := 0;
      end;
    except
      on E:Exception do
      begin
        lvCMDObj.ForcePathObject('result.code').AsInteger := -1;
        lvCMDObj.ForcePathObject('result.msg').AsString := e.Message;
        sfLogger.logMessage('�����߼������쳣:'+ e.Message);
        {$IFDEF CONSOLE}
        writeln('�����߼������쳣:'+ e.Message);
        {$ENDIF}
      end;
    end;

    if lvCMDObj.O['cmdIndex'] <> nil then
    begin
      TMemoryStream(pvObject).Clear;
      lvCMDObj.EncodeToStream(TMemoryStream(pvObject));
      TMemoryStream(pvObject).Position := 0;
      WriteObject(pvObject);  // ��ӵ�SendingQueue��д����
    end;
  finally
    lvCMDObj.Free;
  end;
end;

/// <summary>
/// �г������û�
///
/// </summary>
/// <param name="pvCMDObject">
///
///   �����:
///   {
/// 	   "cmdIndex": 3,
/// 	   "requestID":"xxx-xx-xx-xx",  // �����ID, ���ظ����ַ�������Ӧʱ, �����ȥ
/// 	   "params":
/// 	    {
/// 		    "page":1,               // ��ѯҳ��(��ʾ�ڼ�ҳ����)
/// 		  }
/// 	}
///
/// 	��Ӧ��:
///   {
/// 	   "cmdIndex": 3,
/// 	   "requestID":"xxx-xx-xx-xx",  // �����ID, ���ظ����ַ�������Ӧʱ, �����ȥ
///   	 "result":
/// 	    {
/// 		   "code":0,           // ������, 0:�ɹ�, -1:ʧ��
/// 		   "msg":"������Ϣ"
/// 	    },
/// 	   "list":
///       [
/// 	      {"userid":"������ߵ绰", "nickname":"�ǳ�", "imageIndex":0, "state":0},
/// // state:״̬(0,����, 1:����, 2:����)
/// 		    {"userid":"������ߵ绰", "nickname":"�ǳ�", "imageIndex":0, "state":0}
/// 	    ]
/// 	}
/// </param>
procedure TMyClientContext.ExecuteAllUsers(pvCMDObject: TSimpleMsgPack);
var
  lvSession, lvTempSession: TChatSession;
  i: Integer;
  lvItem, lvList:TSimpleMsgPack;
  lvSessions:TList;
begin
  if Self.LockContext('ִ�е�½', nil) then
  try
    lvSession := TChatSession(Self.Data);
    if lvSession = nil then
    begin
      raise Exception.Create('δ��½�û�!');
    end;

    lvSessions := TList.Create;
    try
      // ��ȡ������������������
      ChatSessions.GetSessionList(lvSessions);

      lvList := pvCMDObject.ForcePathObject('list');
      for i := 0 to lvSessions.Count - 1 do
      begin
        lvTempSession := TChatSession(lvSessions[i]);
        if lvTempSession <> lvSession then  // ���ǵ�ǰ�������ݵ��û�
        begin
          if lvTempSession.State = 1 then  // ����
          begin
            lvItem := lvList.AddArrayChild;
            lvItem.Add('userid', lvTempSession.UserID);
          end;
        end;
      end;
    finally
      lvSessions.Free;
    end;
  finally
    Self.UnLockContext('ִ�е�½', nil);
  end;
end;

/// <summary> ��������
/// </summary>
/// <param name="pvCMDObject">
///   {
///      "cmdIndex": 0,
///   }
/// </param>
procedure TMyClientContext.ExecuteHeart(pvCMDObject: TSimpleMsgPack);
var
  lvSession:TChatSession;
begin
  if Self.LockContext('ִ������', nil) then
  try
    lvSession := TChatSession(Self.Data);
    if lvSession = nil then
    begin
      pvCMDObject.ForcePathObject('result.msg').AsString := '��δ��½...';
      pvCMDObject.ForcePathObject('result.code').AsInteger := -1;
      Exit;
    end;

    {if lvSession.Context <> Self then
    begin
      pvCMDObject.ForcePathObject('result.msg').AsString := '����ʺ��Ѿ��������ͻ��˽��е�½...';
      pvCMDObject.ForcePathObject('result.code').AsInteger := -1;
      Exit;
    end;}

    //sfLogger.logMessage(lvSession.UserID + ' ������');

    if lvSession.Verified then
    begin
      if lvSession.State = 0 then
      begin  // ����
        lvSession.State := 1;
      end;
    end;

    lvSession.DoActivity();

    // ��������Ҫ���ؿͻ���
    pvCMDObject.Clear;
  finally
    Self.UnLockContext('ִ������', nil);
  end;
end;

/// <summary>
///  �û���½
/// </summary>
/// <param name="pvCMDObject">
/// ��½:
///    �����:
///     {
///       "cmdIndex": 11,
///       "requestID":"xxx-xx-xx-xx",  // �����ID, ���ظ����ַ�������Ӧʱ, �����ȥ
///       "params":
///       {
///         "userid":"������ߵ绰",      // ������ϢID
///         "pass":"xxx",                 // ����base 64λ����
///       }
///     }
///
/// 	��Ӧ��:
///     {
///       "cmdIndex": 11,
///       "requestID":"xxx-xx-xx-xx",  // �����ID, ���ظ����ַ�������Ӧʱ, �����ȥ
///       "result":
///       {
///         "code":0,           // ������, 0:�ɹ�, -1:ʧ��, 1:��������
///         "msg":"������Ϣ"
///       }
///     }
///  </param>
procedure TMyClientContext.ExecuteLogin(pvCMDObject: TSimpleMsgPack);
var
  lvSession:TChatSession;
  lvSQL, lvPass, lvUserID:String;
  lvCMDObject:TSimpleMsgPack;
begin
  lvUserID := pvCMDObject.ForcePathObject('params.userid').AsString;
  if lvUserID = '' then
  begin
    raise Exception.Create('ȱ��ָ���û�ID');
  end;

  if ChatSessions.FindSession(lvUserID) <> nil then
  begin
    raise Exception.Create('�û��Ѿ���½!');
  end;

  if Self.LockContext('ִ�е�½', nil) then
  try
    lvSession := TChatSession(ChatSessions.CheckSession(lvUserID));  // ���һỰ�����û���򴴽�
    lvSession.Context := Self;
    //lvSession.OwnerTcpServer := Self.Owner;

    lvSession.UserID := lvUserID;
    lvSession.State := 1;  // ����
    lvSession.Verified := true;  // �Ѿ���֤
    Self.Data := lvSession;  // ����������ϵ

    sfLogger.logMessage(lvUserID + ' ����[' + RemoteAddr + ':' + IntToStr(RemotePort) + ']');

    // ����֪ͨ����
    lvCMDObject := TSimpleMsgPack.Create;
    try
      lvCMDObject.ForcePathObject('cmdIndex').AsInteger := 21;
      lvCMDObject.ForcePathObject('userid').AsString := lvUserID;
      lvCMDObject.ForcePathObject('type').AsInteger := 1;  // ����
      if Self <> nil then
      begin   // ������Ϣ
        DispatchCMDObject(lvCMDObject);
      end;
    finally
      lvCMDObject.Free;
    end;
  finally
    Self.UnLockContext('ִ�е�½', nil);
  end;
end;

/// <summary>
/// ������Ϣ
/// </summary>
/// <param name="pvCMDObject">
/// ������Ϣ:
///   �����:
///   {
///     "cmdIndex": 5,
///     "requestID":"xxx-xx-xx-xx",  // �����ID, ���ظ����ַ�������Ӧʱ, �����ȥ
///     "params":
///     {
///       "userid":"������ߵ绰",      // ������ϢID
///       "msg":"Ҫ���͵�����"
/// 		}
///
/// 	}
///
/// 	��Ӧ��:
///   {
///     "cmdIndex": 5,
///     "requestID":"xxx-xx-xx-xx",  // �����ID, ���ظ����ַ�������Ӧʱ, �����ȥ
///     "result":
///     {
///       "code":0,           // ������, 0:�ɹ�, -1:ʧ��, 1:������Ϣ
///       "msg":"������Ϣ"
///     }
///   }
///  </param>
procedure TMyClientContext.ExecuteSendMessage(pvCMDObject: TSimpleMsgPack);
var
  lvSession, lvSession2:TChatSession;
  lvSent:Boolean;
  lvSQL, lvPass, lvUserID, lvUserID2:String;
  lvItem, lvList, lvSendCMDObject:TSimpleMsgPack;
  lvSendContext: TIocpClientContext;
begin
  lvSent := false;
  if Self.LockContext('������Ϣ', nil) then
  try
    lvSession := TChatSession(Self.Data);
    if lvSession = nil then
    begin
      raise Exception.Create('δ��½�û�!');
    end;

    // �����û�ID <��ָ�����͸������û�>
    lvUserID2 := pvCMDObject.ForcePathObject('params.userid').AsString;

    // ����ID
    lvUserID := lvSession.UserID;

    if lvUserID2 = '' then
    begin    // ���͸������û�
      lvSendCMDObject := TSimpleMsgPack.Create;
      try
        lvSendCMDObject.ForcePathObject('cmdIndex').AsInteger := 6;
        lvSendCMDObject.ForcePathObject('userid').AsString := lvUserID;
        lvSendCMDObject.ForcePathObject('requestID').AsString := pvCMDObject.ForcePathObject('requestID').AsString;
        lvSendCMDObject.ForcePathObject('msg').AsString :=
          pvCMDObject.ForcePathObject('params.msg').AsString;
        DispatchCMDObject(lvSendCMDObject);

        sfLogger.logMessage(lvUserID + ' �����ˣ�' + pvCMDObject.ForcePathObject('params.msg').AsString);
      finally
        lvSendCMDObject.Free;
      end;
    end
    else
    begin
      // �����û�
      lvSession2 := TChatSession(ChatSessions.FindSession(lvUserID2));

      if lvSession2 <> nil then
      begin
        lvSendContext := lvSession2.Context;
        if lvSendContext <> nil then
        begin
          if lvSendContext.LockContext('������Ϣ', nil) then
          begin
            try
              lvSendCMDObject := TSimpleMsgPack.Create;
              try
                lvSendCMDObject.ForcePathObject('cmdIndex').AsInteger := 6;
                lvSendCMDObject.ForcePathObject('userid').AsString := lvUserID;
                lvSendCMDObject.ForcePathObject('requestID').AsString := pvCMDObject.ForcePathObject('requestID').AsString;
                lvSendCMDObject.ForcePathObject('msg').AsString :=
                  pvCMDObject.ForcePathObject('params.msg').AsString;

                SendCMDObject(lvSendCMDObject, lvSendContext);
                lvSent := true;

                sfLogger.logMessage(lvUserID + ' ' + lvUserID2 + '��' + pvCMDObject.ForcePathObject('params.msg').AsString);
              finally
                lvSendCMDObject.Free;
              end;
            finally
              lvSendContext.UnLockContext('������Ϣ', nil);
            end;
          end;
        end;
      end;

      if not lvSent then
      begin
        // ������Ϣ
        pvCMDObject.ForcePathObject('result.code').AsInteger := -1;
        pvCMDObject.ForcePathObject('result.msg').AsString := '�û�������';
      end;
    end;
  finally
    Self.UnLockContext('ִ�е�½', nil);
  end;
end;

procedure TMyClientContext.OnConnected;
begin
  //sfLogger.logMessage(RemoteAddr + ':' + IntToStr(RemotePort) + ' ����');
end;

procedure TMyClientContext.OnDisconnected;
var
  lvCMDObject: TSimpleMsgPack;
  lvSession: TChatSession;
begin
  lvSession := TChatSession(Self.Data);
  lvCMDObject := TSimpleMsgPack.Create;
  try
    lvCMDObject.ForcePathObject('cmdIndex').AsInteger := 21;
    lvCMDObject.ForcePathObject('userid').AsString := lvSession.UserID;
    lvCMDObject.ForcePathObject('type').AsInteger := 0;  // ����
    //if (lvSession.OwnerTcpServer <> nil) and (Self <> nil) then  // ������Ϣ
    DispatchCMDObject(lvCMDObject);

    sfLogger.logMessage(lvSession.UserID + ' ����[' + RemoteAddr + ':' + IntToStr(RemotePort) + ']');
    ChatSessions.RemoveSession(lvSession.UserID);
  finally
    lvCMDObject.Free;
  end;
end;

procedure TMyClientContext.SendCMDObject(pvCMDObject: TSimpleMsgPack; pvContext: TObject);
var
  lvMS:TMemoryStream;
begin
  lvMS := TMemoryStream.Create;
  try
    pvCMDObject.EncodeToStream(lvMS);
    lvMS.Position := 0;
    TIOCPCoderClientContext(pvContext).WriteObject(lvMS);
  finally
    lvMS.Free;
  end;
end;

{ TChatSession }

constructor TChatSession.Create;
begin
  inherited;
  FData := TSimpleMsgPack.Create;
end;

destructor TChatSession.Destroy;
begin
  FData.Free;
  inherited;
end;

initialization
  ChatSessions := TSessions.Create(TChatSession);

finalization
  ChatSessions.Free;

end.


