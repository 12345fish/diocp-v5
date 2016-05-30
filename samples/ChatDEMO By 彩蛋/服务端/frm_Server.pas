unit frm_Server;

interface

uses
  SysUtils, Classes, Controls, Forms, Dialogs,
  ComCtrls, ExtCtrls, Menus, StdCtrls, Generics.Collections,
  diocp_coder_tcpServer, diocp_tcp_server, uMyClientContext, diocp.session,
  SimpleMsgPack, utils_locker;

type
  TForm5 = class(TForm)
    mmain: TMainMenu;
    mniN1: TMenuItem;
    mniStart: TMenuItem;
    mniN3: TMenuItem;
    mniStop: TMenuItem;
    tmrKeepAlive: TTimer;
    pgc: TPageControl;
    tsState: TTabSheet;
    tsMsg: TTabSheet;
    lvUser: TListView;
    statCtl: TStatusBar;
    mmoMsg: TMemo;
    pnl1: TPanel;
    edtMsg: TEdit;
    btnSend: TButton;
    btn1: TButton;
    procedure mniStartClick(Sender: TObject);
    procedure mniN3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mniStopClick(Sender: TObject);
    procedure tmrKeepAliveTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    /// <summary>
    /// UI������
    /// </summary>
    FUILocker: TIocpLocker;

    /// <summary>
    /// IOCPServer
    /// </summary>
    FTcpServer: TDiocpCoderTcpServer;

    /// <summary>
    /// ������Ϣ�б�
    /// </summary>
    FOfflineMsgs: TObjectList<TOfflineInfo>;

    /// <summary>
    /// ˢ�½�����ʾ������
    /// </summary>
    procedure RefreshUIState;

    /// <summary>
    /// ˢ���û�
    /// </summary>
    procedure RefreshClientList;

    /// <summary>
    /// �����û�����
    /// </summary>
    /// <param name="AUserID">�����û���UserID</param>
    procedure ContextLogin(const AUserID: string);

    /// <summary>
    /// ���û�����
    /// </summary>
    /// <param name="AUserID"></param>
    procedure ContextLogout(const AUserID: string);

    /// <summary>
    /// �ͻ��������ȡ�����û��¼�
    /// </summary>
    /// <param name="AMsgPackFrom">������Ϣ</param>
    procedure GetAllUserEvent(const AMsgPackFrom: TSimpleMsgPack);

    /// <summary>
    /// ����˼�¼һ��������Ϣ
    /// </summary>
    /// <param name="AToUserID">������UserID</param>
    /// <param name="AFromUserID">������UserID</param>
    /// <param name="AMsg">������Ϣ</param>
    procedure SetOffLineMsgEvent(const AToUserID, AFromUserID, AMsg: string);

    /// <summary>
    /// ����ָ���˵�������Ϣ
    /// </summary>
    /// <param name="AMsgPackFrom">������Ϣ</param>
    procedure GetOfflineMsgEvent(const AMsgPackFrom: TSimpleMsgPack);

    /// <summary>
    /// ���͹���
    /// </summary>
    /// <param name="AMsg">������Ϣ</param>
    procedure SendAnnouncement(const AMsg: string);
  public
    { Public declarations }
  end;

var
  Form5: TForm5;

implementation

uses
  uDIOCPStreamCoder, utils_safeLogger, uFMMonitor, frm_dm;

{$R *.dfm}

procedure TForm5.btnSendClick(Sender: TObject);
begin
  SendAnnouncement(edtMsg.Text);  // ���͹����������
end;

procedure TForm5.ContextLogin(const AUserID: string);
begin
  RefreshClientList;  // ˢ���û��б�UI
end;

procedure TForm5.ContextLogout(const AUserID: string);
begin
  RefreshClientList; // ˢ���û��б�UI
end;

procedure TForm5.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FTcpServer.Active then
  begin
    ShowMessage('����ֹͣ����˵����У����˳���');
    CanClose := False;
  end;
end;

procedure TForm5.FormCreate(Sender: TObject);
begin
  pgc.ActivePageIndex := 0;
  FUILocker := TIocpLocker.Create('�����첽������');
  FOfflineMsgs := TObjectList<TOfflineInfo>.Create;

  FTcpServer := TDiocpCoderTcpServer.Create(Self);
  FTcpServer.CreateDataMonitor;  // ����������(�粻����TFMMonitor�������ܻ�ȡ�������)
  FTcpServer.WorkerCount := 3;
  // register decoder and encoder class
  FTcpServer.RegisterCoderClass(TIOCPStreamDecoder, TIOCPStreamEncoder);  // ע��ӽ�������
  FTcpServer.RegisterContextClass(TMyClientContext);  // ע��ͻ���Context
  //FTcpServer.OnContextDisconnected := OnContextNotifyEvent;
  // ������־��¼
  sfLogger.setAppender(TStringsAppender.Create(mmoMsg.Lines));
  sfLogger.AppendInMainThread := true;

  TFMMonitor.CreateAsChild(tsState, FTcpServer);  // ������������м��
end;

procedure TForm5.FormDestroy(Sender: TObject);
begin
  FTcpServer.Free;
  FOfflineMsgs.Free;
  FUILocker.Free;
end;

procedure TForm5.FormShow(Sender: TObject);
begin
  RefreshUIState;
end;

procedure TForm5.GetAllUserEvent(const AMsgPackFrom: TSimpleMsgPack);
var
  i: Integer;
  vMsgList, lvItem: TSimpleMsgPack;
  vReqUserID: string;
  vPageNo: Integer;
begin
  FUILocker.Lock('��ȡ�����û�');
  try
    vReqUserID := AMsgPackFrom.ForcePathObject('requestID').AsString;  // �����˵�UserID
    vPageNo := AMsgPackFrom.ForcePathObject('params.page').AsInteger;  // ����ڼ�ҳ����
    vMsgList := AMsgPackFrom.ForcePathObject('list');  // ���󷵻����ݴ�ŵ��б�
    // �����е��û����ص�����
    for i := 0 to lvUser.Items.Count - 1 do
    begin
      if lvUser.Items[i].Caption <> vReqUserID then
      begin
        lvItem := vMsgList.AddArrayChild;
        lvItem.ForcePathObject('user.id').AsString := lvUser.Items[i].Caption;
        lvItem.ForcePathObject('user.name').AsString := lvUser.Items[i].SubItems[0];
        if lvUser.Items[i].SubItems[2] = '����' then
          lvItem.ForcePathObject('user.state').AsInteger := 1
        else
          lvItem.ForcePathObject('user.state').AsInteger := 0;
      end;
    end;
  finally
    FUILocker.UnLock;
  end;
end;

procedure TForm5.mniN3Click(Sender: TObject);
begin
  FTcpServer.DisconnectAll;
end;

procedure TForm5.mniStartClick(Sender: TObject);
begin
  FTcpServer.Port := 60544;
  FTcpServer.Active := true;
  // ��ֵ����¼�
  OnContextLogin := ContextLogin;
  OnContextLogout := ContextLogout;
  OnGetAllUser := GetAllUserEvent;
  OnSetOfflineMsg := SetOffLineMsgEvent;
  OnGetOfflineMsg := GetOfflineMsgEvent;

  RefreshUIState;
  RefreshClientList;
end;

procedure TForm5.mniStopClick(Sender: TObject);
begin
  FTcpServer.SafeStop;
  RefreshUIState;
end;

procedure TForm5.SetOffLineMsgEvent(const AToUserID, AFromUserID, AMsg: string);
var
  vOfflineInfo: TOfflineInfo;
begin
  // ������Ϣ
  vOfflineInfo := TOfflineInfo.Create;
  vOfflineInfo.DT := Now;  // ��������ʱ��
  vOfflineInfo.ToUID := AToUserID;  // ������Ϣ������
  vOfflineInfo.FromUID := AFromUserID;  // ������Ϣ������
  vOfflineInfo.Msg := AMsg;  // ������Ϣ����
  FOfflineMsgs.Add(vOfflineInfo);
end;

procedure TForm5.RefreshClientList;
var
  i, vInLineCount: Integer;
  vListItem: TListItem;
  vSession: TChatSession;
