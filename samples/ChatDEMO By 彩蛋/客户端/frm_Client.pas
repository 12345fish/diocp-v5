unit frm_Client;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  diocp_coder_tcpClient, SimpleMsgPack, diocp_sockets, diocp_task;

type
  TForm6 = class(TForm)
    btn1: TButton;
    lstUsers: TListBox;
    mmoMsg: TMemo;
    tmrKeepAlive: TTimer;
    btn3: TButton;
    btn4: TButton;
    edtUserID: TEdit;
    edtMsg: TEdit;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tmrKeepAliveTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure btn4Click(Sender: TObject);
    procedure edtUserIDChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FUserID: string;
    FCoderTcpClient: TDiocpCoderTcpClient;
    FDiocpContext: TIocpCoderRemoteContext;
    FCMDObject: TSimpleMsgPack;
    FCMDStream: TMemoryStream;
    //
    procedure SendCMDObject(pvCMDObject: TSimpleMsgPack);
    procedure OnRecvObject(pvObject:TObject);
    procedure OnDisconnected(pvContext: TDiocpCustomContext);
    procedure KeepAlive;
    procedure UpdataUser;  // ��ȡ�����û��б�
  public
    { Public declarations }
  end;

var
  Form6: TForm6;

implementation

uses
  uDIOCPStreamCoder, utils_safeLogger;

{$R *.dfm}

procedure TForm6.btn1Click(Sender: TObject);
begin
  if edtUserID.Text = '' then
  begin
    ShowMessage('���������������');
    Exit;
  end;
  // ����
  FCoderTcpClient.open;
  if FDiocpContext.Active then
  begin
    //sfLogger.logMessage('�Ѿ����ӵ�������');
    Exit;
  end;
  FDiocpContext.Host := '192.168.1.10';
  FDiocpContext.Port := 60544;
  FDiocpContext.Connect;
  //sfLogger.logMessage('��������������ӳɹ�, ����е�½');
  // ����
  if FDiocpContext.Active then
  begin
    FCMDObject.Clear;
    FCMDObject.ForcePathObject('cmdIndex').AsInteger := 11;
    FCMDObject.ForcePathObject('requestID').AsString := 'login';
    FCMDObject.ForcePathObject('params.userid').AsString := FUserID;
    SendCMDObject(FCMDObject);
  end;
end;

procedure TForm6.btn3Click(Sender: TObject);
begin
  FCMDObject.Clear;
  FCMDObject.ForcePathObject('cmdIndex').AsInteger := 5;
  FCMDObject.ForcePathObject('requestID').AsString := 'messageID';
  FCMDObject.ForcePathObject('params.msg').AsString := edtMsg.Text;
  SendCMDObject(FCMDObject);
end;

procedure TForm6.btn4Click(Sender: TObject);
begin
  FCMDObject.ForcePathObject('cmdIndex').AsInteger := 5;
  //FCMDObject.ForcePathObject('userid').AsString := cbbName.Text;
  FCMDObject.ForcePathObject('params.userid').AsString := lstUsers.Items[lstUsers.ItemIndex];
  FCMDObject.ForcePathObject('params.msg').AsString := edtMsg.Text;
  SendCMDObject(FCMDObject);
end;

procedure TForm6.edtUserIDChange(Sender: TObject);
begin
  FUserID := edtUserID.Text;
end;

procedure TForm6.FormCreate(Sender: TObject);
begin
  sfLogger.setAppender(TStringsAppender.Create(mmoMsg.Lines));
  sfLogger.AppendInMainThread := true;

  FCoderTcpClient := TDiocpCoderTcpClient.Create(Self);
  FCoderTcpClient.OnContextDisconnected := OnDisconnected;

  FDiocpContext := TIocpCoderRemoteContext(FCoderTcpClient.Add);
  FDiocpContext.RegisterCoderClass(TIOCPStreamDecoder, TIOCPStreamEncoder);
  FDiocpContext.OnContextAction := OnRecvObject;

  FCMDObject := TSimpleMsgPack.Create();
  FCMDStream := TMemoryStream.Create;
end;

procedure TForm6.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FCMDObject);
  sfLogger.Enable := false;
  FCoderTcpClient.DisconnectAll;
  FCoderTcpClient.Free;
  FCMDStream.Free;
end;

procedure TForm6.FormShow(Sender: TObject);
begin
  FUserID := edtUserID.Text;
end;

procedure TForm6.OnDisconnected(pvContext: TDiocpCustomContext);
begin
  //sfLogger.logMessage('��������Ͽ�����...');
