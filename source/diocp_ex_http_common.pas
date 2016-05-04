unit diocp_ex_http_common;

interface

// С��2007�İ汾��ʹ��ZlibExGZ
{$if CompilerVersion>= 18}
  {$IFDEF MSWINDOWS}
    {$DEFINE USE_ZLIBExGZ}
  {$ENDIF}
{$ifend}

{$if CompilerVersion>= 28}    // XE7:28
{$DEFINE USE_NetEncoding}
{$ifend}
uses
  utils_strings, SysUtils, utils_dvalue
{$IFDEF USE_NetEncoding}
    , System.NetEncoding
{$ENDIF}

{$IFDEF USE_ZLIBExGZ}
  , ZLibExGZ, ZLibEx
{$ENDIF}
  , Classes, Zlib;

{$if CompilerVersion>= 21}
  {$define NEWZLib}
{$IFEND}


const
  END_BYTES : array[0..3] of Byte = (13,10,13,10);

  /// ͷ�����10K
  MAX_HEADER_BUFFER_SIZE = 1024 * 10;  

type
{$if CompilerVersion < 18}
  TBytes = utils_strings.TBytes;
{$ifend}

  TDHttpCookie = class;
  THttpRequest = class(TObject)
  private
    FContentBuilder: TDBufferBuilder;
    FHeaderBuilder: TDBufferBuilder;

    // �������ݵ�Builder
    FRecvBuilder:TDBufferBuilder;

    FContentLength: Int64;
    FEndMatchIndex: Integer;
    FHeaders: TDValue;

    /// <summary>
    ///   URL�еĲ���
    /// </summary>
    FURLParams: TDValue;

    /// <summary>
    ///   Form�ύ�Ĳ���
    /// </summary>
    FRequestFormParams: TDValue;

    /// <summary>
    ///   URL�еĲ�����Form�ύ�Ĳ���
    /// </summary>
    FRequestParams:TDValue;

    /// <summary>
    ///   0: ��Ҫ��ʼ��
    ///   1: �Ѿ���ʼ��
    /// </summary>
    FFlag: Byte;
    FRawHeader: String;
    FContentDataLength: Integer;
    FHttpVersion: String;
    FMethod: String;
    FPtrBuffer: PByte;
    FRequestRawURL: string;

    FRequestURL:String;

    /// <summary>
    ///   ��������
    /// </summary>
    FContentType:String;


    FRequestRawCookie: string;
    // ��ſͻ��������Cookie��Ϣ
    FRequestCookieList: TStrings;


    /// <summary>
    ///  ԭʼ�����е�URL��������(û�о���URLDecode����Ϊ��DecodeRequestHeader��Ҫƴ��RequestURLʱ��ʱ������URLDecode)
    ///  û�о���URLDecode�ǿ��ǵ�����ֵ�б������&�ַ�������DecodeURLParam���ֲ������쳣
    /// </summary>
    FRequestRawURLParamStr: string;

    FRequestURI: string;
    /// <summary>
    ///  0: RawHeader;
    ///  1: ContentAsRAWString;
    /// </summary>
    FSectionFlag: Byte;

    /// <summary>
    ///   ����״̬
    /// </summary>
    FDecodeState: Integer;
    function DecodeRequestMethod: Integer;

    function DecodeHeader: Integer;
    procedure DecodeHeaderLine(pvLine:string);
    function DecodeFirstLine(pvLine: string): Integer;
    function GetContentLength: Int64;
    function GetContentAsMemory: PByte;

    function GetRawCookie: String;

    procedure CheckCookie;
    function GetContentAsRAWString: RAWString;
    function GetContentBody: TDBufferBuilder;
    function GetContentType: String;
    function GetHeaderAsMermory: PByte;
    function GetHeaderAsRAWString: RAWString;
    function GetHeaderDataLength: Integer;
    function GetRequestCookieList: TStrings;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   ��Post��ԭʼ���ݽ��룬�ŵ������б���
    ///    content����Ϊ: application/x-www-form-urlencoded
    /// </summary>
    procedure DecodeContentAsFormUrlencoded({$IFDEF UNICODE} pvEncoding:TEncoding
        {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});


    /// <summary>
    ///   ����URL�еĲ������ŵ������б���
    ///   ��OnDiocpHttpRequest�е���
    /// </summary>
    procedure DecodeURLParam(pvUseUtf8Decode:Boolean); overload;

    {$IFDEF UNICODE}
    procedure DecodeURLParam(pvEncoding:TEncoding); overload;
    {$ENDIF}

    procedure DoCleanUp;
    /// <summary>
    ///  ��ȡ�����Cookieֵ
    /// </summary>
    function GetCookie(pvCookieName:string): String;

    /// <summary>THttpRequest.InputBuffer
    /// </summary>
    /// <returns>
    ///  0: ��Ҫ�������������ɽ���
    ///  -2: ͷ��������󳤶�(MAX_HEADER_BUFFER_SIZE)
    ///  1: ���뵽ͷ
    ///  2: ���뵽������
    /// </returns>
    /// <param name="pvByte"> (Byte) </param>
    function InputBuffer(pvByte:Byte): Integer;

    procedure ContentSaveToFile(pvFile:String);

    /// <summary>
    ///   ����ΪPOST, PUTʱ�������Ϊ�ύ������
    /// </summary>
    property ContentAsMemory: PByte read GetContentAsMemory;

    property ContentAsRAWString: RAWString read GetContentAsRAWString;

    property ContentBody: TDBufferBuilder read GetContentBody;


    
    /// <summary>
    ///   ���ݳ���
    /// </summary>
    property ContentDataLength: Integer read FContentDataLength;

    property HeaderAsMermory: PByte read GetHeaderAsMermory;
    property HeaderAsRAWString: RAWString read GetHeaderAsRAWString;
    property HeaderDataLength: Integer read GetHeaderDataLength;

    property RawHeader: String read FRawHeader;

    property Headers: TDValue read FHeaders;

    property HttpVersion: String read FHttpVersion;

    property Method: String read FMethod write FMethod;
    
    property ContentLength: Int64 read GetContentLength;
    property ContentType: String read GetContentType;

    property RawCookie: String read GetRawCookie;
    property RequestCookieList: TStrings read GetRequestCookieList write
        FRequestCookieList;

    property RequestRawURL: string read FRequestRawURL write FRequestRawURL;

    property RequestRawURLParamStr: string read FRequestRawURLParamStr;

    property RequestURI: string read FRequestURI;

    /// <summary>
    ///   Decode֮��Ż�������
    /// </summary>
    property URLParams: TDValue read FURLParams;

    /// <summary>
    ///  ������ֵ, DecodeContentAsFormUrlencoded֮��Ż�������
    /// </summary>
    property RequestFormParams: TDValue read FRequestFormParams;
    property RequestParams: TDValue read FRequestParams;
    property RequestURL: String read FRequestURL;
  end;

  /// <summary>
  ///   ���ڽ�������
  /// </summary>
  THttpBuffer = class(TObject)
  private
    // �������ݵ�Builder
    FRecvBuilder:TDBufferBuilder;

    FContentBuilder: TDBufferBuilder;
    FContentLength: Int64;
    FHeaderBuilder: TDBufferBuilder;

    FRecvSize: Integer;
    
    /// <summary>
    ///   ����״̬
    /// </summary>
    FDecodeState: Integer;

    /// <summary>
    ///   0: ��Ҫ��ʼ��
    ///   1: �Ѿ���ʼ��
    /// </summary>
    FFlag: Byte;

    /// <summary>
    ///  0: RawHeader;
    ///  1: ContentAsRAWString;
    /// </summary>
    FSectionFlag: Byte;
  public
    constructor Create();

    destructor Destroy; override;

    procedure DoCleanUp;

    /// <summary>THttpBuffer.InputBuffer
    /// </summary>
    /// <returns>
    ///  0: ��Ҫ�������������ɽ���
    ///  -2: ͷ��������󳤶�(MAX_HEADER_BUFFER_SIZE)
    ///  1: ���뵽ͷ
    ///  2: ���뵽������
    /// </returns>
    /// <param name="pvByte"> (Byte) </param>
    function InputBuffer(pvByte:Byte): Integer;

    property ContentBuilder: TDBufferBuilder read FContentBuilder;
    /// <summary>
    ///   ��Ҫ���յ����ݳ���
    /// </summary>
    property ContentLength: Int64 read FContentLength write FContentLength;
    property HeaderBuilder: TDBufferBuilder read FHeaderBuilder;

  end;

  THttpResponse = class(TObject)
  private
    FHeaderBuilder: TDBufferBuilder;
    FContentBuffer: TDBufferBuilder;
    FCookies: TDValue;
    FHeaders: TDValue;
    FResponseCode: Word;
    FResponseCodeStr: String;
    function GetContentType: RAWString;
    procedure InnerBuildHeader(pvBuilder: TDBufferBuilder); virtual;
    procedure SetContentType(const Value: RAWString);
  public
    procedure DoCleanUp;
    constructor Create;
    destructor Destroy; override;
    function AddCookie: TDHttpCookie; overload;
    function AddCookie(pvName:String; pvValue:string): TDHttpCookie; overload;
    
    property ContentBuffer: TDBufferBuilder read FContentBuffer;

    property ContentType: RAWString read GetContentType write SetContentType;
    property HeaderBuilder: TDBufferBuilder read FHeaderBuilder;
    property Headers: TDValue read FHeaders;
    property ResponseCode: Word read FResponseCode write FResponseCode;

    property ResponseCodeStr: String read FResponseCodeStr write FResponseCodeStr;


    /// <summary>
    ///  ��ȡ�����Cookieֵ
    /// </summary>
    function GetCookie(pvCookieName:string): TDHttpCookie;
    procedure ClearCookies;
    
    procedure EncodeHeader(pvContentLength: Integer);
    procedure ChunkedBuffer(pvBuffer:Pointer; pvLen:Integer);

    procedure ChunkedBufferStart;
    procedure ChunkedBufferEnd;

    /// <summary>
    ///   GZip ѹ��
    /// </summary>
    procedure GZipContent;

    procedure DeflateCompressContent;

    procedure ZCompressContent;
  end;

  /// <summary>
  ///   ��������ÿͻ���Cookie������
  /// </summary>
  TDHttpCookie = class(TObject)
  private
    FExpires: TDateTime;
    FName: String;
    FPath: String;
    FValue: String;
  public
    /// <summary>
    ///   �����һ��String
    /// </summary>
    function ToString: String;

    property Expires: TDateTime read FExpires write FExpires;
    property Name: String read FName write FName;
    property Path: String read FPath write FPath;
    property Value: String read FValue write FValue;
  end;

  EHTTPException = class(Exception)
  end;



