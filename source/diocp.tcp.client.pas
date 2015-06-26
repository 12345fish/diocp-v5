(*
 *	 Unit owner: d10.�����
 *	       blog: http://www.cnblogs.com/dksoft
 *     homePage: www.diocp.org
 *
 *   2015-02-22 08:29:43
 *     DIOCP-V5 ����
 *
 *)
unit diocp.tcp.client;

{$I 'diocp.inc'}

interface


uses
  diocp.sockets, SysUtils, diocp.sockets.utils
  {$IFDEF UNICODE}, Generics.Collections{$ELSE}, Contnrs {$ENDIF}
  , Classes, Windows, utils.objectPool, diocp.res;

type
  TIocpRemoteContext = class(TDiocpCustomContext)
  private
    FLastDisconnectTime:Cardinal;
    FIsConnecting: Boolean;

    FAutoReConnect: Boolean;
    FConnectExRequest: TIocpConnectExRequest;

    FHost: String;
    FPort: Integer;
    procedure PostConnectRequest;
    procedure ReCreateSocket;
    function CanAutoReConnect:Boolean;
  protected
    procedure OnConnecteExResponse(pvObject:TObject);

    procedure OnDisconnected; override;

    procedure OnConnected; override;

    procedure SetSocketState(pvState:TSocketState); override;

  public
    constructor Create; override;
    destructor Destroy; override;
    /// <summary>
    ///  ������ʽ��������
    ///    ����״̬�仯: ssDisconnected -> ssConnected/ssDisconnected
    /// </summary>
    procedure Connect;

    /// <summary>
    ///  �����첽����
    ///   ����״̬�仯: ssDisconnected -> ssConnecting -> ssConnected/ssDisconnected
    /// </summary>
    procedure ConnectASync;

    /// <summary>
    ///   ���ø����Ӷ�����Զ���������
    ///    true�������Զ�����
    /// </summary>
    property AutoReConnect: Boolean read FAutoReConnect write FAutoReConnect;

    property Host: String read FHost write FHost;
    property Port: Integer read FPort write FPort;
  end;

  TDiocpTcpClient = class(TDiocpCustom)
  private
    function GetCount: Integer;
    function GetItems(pvIndex: Integer): TIocpRemoteContext;
  private
    FDisableAutoConnect: Boolean;
    FReconnectRequestPool:TObjectPool;

    function CreateReconnectRequest:TObject;

    /// <summary>
    ///   ��Ӧ��ɣ��黹������󵽳�
    /// </summary>
    procedure OnReconnectRequestResponseDone(pvObject:TObject);

    /// <summary>
    ///   ��Ӧ��������Request
    /// </summary>
    procedure OnReconnectRequestResponse(pvObject:TObject);
  private
  {$IFDEF UNICODE}
    FList: TObjectList<TIocpRemoteContext>;
  {$ELSE}
    FList: TObjectList;
  {$ENDIF}
  protected
    /// <summary>
    ///   Ͷ�����������¼�
    /// </summary>
    procedure PostReconnectRequestEvent(pvContext: TIocpRemoteContext);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    /// <summary>
    ///   ���һ��������
    /// </summary>
    function Add: TIocpRemoteContext;

    /// <summary>
    ///   �ܵ����Ӷ�������
    /// </summary>
    property Count: Integer read GetCount;

    /// <summary>
    ///   ��ֹ�������Ӷ����Զ�����
    /// </summary>
    property DisableAutoConnect: Boolean read FDisableAutoConnect write FDisableAutoConnect;

    /// <summary>
    ///   ͨ��λ��������ȡ���е�һ������
    /// </summary>
    property Items[pvIndex: Integer]: TIocpRemoteContext read GetItems; default;

  end;

implementation

uses
  utils.safeLogger, diocp.winapi.winsock2, diocp.core.engine;

resourcestring
  strCannotConnect = '��ǰ״̬�²��ܽ�������...';
  strConnectError  = '��������ʧ��, �������:%d';

const
  // ����������������ӹ��죬����OnDisconnected��û�д������, 1��
  RECONNECT_INTERVAL = 1000;


/// <summary>
///   ��������TickCountʱ�����ⳬ��49������
///      ��л [��ɽ]�׺�һЦ  7041779 �ṩ
///      copy�� qsl���� 
/// </summary>
function tick_diff(tick_start, tick_end: Cardinal): Cardinal;
begin
  if tick_end >= tick_start then
    result := tick_end - tick_start
  else
    result := High(Cardinal) - tick_start + tick_end;
end;

constructor TIocpRemoteContext.Create;
begin
  inherited Create;
  FAutoReConnect := False;
  FConnectExRequest := TIocpConnectExRequest.Create(Self);
  FConnectExRequest.OnResponse := OnConnecteExResponse;
  FIsConnecting := false;  
end;

destructor TIocpRemoteContext.Destroy;
begin
  FreeAndNil(FConnectExRequest);
  inherited Destroy;
end;

function TIocpRemoteContext.CanAutoReConnect: Boolean;
begin
  Result := FAutoReConnect and (Owner.Active) and (not TDiocpTcpClient(Owner).DisableAutoConnect);
end;

procedure TIocpRemoteContext.Connect;
var
  lvRemoteIP:String;
begin
  if not Owner.Active then raise Exception.CreateFmt(strEngineIsOff, [Owner.Name]);

  if SocketState <> ssDisconnected then raise Exception.Create(strCannotConnect);

  ReCreateSocket;

  try
    lvRemoteIP := RawSocket.GetIpAddrByName(FHost);
  except
    lvRemoteIP := FHost;
  end;

  if not RawSocket.connect(lvRemoteIP, FPort) then
    RaiseLastOSError;

  DoConnected;
