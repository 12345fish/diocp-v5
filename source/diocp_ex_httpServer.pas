(*
  *	 Unit owner: D10.Mofen, delphi iocp framework author
  *         homePage: http://www.Diocp.org
  *	       blog: http://www.cnblogs.com/dksoft

  *   2015-02-22 08:29:43
  *     DIOCP-V5 ����

  *
  *   2015-04-08 12:34:33
  *    (��л (Xjumping  990669769)/(suoler)����bug���ṩbug����)
  *    ��Ϊ�첽����Http�����
  *      �������Ѿ��رգ���������û�����ü�����Ȼ�������������Ѿ��黹���أ����ʱ��Ӧ�÷�����������()
  *
  *   2015-07-29 12:06:08
  *   diocp_ex_httpServer�������Cookie��Session
  *
  *
  *   2015-08-25 09:56:05
  *   ����TDiocpHttpRequest�ع�����ʱ������������󡣱�����������Cookie����(��л��ľ����bug)
  *
  *
*)
unit diocp_ex_httpServer;

interface

/// �������뿪�أ�ֻ�ܿ���һ��
{.$DEFINE INNER_IOCP}     // iocp�̴߳����¼�
{.$DEFINE  QDAC_QWorker} // ��qworker���е��ȴ����¼�
{.$DEFINE DIOCP_Task}    // ��diocp_task���е��ȴ����¼�


uses
  Classes, StrUtils, SysUtils, utils_buffer, utils_strings


  {$IFDEF QDAC_QWorker}, qworker{$ENDIF}
  {$IFDEF DIOCP_Task}, diocp_task{$ENDIF}
  , diocp_tcp_server, utils_queues, utils_hashs, utils_dvalue
  , diocp_ex_http_common
  , utils_objectPool, utils_safeLogger, Windows, utils_threadinfo, SyncObjs;



const
  HTTPLineBreak = #13#10;
  SESSIONID = 'diocp_sid';

type
  TDiocpHttpState = (hsCompleted, hsRequest { �������� } , hsRecvingPost { �������� } );
  TDiocpHttpResponse = class;
  TDiocpHttpClientContext = class;
  TDiocpHttpServer = class;
  TDiocpHttpRequest = class;
  TDiocpHttpSession = class;

  TDiocpHttpCookie = diocp_ex_http_common.TDHttpCookie;

  TDiocpHttpSessionClass = class of TDiocpHttpSession;