function GetResponseCodeText(pvCode: Word): RAWString;

procedure DeflateCompressBufferBuilder(pvBuilder:TDBufferBuilder);

procedure ZDecompressBufferBuilder(pvBuilder:TDBufferBuilder);

procedure ZCompressBufferBuilder(pvBuilder:TDBufferBuilder);

function GetContentTypeFromFileExt(pvFileExt, pvDefault: string): String;


{$IFDEF USE_ZLIBExGZ}
procedure GZCompressBufferBuilder(pvBuilder:TDBufferBuilder);
procedure GZDecompressBufferBuilder(pvBuilder:TDBufferBuilder);
{$ENDIF}

/// <summary>
///   [utf8/ansi]->url
/// </summary>
function URLEncode(pvStr: string; pvConvertUtf8: Boolean = true): string;

/// <summary>
///   raw buffer -> url
/// </summary>
function BufferURLEncode(pvBuff: PByte; pvLen: Integer): string;

/// <summary>
///   urlencodestr -> raw buffer
/// </summary>
function BufferURLDecode(pvInputStr: string; pvOutBuffer: PByte;
    pvOutBufferLen: Integer): Integer;

/// <summary>
///   urldecode -> utf8
/// </summary>
function URLDecode(pvInputStr: string; pvConvertUtf8: Boolean = true): String; overload;

{$IFDEF UNICODE}
/// <summary>
///   urldecode -> TEncoding
/// </summary>
function URLDecode(pvInputStr: string; pvEncoding:TEncoding): String; overload;
{$ENDIF}





implementation

resourcestring
  { System.NetEncoding }
  sErrorDecodingURLText = 'Error decoding URL style (%%XX) encoded string at position %d';
  sInvalidURLEncodedChar = 'Invalid URL encoded character (%s) at position %d';
  sErrorDecodingURL_InvalidateChar = 'URL�к��зǷ��ַ�:%s';
  sErrorDecodingURL_BufferIsNotEnough = '�����Buffer���Ȳ���';

