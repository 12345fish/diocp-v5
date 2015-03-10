(*
  *	 Unit owner: D10.Mofen, delphi iocp framework author
  *         homePage: http://www.Diocp.org
  *	       blog: http://www.cnblogs.com/dksoft

  *   2015-02-22 08:29:43
  *     DIOCP-V5 ����

  *    HttpЭ�鴦��Ԫ
  *    ���д󲿷�˼·������delphi iocp framework�е�iocp.HttpServer
  *
*)
unit diocp.ex.httpServer;

interface

uses
  Classes, StrUtils, SysUtils, utils.buffer, utils.strings,
  diocp.tcp.server;

const
  HTTPLineBreak = #13#10;

type
  TDiocpHttpState = (hsCompleted, hsRequest { �������� } , hsRecvingPost { �������� } );
  TDiocpHttpResponse = class;
  TDiocpHttpClientContext = class;

  TDiocpHttpRequest = class(TObject)
  private
    FDiocpContext: TDiocpHttpClientContext;

    /// ͷ��Ϣ
    FHttpVersion: Word; // 10, 11

    FRequestVersionStr: String;

    FRequestMethod: String;
    FRequestRawURL: String;       // ԭʼ������URL���������κν���

    /// <summary>
    ///  ԭʼ�����е�URL��������(û�о���URLDecode����Ϊ��DecodeRequestHeader��Ҫƴ��RequestURLʱ��ʱ������URLDecode)
    ///  û�о���URLDecode�ǿ��ǵ�����ֵ�б������&�ַ�������DecodeURLParam���ֲ������쳣
    /// </summary>
    FRequestURLParamData: string;

    FRequestURL: String;          // URI + ����
    FRequestURI: String;          // URI ��������


    FRequestParamsList: TStringList; // TODO:���http������StringList

    FContextType: string;
    FContextLength: Int64;
    FKeepAlive: Boolean;
    FRequestAccept: String;
    FRequestReferer: String;
    FRequestAcceptLanguage: string;
    FRequestAcceptEncoding: string;
    FRequestUserAgent: string;
    FRequestAuth: string;
    FRequestCookies: string;
    FRequestHostName: string;
    FRequestHostPort: string;



    FXForwardedFor: string;

    FRawHeaderData: TMemoryStream;

    /// <summary>
    ///   ԭʼ��POST����
    /// </summary>
    FRawPostData: TMemoryStream;

    FPostDataLen: Integer;

    FRequestHeader: TStringList;

    FResponse: TDiocpHttpResponse;

    /// <summary>
    /// �Ƿ���Ч��Http ���󷽷�
    /// </summary>
    /// <returns>
    /// 0: ���ݲ��㹻���н���
    /// 1: ��Ч������ͷ
    /// 2: ��Ч����������ͷ
    /// </returns>
    function DecodeHttpRequestMethod: Integer;

    /// <summary>
    /// ����Http���������Ϣ
    /// </summary>
    /// <returns>
    /// 1: ��Ч��Http��������
    /// </returns>
    function DecodeHttpRequestHeader: Integer;
    
    /// <summary>
    /// ���յ���Buffer,д������
    /// </summary>
    procedure WriteRawBuffer(const buffer: Pointer; len: Integer);
  protected
  public
    constructor Create;
    destructor Destroy; override;


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
    procedure DecodeURLParam(
      {$IFDEF UNICODE} pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});

    /// <summary>
    ///   ����
    /// </summary>
    procedure Clear;

    property ContextLength: Int64 read FContextLength;


    /// <summary>
    ///   ��ͻ��˽���������
    /// </summary>
    property Connection: TDiocpHttpClientContext read FDiocpContext;
    property HttpVersion: Word read FHttpVersion;
    /// <summary>
    ///   ԭʼ��Post����������
    /// </summary>
    property RawPostData: TMemoryStream read FRawPostData;
    property RequestAccept: String read FRequestAccept;
    property RequestAcceptEncoding: string read FRequestAcceptEncoding;
    property RequestAcceptLanguage: string read FRequestAcceptLanguage;
    property RequestCookies: string read FRequestCookies;

    /// <summary>
    ///   �����ͷ��Ϣ
    /// </summary>
    property RequestHeader: TStringList read FRequestHeader;

    /// <summary>
    ///   ��ͷ��Ϣ������������Url,��������
    /// </summary>
    property RequestURL: String read FRequestURL;

    /// <summary>
    ///   ��ͷ��Ϣ��ȡ������URL��δ�����κμӹ�,��������
    /// </summary>
    property RequestRawURL: String read FRequestRawURL;

    /// <summary>
    ///   ����URL����
    /// </summary>
    property RequestURI: String read FRequestURI;

    /// <summary>
    ///  ��ͷ��Ϣ�ж�ȡ���������������ʽ
    /// </summary>
    property RequestMethod: string read FRequestMethod;

    /// <summary>
    ///   ��ͷ��Ϣ�ж�ȡ�����������IP��ַ
    /// </summary>
    property RequestHostName: string read FRequestHostName;

    /// <summary>
    ///   ��ͷ��Ϣ�ж�ȡ������������˿�
    /// </summary>
    property RequestHostPort: string read FRequestHostPort;

    /// <summary>
    /// Http��Ӧ���󣬻�д����
    /// </summary>
    property Response: TDiocpHttpResponse read FResponse;

    /// <summary>
    ///   ��Url��Post�����еõ��Ĳ�����Ϣ: key = value
    /// </summary>
    property RequestParamsList: TStringList read FRequestParamsList;

    property RequestReferer: String read FRequestReferer;




    /// <summary>
    /// Ӧ����ϣ����ͻ�ͻ���
    /// </summary>
    procedure ResponseEnd;

    /// <summary>
    ///  �ر�����
    /// </summary>
    procedure CloseContext;

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
    /// ����POST��GET����
    /// </summary>
    /// <pvParamText>
    /// <param name="pvParamText">Ҫ������ȫ������</param>
    /// </pvParamText>
    procedure ParseParams(pvParamText: string);

  end;

  TDiocpHttpResponse = class(TObject)
  private
    FResponseHeader: string;
    FContentType: String;
    FData: TMemoryStream;
    FDiocpContext : TDiocpHttpClientContext;
  public
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
    procedure WriteBuf(pvBuf: Pointer; len: Cardinal);
    procedure WriteString(pvString: string; pvUtf8Convert: Boolean = true);
    /// <summary>
    ///   ��ͻ��˽���������
    /// </summary>
    property Connection: TDiocpHttpClientContext read FDiocpContext;

    property ContentType: String read FContentType write FContentType;

    procedure RedirectURL(pvURL:String);
  end;

  /// <summary>
  /// Http �ͻ�������
  /// </summary>
  TDiocpHttpClientContext = class(TIocpClientContext)
  private
    FHttpState: TDiocpHttpState;
    FRequest: TDiocpHttpRequest;
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
  /// Http ��������
  /// </summary>
  TDiocpHttpServer = class(TDiocpTcpServer)
  private
    FOnDiocpHttpRequest: TOnDiocpHttpRequestEvent;
    FOnDiocpHttpRequestPostDone: TOnDiocpHttpRequestEvent;

    /// <summary>
    /// ��ӦHttp���� ִ����Ӧ�¼�
    /// </summary>
    procedure DoRequest(pvRequest: TDiocpHttpRequest);

    /// <summary>
    ///   ��ӦPost�����¼�
    /// </summary>
    procedure DoRequestPostDataDone(pvRequest: TDiocpHttpRequest);

  public
    constructor Create(AOwner: TComponent); override;



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

  end;



