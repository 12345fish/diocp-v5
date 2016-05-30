unit ClientIocpOper;

interface

uses
  Classes, diocp_coder_tcpClient, SimpleMsgPack, uDIOCPStreamCoder;

  /// <summary>
  /// �����¼
  /// </summary>
  /// <param name="AUserID">�˺�</param>
  /// <param name="APaw">����</param>
  procedure CMD_Login(const AUserID, APaw: string);

  /// <summary>
  /// ��������Ϣ
  /// </summary>
  /// <param name="AUserID">��Ϣ������ID(�ձ�ʾ���͸�������)</param>
  /// <param name="AMsg">��Ϣ����</param>
  procedure CMD_SendMsg(const AUserID, AMsg: string);

  /// <summary>
  /// ����������
  /// </summary>
  procedure CMD_KeepAlive;

  /// <summary>
  /// �����û��б�
  /// </summary>
  procedure CMD_UpdataUsers(const AUserID: string);

  /// <summary>
  /// ����������Ϣ
  /// </summary>
  /// <param name="AUserID">������ID</param>
  procedure CMD_OfflineMessage(const AUserID: string);

  /// <summary>
  /// ��ʼ���ͻ���ʹ�õĶ���
  /// </summary>
  procedure IniClientObject;

  /// <summary>
  /// ���ٿͻ��˴����Ķ���
  /// </summary>
  procedure UnIniClientObject;

var
  CurUserID: string;
  CoderTcpClient: TDiocpCoderTcpClient;
  DiocpContext: TIocpCoderRemoteContext;
  //
implementation

uses SysUtils;

var
  CMDObject: TSimpleMsgPack;
  CMDStream: TMemoryStream;

procedure SendCMDObject(pvCMDObject: TSimpleMsgPack);
var
  lvCMDStream:TMemoryStream;
begin
  lvCMDStream := TMemoryStream.Create;
  try
    pvCMDObject.EncodeToStream(lvCMDStream);  // ������Ϣ
    DiocpContext.WriteObject(lvCMDStream);
  finally
    lvCMDStream.Free;
  end;
end;

procedure CMD_UpdataUsers(const AUserID: string);
begin
  CMDObject.Clear;
  CMDObject.ForcePathObject('cmdIndex').AsInteger := 3;
  CMDObject.ForcePathObject('requestID').AsString := AUserID;
  CMDObject.ForcePathObject('params.page').AsInteger := 1;
  SendCMDObject(CMDObject);
end;

procedure CMD_OfflineMessage(const AUserID: string);
begin
  CMDObject.Clear;
  CMDObject.ForcePathObject('cmdIndex').AsInteger := 7;
  CMDObject.ForcePathObject('requestID').AsString := AUserID;
  SendCMDObject(CMDObject);
end;

procedure CMD_SendMsg(const AUserID, AMsg: string);
begin
  if AMsg <> '' then
  begin
    CMDObject.Clear;
    CMDObject.ForcePathObject('cmdIndex').AsInteger := 5;
    CMDObject.ForcePathObject('requestID').AsString := 'messageID';
    CMDObject.ForcePathObject('params.userid').AsString := AUserID;
    CMDObject.ForcePathObject('params.msg').AsString := AMsg;
    SendCMDObject(CMDObject);
  end;
end;

procedure CMD_Login(const AUserID, APaw: string);
begin
  // ����
  CoderTcpClient.open;
  if DiocpContext.Active then Exit;
  DiocpContext.Connect;
  //sfLogger.logMessage('��������������ӳɹ�, ����е�½');
  // ����
  if DiocpContext.Active then  // ���ӳɹ��������½
  begin
    CMDObject.Clear;
    CMDObject.ForcePathObject('cmdIndex').AsInteger := 11;
    CMDObject.ForcePathObject('requestID').AsString := 'login';
    CMDObject.ForcePathObject('user.id').AsString := AUserID;
    CMDObject.ForcePathObject('user.paw').AsString := APaw;
    SendCMDObject(CMDObject);
  end;
end;

procedure CMD_KeepAlive;
begin
  CMDObject.Clear;
  CMDObject.ForcePathObject('cmdIndex').AsInteger := 0;
  SendCMDObject(CMDObject);
end;

procedure IniClientObject;
begin
  CoderTcpClient := TDiocpCoderTcpClient.Create(nil);

  DiocpContext := TIocpCoderRemoteContext(CoderTcpClient.Add);
  DiocpContext.RegisterCoderClass(TIOCPStreamDecoder, TIOCPStreamEncoder);

  CMDObject := TSimpleMsgPack.Create;
  CMDStream := TMemoryStream.Create;
end;

procedure UnIniClientObject;
begin
  FreeAndNil(CMDObject);
  CoderTcpClient.DisconnectAll;
  CoderTcpClient.Free;
  CMDStream.Free;
end;

initialization
  IniClientObject;

finalization
  UnIniClientObject;

end.
