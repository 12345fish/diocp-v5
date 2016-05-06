unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, utils_safeLogger, utils_async, utils_threadinfo,
  ExtCtrls, SingleLogFileAppender4SafeLogger;

type
  TfrmMain = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    btnStart: TButton;
    edtThreadNum: TEdit;
    mmoInfo: TMemo;
    btnThreadInfo: TButton;
    rgAppender: TRadioGroup;
    edtPerNum: TEdit;
    Label1: TLabel;
    edtSleep: TEdit;
    procedure btnStartClick(Sender: TObject);
    procedure btnThreadInfoClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure OnASyncWorker(pvWorker:TASyncWorker);
  end;

  TEmptyAppender4SafeLogger = class(TBaseAppender)
  public
    procedure AppendLog(pvData:TLogDataObject); override;
  end;

var
  frmMain: TfrmMain;

  __runCounter:Integer;
  __terminated:Boolean;
  __num:Integer;
  __sleep:Integer;
  __loggers:array of TSafeLogger;

implementation



{$R *.dfm}

procedure TfrmMain.btnStartClick(Sender: TObject);
var
  i: Integer;
begin
  if btnStart.Tag = 0 then
  begin
    if __runCounter <> 0 then raise Exception.Create(Format('����:%d�߳�������, ���ȵȴ��ֳ��������', [__runCounter]));

    ResetThreadHintInfo();

    if Length(__loggers) = 0 then
    begin
      SetLength(__loggers, 10);
      for i := 0 to length(__loggers) - 1 do
      begin
        __loggers[i] := TSafeLogger.Create;
        __loggers[i].Name := 'logger_' + IntToStr(i);
      end;
    end;
    for i := Low(__loggers) to High(__loggers) do
    begin
      if rgAppender.ItemIndex = 0 then
      begin
        __loggers[i].setAppender(TEmptyAppender4SafeLogger.Create, true);
      end else
      begin
        __loggers[i].setAppender(TSingleLogFileAppender4SafeLogger.Create, true);
        TSingleLogFileAppender4SafeLogger(__loggers[i].Appender).CacheSize := 0;
        TSingleLogFileAppender4SafeLogger(__loggers[i].Appender).FilePreFix := 'log_' + IntToStr(i);
      end;
    end;
    __terminated := False;
    btnStart.Tag := 1;
    btnStart.Caption := '���ֹͣ';
    __sleep := StrToInt(edtSleep.Text);
    __num := StrToInt(edtPerNum.Text);
    for i := 0 to StrToInt(edtThreadNum.Text) -1 do
    begin
      ASyncInvoke(OnASyncWorker, nil, nil, i);
    end;
  end else
  begin
    __terminated := True;
    btnStart.Tag := 0;
    btnStart.Caption := '����';
  end;
end;

procedure TfrmMain.btnThreadInfoClick(Sender: TObject);
begin
  mmoInfo.Clear;
  mmoInfo.Lines.Add(GetThreadsHintInfo);
end;

procedure TfrmMain.OnASyncWorker(pvWorker:TASyncWorker);
var
  i, j: Integer;
  lvTickCount, t:Cardinal;

begin
  InterlockedIncrement(__runCounter);
  lvTickCount := GetTickCount;
  SetCurrentThreadInfo('[%d]��ʼ', [pvWorker.DataTag]);
  for i := 1 to __num do
  begin
    j := i mod Length(__loggers);

    t := GetTickCount - lvTickCount;
    if t = 0 then t := 1;
    SetCurrentThreadInfo('[%d]����, ��ǰ:%d, ��ʱ:%d, ����:%d, ops:%f',
      [pvWorker.DataTag, i, t, i, (i) / (t / 1000.000) ]);
    __loggers[j].logMessage(Format('[%d]����[%d]', [pvWorker.DataTag, i]));
    if __sleep >= 0 then Sleep(__sleep);
    if __terminated then Break;
  end;
  t := GetTickCount - lvTickCount;
  if t = 0 then t := 1;
  SetCurrentThreadInfo('[%d]���, ��ʱ:%d, ����:%d, ops:%f',
    [pvWorker.DataTag, t, i, (i) / (t / 1000.000) ]);

  InterlockedDecrement(__runCounter);
end;

procedure TEmptyAppender4SafeLogger.AppendLog(pvData:TLogDataObject);
begin
  inherited;
end;

end.