implementation

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
  FRawHeaderData.Clear;
  FRawPostData.Clear;
  FRequestURL := '';
  FRequestURI := '';
  FRequestRawURL := '';
  FRequestVersionStr := '';
  FRequestMethod := '';
  FRequestCookies := '';
  FRequestParamsList.Clear;
  FContextLength := 0;
  FPostDataLen := 0;
  FResponse.Clear;  
end;

procedure TDiocpHttpRequest.CloseContext;
begin
  FDiocpContext.PostWSACloseRequest();
end;

function TDiocpHttpRequest.GetRequestParam(ParamsKey: string): string;
var
  lvTemp: string; // ���صĲ���ֵ
  lvParamsCount: Integer; // ��������
  I: Integer;
begin
  Result := '';

  lvTemp := ''; // ���صĲ���ֵĬ��ֵΪ��

  // �õ��ύ�����Ĳ���������
  lvParamsCount := self.FRequestParamsList.Count;

  // �ж��Ƿ����ύ�����Ĳ�������
  if lvParamsCount = 0 then exit;

  // ѭ���Ƚ�ÿһ�������key���Ƿ�͵�ǰ����һ��
  for I := 0 to lvParamsCount - 1 do
  begin 
    if Trim(self.FRequestParamsList.Names[I]) = Trim(ParamsKey) then
    begin
      lvTemp := Trim(self.FRequestParamsList.ValueFromIndex[I]);
      Break;
    end;
  end; 

  Result := lvTemp;