function GetResponseCodeText(pvCode: Word): RAWString;
begin
  case pvCode of
    100: Result := '100 Continue';
    101: Result := '101 Switching Protocols';
    102: Result := '102 Processing';
    200: Result := '200 OK';
    201: Result := '201 Created';
    202: Result := '202 Accepted';
    203: Result := '203 Non-Authoriative Information';
    204: Result := '204 No Content';
    205: Result := '205 Reset Content';
    206: Result := '206 Partial Content';
    207: Result := '207 Multi-Status';
    300: Result := '300 Multiple Choices';
    301: Result := '301 Moved Permanently';
    302: Result := '302 Found';
    303: Result := '303 See Other';
    304: Result := '304 Not Modified';
    305: Result := '305 Use Proxy';
    306: Result := '306 (Unused)';
    307: Result := '307 Temporary Redirect';
    400: Result := '400 Bad Request';
    401: Result := '401 Unauthorized';
    403: Result := '403 Forbidden';
    404: Result := '404 Not Found';
    405: Result := '405 Method Not Allowed';
    406: Result := '406 Not Acceptable';
    407: Result := '407 Proxy Authentication Required';
    408: Result := '408 Request Timeout';
    409: Result := '409 Conflict';
    410: Result := '410 Gone';
    411: Result := '411 Length Required';
    412: Result := '412 Precondition Failed';
    413: Result := '413 Request Entity Too Large';
    414: Result := '414 Request URI Too Long';
    415: Result := '415 An Unsupported Media Type';
    416: Result := '416 Requested Range Not Satisfiable';
    417: Result := '417 On Failure';
    422: Result := '422 Unprocessable Entity';
    423: Result := '423 Locked';
    424: Result := '424 Failed Dependency';
    500: Result := '500 Internal Server Error';
    501: Result := '501 Not Implemented';
    502: Result := '502 Bad Gateway';
    503: Result := '503 Service Unavailable';
    504: Result := '504 Gateway Timeout';
    505: Result := '505 Version Not Supported';
    507: Result := '507 Insufficient Storage';
  else
    Result := IntToStr(pvCode) +  ' Unknown Error';
  end;
end;

procedure ZCompressBufferBuilder(pvBuilder:TDBufferBuilder);
{$IFDEF POSIX}
var
  lvOutBuf: TBytes;
{$ELSE}
var
  lvInBuf: TBytes;
  lvOutBuf: Pointer;
  lvOutBytes: Integer;
var
  l: Integer;
{$ENDIF}

begin
{$IFDEF POSIX}
  ZLib.ZCompress(pvBuilder.ToBytes, lvOutBuf);
  pvBuilder.Clear;
  pvBuilder.AppendBuffer(@lvOutBuf[0], length(lvOutBuf));
{$ELSE}
  try
    {$if defined(NEWZLib)}
    ZLib.ZCompress(pvBuilder.Memory, pvBuilder.Length, lvOutBuf, lvOutBytes);
    {$ELSE}
    ZLib.CompressBuf(pvBuilder.Memory, pvBuilder.Length, lvOutBuf, lvOutBytes);
    {$ifend}

    pvBuilder.Clear;
    pvBuilder.AppendBuffer(lvOutBuf, lvOutBytes);
  finally
    FreeMem(lvOutBuf, lvOutBytes);
  end;
{$ENDIF}
end;

procedure DeflateCompressBufferBuilder(pvBuilder:TDBufferBuilder);
{$IFDEF POSIX}
var
  lvBytes, lvOutBytes:TBytes;
{$ELSE}
var
  lvInBuf: TBytes;
  lvOutBuf: Pointer;
  lvOutBytes: Integer;
{$ENDIF}
  lvRefBuf: PByte;
var
  l: Integer;
begin
{$IFDEF POSIX}
  ZLib.ZCompress(pvBuilder.ToBytes, lvOutBytes);

  // ��ȡǰ��2λ��ʶ���ͺ���λ��2007����ͨ��OK, deflateѹ����ʽ)
  lvRefBuf := PByte(@lvOutBytes[0]);
  inc(lvRefBuf, 2);

  pvBuilder.Clear;
  pvBuilder.AppendBuffer(lvRefBuf, length(lvOutBytes) -2 -4);
{$ELSE}
  try
    {$if defined(NEWZLib)}
    ZLib.ZCompress(pvBuilder.Memory, pvBuilder.Length, lvOutBuf, lvOutBytes);
    {$ELSE}
    ZLib.CompressBuf(pvBuilder.Memory, pvBuilder.Length, lvOutBuf, lvOutBytes);
    {$ifend}

    // ��ȡǰ��2λ��ʶ���ͺ���λ��2007����ͨ��OK, deflateѹ����ʽ)
    lvRefBuf := PByte(lvOutBuf);
    inc(lvRefBuf, 2);

    pvBuilder.Clear;
    pvBuilder.AppendBuffer(lvRefBuf, lvOutBytes -2 -4);
  finally
    FreeMem(lvOutBuf, lvOutBytes);
  end;
{$ENDIF}
end;

procedure ZDecompressBufferBuilder(pvBuilder:TDBufferBuilder);
var
  l:Integer;
{$IFDEF POSIX}
var
  lvBytes, lvOutBytes:TBytes;
{$ELSE}
var
  lvBytes:TBytes;
  OutBuf: Pointer;
  OutBytes: Integer;
{$ENDIF}
begin
  if pvBuilder.Length = 0 then exit;
{$IFDEF POSIX}
  ZLib.ZDecompress(pvBuilder.ToBytes, lvOutBytes);
  pvBuilder.Clear;
  pvBuilder.AppendBuffer(@lvOutBytes[0], length(lvOutBytes));
{$ELSE}
  {$if defined(NEWZLib)}
  ZLib.ZDecompress(pvBuilder.Memory, pvBuilder.Length, OutBuf, OutBytes);
  {$ELSE}
  Zlib.DecompressBuf(pvBuilder.Memory, pvBuilder.Length, 0, OutBuf, OutBytes);
  {$ifend}
  try
    pvBuilder.Clear;
    pvBuilder.AppendBuffer(OutBuf, OutBytes);
  finally
    FreeMem(OutBuf, OutBytes);
  end;
{$ENDIF}
end;

