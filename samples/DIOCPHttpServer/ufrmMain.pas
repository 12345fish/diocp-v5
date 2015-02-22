unit ufrmMain;

interface

{$DEFINE JSON}

{$IFDEF JSON}
  {$DEFINE USE_SuperObject}
  {$DEFINE USE_QJSON}
{$ENDIF}



uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ActnList, ExtCtrls
  {$IFDEF USE_SuperObject}, superobject{$ENDIF}
  , utils.safeLogger, StrUtils,
  ComCtrls, diocp.ex.httpServer
  ;

type
  TfrmMain = class(TForm)
    edtPort: TEdit;
    btnOpen: TButton;
    actlstMain: TActionList;
    actOpen: TAction;
    actStop: TAction;
    btnDisconectAll: TButton;
    pgcMain: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    mmoLog: TMemo;
    pnlMonitor: TPanel;
    btnGetWorkerState: TButton;
    btnFindContext: TButton;
    pnlTop: TPanel;
    tmrHeart: TTimer;
    procedure actOpenExecute(Sender: TObject);
    procedure actStopExecute(Sender: TObject);
    procedure btnDisconectAllClick(Sender: TObject);
    procedure btnFindContextClick(Sender: TObject);
    procedure btnGetWorkerStateClick(Sender: TObject);
    procedure tmrHeartTimer(Sender: TObject);
  private
    iCounter:Integer;
    FTcpServer: TDiocpHttpServer;
    procedure refreshState;

    procedure OnHttpSvrRequest(pvRequest:TDiocpHttpRequest);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uFMMonitor, diocp.core.engine;

{$R *.dfm}

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTcpServer := TDiocpHttpServer.Create(Self);
  FTcpServer.Name := 'HttpSVR';
  FTcpServer.SetMaxSendingQueueSize(10000);
  FTcpServer.createDataMonitor;
  FTcpServer.OnDiocpHttpRequest := OnHttpSvrRequest;
  TFMMonitor.createAsChild(pnlMonitor, FTcpServer);
  
  sfLogger.setAppender(TStringsAppender.Create(mmoLog.Lines));
  sfLogger.AppendInMainThread := true;
end;

procedure TfrmMain.OnHttpSvrRequest(pvRequest:TDiocpHttpRequest);
var
  lvJSon:ISuperObject;
  s:String;
  lvRawData:AnsiString;