end;

constructor TDiocpHttpRequest.Create;
begin
  inherited Create;
  FRawHeaderData := TMemoryStream.Create();
  FRawPostData := TMemoryStream.Create();
  FRequestHeader := TStringList.Create();
  FResponse := TDiocpHttpResponse.Create();

  FRequestParamsList := TStringList.Create; // TODO:�������http������StringList
end;

destructor TDiocpHttpRequest.Destroy;
begin
  FreeAndNil(FResponse);
  FRawPostData.Free;
  FRawHeaderData.Free;
  FRequestHeader.Free;

  FreeAndNil(FRequestParamsList); // TODO:�ͷŴ��http������StringList

  inherited Destroy;
end;

function TDiocpHttpRequest.DecodeHttpRequestMethod: Integer;
var
  lvBuf: PAnsiChar;
begin
  Result := 0;
  if FRawHeaderData.Size <= 7 then
    Exit;

  lvBuf := FRawHeaderData.Memory;

  if FRequestMethod <> '' then
  begin
    Result := 1; // �Ѿ�����
    Exit;
  end;

  // ���󷽷������з���ȫΪ��д���ж��֣����������Ľ������£�
  // GET     �����ȡRequest-URI����ʶ����Դ
  // POST    ��Request-URI����ʶ����Դ�󸽼��µ�����
  // HEAD    �����ȡ��Request-URI����ʶ����Դ����Ӧ��Ϣ��ͷ
  // PUT     ����������洢һ����Դ������Request-URI��Ϊ���ʶ
  // DELETE  ���������ɾ��Request-URI����ʶ����Դ
  // TRACE   ��������������յ���������Ϣ����Ҫ���ڲ��Ի����
  // CONNECT ��������ʹ��
  // OPTIONS �����ѯ�����������ܣ����߲�ѯ����Դ��ص�ѡ�������
  // Ӧ�þ�����
  // GET��������������ĵ�ַ����������ַ�ķ�ʽ������ҳʱ�����������GET�������������ȡ��Դ��eg:GET /form.html HTTP/1.1 (CRLF)
  //
  // POST����Ҫ��������������ܸ��������������ݣ��������ύ����

  Result := 1;
  // HTTP 1.1 ֧��8������
  if (StrLIComp(lvBuf, 'GET', 3) = 0) then
  begin
    FRequestMethod := 'GET';
  end
  else if (StrLIComp(lvBuf, 'POST', 4) = 0) then
  begin
    FRequestMethod := 'POST';
  end
  else if (StrLIComp(lvBuf, 'PUT', 3) = 0) then
  begin
    FRequestMethod := 'PUT';
  end
  else if (StrLIComp(lvBuf, 'HEAD', 3) = 0) then
  begin
    FRequestMethod := 'HEAD';
  end
  else if (StrLIComp(lvBuf, 'OPTIONS', 7) = 0) then
  begin
    FRequestMethod := 'OPTIONS';
  end
  else if (StrLIComp(lvBuf, 'DELETE', 6) = 0) then
  begin
    FRequestMethod := 'DELETE';
  end
  else if (StrLIComp(lvBuf, 'TRACE', 5) = 0) then
  begin
    FRequestMethod := 'TRACE';
  end
  else if (StrLIComp(lvBuf, 'CONNECT', 7) = 0) then
  begin
    FRequestMethod := 'CONNECT';
  end
  else
  begin
    Result := 2;
  end;
end;

function TDiocpHttpRequest.DecodeHttpRequestHeader: Integer;
var
  lvRawString: AnsiString;
  lvMethod, lvRawTemp: AnsiString;
  lvRequestCmdLine, lvTempStr, lvRemainStr: String;
  I, J: Integer;
  p : PChar;