{$IFDEF USE_ZLIBExGZ}
procedure GZCompressBufferBuilder(pvBuilder:TDBufferBuilder);
var
  lvInStream, lvOutStream:TMemoryStream;
//  lvOutBuf:Pointer;
//  lvOutBytes:Integer;
begin
//  try
//    ZLibEx.ZCompress(pvBuilder.Memory, pvBuilder.Length, lvOutBuf, lvOutBytes);
//    pvBuilder.Clear;
//    pvBuilder.AppendBuffer(lvOutBuf, lvOutBytes);
//  finally
//    FreeMem(lvOutBuf, lvOutBytes);
//  end;
  lvInStream := TMemoryStream.Create;
  lvOutStream := TMemoryStream.Create;
  try
    lvInStream.SetSize(pvBuilder.Length);
    lvInStream.WriteBuffer(pvBuilder.Memory^, pvBuilder.Length);
    lvInStream.Position := 0;
    GZCompressStream(lvInStream, lvOutStream);
    pvBuilder.Clear;
    pvBuilder.AppendBuffer(lvOutStream.Memory, lvOutStream.Size);
  finally
    lvInStream.Free;
    lvOutStream.Free;
  end;

end;

procedure GZDecompressBufferBuilder(pvBuilder:TDBufferBuilder);
var
  lvInStream, lvOutStream:TMemoryStream;
begin
  lvInStream := TMemoryStream.Create;
  lvOutStream := TMemoryStream.Create;
  try
    lvInStream.SetSize(pvBuilder.Length);
    lvInStream.WriteBuffer(pvBuilder.Memory^, pvBuilder.Length);
    lvInStream.Position := 0;
    GZDecompressStream(lvInStream, lvOutStream);
    pvBuilder.Clear;
    pvBuilder.AppendBuffer(lvOutStream.Memory, lvOutStream.Size);
  finally
    lvInStream.Free;
    lvOutStream.Free;
  end; 
end;
{$ENDIF}