end;

procedure TIocpRemoteContext.ConnectASync;
begin
  if not Owner.Active then raise Exception.CreateFmt(strEngineIsOff, [Owner.Name]);

  if SocketState <> ssDisconnected then raise Exception.Create(strCannotConnect);

  ReCreateSocket;

  PostConnectRequest;

end;

procedure TIocpRemoteContext.OnConnected;
begin
  inherited;
  // ���öϿ�ʱ��
  FLastDisconnectTime := 0;
end;

procedure TIocpRemoteContext.OnConnecteExResponse(pvObject: TObject);
begin
  FIsConnecting := false;
  if TIocpConnectExRequest(pvObject).ErrorCode = 0 then
  begin
    DoConnected;
  end else
  begin
    {$IFDEF DEBUG_ON}
    Owner.logMessage(strConnectError,  [TIocpConnectExRequest(pvObject).ErrorCode]);
    {$ENDIF}

    DoError(TIocpConnectExRequest(pvObject).ErrorCode);

    if (CanAutoReConnect) then
    begin
      Sleep(100);
      PostConnectRequest;
    end else
    begin
      SetSocketState(ssDisconnected);
    end;
  end;
end;

procedure TIocpRemoteContext.OnDisconnected;
begin
  inherited;
end;

procedure TIocpRemoteContext.PostConnectRequest;
begin
  if lock_cmp_exchange(False, True, FIsConnecting) = False then
  begin
    if RawSocket.SocketHandle = INVALID_SOCKET then
    begin
      ReCreateSocket;
    end;

    if not FConnectExRequest.PostRequest(FHost, FPort) then
    begin
      FIsConnecting := false;

      Sleep(1000);

      if CanAutoReConnect then PostConnectRequest;
    end;
  end;
end;

procedure TIocpRemoteContext.ReCreateSocket;
begin
  RawSocket.CreateTcpOverlappedSocket;
  if not RawSocket.bind('0.0.0.0', 0) then
  begin
    RaiseLastOSError;
  end;

  Owner.IocpEngine.IocpCore.Bind2IOCPHandle(RawSocket.SocketHandle, 0);
end;

procedure TIocpRemoteContext.SetSocketState(pvState: TSocketState);
begin
  inherited;
  if pvState = ssDisconnected then
  begin
    // ��¼���Ͽ�ʱ��
    FLastDisconnectTime := GetTickCount;

    if CanAutoReConnect then
    begin
      TDiocpTcpClient(Owner).PostReconnectRequestEvent(Self);
    end;
  end;
end;

constructor TDiocpTcpClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF UNICODE}
  FList := TObjectList<TIocpRemoteContext>.Create();
{$ELSE}
  FList := TObjectList.Create();
{$ENDIF}
  FDisableAutoConnect := false;

  FReconnectRequestPool := TObjectPool.Create(CreateReconnectRequest);
end;

function TDiocpTcpClient.CreateReconnectRequest: TObject;
begin
  Result := TIocpASyncRequest.Create;

end;

destructor TDiocpTcpClient.Destroy;
begin
  FReconnectRequestPool.WaitFor(20000);
  Close;
  FList.Clear;
  FList.Free;
  FReconnectRequestPool.Free;
  inherited Destroy;
end;

function TDiocpTcpClient.Add: TIocpRemoteContext;
begin
  if FContextClass = nil then
  begin
    Result := TIocpRemoteContext.Create;
  end else
  begin
    Result := TIocpRemoteContext(FContextClass.Create());
  end;
  Result.Owner := Self;
  FList.Add(Result);
end;

function TDiocpTcpClient.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TDiocpTcpClient.GetItems(pvIndex: Integer): TIocpRemoteContext;
begin
{$IFDEF UNICODE}
  Result := FList[pvIndex];
{$ELSE}
  Result := TIocpRemoteContext(FList[pvIndex]);
{$ENDIF}

end;

procedure TDiocpTcpClient.OnReconnectRequestResponse(pvObject: TObject);
var
  lvContext:TIocpRemoteContext;
  lvRequest:TIocpASyncRequest;
begin
  // �˳�
  if not Self.Active then Exit;
    
  lvRequest := TIocpASyncRequest(pvObject);
  lvContext := TIocpRemoteContext(lvRequest.Data);

  if tick_diff(lvContext.FLastDisconnectTime, GetTickCount) >= RECONNECT_INTERVAL  then
  begin
    // Ͷ����������������
    lvContext.PostConnectRequest();
  end else
  begin
    // �ٴ�Ͷ����������
    PostReconnectRequestEvent(lvContext);
  end;
end;

procedure TDiocpTcpClient.OnReconnectRequestResponseDone(pvObject: TObject);
begin
  FReconnectRequestPool.ReleaseObject(pvObject);
end;

procedure TDiocpTcpClient.PostReconnectRequestEvent(pvContext:
    TIocpRemoteContext);
var
  lvRequest:TIocpASyncRequest;
begin
  lvRequest := TIocpASyncRequest(FReconnectRequestPool.GetObject);
  lvRequest.DoCleanUp;
  lvRequest.OnResponseDone := OnReconnectRequestResponseDone;
  lvRequest.OnResponse := OnReconnectRequestResponse;
  lvRequest.Data := pvContext;
  IocpEngine.PostRequest(lvRequest);
end;

end.