begin
  Result := 1;
  SetLength(lvRawString, FRawHeaderData.Size);
  FRawHeaderData.Position := 0;
  FRawHeaderData.Read(lvRawString[1], FRawHeaderData.Size);
  FRequestHeader.Text := lvRawString;

  // GET /test?v=abc HTTP/1.1
  lvRequestCmdLine := FRequestHeader[0];
  P := PChar(lvRequestCmdLine);
  FRequestHeader.Delete(0);

  I := 1;
  while (I <= Length(lvRequestCmdLine)) and (lvRequestCmdLine[I] <> ' ') do
    Inc(I);
  // ���󷽷�(GET, POST, PUT, HEAD...)
  lvMethod := UpperCase(Copy(lvRequestCmdLine, 1, I - 1));
  Inc(I);
  while (I <= Length(lvRequestCmdLine)) and (lvRequestCmdLine[I] = ' ') do
    Inc(I);
  J := I;
  while (I <= Length(lvRequestCmdLine)) and (lvRequestCmdLine[I] <> ' ') do
    Inc(I);

  // ���������·��
  lvTempStr := Copy(lvRequestCmdLine, J, I - J);
  FRequestRawURL := lvTempStr;
  FRequestURLParamData := '';

  // ��������
  J := Pos('?', lvTempStr);

  if (J <= 0) then
  begin
    lvRawTemp := '';
    FRequestURL := URLDecode(lvTempStr);
    FRequestURL := UTF8Decode(FRequestURL);  // Url������Utf8����
    FRequestURI := FRequestURL;   //�޲�����urlһ��
  end
  else
  begin
    // IEԭʼURL  : /�й�.asp?topicid=a����a
    // ��̨���յ� : /%E4%B8%AD%E5%9B%BD.asp?topicid=a����a

    // FireFox/360���������ԭʼURL : /%E4%B8%AD%E5%9B%BD.asp?topicid=a%E6%B1%89%E5%AD%97a
    // ��̨���յ� : /%E4%B8%AD%E5%9B%BD.asp?topicid=a%E6%B1%89%E5%AD%97a


    // URI��Ҫ����URLDecode��Utf8����
    FRequestURI := Copy(lvTempStr, 1, J - 1);
    FRequestURI := URLDecode(FRequestURI, False);
    FRequestURI := UTF8Decode(FRequestURI);

    // URL�еĲ�����Ҫ����URLDecode��IE�ύ������Ϊǰ̨��ϵͳĬ�ϱ���
    lvRawTemp := Copy(lvTempStr, J + 1, MaxInt);
    FRequestURLParamData := lvRawTemp;
    lvRawTemp := URLDecode(lvRawTemp, False);      // �����������Ҫ����URLDecode(IE����Ҫ)

    // ƴ��
    FRequestURL := FRequestURI + lvRawTemp;
  end;

  Inc(I);
  while (I <= Length(lvRequestCmdLine)) and (lvRequestCmdLine[I] = ' ') do
    Inc(I);
  J := I;
  while (I <= Length(lvRequestCmdLine)) and (lvRequestCmdLine[I] <> ' ') do
    Inc(I);

  // �����HTTP�汾
  FRequestVersionStr := Trim(UpperCase(Copy(lvRequestCmdLine, J, I - J)));

  if (FRequestVersionStr = '') then
    FRequestVersionStr := 'HTTP/1.0';
  if (lvTempStr = 'HTTP/1.0') then
  begin
    FHttpVersion := 10;
    FKeepAlive := false; // Ĭ��Ϊfalse
  end
  else
  begin
    FHttpVersion := 11;
    FKeepAlive := true; // Ĭ��Ϊtrue
  end;

  FContextLength := 0;


  // eg��POST /reg.jsp HTTP/ (CRLF)
  // Accept:image/gif,image/x-xbit,... (CRLF)
  // ...
  // HOST:www.guet.edu.cn (CRLF)
  // Content-Length:22 (CRLF)
  // Connection:Keep-Alive (CRLF)
  // Cache-Control:no-cache (CRLF)
  // (CRLF)         //��CRLF��ʾ��Ϣ��ͷ�Ѿ��������ڴ�֮ǰΪ��Ϣ��ͷ
  // user=jeffrey&pwd=1234  //��������Ϊ�ύ������
  //
  // HEAD������GET����������һ���ģ�����HEAD����Ļ�Ӧ������˵������HTTPͷ���а�������Ϣ��ͨ��GET�������õ�����Ϣ����ͬ�ġ�����������������ش���������Դ���ݣ��Ϳ��Եõ�Request-URI����ʶ����Դ����Ϣ���÷��������ڲ��Գ����ӵ���Ч�ԣ��Ƿ���Է��ʣ��Լ�����Ƿ���¡�
  // 2������ͷ����
  // 3����������(��)

  for I := 0 to FRequestHeader.Count - 1 do
  begin
    lvRequestCmdLine := FRequestHeader[I];
    P := PChar(lvRequestCmdLine);

    // ��ȡ�ұߵ��ַ�
    lvTempStr := LeftUntil(P, [':']);
    SkipChars(P, [':', ' ']);

    // ��ȡʣ����ַ�
    lvRemainStr := P;

    if (lvRequestCmdLine = '') then
      Continue;

    if SameText(lvTempStr, 'Content-Type') then
    begin
      FContextType := lvRemainStr;
    end else if SameText(lvTempStr, 'Content-Length') then
    begin
      FContextLength := StrToInt64Def(lvRemainStr, -1);
    end else if SameText(lvTempStr, 'Accept') then
    begin
      FRequestAccept := lvRemainStr;
    end else if SameText(lvTempStr, 'Referer') then
    begin
      FRequestReferer := lvRemainStr;
    end else if SameText(lvTempStr, 'Accept-Language') then
    begin
      FRequestAcceptLanguage := lvRemainStr;
    end else if SameText(lvTempStr, 'Accept-Encoding') then
    begin
      FRequestAcceptEncoding := lvRemainStr;
    end else if SameText(lvTempStr, 'User-Agent')then
    begin
      FRequestUserAgent := lvRemainStr;
    end else if SameText(lvTempStr, 'Authorization') then
    begin
      FRequestAuth := lvRemainStr;
    end else if SameText(lvTempStr, 'Cookie') then
    begin
      FRequestCookies := lvRemainStr;
    end else if SameText(lvTempStr, 'Host') then
    begin
      lvTempStr := lvRemainStr;
      J := Pos(':', lvTempStr);
      if J > 0 then
      begin
        FRequestHostName := Copy(lvTempStr, 1, J - 1);
        FRequestHostPort := Copy(lvTempStr, J + 1, 100);
      end
      else
      begin
        FRequestHostName := lvTempStr;
        FRequestHostPort := IntToStr((FDiocpContext).Owner.Port);
      end;
    end
    else if SameText(lvTempStr, 'Connection') then
    begin
      // HTTP/1.0 Ĭ��KeepAlive=False��ֻ����ʾָ����Connection: keep-alive����ΪKeepAlive=True
      // HTTP/1.1 Ĭ��KeepAlive=True��ֻ����ʾָ����Connection: close����ΪKeepAlive=False
      if FHttpVersion = 10 then
        FKeepAlive := SameText(lvRemainStr, 'keep-alive')
      else if SameText(lvRemainStr, 'close') then
        FKeepAlive := false;
    end
    else if SameText(lvTempStr, 'X-Forwarded-For') then
      FXForwardedFor := lvRemainStr;
  end;