{$IFDEF UNICODE}

  /// <summary>
  /// Request�¼�����
  /// </summary>
  TOnDiocpHttpRequestEvent = reference to procedure(pvRequest: TDiocpHttpRequest);
{$ELSE}
  /// <summary>
  /// Request�¼�����
  /// </summary>
  TOnDiocpHttpRequestEvent = procedure(pvRequest: TDiocpHttpRequest) of object;
{$ENDIF}

  /// <summary>
  ///  ������Session�࣬�û������Լ���չ���࣬Ȼ��ע��
  /// </summary>
  TDiocpHttpSession = class(TObject)
  private
    FLastActivity: Integer; 
    procedure SetSessionTimeOut(const Value: Integer);
  protected
    FSessionTimeOut: Integer;
    procedure DoCleanup; virtual;
  public
    constructor Create; virtual;
    property LastActivity: Integer read FLastActivity;
    property SessionTimeOut: Integer read FSessionTimeOut write SetSessionTimeOut;

    /// <summary>
    ///  ����ʧЧ
    /// </summary>
    procedure Invalidate;
  end;

  /// <summary>
  ///   ʹ��DValue�洢���ݵ�Session
  /// </summary>
  TDiocpHttpDValueSession = class(TDiocpHttpSession)
  private
    FDValues: TDValue;
  protected
    procedure DoCleanup; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    property DValues: TDValue read FDValues;
  end;


  TDiocpHttpRequest = class(TObject)
  private
    FOwnerPool:TSafeQueue;
    
    FLocker:TCriticalSection;
    FThreadID:THandle;
    FThreadDebugInfo:String;
    
    FReleaseLater:Boolean;
    FReleaseLaterMsg:String;
    
    FSessionID : String;

    FInnerRequest:THttpRequest;

    /// <summary>
    ///   Ͷ��֮ǰ��¼DNA���������첽����ʱ���Ƿ�ȡ����ǰ����
    /// </summary>
    FContextDNA : Integer;
    FDebugStrings: TStrings;

    /// <summary>
    ///   ������Closeʱ�黹�ض����
    /// </summary>
    FDiocpHttpServer:TDiocpHttpServer;

    FDiocpContext: TDiocpHttpClientContext;



    FLastResponseContentLength: Integer;


    FResponse: TDiocpHttpResponse;

    /// <summary>
    ///   ����ʹ���ˣ��黹�ض����
    /// </summary>
    procedure Close;

    /// <summary>
    ///   ���Cookie�е�SessionID��Ϣ
    ///   ������Session����
    /// </summary>
    procedure CheckCookieSession;
    function GetContentLength: Int64;
    function GetContentType: String;
    function GetContentAsMemory: PByte;
    function GetContentBody: TDBufferBuilder;
    function GetDataAsRawString: RAWString;
    function GetHeader: TDValue;
    function GetHttpVersion: Word;
    function GetContentDataLength: Integer;
    function GetHeaderAsMemory: PByte;
    function GetHeaderDataLength: Integer;
    function GetRequestAccept: String;
    function GetRequestAcceptEncoding: string;
    function GetRequestCookies: string;
    function GetRequestHost: string;
    function GetRequestMethod: string;
    function GetRequestParamsList: TDValue;
    function GetRequestRawHeaderString: string;
    function GetRequestRawURL: String;
    function GetRequestURI: String;
    function GetRequestURL: String;
    function GetRequestURLParamData: string;
    function GetURLParams: TDValue;
    procedure InnerAddToDebugStrings(pvMsg:String);
  protected
  public
    constructor Create;
    destructor Destroy; override;







    /// <summary>
    ///   ����Request��ʱ�������ͷ�
    /// </summary>
    /// <param name="pvMsg"> ��Ϣ(����״̬�۲�) </param>
    procedure SetReleaseLater(pvMsg:String);

    /// <summary>
    ///   ��ȡ��ǰSession
    ///    ���û�л���д���    
    /// </summary>
    function GetSession: TDiocpHttpSession;

    /// <summary>
    ///   �ֶ�����ǰSession
    /// </summary>
    procedure RemoveSession;

    /// <summary>
    ///  ��ȡ��ǰ�ỰID, ���û�л�����Response��Cookie��Ϣ
    /// </summary>
    function GetSessionID: String;


    /// <summary>
    ///   ��Post��ԭʼ���ݽ��룬�ŵ������б���
    ///   ��OnDiocpHttpRequest�е���
    /// </summary>
    procedure DecodePostDataParam(
      {$IFDEF UNICODE} pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});

    /// <summary>
    ///   ����URL�еĲ������ŵ������б���
    ///   ��OnDiocpHttpRequest�е���
    /// </summary>
    procedure DecodeURLParam(pvUseUtf8Decode:Boolean); overload;

    {$IFDEF UNICODE}
    /// <summary>
    ///   ����URL�еĲ������ŵ������б���
    ///   ��OnDiocpHttpRequest�е���
    /// </summary>
    procedure DecodeURLParam(pvEncoding:TEncoding); overload;
    {$ENDIF}

    /// <summary>
    ///   ����
    /// </summary>
    procedure Clear;

    /// <summary>
    ///  ��ȡ�����Cookieֵ
    /// </summary>
    function GetCookie(pvCookieName:string):String;

    /// <summary>
    ///   �����󱣴浽��
    /// </summary>
    procedure SaveToStream(pvStream:TStream);

    /// <summary>
    ///   �����󱣴浽�ļ�
    /// </summary>
    procedure SaveToFile(pvFile:string);

    procedure ContentSaveToFile(pvFile:String);

    property ContentType: String read GetContentType;

    property ContentLength: Int64 read GetContentLength;


    /// <summary>
    ///   ��ͻ��˽���������
    /// </summary>
    property Connection: TDiocpHttpClientContext read FDiocpContext;
    property ContentAsMemory: PByte read GetContentAsMemory;
    property ContentAsString: RAWString read GetDataAsRawString;

    property ContentBody: TDBufferBuilder read GetContentBody;
    /// <summary>
    ///   ��������(ConentAsMemory)����Ӧ����Content-Lengthһ��
    /// </summary>
    property ContentDataLength: Integer read GetContentDataLength;




    /// <summary>
    ///   ����ͷ
    /// </summary>
    property Header: TDValue read GetHeader;

    property HttpVersion: Word read GetHttpVersion;

    property HeaderAsMemory: PByte read GetHeaderAsMemory;
    property HeaderDataLength: Integer read GetHeaderDataLength;

    property LastResponseContentLength: Integer read FLastResponseContentLength;



    property RequestAccept: String read GetRequestAccept;
    property RequestAcceptEncoding: string read GetRequestAcceptEncoding;
    property RequestCookies: string read GetRequestCookies;


    /// <summary>
    ///   ��ͷ��Ϣ������������Url,��������
    ///   URI + ����
    /// </summary>
    property RequestURL: String read GetRequestURL;

    /// <summary>
    ///   ��ͷ��Ϣ��ȡ������URL��δ�����κμӹ�,��������
    /// </summary>
    property RequestRawURL: String read GetRequestRawURL;

    /// <summary>
    ///   ����URL����
    /// </summary>
    property RequestURI: String read GetRequestURI;

    /// <summary>
    ///  ��ͷ��Ϣ�ж�ȡ���������������ʽ
    /// </summary>
    property RequestMethod: string read GetRequestMethod;

    /// <summary>
    ///   ��ͷ��Ϣ�ж�ȡ�����������IP��ַ
    /// </summary>
    property RequestHost: string read GetRequestHost;

    /// <summary>
    /// Http��Ӧ���󣬻�д����
    /// </summary>
    property Response: TDiocpHttpResponse read FResponse;


    property RequestRawHeaderString: string read GetRequestRawHeaderString;

    /// <summary>
    ///  ԭʼ�����е�URL��������(û�о���URLDecode����Ϊ��DecodeRequestHeader��Ҫƴ��RequestURLʱ��ʱ������URLDecode)
    ///  û�о���URLDecode�ǿ��ǵ�����ֵ�б������&�ַ�������DecodeURLParam���ֲ������쳣
    /// </summary>
    property RequestURLParamData: string read GetRequestURLParamData;

    /// <summary>
    ///   ���е���������� ע�����ǰ�ȵ���DecodeURL��DecodePostParams
    /// </summary>
    property RequestParamsList: TDValue read GetRequestParamsList;
    property URLParams: TDValue read GetURLParams;

    

    procedure AddDebugStrings(pvDebugInfo: String; pvAddTimePre: Boolean = true);
    procedure CheckThreadIn;

    procedure CheckThreadSetInfo(pvDebugInfo:string);

    procedure CheckThreadOut;

    /// <summary>
    ///   Ӧ����ϣ����ͻ�ͻ���
    ///   �뾡��ʹ��SendResponse��DoResponseEnd������
    /// </summary>
    procedure ResponseEnd;


    /// <summary>
    ///   ����Ӧ�����, ����Ƿ���Ҫ�ر����ӵ���Ӧ����
    /// </summary>
    procedure DoResponseEnd;


    /// <summary>
    ///   ֱ�ӷ���Response.Header��Data����
    /// </summary>
    procedure SendResponse(pvContentLength: Integer = 0);

    /// <summary>
    ///   ֱ�ӷ�������
    /// </summary>
    procedure SendResponseBuffer(pvBuffer:PByte; pvLen:Cardinal);



    /// <summary>
    ///  �ر�����
    /// </summary>
    procedure CloseContext;
    function GetDebugString: String;

    /// <summary>
    /// �õ�http�������
    /// </summary>
    /// <params>
    /// <param name="ParamsKey">http���������key</param>
    /// </params>
    /// <returns>
    /// 1: http���������ֵ
    /// </returns>
    function GetRequestParam(ParamsKey: string): string;


    /// <summary>
    ///   ��ȡ��Ӧ�����ݳ���(������ͷ��Ϣ)
    /// </summary>
    function GetResponseLength: Integer;

    








  end;

  TDiocpHttpResponse = class(TObject)
  private
    FCookieData : String;
    FDiocpContext : TDiocpHttpClientContext;
    
    FInnerResponse:THttpResponse;
    procedure ClearAllCookieObjects;
    function GetContentBody: TDBufferBuilder;
    function GetContentType: String;
    function GetHeader: TDValue;
    function GetHttpCodeStr: String;
    procedure SetContentType(const Value: String);
    procedure SetHttpCodeStr(const Value: String);
  public
    procedure Clear;
    procedure ClearContent;
    constructor Create;
    destructor Destroy; override;
    procedure WriteBuf(pvBuf: Pointer; len: Cardinal);
    procedure WriteString(pvString: string; pvUtf8Convert: Boolean = true);

    function GetResponseHeaderAsString: RAWString;

    function AddCookie: TDiocpHttpCookie; overload;

    procedure LoadFromFile(pvFile:string);

    function LoadFromStream(pvStream: TStream; pvSize: Integer): Integer;

    function AddCookie(pvName:String; pvValue:string): TDiocpHttpCookie; overload;

    function EncodeHeader: String;

    procedure EncodeResponseHeader(pvContentLength: Integer);

    procedure SaveToFile(pvFile:string);


    /// <summary>
    ///   ��ͻ��˽���������
    /// </summary>
    property Connection: TDiocpHttpClientContext read FDiocpContext;


    /// <summary>
    ///   ������ֱ��ʹ��
    /// </summary>
    property ContentBody: TDBufferBuilder read GetContentBody;

    property ContentType: String read GetContentType write SetContentType;

    property Header: TDValue read GetHeader;

    property HttpCodeStr: String read GetHttpCodeStr write SetHttpCodeStr;

    procedure RedirectURL(pvURL:String);

    procedure GZipContent;

    procedure DeflateCompressContent;

    procedure ZLibContent;

    procedure SetChunkedStart;

    procedure SetChunkedEnd;

    procedure ChunkedFlush;

    procedure SetChunkedBuffer(pvBuffer:Pointer; pvLen:Integer);

    procedure SetChunkedUtf8(pvStr:string);
  end;

  /// <summary>
  /// Http �ͻ�������
  /// </summary>
  TDiocpHttpClientContext = class(TIocpClientContext)
  private
    FHttpState: TDiocpHttpState;
    FCurrentRequest: TDiocpHttpRequest;
    {$IFDEF QDAC_QWorker}
    procedure OnExecuteJob(pvJob:PQJob);
    {$ENDIF}
    {$IFDEF DIOCP_Task}
    procedure OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
    {$ENDIF}

    // ִ���¼�
    procedure DoRequest(pvRequest:TDiocpHttpRequest);

  public
    constructor Create; override;
    destructor Destroy; override;
  protected
    /// <summary>
    /// �黹������أ�����������
    /// </summary>
    procedure DoCleanUp; override;

    /// <summary>
    /// ���յ��ͻ��˵�HttpЭ������, ���н����TDiocpHttpRequest����ӦHttp����
    /// </summary>
    procedure OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode: Word);
      override;
  end;



  /// <summary>
  /// Http ��������
  /// </summary>
  TDiocpHttpServer = class(TDiocpTcpServer)
  private
    FAccessXRequest: Boolean;

    FRequestPool: TSafeQueue;
    FSessionObjectPool: TObjectPool;
    FSessionList: TDHashTableSafe;
    FSessionClass : TDiocpHttpSessionClass;

    FOnDiocpHttpRequest: TOnDiocpHttpRequestEvent;
    FOnDiocpHttpRequestPostDone: TOnDiocpHttpRequestEvent;

    FLogicWorkerNeedCoInitialize: Boolean;
    FSessionTimeOut: Integer;

    /// <summary>
    /// ��ӦHttp���� ִ����Ӧ�¼�
    /// </summary>
    procedure DoRequest(pvRequest: TDiocpHttpRequest);

    /// <summary>
    ///   ��ӦPost�����¼�
    /// </summary>
    procedure DoRequestPostDataDone(pvRequest: TDiocpHttpRequest);

    /// <summary>
    ///   �ӳ��л�ȡһ������
    /// </summary>
    function GetRequest: TDiocpHttpRequest;

    /// <summary>
    ///   ����һ������
    /// </summary>
    procedure GiveBackRequest(pvRequest:TDiocpHttpRequest);

    /// <summary>
    ///   ��ȡһ��Session����
    /// </summary>
    function GetSession(pvSessionID:string): TDiocpHttpSession;

    /// <summary>
    ///   �Ƴ���һ��Session���ͷ�
    /// </summary>
    function RemoveSession(pvSessionID:String): Boolean;

    
    function GetSessionCount: Integer;

    function OnCreateSessionObject: TObject;

    /// <summary>
    ///   SessionMapɾ����ʱ���¼����黹��Session��
    /// </summary>
    procedure OnSessionRemove(pvData:Pointer);

  public
    constructor Create(AOwner: TComponent); override;

    destructor Destroy; override;

    procedure RegisterSessionClass(pvClass:TDiocpHttpSessionClass);

    /// <summary>
    ///   ����������, ���ú�SendRespnose������Ӧ����Ӧͷ
    /// </summary>
    property AccessXRequest: Boolean read FAccessXRequest write FAccessXRequest;
    
    /// <summary>
    ///   ��ȡSession����
    /// </summary>
    property SessionCount: Integer read GetSessionCount;


    /// <summary>
    ///   ��Http�����Post������ɺ󴥷����¼�
    ///   �����������һЩ����,����Post�Ĳ���
    /// </summary>
    property OnDiocpHttpRequestPostDone: TOnDiocpHttpRequestEvent read
        FOnDiocpHttpRequestPostDone write FOnDiocpHttpRequestPostDone;

    /// <summary>
    /// ��ӦHttp�����¼�
    /// </summary>
    property OnDiocpHttpRequest: TOnDiocpHttpRequestEvent read FOnDiocpHttpRequest
        write FOnDiocpHttpRequest;

    /// <summary>
    ///   ���Session��ʱ, �޳���ʱ��Session
    /// </summary>
    procedure CheckSessionTimeOut;

  published
    /// <summary>
    ///   �����߼��߳�ִ���߼�ǰִ��CoInitalize
    /// </summary>
    property LogicWorkerNeedCoInitialize: Boolean read FLogicWorkerNeedCoInitialize
        write FLogicWorkerNeedCoInitialize;
        
    property SessionTimeOut: Integer read FSessionTimeOut write FSessionTimeOut;


  end;