function BufferURLEncode(pvBuff: PByte; pvLen: Integer): string;
// The NoConversion set contains characters as specificed in RFC 1738 and
// should not be modified unless the standard changes.
const
  NoConversion = [Ord('A')..Ord('Z'), Ord('a')..Ord('z'), Ord('*'), Ord('@'),
                  Ord('.'), Ord('_'), Ord('-'), Ord('0')..Ord('9'), Ord('$'),
                  Ord('!'), Ord(''''), Ord('('), Ord(')')];

  procedure AppendByte(B: Byte; var Buffer: PChar);
  const
    Hex = '0123456789ABCDEF';
  {$if CompilerVersion>= 28}   // XE7
    LOW_INDEX = Low(string);
  {$else}
    LOW_INDEX = 1;
  {$ifend}
  begin
    Buffer[0] := '%';
    Buffer[1] := Hex[B shr 4 + LOW_INDEX];
    Buffer[2] := Hex[B and $F + LOW_INDEX];
    Inc(Buffer, 3);
  end;

var
  Rp: PChar;
  lvBuff:PByte;
  MultibyteChar: TBytes;
  I, ByteCount, j: Integer;
begin
  // Characters that require more than 1 byte are translated as "percent-encoded byte"
  // which will be encoded with 3 chars per byte -> %XX
  // Example: U+00D1 ($F1 in CodePage 1252)
  //   UTF-8 representation: $C3 $91 (2 bytes)
  //   URL encode representation: %C3%91
  //
  // 3 characters to represent each byte
  SetLength(Result, pvLen * 3);
  lvBuff := PByte(pvBuff);
  Rp := PChar(Result);
  j := 0;
  while j < pvLen do
  begin
    if lvBuff^ in NoConversion then
    begin
      Rp^ := Char(lvBuff^);
      Inc(Rp)
    end
//    else if pvBuff^ = Ord(' ') then
//    begin
//      Rp^ := '+';
//      Inc(Rp)
//    end
    else
    begin
       AppendByte(lvBuff^, Rp)
    end;
    Inc(lvBuff);
    Inc(j);
  end;
  SetLength(Result, Rp - PChar(Result));
end;

function URLEncode(pvStr: string; pvConvertUtf8: Boolean = true): string;
var
  lvBytes:TBytes;
begin
  if pvConvertUtf8 then
  begin
    lvBytes :=TBytes(StringToUtf8Bytes(pvStr));
  end else
  begin
    lvBytes := TBytes(StringToBytes(pvStr));
  end;

  Result := BufferURLEncode(@lvBytes[0], Length(lvBytes));
end;

function URLDecode(pvInputStr: string; pvConvertUtf8: Boolean = true): String;
var
  lvBytes: TBytes;
  l:Integer;
begin
  SetLength(lvBytes, Length(pvInputStr));
  l := BufferURLDecode(pvInputStr, @lvBytes[0], Length(lvBytes));
  SetLength(lvBytes, l);
  if pvConvertUtf8 then
  begin
    Result := Utf8BytesToString(lvBytes, 0);
  end else
  begin
    Result := BytesToString(lvBytes, 0);
  end;
end;

function BufferURLDecode(pvInputStr: string; pvOutBuffer: PByte;
    pvOutBufferLen: Integer): Integer;

  function DecodeHexChar(const C: Char): Byte;
  begin
    case C of
       '0'..'9': Result := Ord(C) - Ord('0');
       'A'..'F': Result := Ord(C) - Ord('A') + 10;
       'a'..'f': Result := Ord(C) - Ord('a') + 10;
    else
      raise EConvertError.Create('');
    end;
  end;

  function DecodeHexPair(const C1, C2: Char): Byte; 
  begin
    Result := DecodeHexChar(C1) shl 4 + DecodeHexChar(C2)
  end;

var
  Sp, Cp: PChar;
  I: Integer;
  lvPtr:PByte;
begin
  lvPtr := pvOutBuffer;
  I := 0;
  Sp := PChar(pvInputStr);
  Cp := Sp;
  try
    while Sp^ <> #0 do
    begin
      if (I >= pvOutBufferLen) then
      begin
        raise EHTTPException.Create(sErrorDecodingURL_BufferIsNotEnough);
      end;
      case Sp^ of
        '+':
          lvPtr^ := Byte(' ');
        '%':
          begin
            Inc(Sp);
            // Look for an escaped % (%%)
            if (Sp)^ = '%' then
              lvPtr^ := Byte('%')
            else
            begin
              // Get an encoded byte, may is a single byte (%<hex>)
              // or part of multi byte (%<hex>%<hex>...) character
              Cp := Sp;
              Inc(Sp);
              if ((Cp^ = #0) or (Sp^ = #0)) then
                raise EHTTPException.CreateFmt(sErrorDecodingURLText, [Cp - PChar(pvInputStr)]);
              lvPtr^ := DecodeHexPair(Cp^, Sp^)
            end;
          end;
      else
        // Accept single
        if Ord(Sp^) < 128 then
          lvPtr^ := Byte(Sp^)
        else
        begin
          // multi byte characters (������)   s
          raise EHTTPException.CreateFmt(sErrorDecodingURL_InvalidateChar, [Sp^]);
          //I := I + TEncoding.UTF8.GetBytes([Sp^], 0, 1, Bytes, I) - 1
        end;
      end;
      Inc(I);
      Inc(lvPtr);
      Inc(Sp);
    end;
  except
    on E: EConvertError do
      raise EConvertError.CreateFmt(sInvalidURLEncodedChar, [Char('%') + Cp^ + Sp^, Cp - PChar(pvInputStr)])
  end;
  Result := I;
end;


function GetContentTypeFromFileExt(pvFileExt, pvDefault: string): String;
var
  lvExt:String;
begin
  lvExt := LowerCase(pvFileExt);
  if lvExt = '.js' then
  begin
    Result := 'application/javascript';
  end else if lvExt = '.css' then
  begin
    Result := 'text/css';
  end else if (lvExt = '.html') or (lvExt = '.htm') then
  begin
    Result := 'text/html;charset=UTF-8';
  end else
  begin
    Result := pvDefault;
  end;
end;

{$IFDEF UNICODE}
function URLDecode(pvInputStr: string; pvEncoding:TEncoding): String; overload;
var
  lvBytes:TBytes;
  l:Integer;
begin
  SetLength(lvBytes, Length(pvInputStr));
  l := BufferURLDecode(pvInputStr, @lvBytes[0], Length(lvBytes));
  SetLength(lvBytes, l);
  if pvEncoding <> nil then
  begin
    result := pvEncoding.GetString(lvBytes);
  end else
  begin
    result := pvEncoding.Default.GetString(lvBytes);
  end;

end;
{$ENDIF}

constructor THttpRequest.Create;
begin
  inherited Create;
  FContentBuilder := TDBufferBuilder.Create();
  FHeaderBuilder := TDBufferBuilder.Create();
  FHeaders := TDValue.Create();
  FURLParams := TDValue.Create();
  FRequestFormParams := TDValue.Create();
  FRequestParams := TDValue.Create();
  
  FRequestCookieList := TStringList.Create;
  FContentLength := -1;
end;

destructor THttpRequest.Destroy;
begin
  FHeaders.Free;
  FURLParams.Free;
  FRequestFormParams.Free;
  FRequestParams.Free;
  FreeAndNil(FContentBuilder);
  FHeaderBuilder.Free;
  FRequestCookieList.Free;
  inherited Destroy;
end;

procedure THttpRequest.CheckCookie;
begin
  if FRequestRawCookie = '-1' then
  begin
    FRequestRawCookie := FHeaders.GetValueByName('Cookie', '');
    SplitStrings(FRequestRawCookie, FRequestCookieList, [';']);
  end;
end;

procedure THttpRequest.ContentSaveToFile(pvFile:String);
begin
  FContentBuilder.SaveToFile(pvFile);
end;

function THttpRequest.DecodeHeader: Integer;
var
  lvPtr:PChar;
  lvLine:String;
begin
  lvPtr := PChar(FRawHeader);

  lvLine := LeftUntil(lvPtr, [#13, #10]);
  Result := DecodeFirstLine(lvLine);
  if Result = -1 then
  begin
    Exit;
  end;

  while True do
  begin
    SkipChars(lvPtr,  [#13, #10, ' ', #9]);
    if LeftUntil(lvPtr, [#13, #10], lvLine) = 0 then
    begin
      DecodeHeaderLine(lvLine);
    end else
    begin
      break;
    end;
  end;
  

  Result := 0;
end;

procedure THttpRequest.DecodeHeaderLine(pvLine:string);
var
  lvPtr:PChar;
  lvKey:string;
  r:Integer;
begin
  lvPtr := PChar(pvLine);

  r := LeftUntil(lvPtr, [':'], lvKey);
  if r = -1 then Exit;

  lvKey := LowerCase(Trim(lvKey));

  SkipChars(lvPtr, [':', ' ', #9]);
  if lvKey = 'content-length' then
  begin
    FContentLength := StrToInt(lvPtr);
  end;
  FHeaders.ForceByName(lvKey).AsString := lvPtr;
end;

function THttpRequest.DecodeFirstLine(pvLine: string): Integer;
var
  lvPtr, lvTempPtr:PChar;
begin
  // GET /test?v=abc HTTP/1.1
  lvPtr := PChar(pvLine);

  FMethod := UpperCase(LeftUntil(lvPtr, [' ']));
  if FMethod = '' then
  begin
    Result := -1;
    Exit;
  end;

  // �����ո�
  SkipChars(lvPtr, [' ']);
  Result := 0;
  if (FMethod = 'GET') then
  begin
    ;
  end else if (FMethod = 'POST') then
  begin
    ;
  end else if (FMethod = 'PUT') then
  begin
    ;
  end else if (FMethod = 'HEAD') then
  begin
    ;
  end else if (FMethod = 'OPTIONS') then
  begin
    ;
  end else if (FMethod = 'DELETE') then
  begin
    ;
  end else if (FMethod = 'TRACE') then
  begin
    ;
  end else if (FMethod = 'CONNECT') then
  begin
    ;
  end else
  begin
    Result := -1;
  end;

  if Result = 0 then
  begin

    // IEԭʼURL  : /�й�.asp?topicid=a����a
    // ��̨���յ� : /%E4%B8%AD%E5%9B%BD.asp?topicid=a����a

    // FireFox/360���������ԭʼURL : /%E4%B8%AD%E5%9B%BD.asp?topicid=a%E6%B1%89%E5%AD%97a
    // ��̨���յ� : /%E4%B8%AD%E5%9B%BD.asp?topicid=a%E6%B1%89%E5%AD%97a


    // URI��Ҫ����URLDecode��Utf8����

    //if lvPtr^='/' then inc(lvPtr);
    FRequestRawURL := LeftUntil(lvPtr, [' ', #9]);
    lvTempPtr := PChar(FRequestRawURL);
    if LeftUntil(lvTempPtr, ['?'], FRequestURI) = -1 then
    begin     // ��ȡURI
      FRequestURI := URLDecode(FRequestRawURL);
      FRequestURL := FRequestURI;
    end else
    begin
      FRequestURI := URLDecode(FRequestURI);

      // ���沿����ԭʼ����
      Inc(lvTempPtr);
      FRequestRawURLParamStr := lvTempPtr;

      FRequestURL := FRequestURI + '?' + URLDecode(FRequestRawURLParamStr);
    end;

    SkipChars(lvPtr, [' ', #9]);
    FHttpVersion := lvPtr;
  end;
end;

procedure THttpRequest.DecodeContentAsFormUrlencoded({$IFDEF UNICODE}
    pvEncoding:TEncoding {$ELSE}pvUseUtf8Decode:Boolean{$ENDIF});
var
  lvRawData : RAWString;
  lvRawParams, s, lvName, lvValue:String;
  i:Integer;
  lvStrings:TStrings;
begin                       
  if ContentLength = 0 then exit;

  lvRawData := FContentBuilder.ToRAWString;

  lvStrings := TStringList.Create;
  try
    // �ȷ��뵽Strings
    SplitStrings(lvRawData, lvStrings, ['&']);

    for i := 0 to lvStrings.Count - 1 do
    begin
      s := Trim(lvStrings[i]);
      if length(s) > 0 then
      begin
        if SplitStr(s, '=', lvName, lvValue) then
        begin
          {$IFDEF UNICODE}
          lvName := URLDecode(lvName, pvEncoding);
          lvValue := URLDecode(lvValue, pvEncoding);
          {$ELSE}
          lvName := URLDecode(lvName, pvUseUtf8Decode);
          lvValue := URLDecode(lvValue, pvUseUtf8Decode);
          {$ENDIF}
          FRequestFormParams.ForceByName(lvName).AsString := lvValue;
          FRequestParams.ForceByName(lvName).AsString := lvValue;
        end;
      end;
    end;
  finally
    lvStrings.Free;
  end;
end;

function THttpRequest.DecodeRequestMethod: Integer;
var
  lvBuf:PChar;
  lvMethod:String;
begin
  lvMethod := ByteBufferToString(FHeaderBuilder.Memory, 7);
  lvBuf :=  PChar(lvMethod);
  if (StrLIComp(lvBuf, 'GET', 3) = 0) then
  begin
    FMethod := 'GET';
  end
  else if (StrLIComp(lvBuf, 'POST', 4) = 0) then
  begin
    FMethod := 'POST';
  end
  else if (StrLIComp(lvBuf, 'PUT', 3) = 0) then
  begin
    FMethod := 'PUT';
  end
  else if (StrLIComp(lvBuf, 'HEAD', 3) = 0) then
  begin
    FMethod := 'HEAD';
  end
  else if (StrLIComp(lvBuf, 'OPTIONS', 7) = 0) then
  begin
    FMethod := 'OPTIONS';
  end
  else if (StrLIComp(lvBuf, 'DELETE', 6) = 0) then
  begin
    FMethod := 'DELETE';
  end
  else if (StrLIComp(lvBuf, 'TRACE', 5) = 0) then
  begin
    FMethod := 'TRACE';
  end
  else if (StrLIComp(lvBuf, 'CONNECT', 7) = 0) then
  begin
    FMethod := 'CONNECT';
  end
  else
  begin
    Result := -1;
  end;
end;

procedure THttpRequest.DecodeURLParam(pvUseUtf8Decode:Boolean);
var
  lvRawData : String;
  s, lvName:String;
  i:Integer;
  lvStrings:TStrings;
begin
  // ����URL����
  if FRequestRawURLParamStr = '' then exit;

  lvStrings := TStringList.Create;
  try
    lvStrings.Delimiter := '&';
    lvStrings.DelimitedText := FRequestRawURLParamStr;

//    // �ȷ��뵽Strings
//    SplitStrings(FRequestURLParamData, lvStrings, ['&']);

    for i := 0 to lvStrings.Count - 1 do
    begin

      lvRawData := lvStrings.ValueFromIndex[i];
      if lvRawData<> '' then
      begin

        // ���غ�����ͬ����
        s := URLDecode(lvRawData, pvUseUtf8Decode);

        lvName := lvStrings.Names[i];
        FURLParams.ForceByName(lvName).AsString := s;
        FRequestParams.ForceByName(lvName).AsString := s;
      end;
    end;
   // FRequestParamsList.AddStrings(lvStrings);
  finally
    lvStrings.Free;
  end;

end;

{$IFDEF UNICODE}
procedure THttpRequest.DecodeURLParam(pvEncoding:TEncoding);
var
  lvRawData : String;
  s, lvName:String;
  i:Integer;
  lvStrings:TStrings;
begin
  // ����URL����
  if FRequestRawURLParamStr = '' then exit;

  lvStrings := TStringList.Create;
  try
    lvStrings.Delimiter := '&';
    lvStrings.DelimitedText := FRequestRawURLParamStr;

    for i := 0 to lvStrings.Count - 1 do
    begin
      lvRawData := lvStrings.ValueFromIndex[i];
      if lvRawData<> '' then
      begin

        // ֻ���ⲿ�ֲ�ͬ�� DecodeURLParam(pvUseUtf8Decode:Boolean)
        s := URLDecode(lvRawData, pvEncoding);

        lvName := lvStrings.Names[i];
        FURLParams.ForceByName(lvName).AsString := s;
        FRequestParams.ForceByName(lvName).AsString := s;
      end;
    end;
   // FRequestParamsList.AddStrings(lvStrings);
  finally
    lvStrings.Free;
  end;
end;
{$ENDIF}

procedure THttpRequest.DoCleanUp;
begin
  if FContentBuilder <> nil then
    FContentBuilder.Clear;
  if FHeaderBuilder <> nil then
    FHeaderBuilder.Clear;

  FRecvBuilder := FHeaderBuilder;

  FContentDataLength := 0;
  FSectionFlag := 0;
  FFlag := 0;
  FDecodeState := 0;
  FContentLength := -1;
  FRawHeader := '';
  FRequestRawURL := '';
  FRequestRawCookie := '-1';
  FContentType := '-1';
  FRequestCookieList.Clear;
  FRequestRawURLParamStr := '';
  FURLParams.Clear;
  FRequestParams.Clear;
  FRequestFormParams.Clear;
  FHeaders.Clear;
end;

function THttpRequest.GetContentLength: Int64;
begin
  if FContentLength = -1 then
  begin
    FContentLength := FHeaders.GetValueByName('Content-Length', 0);
  end;
  Result := FContentLength;
end;

function THttpRequest.GetContentType: String;
begin
  if FContentType = '-1' then
  begin
    FContentType := FHeaders.GetValueByName('Content-Type', '');
  end;
  Result := FContentType;
end;

function THttpRequest.GetCookie(pvCookieName: string): String;
begin
  Result := StringsValueOfName(RequestCookieList, pvCookieName, ['='], true);
end;

function THttpRequest.GetContentAsMemory: PByte;
begin
  Result := FContentBuilder.Memory;
end;

function THttpRequest.GetContentAsRAWString: RAWString;
begin
  Result := ByteBufferToString(FContentBuilder.Memory, FContentBuilder.Length);
end;

function THttpRequest.GetContentBody: TDBufferBuilder;
begin
  Result := FContentBuilder;
end;

function THttpRequest.GetHeaderAsMermory: PByte;
begin
  Result := FHeaderBuilder.Memory;
end;

function THttpRequest.GetHeaderAsRAWString: RAWString;
begin
  Result := ByteBufferToString(FHeaderBuilder.Memory, FHeaderBuilder.Length);
end;

function THttpRequest.GetHeaderDataLength: Integer;
begin
  Result := FHeaderBuilder.Length;
end;

function THttpRequest.GetRawCookie: String;
begin
  CheckCookie;
  Result := FRequestRawCookie;
end;

function THttpRequest.GetRequestCookieList: TStrings;
begin
  CheckCookie;
  Result := FRequestCookieList;
end;

function THttpRequest.InputBuffer(pvByte:Byte): Integer;

  procedure InnerCaseZero;
  begin
    if FContentDataLength = 7 then
    begin
      if DecodeRequestMethod = -1 then
      begin
        FSectionFlag := 0;
        Result := -1;
        Exit;
      end;
    end else if pvByte = 13 then
    begin
     Inc(FDecodeState);
    end;

    if (FContentDataLength = MAX_HEADER_BUFFER_SIZE) then
    begin            // ͷ�����ݹ���
      FFlag := 0;
      Result := -2;
    end;
  end;
begin
  Result := 0;
  if FFlag = 0 then
  begin
    FContentBuilder.Clear;
    FHeaderBuilder.Clear;
    FFlag := 1;
    FEndMatchIndex := 0;
    FContentDataLength := 0;
  end;

  Inc(FContentDataLength);
  FRecvBuilder.Append(pvByte);
  Inc(FPtrBuffer);

  case FDecodeState of
    0:
     begin
       InnerCaseZero;
     end;
    1:    // ��һ�� #10
    begin
      if pvByte = 10 then Inc(FDecodeState)
      else
      begin
        FDecodeState := 0;
        InnerCaseZero;
      end;
    end;
    2:  // �ڶ��� #13
    begin
      if pvByte = 13 then Inc(FDecodeState)
      else
      begin
        FDecodeState := 0;
        InnerCaseZero;
      end;
    end;
    3:  // �ڶ��� #10
    begin
      if pvByte = 10 then
      begin  // Header
        FRawHeader := ByteBufferToString(FRecvBuilder.Memory, FContentDataLength);
        if DecodeHeader = -1 then
        begin
          FSectionFlag := 0;
          Result := -1;
          FDecodeState := 0;
        end else
        begin
          FSectionFlag := 1;
          Result := 1;
          Inc(FDecodeState);
        end;
        
        FRecvBuilder := FContentBuilder;
        FContentDataLength := 0;
        FFlag := 0;
        Exit;
      end else
      begin
        FDecodeState := 0;
        InnerCaseZero;
      end;
    end;
    4:  // ����Content
    begin
      if FContentLength = FContentDataLength then
      begin
        Result := 2;     // ContentAsRAWString
        FFlag := 0;      // ���¿�ʼ����Buffer���н���
        Exit;
      end;
    end;
  end;
end;

function TDHttpCookie.ToString: String;
begin
  Result := Format('%s=%s; Path=%s;', [self.FName, self.FValue, Self.FPath]);
end;

constructor THttpResponse.Create;
begin
  inherited Create;
  FHeaderBuilder := TDBufferBuilder.Create();
  FContentBuffer := TDBufferBuilder.Create;
  FHeaders := TDValue.Create();
  FCookies := TDValue.Create();
end;

destructor THttpResponse.Destroy;
begin
  FHeaders.Free;
  FCookies.Free;
  FreeAndNil(FHeaderBuilder);
  FContentBuffer.Free;
  inherited Destroy;
end;

function THttpResponse.AddCookie: TDHttpCookie;
begin
  Result := TDHttpCookie.Create;
  Result.Path := '/';
  FCookies.AddArrayChild.BindObject(Result);
end;

function THttpResponse.AddCookie(pvName:String; pvValue:string):
    TDHttpCookie;
begin
  Result := AddCookie;
  Result.Name := pvName;
  Result.Value := pvValue;
end;

procedure THttpResponse.ClearCookies;
begin
  FCookies.Clear;
end;

procedure THttpResponse.DoCleanUp;
begin
  FCookies.Clear;
  FHeaders.Clear;
  FHeaderBuilder.Clear;
  FContentBuffer.Clear;
  FResponseCode := 0;
  FResponseCodeStr := '';
end;

procedure THttpResponse.EncodeHeader(pvContentLength: Integer);
begin
  FHeaderBuilder.Clear;
  InnerBuildHeader(FHeaderBuilder);

  FHeaderBuilder.AppendRawStr('Content-Length:').AppendRawStr(IntToStr(pvContentLength)).AppendBreakLineBytes;
  FHeaderBuilder.AppendBreakLineBytes;
end;

function THttpResponse.GetCookie(pvCookieName:string): TDHttpCookie;
var
  i:Integer;
  lvCookie:TDHttpCookie;
begin
  Result := nil;
  for i := 0 to FCookies.Count - 1 do
  begin
    lvCookie := TDHttpCookie(FCookies[i].AsObject);
    if lvCookie.Name = pvCookieName then
    begin
      Result := lvCookie;
      Exit;
    end;
  end;
end;

procedure THttpResponse.InnerBuildHeader(pvBuilder: TDBufferBuilder);
var
  i:Integer;
  lvItem:TDValue;
  lvCode:Word;
begin
  lvCode := FResponseCode;
  if lvCode = 0 then lvCode := 200;

  if FResponseCodeStr <> ''  then
  begin
    pvBuilder.AppendRawStr('HTTP/1.1 ').AppendRawStr(FResponseCodeStr).AppendBreakLineBytes;
  end else
  begin
    pvBuilder.AppendRawStr('HTTP/1.1 ').AppendRawStr(GetResponseCodeText(lvCode)).AppendBreakLineBytes;
  end;
  pvBuilder.AppendRawStr('Server: DIOCP-V5/1.1').AppendBreakLineBytes;
  if GetContentType = '' then
  begin
    if FContentBuffer.Length > 0 then
    begin
      pvBuilder.AppendRawStr('Content-Type:').AppendRawStr('text/html;charset=UTF-8').AppendBreakLineBytes;
    end;
  end;

  for i := 0 to FHeaders.Count - 1 do
  begin
    lvItem := FHeaders.Items[i];
    pvBuilder.AppendRawStr(lvItem.Name.AsString + ':').AppendRawStr(lvItem.Value.AsString).AppendBreakLineBytes;
  end;

  for i := 0 to FCookies.Count - 1 do
  begin
    pvBuilder.AppendRawStr('Set-Cookie:').AppendRawStr(TDHttpCookie(FCookies[i].AsObject).ToString()).AppendBreakLineBytes;
  end;
end;

procedure THttpResponse.ChunkedBuffer(pvBuffer:Pointer; pvLen:Integer);
begin
  FContentBuffer.AppendRawStr(IntToHex(pvLen, 2)).AppendBreakLineBytes;
  FContentBuffer.AppendBuffer(PByte(pvBuffer), pvLen).AppendBreakLineBytes;
end;

procedure THttpResponse.ChunkedBufferEnd;
begin
  FContentBuffer.AppendRawStr('0').AppendBreakLineBytes.AppendBreakLineBytes;
end;

procedure THttpResponse.ChunkedBufferStart;
begin
  FContentBuffer.Clear;
  InnerBuildHeader(FContentBuffer);
  FContentBuffer.AppendRawStr('Transfer-Encoding: chunked').AppendBreakLineBytes;
  FContentBuffer.AppendBreakLineBytes;
   
end;

procedure THttpResponse.GZipContent;
begin
{$IFDEF USE_ZLIBExGZ}
  GZCompressBufferBuilder(FContentBuffer);
{$ELSE}
  Assert(False, '��Ҫ����ZLibxExGZ');
{$ENDIF}

end;

procedure THttpResponse.DeflateCompressContent;
begin
  DeflateCompressBufferBuilder(FContentBuffer);
end;

function THttpResponse.GetContentType: RAWString;
begin
  Result := FHeaders.GetValueByName('content-type', '');
end;

procedure THttpResponse.SetContentType(const Value: RAWString);
begin
  FHeaders.ForceByName('content-type').AsString := Value;
end;

procedure THttpResponse.ZCompressContent;
begin
  ZCompressBufferBuilder(FContentBuffer);   
end;

{ THttpBuffer }

constructor THttpBuffer.Create;
begin
  FContentBuilder := TDBufferBuilder.Create;
  FHeaderBuilder := TDBufferBuilder.Create;
end;

destructor THttpBuffer.Destroy;
begin
  FreeAndNil(FContentBuilder);
  FreeAndNil(FHeaderBuilder);
  inherited Destroy;
end;

procedure THttpBuffer.DoCleanUp;
begin
  if FContentBuilder <> nil then
    FContentBuilder.Clear;
  if FHeaderBuilder <> nil then
    FHeaderBuilder.Clear;

  FRecvBuilder := FHeaderBuilder;

  FRecvSize := 0;
  FSectionFlag := 0;
  FFlag := 0;
  FDecodeState := 0;
end;

function THttpBuffer.InputBuffer(pvByte:Byte): Integer;

  procedure InnerCaseZero;
  begin
    if pvByte = 13 then
    begin
      Inc(FDecodeState);
    end;

    if FHeaderBuilder.Size >= MAX_HEADER_BUFFER_SIZE then
    begin            // ͷ�����ݹ���
      FFlag := 0;
      Result := -2;
    end;
  end;
begin
  Result := 0;
  if FFlag = 0 then
  begin
    FContentBuilder.Clear;
    FHeaderBuilder.Clear;
    FFlag := 1;
    FRecvSize := 0;
  end;

  FRecvBuilder.Append(pvByte);

  case FDecodeState of
    0:
     begin
       InnerCaseZero;
     end;
    1:    // ��һ�� #10
    begin
      if pvByte = 10 then Inc(FDecodeState)
      else
      begin
        FDecodeState := 0;
        InnerCaseZero;
      end;
    end;
    2:  // �ڶ��� #13
    begin
      if pvByte = 13 then Inc(FDecodeState)
      else
      begin
        FDecodeState := 0;
        InnerCaseZero;
      end;
    end;
    3:  // �ڶ��� #10
    begin
      if pvByte = 10 then
      begin  // Header
        FSectionFlag := 1;
        Result := 1;
        Inc(FDecodeState);
        
        FRecvBuilder := FContentBuilder;
        Exit;
      end else
      begin
        FDecodeState := 0;
        InnerCaseZero;
      end;
    end;
    4:  // ����Content
    begin
      if FContentLength = FContentBuilder.Size then
      begin
        Result := 2;     // ContentAsRAWString
        FFlag := 0;      // ���¿�ʼ����Buffer���н���
        Exit;
      end;
    end;
  end;
end;

end.
