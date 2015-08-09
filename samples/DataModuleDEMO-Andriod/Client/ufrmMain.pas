unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, diocp.task, diocp.tcp.blockClient,
  uStreamCoderSocket, uRawTcpClientCoderImpl, Grids, DBGrids,
  uIRemoteServer, uRemoteServerDIOCPImpl, DB, DBClient;

type
  // �첽ִ���������
  TASyncTaskObject = class
  private
    FData: OleVariant;
    FErrMessage: String;
    FHost: String;
    FPort: Integer;
    FSQL: String;
    FuseTime: Cardinal;
  public
    property Data: OleVariant read FData write FData;
    property ErrMessage: String read FErrMessage write FErrMessage;
    property Host: String read FHost write FHost;
    property Port: Integer read FPort write FPort;
    property SQL: String read FSQL write FSQL;
    property useTime: Cardinal read FuseTime write FuseTime;



  end;

  TfrmMain = class(TForm)
    mmoSQL: TMemo;
    btnConnect: TButton;
    edtHost: TEdit;
    edtPort: TEdit;
    DBGrid1: TDBGrid;
    btnOpen: TButton;
    cdsMain: TClientDataSet;
    dsMain: TDataSource;
    btnOpenASync: TButton;
    procedure btnConnectClick(Sender: TObject);
    procedure btnOpenASyncClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
  private
    { Private declarations }
    FRemoteSvrObj:TRemoteServerDIOCPImpl;
    FRemoteSvr:IRemoteServer;

    procedure OnASyncTask(pvTaskRequest: TIocpTaskRequest);

    /// <summary>
    ///  �첽����ִ����ɵĻص�, ��Ҫ�����������ݵ���ʾ����Ϊ���̲߳���ֱ�ӵ��÷���UI
    /// </summary>
    procedure OnASyncTaskCompleted(pvTaskRequest:TIocpTaskRequest);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation







{$R *.dfm}

{ TfrmMain }

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited;
  FRemoteSvrObj := TRemoteServerDIOCPImpl.Create;
  FRemoteSvr := FRemoteSvrObj;
end;

destructor TfrmMain.Destroy;
begin
  FRemoteSvr := nil;
  inherited Destroy;
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
begin
  FRemoteSvrObj.setHost(edtHost.Text);
  FRemoteSvrObj.setPort(StrToInt(edtPort.Text));
  FRemoteSvrObj.Open();
  ShowMessage('open succ!');
end;

procedure TfrmMain.btnOpenASyncClick(Sender: TObject);
var
  lvTaskObject : TASyncTaskObject;
begin
  // ���ð�ť״̬
  btnOpenASync.Enabled := false;
  btnOpenASync.Caption := '����ִ��...';

  lvTaskObject := TASyncTaskObject.Create();
  lvTaskObject.SQL := mmoSQL.Lines.Text;  // Ҫִ�е�SQL���
  lvTaskObject.Host := edtHost.Text;         // �첽ִ�У� �ڲ���������
  lvTaskObject.Port := StrToInt(edtPort.Text);   // �첽ִ�У� �ڲ���������
  iocpTaskManager.PostATask(OnASyncTask, lvTaskObject);       // Ͷ�ݵ�iocpTask�̣߳��������߳�ִ��, ִ��ʱ�ص�OnASyncTask����

end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
var
  vData:OleVariant;
  l : Cardinal;
begin
  vData := mmoSQL.Lines.Text;

  l := GetTickCount;
  if FRemoteSvr.Execute(1, vData) then
  begin
    self.cdsMain.Data := vData;
    Self.Caption := Format('query: count:%d, time:%d',
      [self.cdsMain.RecordCount, GetTickCount - l]);
  end;
end;

procedure TfrmMain.OnASyncTask(pvTaskRequest: TIocpTaskRequest);
var
  vData:OleVariant;
  l : Cardinal;
  lvTaskObject : TASyncTaskObject;

  lvRemoteSvrObj:TRemoteServerDIOCPImpl;
  lvRemoteSvr:IRemoteServer;

begin
  lvTaskObject :=TASyncTaskObject(pvTaskRequest.TaskData);

  try
    lvRemoteSvrObj := TRemoteServerDIOCPImpl.Create;
    lvRemoteSvr := lvRemoteSvrObj;


    lvRemoteSvrObj.setHost(lvTaskObject.Host);
    lvRemoteSvrObj.setPort(lvTaskObject.Port);
    lvRemoteSvrObj.Open();

    l := GetTickCount;

    vData := lvTaskObject.SQL;

    if lvRemoteSvr.Execute(1, vData) then
    begin
      lvTaskObject.Data := vData;
      lvTaskObject.useTime := GetTickCount - l;
    end;
  except
    on E:Exception do
    begin
      // ִ��ʱ�������쳣, ��¼������Ϣ
      lvTaskObject.ErrMessage := e.Message;
    end;
  end;

  // Ͷ�ݵ�iocpTask�̣߳������߳�ִ��, ִ��ʱ�ص�OnASyncTask����
  // ����������Ϊtrue,�������߳�ȥִ��
  iocpTaskManager.PostATask(OnASyncTaskCompleted, lvTaskObject, true);
end;

procedure TfrmMain.OnASyncTaskCompleted(pvTaskRequest:TIocpTaskRequest);
var
  lvTaskObject : TASyncTaskObject;
begin
  lvTaskObject :=TASyncTaskObject(pvTaskRequest.TaskData);
  try
    // ���ð�ť״̬
    btnOpenASync.Enabled := true;
    btnOpenASync.Caption := '�첽ִ��';

    if lvTaskObject.ErrMessage <> '' then
    begin
      // �쳣
      ShowMessage(lvTaskObject.ErrMessage);
      Exit;
    end else
    begin
      self.cdsMain.Data := lvTaskObject.Data;
      Self.Caption := Format('query: count:%d, time:%d',
        [self.cdsMain.RecordCount, lvTaskObject.useTime]);
    end;
  finally
    // ������Ҫ
    lvTaskObject.Free;
  end;

end;

end.