implementation

uses
  ComObj;

function FixHeader(const Header: string): string;
begin
  Result := Header;
  if (RightStr(Header, 4) <> #13#10#13#10) then
  begin
    if (RightStr(Header, 2) = #13#10) then
      Result := Result + #13#10
    else
      Result := Result + #13#10#13#10;
  end;
end;

function MakeHeader(const Status, pvRequestVersionStr: string; pvKeepAlive:
    Boolean; const ContType, Header: string; pvContextLength: Integer): string;
var
  lvVersionStr:string;
begin
  Result := '';

  lvVersionStr := pvRequestVersionStr;
  if lvVersionStr = '' then lvVersionStr := 'HTTP/1.0';

  if (Status = '') then
    Result := Result + lvVersionStr + ' 200 OK' + #13#10
  else
    Result := Result + lvVersionStr + ' ' + Status + #13#10;

  if (ContType = '') then
    Result := Result + 'Content-Type: text/html' + #13#10
  else
    Result := Result + 'Content-Type: ' + ContType + #13#10;

  if (pvContextLength > 0) then
    Result := Result + 'Content-Length: ' + IntToStr(pvContextLength) + #13#10;
  // Result := Result + 'Cache-Control: no-cache'#13#10;

  if pvKeepAlive then
    Result := Result + 'Connection: keep-alive'#13#10
  else
    Result := Result + 'Connection: close'#13#10;

  Result := Result + 'Server: DIOCP-V5/1.0'#13#10;

end;

procedure TDiocpHttpRequest.Clear;
begin
  FResponse.Clear;
  FReleaseLater := false;
  FInnerRequest.DoCleanUp;
end;

procedure TDiocpHttpRequest.Close;
begin

  if FDiocpHttpServer = nil then
  begin
    if IsDebugMode then
    begin
      Assert(False, 'FDiocpHttpServer is nil');
    end;
    exit;
  end;

  FDiocpHttpServer.GiveBackRequest(Self);
end;

procedure TDiocpHttpRequest.CloseContext;
begin
  FDiocpContext.PostWSACloseRequest();
end;

function TDiocpHttpRequest.GetCookie(pvCookieName: string): String;
var
  lvCookie:TDiocpHttpCookie;
begin
  lvCookie := FResponse.FInnerResponse.GetCookie(pvCookieName);
  if lvCookie <> nil then
  begin
    Result := lvCookie.Value;
  end else
  begin
    Result := FInnerRequest.GetCookie(pvCookieName);
  end;
end;

function TDiocpHttpRequest.GetRequestParam(ParamsKey: string): string;
begin
  Result := FInnerRequest.RequestParams.GetValueByName(ParamsKey, '');
end;

constructor TDiocpHttpRequest.Create;
begin
  inherited Create;
  FLocker := TCriticalSection.Create;
  FDebugStrings := TStringList.Create;
  FInnerRequest := THttpRequest.Create;
  FResponse := TDiocpHttpResponse.Create();

  //FRequestParamsList := TStringList.Create; // TODO:�������http������StringList
end;

destructor TDiocpHttpRequest.Destroy;
begin
  FreeAndNil(FResponse);
  FDebugStrings.Free;

  //FreeAndNil(FRequestParamsList); // TODO:�ͷŴ��http������StringList

  FInnerRequest.Free;

  FLocker.Free;

  inherited Destroy;
end;

procedure TDiocpHttpRequest.AddDebugStrings(pvDebugInfo: String; pvAddTimePre:
    Boolean = true);
var
  s:string;
begin
  if pvAddTimePre then s := Format('[%s]:%s', [NowString, pvDebugInfo])
  else s := pvDebugInfo;
  FLocker.Enter();
  try
    InnerAddToDebugStrings(s);
  finally
    FLocker.Leave;
  end;
end;

procedure TDiocpHttpRequest.DoResponseEnd;
begin
  if not FInnerRequest.CheckKeepAlive then
  begin
    FDiocpContext.PostWSACloseRequest;
  end;    
end;

procedure TDiocpHttpRequest.CheckCookieSession;
begin
  // ��session�Ĵ���
  FSessionID := GetCookie(SESSIONID);
  if FSessionID = '' then
  begin
    FSessionID := SESSIONID + '_' + DeleteChars(CreateClassID, ['-', '{', '}']);
    Response.AddCookie(SESSIONID, FSessionID);
  end;
end;

procedure TDiocpHttpRequest.CheckThreadIn;
var
  s:string;
begin
  if FThreadID <> 0 then
  begin
    s := GetDebugString;
    raise Exception.CreateFmt('(%d,%d)��ǰ�����Ѿ��������߳�����ʹ��::%s',
       [utils_strings.GetCurrentThreadID, FThreadID, s]);
  end;
  FThreadID := utils_strings.GetCurrentThreadID;
end;

procedure TDiocpHttpRequest.CheckThreadOut;
begin
  FThreadID := 0;  
end;

procedure TDiocpHttpRequest.CheckThreadSetInfo(pvDebugInfo:string);
var
  lvThreadID:THandle;
  s:string;
begin
  lvThreadID := utils_strings.GetCurrentThreadID;
  if lvThreadID <> FThreadID then
  begin
    s := GetDebugString;
    raise Exception.CreateFmt('(%d,%d)��ǰ�����Ѿ��������߳�����ʹ��::%s',
      [utils_strings.GetCurrentThreadID, FThreadID, s]);
  end;
  FThreadDebugInfo := pvDebugInfo;
end;

procedure TDiocpHttpRequest.ContentSaveToFile(pvFile:String);
begin
  FInnerRequest.ContentSaveToFile(pvFile);
end;

procedure TDiocpHttpRequest.DecodePostDataParam({$IFDEF UNICODE} pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});
begin
  {$IFDEF UNICODE}
  FInnerRequest.DecodeContentAsFormUrlencoded(pvEncoding);
  {$ELSE}
  FInnerRequest.DecodeContentAsFormUrlencoded(pvUseUtf8Decode);
  {$ENDIF}
end;

{$IFDEF UNICODE}
procedure TDiocpHttpRequest.DecodeURLParam(pvEncoding:TEncoding);
begin
  FInnerRequest.DecodeURLParam(pvEncoding);
end;
{$ENDIF}

procedure TDiocpHttpRequest.DecodeURLParam(pvUseUtf8Decode:Boolean);
begin
  FInnerRequest.DecodeURLParam(pvUseUtf8Decode);
end;

function TDiocpHttpRequest.GetContentLength: Int64;
begin
  Result := FInnerRequest.ContentLength;
end;

function TDiocpHttpRequest.GetContentType: String;
begin
  Result := FInnerRequest.ContentType;
end;

function TDiocpHttpRequest.GetContentAsMemory: PByte;
begin
  Result := FInnerRequest.ContentAsMemory;
end;

function TDiocpHttpRequest.GetContentBody: TDBufferBuilder;
begin
  Result := FInnerRequest.ContentBody;
end;

function TDiocpHttpRequest.GetDataAsRawString: RAWString;
begin
  Result := FInnerRequest.ContentAsRAWString;
end;

function TDiocpHttpRequest.GetHeader: TDValue;
begin
  Result := FInnerRequest.Headers;
end;

function TDiocpHttpRequest.GetHttpVersion: Word;
begin
  Result := FInnerRequest.HttpVersionValue;
end;

function TDiocpHttpRequest.GetContentDataLength: Integer;
begin
  Result := FInnerRequest.ContentBody.Size;
end;

function TDiocpHttpRequest.GetDebugString: String;
begin
  FLocker.Enter();
  try
    Result := FDebugStrings.Text;
  finally
    FLocker.Leave;
  end;
end;

function TDiocpHttpRequest.GetHeaderAsMemory: PByte;
begin
  Result := FInnerRequest.HeaderAsMermory;
end;

function TDiocpHttpRequest.GetHeaderDataLength: Integer;
begin
  Result := FInnerRequest.HeaderDataLength;
end;

function TDiocpHttpRequest.GetRequestAccept: String;
begin
  Result := FInnerRequest.Headers.GetValueByName('Accept', '');
end;

function TDiocpHttpRequest.GetRequestAcceptEncoding: string;
begin
  Result := FInnerRequest.Headers.GetValueByName('Accept-Encoding', '');
end;

function TDiocpHttpRequest.GetRequestCookies: string;
begin  
  Result := FInnerRequest.RawCookie;
end;

function TDiocpHttpRequest.GetRequestHost: string;
begin
  Result := FInnerRequest.Headers.GetValueByName('Host', '');
end;

function TDiocpHttpRequest.GetRequestMethod: string;
begin
  Result := FInnerRequest.Method;
end;

function TDiocpHttpRequest.GetRequestParamsList: TDValue;
begin
  Result := FInnerRequest.RequestParams;
end;

function TDiocpHttpRequest.GetRequestRawHeaderString: string;
begin
  Result := FInnerRequest.RawHeader;
end;

function TDiocpHttpRequest.GetRequestRawURL: String;
begin
  Result := FInnerRequest.RequestRawURL;
end;

function TDiocpHttpRequest.GetRequestURI: String;
begin
  Result := FInnerRequest.RequestURI;
end;

function TDiocpHttpRequest.GetRequestURL: String;
begin
  Result := FInnerRequest.RequestURL;
end;

function TDiocpHttpRequest.GetRequestURLParamData: string;
begin
  Result := FInnerRequest.RequestRawURLParamStr;
end;

function TDiocpHttpRequest.GetResponseLength: Integer;
begin
  Result := FResponse.FInnerResponse.ContentBuffer.Length;
end;

procedure TDiocpHttpRequest.RemoveSession;
begin
  CheckCookieSession;
  TDiocpHttpServer(Connection.Owner).RemoveSession(FSessionID);
end;

function TDiocpHttpRequest.GetSession: TDiocpHttpSession;
begin
  CheckCookieSession;
  Result := TDiocpHttpServer(Connection.Owner).GetSession(FSessionID);
end;

function TDiocpHttpRequest.GetSessionID: String;
begin
  CheckCookieSession;
  Result := FSessionID;
end;

function TDiocpHttpRequest.GetURLParams: TDValue;
begin
  Result := FInnerRequest.URLParams;
end;

procedure TDiocpHttpRequest.InnerAddToDebugStrings(pvMsg:String);
begin
  FDebugStrings.Add(pvMsg);
  if FDebugStrings.Count > 500 then FDebugStrings.Delete(0);
end;

procedure TDiocpHttpRequest.ResponseEnd;
var
  lvFixedHeader: AnsiString;
  len: Integer;
begin       
  lvFixedHeader := FResponse.EncodeHeader;

  if (lvFixedHeader <> '') then
    lvFixedHeader := FixHeader(lvFixedHeader)
  else
    lvFixedHeader := lvFixedHeader + HTTPLineBreak;

  // FResponseSize����׼ȷָ�����͵����ݰ���С
  // �����ڷ�����֮��(Owner.TriggerClientSentData)�Ͽ��ͻ�������
  if lvFixedHeader <> '' then
  begin
    len := Length(lvFixedHeader);
    FDiocpContext.PostWSASendRequest(PAnsiChar(lvFixedHeader), len);
  end;

  if FResponse.FInnerResponse.ContentBuffer.Length > 0 then
  begin
    FDiocpContext.PostWSASendRequest(FResponse.FInnerResponse.ContentBuffer.Memory,
      FResponse.FInnerResponse.ContentBuffer.Length);
  end;

  if not FInnerRequest.CheckKeepAlive then
  begin
    FDiocpContext.PostWSACloseRequest;
  end;
end;

procedure TDiocpHttpRequest.SaveToFile(pvFile:string);
var
  lvFileStream:TFileStream;
begin
  lvFileStream := TFileStream.Create(pvFile, fmCreate);
  try
    SaveToStream(lvFileStream);  
  finally
    lvFileStream.Free;
  end;

end;

procedure TDiocpHttpRequest.SaveToStream(pvStream:TStream);
begin
  pvStream.WriteBuffer(FInnerRequest.HeaderAsMermory^, FInnerRequest.HeaderDataLength);
  if FInnerRequest.ContentLength > 0 then
  begin
    pvStream.WriteBuffer(FInnerRequest.ContentAsMemory^, FInnerRequest.ContentLength);
  end;

end;

procedure TDiocpHttpRequest.SendResponse(pvContentLength: Integer = 0);
var
  len: Integer;
  s:RAWString;
begin
  if FResponse.Header.FindByName('Connection') = nil then
  begin
    if FInnerRequest.CheckKeepAlive then
    begin
      FResponse.Header.ForceByName('Connection').AsString := 'keep-alive';
    end else
    begin
      FResponse.Header.ForceByName('Connection').AsString := 'close';
    end;
  end;

  if FDiocpHttpServer.FAccessXRequest then
  begin  // �������֧��
    FResponse.Header.ForceByName('Access-Control-Allow-Origin').AsString := '*';
    FResponse.Header.ForceByName('Access-Control-Allow-Methods').AsString := 'POST, GET, OPTIONS, DELETE';
    FResponse.Header.ForceByName('Access-Control-Allow-Headers').AsString := 'x-requested-with,content-type';
  end;
  
  if pvContentLength = 0 then
  begin
    FLastResponseContentLength := FResponse.FInnerResponse.ContentBuffer.Length;
    FResponse.EncodeResponseHeader(FLastResponseContentLength);
  end else
  begin
    FLastResponseContentLength := pvContentLength;
    FResponse.EncodeResponseHeader(pvContentLength);
  end;

  if FResponse.FInnerResponse.HeaderBuilder.Size = 0 then
  begin
    Assert(False, '��Ӧ����Ϊ��');
  end;
  
  FDiocpContext.PostWSASendRequest(FResponse.FInnerResponse.HeaderBuilder.Memory,
    FResponse.FInnerResponse.HeaderBuilder.Size);


  if FResponse.FInnerResponse.ContentBuffer.Length > 0 then
  begin
    FDiocpContext.PostWSASendRequest(FResponse.FInnerResponse.ContentBuffer.Memory,
      FLastResponseContentLength);
  end;

end;

procedure TDiocpHttpRequest.SendResponseBuffer(pvBuffer:PByte; pvLen:Cardinal);
begin
  FDiocpContext.PostWSASendRequest(pvBuffer, pvLen);
end;

procedure TDiocpHttpRequest.SetReleaseLater(pvMsg:String);
begin
  FReleaseLater := True;
  FReleaseLaterMsg := pvMsg;
end;

procedure TDiocpHttpResponse.ChunkedFlush;
begin
  FDiocpContext.PostWSASendRequest(FInnerResponse.ContentBuffer.Memory, FInnerResponse.ContentBuffer.Length);
  FInnerResponse.ContentBuffer.Clear;
end;

procedure TDiocpHttpResponse.Clear;
begin
  FInnerResponse.DoCleanUp;
end;

constructor TDiocpHttpResponse.Create;
begin
  inherited Create;
  FInnerResponse := THttpResponse.Create;
end;

destructor TDiocpHttpResponse.Destroy;
begin
  Clear;
  FInnerResponse.Free;
  inherited Destroy;
end;

function TDiocpHttpResponse.AddCookie: TDiocpHttpCookie;
begin
  Result := FInnerResponse.AddCookie;
end;

function TDiocpHttpResponse.AddCookie(pvName:String; pvValue:string):
    TDiocpHttpCookie;
begin
  Result := FInnerResponse.AddCookie(pvName, pvValue);
end;

function TDiocpHttpResponse.EncodeHeader: String;
begin    
  FInnerResponse.EncodeHeader(FInnerResponse.ContentBuffer.Length);
  Result := FInnerResponse.HeaderBuilder.ToRAWString;
end;

procedure TDiocpHttpResponse.ClearAllCookieObjects;
begin
  FInnerResponse.ClearCookies;
end;

procedure TDiocpHttpResponse.ClearContent;
begin
  FInnerResponse.ContentBuffer.Clear;
end;

procedure TDiocpHttpResponse.EncodeResponseHeader(pvContentLength: Integer);
begin
  FInnerResponse.EncodeHeader(pvContentLength);
end;

function TDiocpHttpResponse.GetContentType: String;
begin
  Result := FInnerResponse.ContentType;
end;

function TDiocpHttpResponse.GetHeader: TDValue;
begin
  Result := FInnerResponse.Headers;
end;

function TDiocpHttpResponse.GetHttpCodeStr: String;
begin
  Result := FInnerResponse.ResponseCodeStr;
end;

procedure TDiocpHttpResponse.GZipContent;
begin
  FInnerResponse.GZipContent;
end;

procedure TDiocpHttpResponse.RedirectURL(pvURL: String);
var
  lvFixedHeader: AnsiString;
  len: Integer;
begin
  //lvFixedHeader := MakeHeader('302 Temporarily Moved', 'HTTP/1.0', false, '', '', 0);
  lvFixedHeader := MakeHeader('307 Temporary Redirect', 'HTTP/1.0', false, '', '', 0);

  lvFixedHeader := lvFixedHeader + 'Location: ' + pvURL + HTTPLineBreak;

  lvFixedHeader := FixHeader(lvFixedHeader);

  len := Length(lvFixedHeader);
  FDiocpContext.PostWSASendRequest(PAnsiChar(lvFixedHeader), len);
end;

procedure TDiocpHttpResponse.SetChunkedBuffer(pvBuffer:Pointer; pvLen:Integer);
begin
  FInnerResponse.ChunkedBuffer(pvBuffer, pvLen);
end;

procedure TDiocpHttpResponse.SetChunkedEnd;
begin
  FInnerResponse.ChunkedBufferEnd;
end;

procedure TDiocpHttpResponse.SetChunkedStart;
begin
  FInnerResponse.ChunkedBufferStart;
end;

procedure TDiocpHttpResponse.SetChunkedUtf8(pvStr:string);
var
  lvBytes:TBytes;
begin
  lvBytes := StringToUtf8Bytes(pvStr);
  FInnerResponse.ChunkedBuffer(@lvBytes[0], length(lvBytes));
end;

procedure TDiocpHttpResponse.SetContentType(const Value: String);
begin
  FInnerResponse.ContentType := Value;
end;

procedure TDiocpHttpResponse.SetHttpCodeStr(const Value: String);
begin
  FInnerResponse.ResponseCodeStr := Value;
end;

procedure TDiocpHttpResponse.WriteBuf(pvBuf: Pointer; len: Cardinal);
begin
  FInnerResponse.ContentBuffer.AppendBuffer(PByte(pvBuf), len);
end;

procedure TDiocpHttpResponse.WriteString(pvString: string; pvUtf8Convert:
    Boolean = true);
var
  lvRawString: AnsiString;
begin
  if pvUtf8Convert then
  begin     // ����Utf8ת��
    FInnerResponse.ContentBuffer.AppendUtf8(pvString);
  end else
  begin
    lvRawString := pvString;
    FInnerResponse.ContentBuffer.AppendBuffer(PByte(lvRawString), Length(lvRawString));
  end;
end;

procedure TDiocpHttpResponse.DeflateCompressContent;
begin
  FInnerResponse.DeflateCompressContent
end;

function TDiocpHttpResponse.GetContentBody: TDBufferBuilder;
begin
  Result := FInnerResponse.ContentBuffer;
end;

function TDiocpHttpResponse.GetResponseHeaderAsString: RAWString;
begin
  Result := FInnerResponse.HeaderBuilder.ToRAWString;
end;

procedure TDiocpHttpResponse.LoadFromFile(pvFile:string);
begin
  FInnerResponse.ContentBuffer.LoadFromFile(pvFile);
end;

function TDiocpHttpResponse.LoadFromStream(pvStream: TStream; pvSize: Integer):
    Integer;
begin
  Result := FInnerResponse.ContentBuffer.CopyFrom(pvStream, pvSize);
end;

procedure TDiocpHttpResponse.SaveToFile(pvFile:string);
var
  lvStream:TFileStream;
begin
  lvStream := TFileStream.Create(pvFile, fmCreate);
  try
    lvStream.WriteBuffer(FInnerResponse.HeaderBuilder.Memory^, FInnerResponse.HeaderBuilder.Size);
    lvStream.WriteBuffer(FInnerResponse.ContentBuffer.Memory^, FInnerResponse.ContentBuffer.Size);
  finally
    lvStream.Free;
  end;

end;

procedure TDiocpHttpResponse.ZLibContent;
begin
  FInnerResponse.ZCompressContent;
end;

constructor TDiocpHttpClientContext.Create;
begin
  inherited Create;
end;

destructor TDiocpHttpClientContext.Destroy;
begin
  inherited Destroy;
end;

procedure TDiocpHttpClientContext.DoCleanUp;
begin                                              
  inherited;
  FHttpState := hsCompleted;
  if FCurrentRequest <> nil then
  begin
    FCurrentRequest.Close;
    FCurrentRequest := nil;
  end;
end;

procedure TDiocpHttpClientContext.DoRequest(pvRequest: TDiocpHttpRequest);
begin
   {$IFDEF QDAC_QWorker}
   Workers.Post(OnExecuteJob, pvRequest);
   {$ELSE}
     {$IFDEF DIOCP_TASK}
     iocpTaskManager.PostATask(OnExecuteJob, pvRequest);
     {$ELSE}
      try
        pvRequest.AddDebugStrings('DoRequest::' + pvRequest.RequestURI);

        pvRequest.CheckThreadIn;

        // �����Ҫִ��
        if TDiocpHttpServer(FOwner).LogicWorkerNeedCoInitialize then
          FRecvRequest.IocpWorker.checkCoInitializeEx();

        // ֱ�Ӵ����¼�
        TDiocpHttpServer(FOwner).DoRequest(pvRequest);
      finally
        // �黹HttpRequest����
        if not pvRequest.FReleaseLater then
        begin
          pvRequest.CheckThreadOut;
          pvRequest.Close;
        end;
      end;
     {$ENDIF}
   {$ENDIF}
end;

{$IFDEF QDAC_QWorker}
procedure TDiocpHttpClientContext.OnExecuteJob(pvJob:PQJob);
var
  lvObj:TDiocpHttpRequest;
begin
  // ������ζ�Ҫ�黹HttpRequest����
  lvObj := TDiocpHttpRequest(pvJob.Data);
  try
     // �����Ѿ��Ͽ�, ���������߼�
     if (Self = nil) then Exit;

     // �����Ѿ��Ͽ�, ���������߼�
     if (FOwner = nil) then Exit;

     lvObj.CheckThreadIn;

     // �Ѿ����ǵ�ʱ��������ӣ� ���������߼�
     if lvObj.FContextDNA <> self.ContextDNA then
     begin
       Exit;
     end;

     if Self.LockContext('HTTP�߼�����...', Self) then
     try
       // �����¼�
       TDiocpHttpServer(FOwner).DoRequest(lvObj);
     finally
       self.UnLockContext('HTTP�߼�����...', Self);
     end;
  finally
    // �黹HttpRequest����
    if not lvObj.FReleaseLater then
    begin
      lvObj.CheckThreadOut;
      lvObj.Close;
    end;
  end;
end;

{$ENDIF}

{$IFDEF DIOCP_Task}
procedure TDiocpHttpClientContext.OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
var
  lvObj:TDiocpHttpRequest;
begin
  lvObj := TDiocpHttpRequest(pvTaskRequest.TaskData);
  try
    // �����Ѿ��Ͽ�, ���������߼�
    if (Self = nil) then Exit;

    // �����Ѿ��Ͽ�, ���������߼�
    if (FOwner = nil) then Exit;

    lvObj.CheckThreadIn;

    // �����Ҫִ��
    if TDiocpHttpServer(FOwner).LogicWorkerNeedCoInitialize then
      pvTaskRequest.iocpWorker.checkCoInitializeEx();

     // �Ѿ����ǵ�ʱ��������ӣ� ���������߼�
     if lvObj.FContextDNA <> self.ContextDNA then
     begin
       Exit;
     end;

     if Self.LockContext('HTTP�߼�����...', Self) then
     try
       // �����¼�
       TDiocpHttpServer(FOwner).DoRequest(lvObj);
     finally
       self.UnLockContext('HTTP�߼�����...', Self);
     end;
  finally
    // �黹HttpRequest����
    if not lvObj.FReleaseLater then
    begin
      lvObj.CheckThreadOut;
      lvObj.Close;
    end;
  end;

end;
{$ENDIF}



procedure TDiocpHttpClientContext.OnRecvBuffer(buf: Pointer; len: Cardinal;
  ErrCode: Word);
var
  lvTmpBuf: PByte;
  lvRemain: Cardinal;
  r:Integer;
  lvTempRequest: TDiocpHttpRequest;
begin
  inherited;
  lvTmpBuf := PByte(buf);
  lvRemain := len;
  while (lvRemain > 0) do
  begin
    if FCurrentRequest = nil then
    begin
      FCurrentRequest := TDiocpHttpServer(Owner).GetRequest;
      FCurrentRequest.FDiocpContext := self;
      FCurrentRequest.Response.FDiocpContext := self;
      FCurrentRequest.Clear;

      // ��¼��ǰcontextDNA���첽����ʱ�������
      FCurrentRequest.FContextDNA := self.ContextDNA;
    end;
    
    r := FCurrentRequest.FInnerRequest.InputBuffer(lvTmpBuf^);
    if r = -1 then
    begin

      lvTempRequest := FCurrentRequest;
      try
        FCurrentRequest := nil;
        lvTempRequest.Response.FInnerResponse.ResponseCode := 400;
        lvTempRequest.Response.WriteString(PAnsiChar(lvTmpBuf) + '<BR>******<BR>******<BR>' + PAnsiChar(buf));
        lvTempRequest.ResponseEnd;
      finally
        lvTempRequest.Close;
      end;


      //self.RequestDisconnect('��Ч��Http����', self);
      Exit;
    end;

    if r = -2 then
    begin
      self.RequestDisconnect('HTTP����ͷ���ݹ���', self);
      Exit;
    end;

    if r = 0 then
    begin
      ; //��Ҫ��������ݽ���
    end else
    if r = 1 then
    begin
      if SameText(FCurrentRequest.FInnerRequest.Method, 'POST') or
          SameText(FCurrentRequest.FInnerRequest.Method, 'PUT') then
      begin
        if FCurrentRequest.FInnerRequest.ContentLength = 0 then
        begin
          self.RequestDisconnect('��Ч��POST/PUT��������', self);
          Exit;
        end;
      end else
      begin
        lvTempRequest := FCurrentRequest;

        // ����Ͽ��󻹻ض���أ�����ظ�����
        FCurrentRequest := nil;

        DoRequest(lvTempRequest);
      end;
    end else
    if r = 2 then
    begin
      lvTempRequest := FCurrentRequest;

      // ����Ͽ��󻹻ض���أ�����ظ�����
      FCurrentRequest := nil;

      // �����¼�
      DoRequest(lvTempRequest);
    end;   

    Dec(lvRemain);
    Inc(lvTmpBuf);
  end;
end;

{ TDiocpHttpServer }

constructor TDiocpHttpServer.Create(AOwner: TComponent);
begin
  inherited;
  FRequestPool := TSafeQueue.Create;
  FSessionObjectPool := TObjectPool.Create(OnCreateSessionObject);
  FSessionList := TDHashTableSafe.Create;
  FSessionList.OnDelete := OnSessionRemove;
  FSessionTimeOut := 300;  // five miniutes
  KeepAlive := false;
  RegisterContextClass(TDiocpHttpClientContext);
  RegisterSessionClass(TDiocpHttpDValueSession);
end;

destructor TDiocpHttpServer.Destroy;
begin
  FRequestPool.FreeDataObject;
  FRequestPool.Free;

  /// ֻ��Ҫ��������ʱ��黹��Session�����
  FSessionList.Clear;
  FSessionList.Free;

  FSessionObjectPool.WaitFor(10000);
  FSessionObjectPool.Free;
  inherited;
end;

procedure TDiocpHttpServer.CheckSessionTimeOut;
begin
  ;
end;

procedure TDiocpHttpServer.DoRequest(pvRequest: TDiocpHttpRequest);
var
  lvMsg:String;
begin
  try
    pvRequest.Connection.SetRecvWorkerHint('����Http::DoRequest');
    SetCurrentThreadInfo('����Http::DoRequest');
    try
      try
        pvRequest.CheckCookieSession;

        if Assigned(FOnDiocpHttpRequest) then
        begin
          pvRequest.Connection.SetRecvWorkerHint('DoRequest::FOnDiocpHttpRequest - 1');
          FOnDiocpHttpRequest(pvRequest);
          pvRequest.Connection.SetRecvWorkerHint('DoRequest::FOnDiocpHttpRequest - 1');
        end;
      except
        on E:Exception do
        begin
          pvRequest.Connection.SetRecvWorkerHint('DoRequest::Exception - 1');
          self.LogMessage('Http�߼������쳣:%s', [e.Message], '', lgvError);
          pvRequest.FReleaseLater := False;
          pvRequest.Response.FInnerResponse.ResponseCode := 500;
          pvRequest.Response.Clear;
          pvRequest.Response.ContentType := 'text/html; charset=utf-8';
          lvMsg := e.Message;
          lvMsg := StringReplace(lvMsg, sLineBreak, '<BR>', [rfReplaceAll]);
          pvRequest.Response.WriteString(lvMsg);
          pvRequest.Connection.SetRecvWorkerHint('DoRequest::Exception - 2');
        end;
      end;
    except
      on E:Exception do
      begin
        pvRequest.Connection.SetRecvWorkerHint('DoRequest::*Exception - 1');
        self.LogMessage('*Http�߼������쳣:%s', [e.Message], CORE_LOG_FILE, lgvError);
        pvRequest.Connection.SetRecvWorkerHint('DoRequest::*Exception - 2');
      end;
    end;
  finally
    SetCurrentThreadInfo('����Http::DoRequest');
    pvRequest.Connection.SetRecvWorkerHint('DoRequest:: end');
  end;
end;

procedure TDiocpHttpServer.DoRequestPostDataDone(pvRequest: TDiocpHttpRequest);
begin 
  if Assigned(FOnDiocpHttpRequestPostDone) then
  begin
    FOnDiocpHttpRequestPostDone(pvRequest);
  end;
end;

function TDiocpHttpServer.GetRequest: TDiocpHttpRequest;
begin
  Result := TDiocpHttpRequest(FRequestPool.DeQueue);
  if Result = nil then
  begin
    Result := TDiocpHttpRequest.Create;
  end;
  Result.AddDebugStrings('+ GetRequest');
  Result.FDiocpHttpServer := Self;
  Result.FOwnerPool := FRequestPool;
  Result.Clear;
end;

function TDiocpHttpServer.GetSession(pvSessionID:string): TDiocpHttpSession;
begin
  FSessionList.Lock;
  try
    Result := TDiocpHttpSession(FSessionList.ValueMap[pvSessionID]);
    if Result = nil then
    begin
      Result := TDiocpHttpSession(FSessionObjectPool.GetObject);
      Result.DoCleanup;
      Result.SessionTimeOut := self.FSessionTimeOut;
      FSessionList.ValueMap[pvSessionID] := Result;
    end;
    Result.FLastActivity := GetTickCount;
  finally
    FSessionList.unLock;
  end;
end;

function TDiocpHttpServer.GetSessionCount: Integer;
begin
  Result := FSessionList.Count;
end;

procedure TDiocpHttpServer.GiveBackRequest(pvRequest: TDiocpHttpRequest);
var
  s:String;
begin
  if pvRequest.FDiocpHttpServer = nil then
  begin
    s := GetDebugString;
    Assert(pvRequest.FDiocpHttpServer <> nil,
      'TDiocpHttpServer.GiveBackRequest::�����ظ��ر�:' + s);
  end;
  pvRequest.Clear;
  pvRequest.AddDebugStrings('- GiveBackRequest');
  pvRequest.FOwnerPool := nil;
  pvRequest.FDiocpHttpServer := nil;
  FRequestPool.EnQueue(pvRequest);
end;

function TDiocpHttpServer.OnCreateSessionObject: TObject;
begin
  if FSessionClass = nil then raise Exception.Create('��δע��SessionClass, ���ܻ�ȡSession');
  Result := FSessionClass.Create();
end;

procedure TDiocpHttpServer.OnSessionRemove(pvData: Pointer);
begin
  try
    // ����Session
    TDiocpHttpSession(pvData).DoCleanup();
  except
    on E:Exception do
    begin
      LogMessage('Session DoCleanUp Error:' + e.Message, 'rpc_exception', lgvError);
    end;
  end;
  FSessionObjectPool.ReleaseObject(TObject(pvData));
end;

procedure TDiocpHttpServer.RegisterSessionClass(pvClass:TDiocpHttpSessionClass);
begin
  FSessionClass := pvClass;
end;

function TDiocpHttpServer.RemoveSession(pvSessionID:String): Boolean;
var
  lvSession:TDiocpHttpSession;
begin
  FSessionList.Lock;
  try
    lvSession := TDiocpHttpSession(FSessionList.ValueMap[pvSessionID]);
    if lvSession <> nil then
    begin
      // �ᴥ��OnSessionRemove, �黹��Ӧ�Ķ��󵽳�
      Result := FSessionList.Remove(pvSessionID);

    end else
    begin
      Result := false;
    end;
  finally
    FSessionList.unLock;
  end;  
end;

constructor TDiocpHttpSession.Create;
begin
  FSessionTimeOut := 300;
end;

constructor TDiocpHttpDValueSession.Create;
begin
  inherited Create;
  FDValues := TDValue.Create();
end;

destructor TDiocpHttpDValueSession.Destroy;
begin
  FDValues.Free;
  inherited Destroy;
end;



procedure TDiocpHttpDValueSession.DoCleanup;
begin
  inherited;
  FDValues.Clear;
end;

procedure TDiocpHttpSession.DoCleanup;
begin

end;

procedure TDiocpHttpSession.Invalidate;
begin
  DoCleanup;
end;

procedure TDiocpHttpSession.SetSessionTimeOut(const Value: Integer);
begin
  FSessionTimeOut := Value;
end;

end.