begin
  FUILocker.Lock('�������߿ͻ���');
  //FTcpServer.GetOnlineContextList(vContexts);
  try
    lvUser.Clear;
    vInLineCount := 0;

    if not FTcpServer.Active then Exit;

    dm.GetAllUser;  // ��ȡ����ע����û�
    if dm.qryTemp.RecordCount = 0 then Exit;
    // �û���Ϣ���µ�����ؼ�
    lvUser.Items.BeginUpdate;
    try
      dm.qryTemp.First;
      while not dm.qryTemp.Eof do
      begin
        vListItem := lvUser.Items.Add;
        vListItem.Data := nil;
        vListItem.Caption := dm.qryTemp.FieldByName('UserID').AsString;
        vListItem.SubItems.Add(dm.qryTemp.FieldByName('UserName').AsString);
        vListItem.SubItems.Add('');
        vListItem.SubItems.Add('');

        dm.qryTemp.Next;
      end;
      // ���ݵ�ǰ�����û����޸��û��ؼ��ϸ��û�������״̬
      for i := 0 to lvUser.Items.Count - 1 do
      begin
        vSession := TChatSession(ChatSessions.FindSession(lvUser.Items[i].Caption));
        if vSession <> nil then
        begin
          if vSession.State = 1 then  // ����
          begin
            lvUser.Items[i].SubItems[1] := vSession.Context.RemoteAddr + ':'
              + IntToStr(vSession.Context.RemotePort);
            lvUser.Items[i].SubItems[2] := '����';
            Inc(vInLineCount);
          end
          else
          begin
            lvUser.Items[i].SubItems[1] := '';
            lvUser.Items[i].SubItems[2] := '����';
          end;
        end
        else
        begin
          lvUser.Items[i].SubItems[1] := '';
          lvUser.Items[i].SubItems[2] := '����';
        end;
      end;

      statCtl.Panels[0].Text := '�� ' + IntToStr(dm.qryTemp.RecordCount)
        + ' �� ���� ' + IntToStr(vInLineCount);
    finally
      lvUser.Items.EndUpdate;
    end;
  finally
    FUILocker.UnLock;
  end;
end;

procedure TForm5.RefreshUIState;
begin
  mniStart.Enabled := not FTcpServer.Active;
  mniStop.Enabled := FTcpServer.Active;
end;

procedure TForm5.SendAnnouncement(const AMsg: string);
var
  vMS: TMemoryStream;
  i: Integer;
  vOnlineContextList: TList;
  vContext: TIOCPCoderClientContext;
  vMsgPack: TSimpleMsgPack;
begin
  FTcpServer.Locker.Lock('����');
  try
    vMS := TMemoryStream.Create;
    vOnlineContextList := TList.Create;
    try
      vMsgPack := TSimpleMsgPack.Create;
      try
        // ��֯������Ϣ������
        vMsgPack.ForcePathObject('cmdIndex').AsInteger := 5;
        vMsgPack.ForcePathObject('requestID').AsString := 'messageID';
        vMsgPack.ForcePathObject('params.userid').AsString := 'admin';
        vMsgPack.ForcePathObject('params.msg').AsString := AMsg;
        vMsgPack.EncodeToStream(vMS);

        FTcpServer.GetOnlineContextList(vOnlineContextList);  // ��ȡ���������û�(�����и���Ϊ��ȡ�����û�������ֱ�ӷ��ͣ������ߵı�����������Ϣ�б���)
        // ������Ϣ��ÿһ���ͻ�
        for i := 0 to vOnlineContextList.Count - 1 do
        begin
          vContext := TIOCPCoderClientContext(vOnlineContextList[i]);
          vContext.LockContext('������Ϣ', nil);
          try
            vMS.Position := 0;
            vContext.WriteObject(vMS);
          finally
            vContext.UnLockContext('������Ϣ', nil);
          end;
        end;
      finally
        vMsgPack.Free;
      end;
    finally
      vMS.Free;
      vOnlineContextList.Free;
    end;
  finally
    FTcpServer.Locker.UnLock;
  end;
end;

procedure TForm5.GetOfflineMsgEvent(const AMsgPackFrom: TSimpleMsgPack);
var
  i: Integer;
  vMsgList, vMsgPack: TSimpleMsgPack;
  vUserID: string;
begin
  vUserID := AMsgPackFrom.ForcePathObject('requestID').AsString;
  if vUserID = '' then Exit;
  vMsgList := AMsgPackFrom.ForcePathObject('list');
  for i := FOfflineMsgs.Count - 1 downto 0 do  // �����������������Ϣ
  begin
    if FOfflineMsgs[i].ToUID = vUserID then  // �Ƿ��͸���ǰ�û�����Ϣ
    begin
      vMsgPack := vMsgList.AddArrayChild;
      vMsgPack.ForcePathObject('dt').AsDateTime := FOfflineMsgs[i].DT;
      vMsgPack.ForcePathObject('from').AsString := FOfflineMsgs[i].FromUID;
      vMsgPack.ForcePathObject('msg').AsString := FOfflineMsgs[i].Msg;

      FOfflineMsgs.Delete(i);
    end;
  end;

end;

procedure TForm5.tmrKeepAliveTimer(Sender: TObject);
begin
  FTcpServer.KickOut(20000);
  ChatSessions.KickOut(20000);
  RefreshClientList;
end;

end.