end;

procedure TDiocpHttpRequest.DecodePostDataParam({$IFDEF UNICODE} pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});
var
  lvRawData : AnsiString;
  lvRawParams, s:String;
  i:Integer;
  lvStrings:TStrings;
{$IFDEF UNICODE}
var
  lvBytes:TBytes;
{$ELSE}
{$ENDIF}
begin
  // ��ȡԭʼ����
  SetLength(lvRawData, FRawPostData.Size);
  FRawPostData.Position := 0;
  FRawPostData.Read(lvRawData[1], FRawPostData.Size);

  lvStrings := TStringList.Create;
  try
    // �ȷ��뵽Strings
    SplitStrings(lvRawData, lvStrings, ['&']);

    for i := 0 to lvStrings.Count - 1 do
    begin
      lvRawData := URLDecode(lvStrings.ValueFromIndex[i]);
      if lvRawData <> '' then   // ���Ϸ���Key-Value�ᵼ�¿��ַ���
      begin
        {$IFDEF UNICODE}
        if pvEncoding <> nil then
        begin
          // �ַ�����ת��
          SetLength(lvBytes, length(lvRawData));
          Move(PByte(lvRawData)^, lvBytes[0], Length(lvRawData));
          s := pvEncoding.GetString(lvBytes);
        end else
        begin
          s := lvRawData;
        end;
        {$ELSE}
        if pvUseUtf8Decode then
        begin
          s := UTF8Decode(lvRawData);
        end else
        begin
          s := lvRawData;
        end;
        {$ENDIF}

        // �������
        lvStrings.ValueFromIndex[i] := s;
      end;
    end;
    FRequestParamsList.AddStrings(lvStrings);
  finally
    lvStrings.Free;
  end;
