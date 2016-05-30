unit frm_Client;

interface

uses
  SysUtils, Classes, Controls, Forms, ComCtrls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, diocp_task, SimpleMsgPack, locker, diocp_sockets;

type
  TfrmClient = class(TForm)
    tmrKeepAlive: TTimer;
    lvUser: TListView;
    pnl1: TPanel;
    pnl2: TPanel;
    btnSendMsg: TButton;
    edtMsg: TEdit;
    mmoMsg: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmrKeepAliveTimer(Sender: TObject);
    procedure btnSendMsgClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    /// <summary>
    /// UIͬ���ٽ�������
    /// </summary>
    FUILocker: TLocker;

    /// <summary>
    /// ������
    /// </summary>
    procedure KeepAliveEx;

    /// <summary>
    /// �ͻ���Contextg�¼�
    /// </summary>
    /// <param name="AObject">��Ϣ��</param>
    procedure OnContextActionEx(AObject: TObject);

    /// <summary>
    /// ˢ���û��б�
    /// </summary>
    /// <param name="AMsgPack">��Ϣ��</param>
    procedure RefreshUserList(const AMsgPack: TSimpleMsgPack);

    /// <summary>
    /// ��ʾ��ȡ����������Ϣ
    /// </summary>
    /// <param name="AMsgPack">������Ϣ����Ϣ��</param>
    procedure SetOfflineMsg(const AMsgPack: TSimpleMsgPack);

    /// <summary>
    /// �ͻ��˶Ͽ�����
    /// </summary>
    /// <param name="AContext">�ͻ���Context</param>
    procedure OnDisConnected(AContext: TDiocpCustomContext);
  public
    { Public declarations }
  end;

var
  frmClient: TfrmClient;

implementation

uses
  ClientIocpOper, utils_safeLogger;

{$R *.dfm}

procedure TfrmClient.btnSendMsgClick(Sender: TObject);
var
  vMsgToID: string;
begin
  if DiocpContext.Active then
  begin
    if edtMsg.Text <> '' then  // ��Ϣ��Ϊ��
    begin
      if lvUser.ItemIndex < 1 then  // ����������
        vMsgToID := ''
      else  // ����ָ��������
        vMsgToID := lvUser.Items[lvUser.ItemIndex].Caption;
      CMD_SendMsg(vMsgToID, edtMsg.Text);  // ��������Ϣ
    end;
  end
  else
  begin
    ShowMessage('����˹رգ������µ�¼��');
  end;
end;

procedure TfrmClient.FormCreate(Sender: TObject);
begin
  FUILocker := TLocker.Create('���������');  // ����UIͬ���ٽ�������
  // �����첽��־��¼��ز���
  sfLogger.setAppender(TStringsAppender.Create(mmoMsg.Lines));
  sfLogger.AppendInMainThread := True;
  IocpTaskManager.PostATask(KeepAliveEx, True);  // ���һ�����������߳�ִ��

  DiocpContext.LockContext('�ͻ��˳�ʼ��', Self);
  try
    DiocpContext.OnContextAction := OnContextActionEx;  // �ͻ����������¼�
    DiocpContext.OnDisconnectedEvent := OnDisConnected;
  finally
    DiocpContext.UnLockContext('�ͻ��˳�ʼ��', Self);
  end;
end;

procedure TfrmClient.FormDestroy(Sender: TObject);
begin
  sfLogger.Enable := False;
  FUILocker.Free;
end;

procedure TfrmClient.FormShow(Sender: TObject);
begin
  CMD_UpdataUsers(CurUserID);  // ���������û��б�
  CMD_OfflineMessage(CurUserID);  // ����
end;

procedure TfrmClient.KeepAliveEx;
begin
  tmrKeepAlive.Enabled := true;
end;

procedure TfrmClient.OnContextActionEx(AObject: TObject);
var
  lvStream:TMemoryStream;
  lvCMDObject: TSimpleMsgPack;
  lvItem, lvList:TSimpleMsgPack;
