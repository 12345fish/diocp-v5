unit CHATHandler;

interface

uses
  SimpleMsgPack, diocp.session, diocp_tcp_server;

type
  TChatSession = class(TSessionItem)
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
    ///   ״̬ (0,����, 1:����, 2:����)
    /// </summary>
    property State: Integer read FState write FState;
    property UserID: String read FUserID write FUserID;
    /// <summary>
    ///   ��֤״̬
    /// </summary>
    property Verified: Boolean read FVerified write FVerified;
    property OwnerTcpServer: TDiocpTcpServer read FOwnerTcpServer write FOwnerTcpServer;
  end;

/// <summary>procedure CHATExecute
/// </summary>
/// <param name="pvCMDObject"> (TSimpleMsgPack) </param>
var
  ChatSessions: TSessions;

implementation

uses
  utils_safeLogger, SysUtils, ComObj,diocp_coder_tcpServer,
  Classes;

constructor TChatSession.Create;
begin
  inherited;
  FData := TSimpleMsgPack.Create;
  FOwnerTcpServer := nil;
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
