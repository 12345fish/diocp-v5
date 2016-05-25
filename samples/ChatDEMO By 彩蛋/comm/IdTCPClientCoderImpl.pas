(*
   unit owner: Diocp.Author

   IdTcpClientʵ��ICoderSocket�ӿ�
*)
unit IdTCPClientCoderImpl;

interface

uses
  uICoderSocket, SysUtils, IdTCPClient, IdGlobal;

type
  TIdTCPClientCoderImpl = class(TInterfacedObject, ICoderSocket)
  private
    FReconnect: Boolean;
    FTcpClient: TIdTCPClient;
    procedure CheckConnect;
    
    function RecvRawBuffer(buf: Pointer; len: Cardinal): Integer;
    function SendRawBuffer(buf: Pointer; len: Cardinal): Integer;
  protected
    function SendBuf(buf:Pointer; len:Cardinal): Cardinal; stdcall;
    function RecvBuf(buf:Pointer; len:Cardinal): Cardinal; stdcall;
    procedure CloseSocket; stdcall;
  public
    /// <summary>
    ///   ����һ��ICoderSocket�ӿ�
    /// </summary>
    /// <param name="ATcpClient"> ��Ҫʹ�õ�IdTcp��� </param>
    /// <param name="pvReconnect"> ������δ���Ƿ������ </param>
    constructor Create(ATcpClient: TIdTCPClient; pvReconnect: Boolean = true);
    destructor Destroy; override;
  end;

implementation

constructor TIdTCPClientCoderImpl.Create(ATcpClient: TIdTCPClient; pvReconnect:
    Boolean = true);
begin
  inherited Create;
  FTcpClient := ATcpClient;
  FReconnect := pvReconnect;
end;

destructor TIdTCPClientCoderImpl.Destroy;
begin
  inherited Destroy;
end;

{ TIdTCPClientCoderImpl }

procedure TIdTCPClientCoderImpl.CheckConnect;
begin
  if (not FTcpClient.Connected) then
  begin
    try
      FTcpClient.Connect();
    except
      on E:Exception do
      begin
        raise Exception.Create(
          Format('�������[%s:%d]��������ʧ��', [FTcpClient.Host, FTcpClient.Port]) + sLineBreak + e.Message);      
      end; 
    end;
  end;
end;

procedure TIdTCPClientCoderImpl.CloseSocket;
begin
  try
    FTcpClient.Disconnect;
  except
  end;
end;

function TIdTCPClientCoderImpl.RecvBuf(buf:Pointer; len:Cardinal): Cardinal;
begin
  if FReconnect then
  begin
    CheckConnect;
    try
      Result := RecvRawBuffer(buf, len);
    except
      CloseSocket;
      raise;
    end;
  end else
  begin
     Result := RecvRawBuffer(buf, len);
  end;

end;

function TIdTCPClientCoderImpl.RecvRawBuffer(buf: Pointer; len: Cardinal):
    Integer;
var
  lvBuf: TIdBytes;
begin
  FTcpClient.Socket.ReadBytes(lvBuf, len);
  Result := Length(lvBuf);
  Move(lvBuf[0], buf^, Result);
  SetLength(lvBuf, 0);
end;

function TIdTCPClientCoderImpl.SendBuf(buf:Pointer; len:Cardinal): Cardinal;
begin
  if FReconnect then
  begin
    CheckConnect;;
    try
      Result := SendRawBuffer(buf, len);
    except
      CloseSocket;
      raise;
    end;
  end else
  begin
    Result := SendRawBuffer(buf, len);
  end;
end;

function TIdTCPClientCoderImpl.SendRawBuffer(buf: Pointer; len: Cardinal):
    Integer;
var
  lvBytes:TIdBytes;
begin
  SetLength(lvBytes, len);
  Move(buf^, lvBytes[0], len);
  FTcpClient.Socket.Write(lvBytes);
  SetLength(lvBytes, 0);
  Result := len;
end;

end.
