unit CHATHandler;

interface

uses
  SimpleMsgPack, diocp.session, diocp_tcp_server;

type
  TCHATSession = class(TSessionItem)
  private
    FContext: TIocpClientContext;
    FOwnerTcpServer: TDiocpTcpServer;
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
    ///   �Ͽ� SessionʧЧ, �Ƴ��б�׼���ͷ�SessionItemʱִ��
    /// </summary>
    procedure OnDisconnect(); override;

    /// <summary>
    ///   ״̬ (0,����, 1:����, 2:����)
    /// </summary>
    property State: Integer read FState write FState;
    
    property UserID: String read FUserID write FUserID;

    

    /// <summary>
    ///   ��֤״̬
    /// </summary>
    property Verified: Boolean read FVerified write FVerified;
        
  end;

/// <summary>procedure CHATExecute
/// </summary>
/// <param name="pvCMDObject"> (TSimpleMsgPack) </param>
procedure CHATExecute(pvCMDObject: TSimpleMsgPack; pvContext:
    TIocpClientContext);


var
  ChatSessions:TSessions;

implementation

uses
  utils_safeLogger, SysUtils, ComObj,diocp_coder_tcpServer,
  Classes;

procedure SendCMDObject(pvCMDObject:TSimpleMsgPack; pvContext: TObject);
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


/// <summary>
///   ���й㲥
/// </summary>
procedure DispatchCMDObject(pvCMDObject: TSimpleMsgPack; pvOwnerTcpServer:
    TDiocpTcpServer; pvIgnoreContext: TIOCPCoderClientContext);
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

    pvOwnerTcpServer.GetOnlineContextList(lvList);
    for i := 0 to lvList.Count - 1 do
    begin
      lvContext := TIOCPCoderClientContext(lvList[i]);
      if lvContext <> pvIgnoreContext then
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

/// <summary> ��������
/// </summary>
/// <param name="pvCMDObject">
///   {
///      "cmdIndex": 0,
///   }
/// </param>
procedure ExecuteHeart(pvCMDObject: TSimpleMsgPack; pvContext: TObject);
var
  lvSession:TCHATSession;
  lvContext:TIocpClientContext;
begin

  lvContext := TIocpClientContext(pvContext);
  if lvContext.LockContext('ִ������', nil) then
  try  
    lvSession := TCHATSession(lvContext.Data);
    if lvSession = nil then
    begin
      pvCMDObject.ForcePathObject('result.msg').AsString := '��δ��½...';
      pvCMDObject.ForcePathObject('result.code').AsInteger := -1;
      exit;
    end;

    if lvSession.Context <> pvContext then
    begin
      pvCMDObject.ForcePathObject('result.msg').AsString := '����ʺ��Ѿ��������ͻ��˽��е�½...';
      pvCMDObject.ForcePathObject('result.code').AsInteger := -1;
      exit;
    end;
    if lvSession.FVerified then
    begin
      if lvSession.FState = 0 then
      begin  // ����
        lvSession.FState := 1;
      end;
    end;

    lvSession.DoActivity();

    // ��������Ҫ���ؿͻ���
    pvCMDObject.Clear;

  finally
    lvContext.UnLockContext('ִ������', nil);
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
procedure ExecuteAllUsers(pvCMDObject: TSimpleMsgPack; pvContext: TIocpClientContext);
var
  lvSession, lvTempSession:TCHATSession;
  lvContext:TIocpClientContext;
  i: Integer;
var
  lvItem, lvList:TSimpleMsgPack;
  lvSessions:TList;
begin
  lvContext := TIocpClientContext(pvContext);
  if lvContext.LockContext('ִ�е�½', nil) then
  try
    lvSession := TCHATSession(lvContext.Data);
    if lvSession = nil then
    begin
      raise Exception.Create('δ��½�û�!');
    end;

    lvSessions := TList.Create;
    try
      /// ��ȡ������������������
      CHATSessions.GetSessionList(lvSessions);

      lvList := pvCMDObject.ForcePathObject('list');
      for i := 0 to lvSessions.Count - 1 do
      begin
        lvTempSession := TCHATSession(lvSessions[i]);
        if lvTempSession <> lvSession then
        begin   // ��������ĵ�ǰ�û�
          // ����
          if lvTempSession.State = 1 then
          begin
            lvItem := lvList.AddArrayChild;
            lvItem.Add('userid', lvTempSession.UserID);
            /// ....
          end;
        end;

      end;
    finally
      lvSessions.Free;
    end;


  finally
    lvContext.UnLockContext('ִ�е�½', nil);
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
procedure ExecuteLogin(pvCMDObject: TSimpleMsgPack; pvContext: TIocpClientContext);
var
  lvSession:TCHATSession;
  lvContext:TIocpClientContext;