end;

procedure TForm6.OnRecvObject(pvObject: TObject);
var
  s:AnsiString;
  lvStream:TMemoryStream;
  lvCMDObject:TSimpleMsgPack;
  lvItem, lvList:TSimpleMsgPack;
  UserNum,I:Integer;
begin
  lvStream := TMemoryStream(pvObject);
  lvCMDObject:= TSimpleMsgPack.Create;
  try
    lvCMDObject.DecodeFromStream(lvStream);
    // �쳣��Ϣ
    if lvCMDObject.ForcePathObject('result.code').AsInteger = -1 then
      sfLogger.logMessage(lvCMDObject.ForcePathObject('result.msg').AsString);

    if lvCMDObject.ForcePathObject('requestID').AsString = 'login' then
    begin
      UpdataUser;
      if lvCMDObject.ForcePathObject('result.code').AsInteger = 0 then
      begin
        sfLogger.logMessage('��½�ɹ�...');
        iocpTaskManager.PostATask(KeepAlive, true);
      end;
    end
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 21 then
    begin
       UpdataUser;
      if lvCMDObject.ForcePathObject('type').AsInteger = 0 then
      begin
        sfLogger.logMessage(Format('�û�[%s]�Ѿ�����!', [lvCMDObject.ForcePathObject('userid').AsString]));
      end
      else
      begin
        sfLogger.logMessage(Format('�û�[%s]����!', [lvCMDObject.ForcePathObject('userid').AsString]));
      end;
    end
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 6 then
    begin
      sfLogger.logMessage(Format('�û�[%s]˽�Ķ���˵:%s',[lvCMDObject.ForcePathObject('userid').AsString, lvCMDObject.ForcePathObject('msg').AsString]));
    end
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 5 then
    begin
      if lvCMDObject.ForcePathObject('result.code').AsInteger = 0 then
      begin
        sfLogger.logMessage(Format('��˵��:%s',
          [lvCMDObject.ForcePathObject('params.msg').AsString]));
      end;
    end
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 3 then  // �û��б�
    begin
      if lvCMDObject.ForcePathObject('result.code').AsInteger = 0 then
      begin
        UserNum:=lvCMDObject.ForcePathObject('list').Count;
        for I := 0 to UserNum-1 do
        begin
          lstUsers.Clear;
          lstUsers.Items.Add(lvCMDObject.ForcePathObject('list').Items[i].ForcePathObject('userid').AsString);
        end;
//         ShowMessage(lvCMDObject.ForcePathObject('list').Items[0].ForcePathObject('userid').AsString);
//         ShowMessage(lvCMDObject.ForcePathObject('list').Items[1].ForcePathObject('userid').AsString);
      end;
    end
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 6 then
    begin
      if lvCMDObject.ForcePathObject('result.code').AsInteger = 0 then
      begin
         mmoMsg.Lines.Add(lvCMDObject.ForcePathObject('userid').AsString+'˵��'+
           lvCMDObject.ForcePathObject('msg').AsString );
//         ShowMessage(lvCMDObject.ForcePathObject('list').Items[0].ForcePathObject('userid').AsString);
//         ShowMessage(lvCMDObject.ForcePathObject('list').Items[1].ForcePathObject('userid').AsString);
      end;
    end;
  finally
    lvCMDObject.Free;
  end;
end;

procedure TForm6.SendCMDObject(pvCMDObject: TSimpleMsgPack);
var
  lvCMDStream:TMemoryStream;
begin
  lvCMDStream := TMemoryStream.Create;
  try
    pvCMDObject.EncodeToStream(lvCMDStream);
    FDiocpContext.WriteObject(lvCMDStream);
  finally
    lvCMDStream.Free;
  end;
end;

procedure TForm6.tmrKeepAliveTimer(Sender: TObject);
begin
  FCMDObject.Clear;
  FCMDObject.ForcePathObject('cmdIndex').AsInteger := 0;
  SendCMDObject(FCMDObject);
end;

procedure TForm6.KeepAlive;
begin
  tmrKeepAlive.Enabled := true;
end;

procedure TForm6.UpdataUser;
begin
  FCMDObject.Clear;
  FCMDObject.ForcePathObject('cmdIndex').AsInteger := 3;
  FCMDObject.ForcePathObject('requestID').AsString := FUserID;
  FCMDObject.ForcePathObject('params.page').AsString := '1';
  SendCMDObject(FCMDObject);
end;

end.
