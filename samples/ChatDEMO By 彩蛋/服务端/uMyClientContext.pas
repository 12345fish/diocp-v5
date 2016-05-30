unit uMyClientContext;

interface

uses
  diocp_coder_tcpServer, SysUtils, Classes, Windows, Math, SimpleMsgPack,
  diocp_tcp_server, diocp.session;

type
  TOfflineInfo = class
  private
    FFromUID,
    FToUID,
    FMsg: string;
    FDT: TDateTime;
  public
    property FromUID: string read FFromUID write FFromUID;
    property ToUID: string read FToUID write FToUID;
    property Msg: string read FMsg write FMsg;
    property DT: TDateTime read FDT write FDT;
  end;

  TChatSession = class(TSessionItem)
  private
    /// <summary>
    /// �Ự��Ӧ������Context
    /// </summary>
    FContext: TIocpClientContext;

    /// <summary>
    /// �Ựÿ���������Ϣ��
    /// </summary>
    FMsgPack: TSimpleMsgPack;

    /// <summary>
    /// �Ự��ǰ״̬
    /// </summary>
    FState: Integer;

    /// <summary>
    /// �Ự��Ӧ���û�UserID
    /// </summary>
    FUserID: string;
  public
    constructor Create; override;
    destructor Destroy; override;
    /// <summary>
    /// ��Ӧ������Context
    /// </summary>
    property Context: TIocpClientContext read FContext write FContext;
    property MsgPack: TSimpleMsgPack read FMsgPack;
    /// <summary>
    ///   ״̬ (0,����, 1:����, 2:����)
    /// </summary>
    property State: Integer read FState write FState;
    property UserID: string read FUserID write FUserID;
  end;

  /// <summary>
  /// �û������¼�
  /// </summary>
  TContextLoginNotify = procedure(const AUserID: string) of object;

  /// <summary>
  /// �û������¼�
  /// </summary>
  TContextLogoutNotify = procedure(const AUserID: string) of object;

  /// <summary>
  /// �û�����������Ϣ�¼�
  /// </summary>
  TSetOfflineMsgNotify = procedure (const AToUserID, AFromUserID, AMsg: string) of object;

  /// <summary>
  /// �û���ȡ������Ϣ�¼�
  /// </summary>
  TGetOfflineMsgNotify = procedure(const AMsgPack: TSimpleMsgPack) of object;

  /// <summary>
  /// ��ȡ�����û��¼�
  /// </summary>
  TGetAllUserNotify = procedure (const AMsgPack: TSimpleMsgPack) of object;

  TMyClientContext = class(TIOCPCoderClientContext)
  private
    /// <summary>
    /// �ͻ��������ݷ��͵������
    /// </summary>
    /// <param name="pvCMDObject"></param>
    procedure ChatExecute(pvCMDObject: TSimpleMsgPack);

    /// <summary>
    /// ������Ϣ
    /// </summary>
    /// <param name="pvCMDObject">��Ϣ��</param>
    /// <param name="pvContext">�ͻ���Context</param>
    procedure SendMsgPack(AMsgPack: TSimpleMsgPack; pvContext: TObject);

    /// <summary>
    /// �ַ���Ϣ�����������û�
    /// </summary>
    /// <param name="AMsgPack">��Ϣ��</param>
    procedure DispatchMsgPackToAll(AMsgPack: TSimpleMsgPack);

    /// <summary>
    /// ������
    /// </summary>
    /// <param name="AMsgPack">������Ϣ��</param>
    procedure ExecuteHeart(AMsgPack: TSimpleMsgPack);

    /// <summary>
    /// ��ȡ���������û�
    /// </summary>
    /// <param name="AMsgPack">��Ϣ��</param>
    procedure ExecuteAllUser(AMsgPack: TSimpleMsgPack);

    /// <summary>
    /// �û�����
    /// </summary>
    /// <param name="AMsgPack">������Ϣ��</param>
    procedure ExecuteLogin(AMsgPack: TSimpleMsgPack);

    /// <summary>
    /// ������Ϣ��ָ���û�
    /// </summary>
    /// <param name="AMsgPackFrom">��Ϣ��</param>
    procedure ExecuteSendMessage(AMsgPackFrom: TSimpleMsgPack);

    /// <summary>
    /// ��ȡ������Ϣ
    /// </summary>
    /// <param name="AMsgPackFrom">��Ϣ��</param>
    procedure ExecuteOfflineMessage(AMsgPackFrom: TSimpleMsgPack);
  protected
    procedure OnDisconnected; override;
    procedure OnConnected; override;
  public
    /// <summary>
    /// ����ͻ��˴���������
    /// </summary>
    procedure DoContextAction(const pvObject: TObject); override;
  end;