begin
  lvStream := TMemoryStream(AObject);
  lvCMDObject:= TSimpleMsgPack.Create;
  try
    lvCMDObject.DecodeFromStream(lvStream);
    // �쳣��Ϣ
    if lvCMDObject.ForcePathObject('result.code').AsInteger = -1 then
      sfLogger.logMessage(lvCMDObject.ForcePathObject('result.msg').AsString);

    if lvCMDObject.ForcePathObject('requestID').AsString = 'login' then  // ��¼����ķ�������
    begin
      CMD_UpdataUsers(CurUserID);
      if lvCMDObject.ForcePathObject('result.code').AsInteger = 0 then  // ��������������ִ�гɹ�
      begin
        sfLogger.logMessage('��¼�ɹ�...');
        IocpTaskManager.PostATask(KeepAliveEx, True);
      end;
    end
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 21 then  // ������������ߵ�֪ͨ
    begin
      CMD_UpdataUsers(CurUserID);
      if lvCMDObject.ForcePathObject('type').AsInteger = 0 then
        sfLogger.logMessage(Format('[%s]����!', [lvCMDObject.ForcePathObject('userid').AsString]))
      else
        sfLogger.logMessage(Format('[%s]����!', [lvCMDObject.ForcePathObject('userid').AsString]));
    end
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 6 then  // ��Ϣ�Ƿ����˶������˷��ͣ����棩
      sfLogger.logMessage(Format('[%s]:%s', [lvCMDObject.ForcePathObject('userid').AsString,
        lvCMDObject.ForcePathObject('msg').AsString]))
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 5 then  // ���˷���˽����Ϣ
    begin
      if lvCMDObject.ForcePathObject('result.code').AsInteger = 0 then
      begin
        sfLogger.logMessage(Format('%s', [lvCMDObject.ForcePathObject('params.msg').AsString]));
      end;
    end
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 7 then  // �ӷ���˻�ȡ�������ڼ���۵���Ϣ
    begin
      if lvCMDObject.ForcePathObject('result.code').AsInteger = 0 then
        SetOfflineMsg(lvCMDObject);
    end
    else
    if lvCMDObject.ForcePathObject('cmdIndex').AsInteger = 3 then  // ���������û��б���Ϣ
    begin
      if lvCMDObject.ForcePathObject('result.code').AsInteger = 0 then
        RefreshUserList(lvCMDObject);
    end;
  finally
    lvCMDObject.Free;
  end;
end;

procedure TfrmClient.OnDisConnected(AContext: TDiocpCustomContext);
begin
  ShowMessage('����˹رգ������µ�¼��');
end;

procedure TfrmClient.RefreshUserList(const AMsgPack: TSimpleMsgPack);
var
  vUserCount, i: Integer;
  vListItem: TListItem;
begin
  FUILocker.Lock('�����û��б�');
  try
    vUserCount := AMsgPack.ForcePathObject('list').Count;  // �û���
    lvUser.Clear;
    if vUserCount = 0 then Exit;
    vListItem := lvUser.Items.Add;  // �����һ�������˵����ݱ����������˷�����Ϣ
    vListItem.Caption := '������';
    // ��Ӹ��û�
    lvUser.Items.BeginUpdate;
    try
      for i := 0 to vUserCount - 1 do
      begin
        vListItem := lvUser.Items.Add;
        vListItem.Caption := AMsgPack.ForcePathObject('list').Items[i].ForcePathObject('user.id').AsString;  // �û�ID
        vListItem.SubItems.Add(AMsgPack.ForcePathObject('list').Items[i].ForcePathObject('user.name').AsString);  // �û���
        if AMsgPack.ForcePathObject('list').Items[i].ForcePathObject('user.state').AsInteger = 0 then  // ������
          vListItem.SubItems.Add('����')
        else
          vListItem.SubItems.Add('����');
      end;
    finally
      lvUser.Items.EndUpdate;
    end;
  finally
    FUILocker.UnLock;
  end;
end;

procedure TfrmClient.SetOfflineMsg(const AMsgPack: TSimpleMsgPack);
var
  vMsgCount, i: Integer;
  vListItem: TListItem;
begin
  FUILocker.Lock('��ȡ������Ϣ');
  try
    vMsgCount := AMsgPack.ForcePathObject('list').Count;  // ��ȡ������ص�������Ϣ��
    if vMsgCount = 0 then Exit;
    mmoMsg.Lines.BeginUpdate;
    try
      for i := 0 to vMsgCount - 1 do
      begin
        mmoMsg.Lines.Add(Format('[%s] %s:%s',  // ��ʾ��������Ϣ
          [FormatDateTime('YYYY-MM-DD hh:mm:ss', AMsgPack.ForcePathObject('list').Items[i].ForcePathObject('dt').AsDateTime),
          AMsgPack.ForcePathObject('list').Items[i].ForcePathObject('from').AsString,
          AMsgPack.ForcePathObject('list').Items[i].ForcePathObject('msg').AsString]));
      end;
    finally
      mmoMsg.Lines.EndUpdate;
    end;
  finally
    FUILocker.UnLock;
  end;
end;

procedure TfrmClient.tmrKeepAliveTimer(Sender: TObject);
begin
  CMD_KeepAlive;  // ������
end;

end.
