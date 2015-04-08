unit uAPPHandler;

interface

uses
  SimpleMsgPack, utils.unipool, utils.unipool.tools, diocp.session, diocp.tcp.server;

type
  TCHATSession = class(TSessionItem)
  private
    FContext: TIocpClientContext;
    FData: TSimpleMsgPack;
    FState: Integer;
    FUserID: String;
    FUserKey: string;
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
    property UserKey: string read FUserKey write FUserKey;

    

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
  utils.safeLogger, SysUtils, ComObj, utils.base64, diocp.coder.tcpServer, Uni;

/// <summary> ��������
/// </summary>
/// <param name="pvCMDObject">
///   {
///      "cmdIndex": 0,
///      "B":0,
///      "L":0,
///      "H":0,
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

    lvSession.FData.ForcePathObject('position.time').AsString := FormatDateTime('yyyy-MM-dd hh:nn:ss.zzz', Now);
    lvSession.FData.ForcePathObject('position.B').AsString := pvCMDObject.ForcePathObject('B').AsString;
    lvSession.FData.ForcePathObject('position.L').AsString := pvCMDObject.ForcePathObject('L').AsString;
    lvSession.FData.ForcePathObject('position.H').AsString := pvCMDObject.ForcePathObject('H').AsString;

    // ��������Ҫ���ؿͻ���
    pvCMDObject.Clear;

  finally
    lvContext.UnLockContext('ִ�е�½', nil);
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
  lvSession:TCHATSession;
  lvContext:TIocpClientContext;
var
  lvUniOperator:TDUniOperator;
  lvSQL, lvPass, lvUserID:String;
var
  lvItem, lvList:TSimpleMsgPack;
begin
  lvContext := TIocpClientContext(pvContext);
  if lvContext.LockContext('ִ�е�½', nil) then
  try
    lvSession := TCHATSession(lvContext.Data);
    if lvSession = nil then
    begin
      raise Exception.Create('δ��½�û�!');
    end;
    lvSession.FContext := lvContext;

    lvUniOperator := defaultPool.GetUniOperator();
    try
      // �����û��������ҵ��û�
      lvSQL :=
        'SELECT * FROM sys_users WHERE FCode NOT IN (SELECT FFriendUserID from app_myfriends WHERE FUserID = :userid)';
      lvUniOperator.UniQuery.SQL.Clear;
      lvUniOperator.UniQuery.SQL.Add(lvSQL);
      lvUniOperator.UniQuery.ParamByName('userid').AsString := lvSession.UserID;
      lvUniOperator.UniQuery.Open;

      lvUniOperator.UniQuery.First;

      lvList := pvCMDObject.ForcePathObject('list');
      lvList.DataType := jdtArray;

      while not lvUniOperator.UniQuery.Eof do
      begin


        lvItem := lvList.Add();
        lvUserID := lvUniOperator.UniQuery.FieldByName('FCode').AsString;
        lvItem.Add('userid', lvUserID);
        lvItem.Add('nickname', lvUniOperator.UniQuery.FieldByName('FName').AsString);
        lvItem.Add('imageIndex', lvUniOperator.UniQuery.FieldByName('FImageIndex').AsString);

        AssignUserRTLInfo(lvUserID, lvItem);

        lvUniOperator.UniQuery.Next;
      end;


    finally
      lvUniOperator.Close;
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
  lvUniOperator:TDUniOperator;
  lvSQL, lvPass, lvUserID:String;
begin
  lvUserID := pvCMDObject.ForcePathObject('params.userid').AsString;
  if lvUserID = '' then
  begin
    raise Exception.Create('ȱ��ָ���û�ID');
  end;  

  lvContext := TIocpClientContext(pvContext);
  if lvContext.LockContext('ִ�е�½', nil) then
  try
    lvSession := TCHATSession(ChatSessions.CheckSession(lvUserID));
    lvSession.FContext := lvContext;
    // ����
    lvSession.FState := 1;





    // �Ѿ���֤
    lvSession.Verified := true;

    /// ����������ϵ
    lvContext.Data := lvSession;


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
  lvUniOperator:TDUniOperator;
  lvSQL, lvPass, lvUserID, lvUserID2:String;
var
  lvItem, lvList, lvSendCMDObject:TSimpleMsgPack;
  lvSendContext:TIocpClientContext;

var
  lvQuery1, lvQuery2:TUniQuery;
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


      // �����û�ID
      lvUserID2 := pvCMDObject.ForcePathObject('params.userid').AsString;

      // ����ID
      lvUserID := lvSession.UserID;

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
                lvSendCMDObject.ForcePathObject('requestID').AsString :=
                  pvCMDObject.ForcePathObject('requestID').AsString;
                lvSendCMDObject.ForcePathObject('msg').AsString :=
                  pvCMDObject.ForcePathObject('params.msg').AsString;
                TIOCPCoderClientContext(lvSendContext).WriteObject(lvSendCMDObject);
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
end;


destructor TCHATSession.Destroy;
begin
   FData.Free;
   inherited;
end;

initialization
  ChatSessions := TSessions.Create(TCHATSession);

finalization
  ChatSessions.Free;

end.