begin
  // Context Type
  // pvRequest.Response.ContentType := 'utf-8';

  // ����Post���ݲ���
  {$IFDEF UNICODE}
  pvRequest.DecodePostDataParam(nil);
  {$ELSE}
  pvRequest.DecodePostDataParam(false);
  {$ENDIF}

  pvRequest.Response.WriteString('���󷽷�:' + pvRequest.RequestMethod);
  pvRequest.Response.WriteString('<br>');
  pvRequest.Response.WriteString('=======================================<br>');

  if pvRequest.RequestUrl = '/diocp-v5' then
  begin  // ���diocp������Ϣ
    pvRequest.Response.WriteString('DIOCP������Ϣ<br>');
    s := FTcpServer.GetStateInfo;
    s := ReplaceText(s, sLineBreak, '<br>');
    pvRequest.Response.WriteString(s);
    pvRequest.Response.WriteString('<br>');

    pvRequest.Response.WriteString('IOCP�߳���Ϣ<br>');
    s := FTcpServer.IocpEngine.GetStateINfo;
    s := ReplaceText(s, sLineBreak, '<br>');
    pvRequest.Response.WriteString(s);
  end else if pvRequest.RequestUrl = '/input' then
  begin  // ���diocp������Ϣ
    pvRequest.Response.WriteString('DIOCP HTTP ���ύ����<br>');
    pvRequest.Response.WriteString('<form id="form1" name="form1" method="post" action="/post?param1=''����''&time=' + DateTimeToStr(Now()) +'">');
    pvRequest.Response.WriteString('<table width="50%" border="1" align="center">');
    pvRequest.Response.WriteString('<tr><td width="35%">�������������:</td>');
    pvRequest.Response.WriteString('<td width="35%"><input name="a" type="text" value="DIOCP-V5" /></td></tr>');
    pvRequest.Response.WriteString('<tr><td width="35%">��������İ���:</td>');
    pvRequest.Response.WriteString('<td width="35%"><input name="b" type="text" value="LOLӢ������" /></td></tr>');
    pvRequest.Response.WriteString('<tr><td width="35%">����:</td>');
    pvRequest.Response.WriteString('<td width="35%"><input type="submit" name="Submit" value="�ύ"/></td></tr>');
    pvRequest.Response.WriteString('</table></form>');
  end else
  begin

    // ��д����
    pvRequest.Response.WriteString('����ʱ��:' + DateTimeToStr(Now()) + '<br>');
    pvRequest.Response.WriteString('<a href="http://www.diocp.org">DIOCP/MyBean�ٷ�����</a><br>');
    pvRequest.Response.WriteString('<a href="/diocp-v5">�鿴diocp������Ϣ</a><br>');
    pvRequest.Response.WriteString('<a href="/input">���ύ����</a><br>'); 
    pvRequest.Response.WriteString('<br>');

    pvRequest.Response.WriteString('<div>');

    // ��ȡͷ��Ϣ
    s := pvRequest.RequestHeader.Text;
    s := ReplaceText(s, sLineBreak, '<br>');
    pvRequest.Response.WriteString('ͷ��Ϣ<br>');
    pvRequest.Response.WriteString('����Url:' + pvRequest.RequestUrl + '<br>');


    pvRequest.Response.WriteString(s);
    pvRequest.Response.WriteString('<br>');
    pvRequest.Response.WriteString('������Ϣ<br>');
    pvRequest.Response.WriteString('=======================================<br>');
    pvRequest.Response.WriteString(Format('ԭʼ���ݳ���:%d', [pvRequest.RawPostData.Size]));
    pvRequest.Response.WriteString('<br>');

    pvRequest.Response.WriteString(Format('context-length:%d', [pvRequest.ContextLength]));
    pvRequest.Response.WriteString('<br>');

    SetLength(lvRawData,pvRequest.RawPostData.Size);
    pvRequest.RawPostData.Position := 0;
    pvRequest.RawPostData.Read(PByte(lvRawData)^, pvRequest.RawPostData.Size);
    pvRequest.Response.WriteString('ԭʼ����:');
    pvRequest.Response.WriteString(lvRawData);
    pvRequest.Response.WriteString('<br>=======================================<br>');

    pvRequest.Response.WriteString('<br>');
    pvRequest.Response.WriteString('���������Ϣ<br>');
    pvRequest.Response.WriteString(pvRequest.RequestParamsList.Text);
    pvRequest.Response.WriteString('<br>');
    pvRequest.Response.WriteString('=======================================<br>'); 


    // ����json
    lvJSon := SO();
    lvJSon.S['title'] := 'DIOCP3 Http ������ʾ';
    lvJSon.S['author'] := 'D10.�����';
    lvJSon.S['date'] := DateTimeToStr(Now());
    s := lvJSon.AsJSon(True, False);
    s := ReplaceText(s, sLineBreak, '<br>');
    pvRequest.Response.WriteString(s);
    pvRequest.Response.WriteString('</div>');
  end;

  // Ӧ����ϣ����ͻ�ͻ���
  pvRequest.ResponseEnd;

  pvRequest.CloseContext;
end;

destructor TfrmMain.Destroy;
begin
  FTcpServer.SafeStop();
  inherited Destroy;
end;

procedure TfrmMain.refreshState;
begin
  if FTcpServer.Active then
  begin
    btnOpen.Action := actStop;
  end else
  begin
    btnOpen.Action := actOpen;
  end;
end;

procedure TfrmMain.actOpenExecute(Sender: TObject);
begin
  FTcpServer.Port := StrToInt(edtPort.Text);
  FTcpServer.Active := true;
  refreshState;
  tmrHeart.Enabled := true;
end;

procedure TfrmMain.actStopExecute(Sender: TObject);
begin
  FTcpServer.safeStop;
  refreshState;
end;

procedure TfrmMain.btnDisconectAllClick(Sender: TObject);
begin
  FTcpServer.DisConnectAll();
end;

procedure TfrmMain.btnFindContextClick(Sender: TObject);
var
  lvList:TList;
  i:Integer;
begin
  lvList := TList.Create;
  try
    FTcpServer.getOnlineContextList(lvList);
    for i:=0 to lvList.Count -1 do
    begin
      FTcpServer.findContext(TDiocpHttpClientContext(lvList[i]).SocketHandle);
    end;
  finally
    lvList.Free;
  end;

end;

procedure TfrmMain.btnGetWorkerStateClick(Sender: TObject);
begin
  //ShowMessage(FTcpServer.IocpEngine.getWorkerStateInfo(0));

end;

procedure TfrmMain.tmrHeartTimer(Sender: TObject);
begin
  FTcpServer.KickOut();
end;



end.
