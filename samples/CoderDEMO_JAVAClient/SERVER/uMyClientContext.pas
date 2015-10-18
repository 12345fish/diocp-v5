unit uMyClientContext;

interface

uses
  diocp.coder.tcpServer, SysUtils, Classes, Windows, Math, superobject,
  diocp_ex_strObjectCoder;


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
var
  lvJSON:ISuperObject;
begin
  lvJSON := SO(TStringObject(pvObject).DataString);
  if lvJSON <> nil then
  begin
    lvJSON.S['agent'] := 'DIOCP�����������˴���';

    // ���÷��ص�����ΪJSON �ַ���
    TStringObject(pvObject).DataString := lvJSON.AsJSon(True, False);
  end;

  // ��д����
  writeObject(pvObject);
end;

procedure TMyClientContext.OnConnected;
begin

end;

procedure TMyClientContext.OnDisconnected;
begin
end;

end.