var
  ChatSessions: TSessions;
  OnContextLogin: TContextLoginNotify;
  OnContextLogout: TContextLogoutNotify;
  OnGetAllUser: TGetAllUserNotify;
  OnSetOffLineMsg: TSetOfflineMsgNotify;
  OnGetOfflineMsg: TGetOfflineMsgNotify;

implementation

uses
  utils_safeLogger;

procedure TMyClientContext.ChatExecute(pvCMDObject: TSimpleMsgPack);
var
  lvCMDIndex:Integer;
begin
  lvCMDIndex := pvCMDObject.ForcePathObject('cmdIndex').AsInteger;
  case lvCMDIndex of
    0: ExecuteHeart(pvCMDObject);        // ����
    3: ExecuteAllUser(pvCMDObject);     // ��ȡ�����û�
    5: ExecuteSendMessage(pvCMDObject);  // ������Ϣ
    7: ExecuteOfflineMessage(pvCMDObject);  // ��ȡ������Ϣ
    11: ExecuteLogin(pvCMDObject);       // ��½/����
  else
    begin
      raise exception.CreateFmt('δ֪������[%d]', [lvCMDIndex]);
    end;
  end;
end;

procedure TMyClientContext.DispatchMsgPackToAll(AMsgPack: TSimpleMsgPack);
var
  lvMS:TMemoryStream;
  i:Integer;
  lvList:TList;
  lvContext:TIOCPCoderClientContext;
begin
  lvMS := TMemoryStream.Create;
  lvList := TList.Create;
  try
    AMsgPack.EncodeToStream(lvMS);
    lvMS.Position := 0;
    // ֪ͨ�������ߵĿͻ����������߻����ߵ���Ϊ
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
  // �˷����Ѿ��� TIOCPCoderClientContext.DoExecuteRequest �д������߳�ͬ����
  lvCMDObj := TSimpleMsgPack.Create;
  try
    try
      TMemoryStream(pvObject).Position := 0;
      lvCMDObj.DecodeFromStream(TMemoryStream(pvObject));  // ������Ϣ

      ChatExecute(lvCMDObj);  // ������ϢЭ�������ɶ�Ӧ���¼�����

      // ֪ͨ�ͻ��˱��ε����Ƿ�ɹ�
      if lvCMDObj.O['cmdIndex'] <> nil then  // �� lvCMDObj.ForcePathObject('cmdIndex').AsString <> ''
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
      lvCMDObj.EncodeToStream(TMemoryStream(pvObject));  // ������Ϣ
      TMemoryStream(pvObject).Position := 0;
      WriteObject(pvObject);  // ��ӵ�SendingQueue��д����
    end;
  finally
    lvCMDObj.Free;
  end;
end;

procedure TMyClientContext.ExecuteAllUser(AMsgPack: TSimpleMsgPack);
var
  lvSession: TChatSession;
begin
  if Self.LockContext('ִ�е�½', nil) then
  try
    lvSession := TChatSession(Self.Data);
    if lvSession = nil then
    begin
      raise Exception.Create('δ��½�û�!');
    end;

    if Assigned(OnGetAllUser) then
      OnGetAllUser(AMsgPack);
  finally
    Self.UnLockContext('ִ�е�½', nil);
  end;
end;

procedure TMyClientContext.ExecuteHeart(AMsgPack: TSimpleMsgPack);
var
  lvSession:TChatSession;
