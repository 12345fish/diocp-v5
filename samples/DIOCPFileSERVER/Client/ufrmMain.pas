unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IdTCPClient, diocp.tcp.blockClient,
  uICoderSocket, DiocpFileOperator;

type
  TfrmMain = class(TForm)
    edtHost: TEdit;
    edtPort: TEdit;
    btnConnect: TButton;
    dlgOpen: TOpenDialog;
    btnUpload: TButton;
    btnDownload: TButton;
    edtRFileID: TEdit;
    Label1: TLabel;
    btnDel: TButton;
    btnFileSize: TButton;
    edtUploadFileName: TEdit;
    btnUpload2: TButton;
    rgFileAccess: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnFileSizeClick(Sender: TObject);
    procedure btnUpload2Click(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
  private
    { Private declarations }
    FIdTcpClient: TIdTcpClient;
    FDiocpTcpClient: TDiocpBlockTcpClient;
    FCoderSocket:ICoderSocket;
    FDiocpFileOperator: TDiocpFileOperator;
  public
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  IdTCPClientCoderImpl, uDTcpClientCoderImpl;


{$R *.dfm}


procedure TfrmMain.btnConnectClick(Sender: TObject);
var
  lvHost:AnsiString;
begin
  lvHost := edtHost.Text;
  if rgFileAccess.ItemIndex = 0 then
  begin
    FIdTcpClient.Host := lvHost;
    FIdTcpClient.Port := StrToInt(edtPort.Text);
    FIdTcpClient.Connect;
    FCoderSocket := TIdTCPClientCoderImpl.Create(FIdTcpClient, true);
  end else
  begin
    FDiocpTcpClient.Host := lvHost;
    FDiocpTcpClient.Port := StrToInt(edtPort.Text);
    FDiocpTcpClient.Connect;
    FCoderSocket := TDTcpClientCoderImpl.Create(FDiocpTcpClient, true);   
  end;

  FDiocpFileOperator.SetCoderSocket(FCoderSocket);

  ShowMessage('�������ӳɹ�!');
  lvHost := '';
end;

procedure TfrmMain.btnDelClick(Sender: TObject);
begin
  FDiocpFileOperator.DeleteFile(
   edtRFileID.Text,   //Զ���ļ�
   ''
   );
  ShowMessage('ɾ���ļ��ɹ�!');

end;

procedure TfrmMain.btnDownloadClick(Sender: TObject);
var
  lvLocalFile:String;
begin
  lvLocalFile := ExtractFilePath(ParamStr(0)) + 'tempFiles\' + ExtractFileName(edtRFileID.Text);
  ForceDirectories(ExtractFilePath(lvLocalFile));
  FDiocpFileOperator.DownFile(
   edtRFileID.Text,   //Զ���ļ�
   lvLocalFile,
   '');                                  //�����ļ�
  ShowMessage('�����ļ��ɹ�!');
end;

procedure TfrmMain.btnFileSizeClick(Sender: TObject);
begin
  ShowMessage('�ļ���С:' +
    intToStr(
    FDiocpFileOperator.ReadFileSize(
   edtRFileID.Text   //Զ���ļ�
   , '')));
end;


procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FDiocpTcpClient := TDiocpBlockTcpClient.Create(Self);
  FIdTcpClient := TIdTcpClient.Create(Self);
  FDiocpFileOperator := TDiocpFileOperator.Create(nil);
end;

procedure TfrmMain.btnUpload2Click(Sender: TObject);
var
  lvRFileID, lvLocalFile:String;
begin
  lvLocalFile := edtUploadFileName.Text;
  if not FileExists(lvLocalFile) then
  begin
    raise Exception.CreateFmt('ָ�����ļ�[%s]������', [lvLocalFile]);
  end;

  lvRFileID := 'diocpBean\' + ExtractFileName(lvLocalFile);
  FDiocpFileOperator.UploadFile(
   lvRFileID,   //Զ���ļ�
   lvLocalFile, '');                                  //�����ļ�
  ShowMessage('�ϴ��ļ��ɹ�!');
  edtRFileID.Text := lvRFileID;   
end;


procedure TfrmMain.btnUploadClick(Sender: TObject);
var
  lvRFileID:String;
begin
  if dlgOpen.Execute then
  begin
    lvRFileID := 'diocpBean\' + ExtractFileName(dlgOpen.FileName);
    FDiocpFileOperator.UploadFile(
     lvRFileID,   //Զ���ļ�
     dlgOpen.FileName, '');                                  //�����ļ�
    ShowMessage('�ϴ��ļ��ɹ�!');
    edtRFileID.Text := lvRFileID;
  end;
end;

destructor TfrmMain.Destroy;
begin
  FDiocpFileOperator.Free;
  inherited;
end;

end.