var
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

  lvContext := TIocpClientContext(pvContext);
  if lvContext.LockContext('ִ�е�½', nil) then
  try

    lvSession := TCHATSession(ChatSessions.CheckSession(lvUserID));
    lvSession.FContext := lvContext;
    lvSession.FOwnerTcpServer := lvContext.Owner;
    
    lvSession.UserID := lvUserID;
    
    // ����
    lvSession.FState := 1;

    // �Ѿ���֤
    lvSession.Verified := true;

    /// ����������ϵ
    lvContext.Data := lvSession;

    // ����֪ͨ����
    lvCMDObject := TSimpleMsgPack.Create;
    try
      lvCMDObject.ForcePathObject('cmdIndex').AsInteger := 21;
      lvCMDObject.ForcePathObject('userid').AsString := lvUserID;
      lvCMDObject.ForcePathObject('type').AsInteger := 1;  // ����
      if lvContext <> nil then
      begin   // ������Ϣ
        DispatchCMDObject(lvCMDObject, lvContext.Owner, TIOCPCoderClientContext(lvContext));
      end;
    finally
      lvCMDObject.Free;
    end;
  finally
    lvContext.UnLockContext('ִ�е�½', nil);
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
procedure ExecuteSendMessage(pvCMDObject: TSimpleMsgPack; pvContext:
    TIocpClientContext);
var
  lvSession, lvSession2:TCHATSession;
  lvContext:TIocpClientContext;
  lvSent:Boolean;
var
  lvSQL, lvPass, lvUserID, lvUserID2:String;
var
  lvItem, lvList, lvSendCMDObject:TSimpleMsgPack;
  lvSendContext:TIocpClientContext;

begin
  lvSent := false;
  lvContext := TIocpClientContext(pvContext);
  if lvContext.LockContext('������Ϣ', nil) then
  try
    lvSession := TCHATSession(lvContext.Data);
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
        DispatchCMDObject(lvSendCMDObject, lvContext.Owner, TIOCPCoderClientContext(lvContext));
      finally
        lvSendCMDObject.Free;
      end;
    end else
    begin   
      // �����û�
      lvSession2 := TCHATSession(ChatSessions.FindSession(lvUserID2));

      if lvSession2 <> nil then
      begin
        lvSendContext := lvSession2.FContext;
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
    lvContext.UnLockContext('ִ�е�½', nil);
  end;
end;



procedure CHATExecute(pvCMDObject: TSimpleMsgPack; pvContext:
    TIocpClientContext);
var
  lvCMDIndex:Integer;
begin
  lvCMDIndex := pvCMDObject.ForcePathObject('cmdIndex').AsInteger;
  case lvCMDIndex of
    0: ExecuteHeart(pvCMDObject, pvContext);               // ����
    3: ExecuteAllUsers(pvCMDObject, pvContext);            // �����û�
    5: ExecuteSendMessage(pvCMDObject, pvContext);         // ������Ϣ
    11: ExecuteLogin(pvCMDObject, pvContext);              // ��½
  else
    begin
      raise exception.CreateFmt('δ֪������[%d]', [lvCMDIndex]);
    end;
  end;
end;

constructor TCHATSession.Create;
begin
  inherited;
  FData := TSimpleMsgPack.Create;
  FOwnerTcpServer := nil;
end;


destructor TCHATSession.Destroy;
begin
   FData.Free;
   inherited;
end;

procedure TCHATSession.OnDisconnect;
var
  lvCMDObject:TSimpleMsgPack;
begin
  lvCMDObject := TSimpleMsgPack.Create;
  try
    lvCMDObject.ForcePathObject('cmdIndex').AsInteger := 21;
    lvCMDObject.ForcePathObject('userid').AsString := Self.UserID;
    lvCMDObject.ForcePathObject('type').AsInteger := 0;  // ����
    if (FOwnerTcpServer <> nil) and (Context <> nil) then
    begin   // ������Ϣ
      DispatchCMDObject(lvCMDObject, FOwnerTcpServer, TIOCPCoderClientContext(Context));
    end;
  finally
    lvCMDObject.Free;
  end;
end;

initialization
  ChatSessions := TSessions.Create(TCHATSession);

finalization
  ChatSessions.Free;

end.