begin
  if Self.LockContext('ִ������', nil) then
  try
    lvSession := TChatSession(Self.Data);
    if lvSession = nil then
    begin
      AMsgPack.ForcePathObject('result.msg').AsString := '��δ��½...';
      AMsgPack.ForcePathObject('result.code').AsInteger := -1;
      Exit;
    end;

    if lvSession.Context <> Self then
    begin
      AMsgPack.ForcePathObject('result.msg').AsString := '����ʺ��Ѿ��������ͻ��˽��е�½...';
      AMsgPack.ForcePathObject('result.code').AsInteger := -1;
      Exit;
    end;

    {sfLogger.logMessage(lvSession.UserID + ' ������');

    if lvSession.Verified then
    begin
      if lvSession.State = 0 then
      begin  // ����
        lvSession.State := 1;
      end;
    end;}

    lvSession.DoActivity();

    AMsgPack.Clear;  // ��������Ҫ���ؿͻ���
  finally
    Self.UnLockContext('ִ������', nil);
  end;
end;

procedure TMyClientContext.ExecuteLogin(AMsgPack: TSimpleMsgPack);
var
  lvSession: TChatSession;
  lvSQL, vUserPaw, lvUserID: String;
  lvCMDObject:TSimpleMsgPack;
begin
  lvUserID := AMsgPack.ForcePathObject('user.id').AsString;  // ��¼��UserID
  vUserPaw := AMsgPack.ForcePathObject('user.paw').AsString;  // ��¼������
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

    lvSession.UserID := lvUserID;
    lvSession.State := 1;  // ����
    Self.Data := lvSession;  // ����������ϵ

    sfLogger.logMessage(lvUserID + ' ����[' + RemoteAddr + ':' + IntToStr(RemotePort) + ']');

    // ����֪ͨ����
    lvCMDObject := TSimpleMsgPack.Create;
    try
      lvCMDObject.ForcePathObject('cmdIndex').AsInteger := 21;  // ��������
      lvCMDObject.ForcePathObject('userid').AsString := lvUserID;
      lvCMDObject.ForcePathObject('type').AsInteger := 1;  // ����
      if Self <> nil then
        DispatchMsgPackToAll(lvCMDObject);  // ������Ϣ��֪ͨ�������ߵĿͻ�������������
    finally
      lvCMDObject.Free;
    end;
  finally
    Self.UnLockContext('ִ�е�½', nil);
  end;

  if Assigned(OnContextLogin) then
    OnContextLogin(lvUserID);  // ����
end;

procedure TMyClientContext.ExecuteOfflineMessage(AMsgPackFrom: TSimpleMsgPack);
var
  lvSession: TChatSession;
begin
  if Self.LockContext('��ȡ������Ϣ', nil) then
  try
    lvSession := TChatSession(Self.Data);  // �õ��Ự
    if lvSession = nil then
      raise Exception.Create('δ��½�û�!');

    if Assigned(OnGetOfflineMsg) then
      OnGetOfflineMsg(AMsgPackFrom);
  finally
    Self.UnLockContext('��ȡ������Ϣ', nil);
  end;
end;

procedure TMyClientContext.ExecuteSendMessage(AMsgPackFrom: TSimpleMsgPack);
var
  vFromSession, vToSession: TChatSession;
  vFromUserID, vToUserID: string;
  vMsgPackTo: TSimpleMsgPack;
  vToContext: TIocpClientContext;
