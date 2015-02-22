unit uMyClientContext;

interface

uses
  diocp.coder.tcpServer, SysUtils, Classes, Windows, Math;


type
  TMyClientContext = class(TIOCPCoderClientContext)
  private
  protected
    procedure OnDisconnected; override;

    procedure OnConnected; override;
  public
    /// <summary>
    ///   ���ݴ���
    /// </summary>
    /// <param name="pvObject"> (TObject) </param>
    procedure DoContextAction(const pvObject: TObject); override;
  end;

implementation

procedure TMyClientContext.DoContextAction(const pvObject: TObject);
begin
  // ֱ�ӷ���
  writeObject(pvObject);
end;

procedure TMyClientContext.OnConnected;
begin

end;

procedure TMyClientContext.OnDisconnected;
begin
end;

end.