end;


procedure TDiocpHttpRequest.DecodeURLParam(
  {$IFDEF UNICODE} pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});
var
  lvRawData : AnsiString;
  lvRawParams, s:String;
  i:Integer;
  lvStrings:TStrings;
{$IFDEF UNICODE}
var
  lvBytes:TBytes;
{$ELSE}
{$ENDIF}
begin
  // ����URL����
  if FRequestURLParamData = '' then exit;

  lvStrings := TStringList.Create;
  try
    // �ȷ��뵽Strings
    SplitStrings(FRequestURLParamData, lvStrings, ['&']);

    for i := 0 to lvStrings.Count - 1 do
    begin
      lvRawData := URLDecode(lvStrings.ValueFromIndex[i]);
      if lvRawData<> '' then
      begin
        {$IFDEF UNICODE}
        if pvEncoding <> nil then
        begin
          // �ַ�����ת��
          SetLength(lvBytes, length(lvRawData));
          Move(PByte(lvRawData)^, lvBytes[0], Length(lvRawData));
          s := pvEncoding.GetString(lvBytes);
        end else
        begin
          s := lvRawData;
        end;
        {$ELSE}
        if pvUseUtf8Decode then
        begin
          s := UTF8Decode(lvRawData);
        end else
        begin
          s := lvRawData;
        end;
        {$ENDIF}

        // �������
        lvStrings.ValueFromIndex[i] := s;
      end;
    end;
    FRequestParamsList.AddStrings(lvStrings);
  finally
    lvStrings.Free;
  end;

end;

/// <summary>
///  ����POST��GET����
/// </summary>
/// <pvParamText>
/// <param name="pvParamText">Ҫ������ȫ������</param>
/// </pvParamText>
procedure TDiocpHttpRequest.ParseParams(pvParamText: string);
begin
  SplitStrings(pvParamText, FRequestParamsList, ['&']);
end;

procedure TDiocpHttpRequest.ResponseEnd;
var
  lvFixedHeader: AnsiString;
  len: Integer;
begin
  lvFixedHeader := MakeHeader('200 OK', FRequestVersionStr, FKeepAlive, FResponse.FContentType,
    FResponse.FResponseHeader, FResponse.FData.Size);

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

  if FResponse.FData.Size > 0 then
  begin
    FDiocpContext.PostWSASendRequest(FResponse.FData.Memory,
      FResponse.FData.Size);
  end;

  if not FKeepAlive then
  begin
    FDiocpContext.PostWSACloseRequest;
  end;
end;

procedure TDiocpHttpRequest.WriteRawBuffer(const buffer: Pointer; len: Integer);
begin
  FRawHeaderData.WriteBuffer(buffer^, len);
end;

procedure TDiocpHttpResponse.Clear;
begin
  FContentType := '';
  FData.Clear;
  FResponseHeader := '';
end;

constructor TDiocpHttpResponse.Create;
begin
  inherited Create;
  FData := TMemoryStream.Create();
end;

destructor TDiocpHttpResponse.Destroy;
begin
  FreeAndNil(FData);
  inherited Destroy;
end;

procedure TDiocpHttpResponse.RedirectURL(pvURL: String);
var
  lvFixedHeader: AnsiString;
  len: Integer;
begin
  lvFixedHeader := MakeHeader('302 Temporarily Moved', 'HTTP/1.0', false, '',
    '', 0);

  lvFixedHeader := lvFixedHeader + 'Location: ' + pvURL + HTTPLineBreak;

  lvFixedHeader := FixHeader(lvFixedHeader);

  // FResponseSize����׼ȷָ�����͵����ݰ���С
  // �����ڷ�����֮��(Owner.TriggerClientSentData)�Ͽ��ͻ�������
  if lvFixedHeader <> '' then
  begin
    len := Length(lvFixedHeader);
    FDiocpContext.PostWSASendRequest(PAnsiChar(lvFixedHeader), len);
  end;

end;

procedure TDiocpHttpResponse.WriteBuf(pvBuf: Pointer; len: Cardinal);
begin
  FData.Write(pvBuf^, len);
end;