begin
  if Self.LockContext('������Ϣ', nil) then
  try
    vFromSession := TChatSession(Self.Data);  // �õ���ǰContext��Ӧ�ĻỰ
    if vFromSession = nil then
      raise Exception.Create('�û�δ��½��');

    // �����û�ID <��ָ�����͸������û�>
    vToUserID := AMsgPackFrom.ForcePathObject('params.userid').AsString;
    vFromUserID := vFromSession.UserID;  // ����ID

    if vToUserID = '' then  // ���͸������û�
    begin
      vMsgPackTo := TSimpleMsgPack.Create;
      try
        vMsgPackTo.ForcePathObject('cmdIndex').AsInteger := 6;
        vMsgPackTo.ForcePathObject('userid').AsString := vFromUserID;
        vMsgPackTo.ForcePathObject('requestID').AsString := AMsgPackFrom.ForcePathObject('requestID').AsString;
        vMsgPackTo.ForcePathObject('msg').AsString := AMsgPackFrom.ForcePathObject('params.msg').AsString;
        DispatchMsgPackToAll(vMsgPackTo);

        sfLogger.logMessage(vFromUserID + ' �� �����ˣ�' + AMsgPackFrom.ForcePathObject('params.msg').AsString);
      finally
        vMsgPackTo.Free;
      end;
    end
    else  // ���͵�ָ���û�
    begin
      vToSession := TChatSession(ChatSessions.FindSession(vToUserID));
      if vToSession <> nil then  // �����û�����
      begin
        vToContext := vToSession.Context;
        if vToContext <> nil then
        begin
          if vToContext.LockContext('������Ϣ', nil) then
          begin
            try  // ��֯��Ϣ��
              vMsgPackTo := TSimpleMsgPack.Create;
              try
                vMsgPackTo.ForcePathObject('cmdIndex').AsInteger := 6;
                vMsgPackTo.ForcePathObject('userid').AsString := vFromUserID;
                vMsgPackTo.ForcePathObject('requestID').AsString :=
                  AMsgPackFrom.ForcePathObject('requestID').AsString;
                vMsgPackTo.ForcePathObject('msg').AsString :=
                  AMsgPackFrom.ForcePathObject('params.msg').AsString;

                SendMsgPack(vMsgPackTo, vToContext);

                sfLogger.logMessage(vFromUserID + ' ��' + vToUserID + '��'
                  + AMsgPackFrom.ForcePathObject('params.msg').AsString);
              finally
                vMsgPackTo.Free;
              end;
            finally
              vToContext.UnLockContext('������Ϣ', nil);
            end;
          end;
        end;
      end
      else  // �����û�������
      begin
        AMsgPackFrom.ForcePathObject('result.code').AsInteger := -1;
        AMsgPackFrom.ForcePathObject('result.msg').AsString := '�Է������ߣ������ԣ�';
        if Assigned(OnSetOfflineMsg) then  // ��Ϣ��ӵ�������Ϣ�б�
          OnSetOfflineMsg(vToUserID, vFromUserID, AMsgPackFrom.ForcePathObject('params.msg').AsString);
      end;
    end;
  finally
    Self.UnLockContext('������Ϣ', nil);
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
  vUserID: string;
begin
  lvSession := TChatSession(Self.Data);
  lvCMDObject := TSimpleMsgPack.Create;
  try
    lvCMDObject.ForcePathObject('cmdIndex').AsInteger := 21;
    lvCMDObject.ForcePathObject('userid').AsString := lvSession.UserID;
    lvCMDObject.ForcePathObject('type').AsInteger := 0;  // ����
    //if (lvSession.OwnerTcpServer <> nil) and (Self <> nil) then  // ������Ϣ
    DispatchMsgPackToAll(lvCMDObject);  // ֪ͨ���������ˣ���������

    vUserID := lvSession.UserID;
    sfLogger.logMessage(vUserID + ' ����[' + RemoteAddr + ':' + IntToStr(RemotePort) + ']');
    ChatSessions.RemoveSession(vUserID);  // �Ƴ����߿ͻ��˶�Ӧ�ĻỰ
    if Assigned(OnContextLogout) then
      OnContextLogout(vUserID);  // �����¼�
  finally
    lvCMDObject.Free;
  end;
end;

procedure TMyClientContext.SendMsgPack(AMsgPack: TSimpleMsgPack; pvContext: TObject);
var
  lvMS:TMemoryStream;
begin
  lvMS := TMemoryStream.Create;
  try
    AMsgPack.EncodeToStream(lvMS);
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
  FMsgPack := TSimpleMsgPack.Create;
end;

destructor TChatSession.Destroy;
begin
  FMsgPack.Free;
  inherited;
end;

initialization
  ChatSessions := TSessions.Create(TChatSession);

finalization
  ChatSessions.Free;

end.


