unit frm_Login;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfrmLogin = class(TForm)
    edtUserID: TEdit;
    edtPaw: TEdit;
    btnOk: TButton;
    btnClose: TButton;
    lbl1: TLabel;
    lbl2: TLabel;
    procedure btnOkClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
    procedure OnContextActionEx(AObject: TObject);
  public
    { Public declarations }
  end;

var
  frmLogin: TfrmLogin;

implementation

uses frm_Client, ClientIocpOper, SimpleMsgPack;

{$R *.dfm}

procedure TfrmLogin.btnCloseClick(Sender: TObject);
begin
  Self.ModalResult := mrClose;
end;

procedure TfrmLogin.btnOkClick(Sender: TObject);
begin
  DiocpContext.Host := '192.168.1.10';
  DiocpContext.Port := 60544;
  // DiocpContext���ڻ�û�����ӣ����Բ���LockContext
  DiocpContext.OnContextAction := OnContextActionEx;
  CMD_Login(edtUserID.Text, edtPaw.Text);  // ��¼����
end;

procedure TfrmLogin.OnContextActionEx(AObject: TObject);
var
  vStream: TMemoryStream;
  vMsgPack: TSimpleMsgPack;
begin
  vStream := TMemoryStream(AObject);
  vMsgPack:= TSimpleMsgPack.Create;
  try
    vMsgPack.DecodeFromStream(vStream);  // ������Ϣ
    if vMsgPack.ForcePathObject('result.code').AsInteger <> -1 then  // �����ڷ����ִ�гɹ�
    begin
      if vMsgPack.ForcePathObject('requestID').AsString = 'login' then  // �ǵ�¼���󷵻ص���Ϣ
      begin
        if vMsgPack.ForcePathObject('result.code').AsInteger = 0 then  // ��¼�ɹ�
        begin
          DiocpContext.LockContext('��¼���', Self);
          try
            CurUserID := edtUserID.Text;
            DiocpContext.OnContextAction := nil;  // �����¼���׼�����ͻ�����ʹ��
          finally
            DiocpContext.UnLockContext('��¼���', Self);
          end;
          Self.ModalResult := mrOk;
        end;
      end
    end;
  finally
    vMsgPack.Free;
  end;
end;

end.