procedure TDiocpHttpResponse.WriteString(pvString: string; pvUtf8Convert:
    Boolean = true);
var
  lvRawString: AnsiString;
begin
  if pvUtf8Convert then
  begin     // ����Utf8ת��
    lvRawString := UTF8Encode(pvString);
  end else
  begin
    lvRawString := AnsiString(pvString);
  end;
  FData.WriteBuffer(PAnsiChar(lvRawString)^, Length(lvRawString));
end;

constructor TDiocpHttpClientContext.Create;
begin
  inherited Create;
  FRequest := TDiocpHttpRequest.Create();
  FRequest.FDiocpContext := self;
  FRequest.Response.FDiocpContext := self;
end;

destructor TDiocpHttpClientContext.Destroy;
begin
  FreeAndNil(FRequest);
  inherited Destroy;
end;

procedure TDiocpHttpClientContext.DoCleanUp;
begin
  inherited;
  FHttpState := hsCompleted;
end;

procedure TDiocpHttpClientContext.OnRecvBuffer(buf: Pointer; len: Cardinal;
  ErrCode: Word);
var
  lvTmpBuf: PAnsiChar;
  CR, LF: Integer;
  lvRemain: Cardinal;
begin
  inherited;
  lvTmpBuf := buf;
  CR := 0;
  LF := 0;
  lvRemain := len;
  while (lvRemain > 0) do
  begin
    if FHttpState = hsCompleted then
    begin // ��ɺ����ã����´�����һ����
      FRequest.Clear;
      FHttpState := hsRequest;
    end;

    if (FHttpState = hsRequest) then
    begin
      case lvTmpBuf^ of
        #13:
          Inc(CR);
        #10:
          Inc(LF);
      else
        CR := 0;
        LF := 0;
      end;

      // д����������
      FRequest.WriteRawBuffer(lvTmpBuf, 1);

      if FRequest.DecodeHttpRequestMethod = 2 then
      begin // ��Ч��Http����
        self.RequestDisconnect('��Ч��Http����', self);
        Exit;
      end;

      // ���������ѽ������(#13#10#13#10��HTTP��������ı�־)
      if (CR = 2) and (LF = 2) then
      begin
        if FRequest.DecodeHttpRequestHeader = 0 then
        begin
          self.RequestDisconnect('��Ч��HttpЭ������', self);
          Exit;
        end;

        if SameText(FRequest.FRequestMethod, 'POST') or
          SameText(FRequest.FRequestMethod, 'PUT') then
        begin
          // ��Ч��Post����ֱ�ӶϿ�
          if (FRequest.FContextLength <= 0) then
          begin
            self.RequestDisconnect('��Ч��POST/PUT��������', self);
            Exit;
          end;
          // �ı�Http״̬, �����������״̬
          FHttpState := hsRecvingPost;
        end
        else
        begin
          FHttpState := hsCompleted;
          // �����¼�
          TDiocpHttpServer(FOwner).DoRequest(FRequest);
          Break;
        end;
      end;
    end
    else if (FHttpState = hsRecvingPost) then
    begin
      FRequest.FRawPostData.Write(lvTmpBuf^, 1);
      Inc(FRequest.FPostDataLen);

      if FRequest.FPostDataLen >= FRequest.FContextLength then
      begin
        FHttpState := hsCompleted;

        // �����¼�
        TDiocpHttpServer(FOwner).DoRequestPostDataDone(FRequest);

        // �����¼�
        TDiocpHttpServer(FOwner).DoRequest(FRequest);

      end;
    end;
    Dec(lvRemain);
    Inc(lvTmpBuf);
  end;
end;

{ TDiocpHttpServer }

constructor TDiocpHttpServer.Create(AOwner: TComponent);
begin
  inherited;
  KeepAlive := false;
  registerContextClass(TDiocpHttpClientContext);
end;

procedure TDiocpHttpServer.DoRequest(pvRequest: TDiocpHttpRequest);
begin
  if Assigned(FOnDiocpHttpRequest) then
  begin
    FOnDiocpHttpRequest(pvRequest);
  end;
end;

procedure TDiocpHttpServer.DoRequestPostDataDone(pvRequest: TDiocpHttpRequest);
var
  lvRawData:AnsiString;
begin 
  if Assigned(FOnDiocpHttpRequestPostDone) then
  begin
    FOnDiocpHttpRequestPostDone(pvRequest);
  end;
end;

end.
