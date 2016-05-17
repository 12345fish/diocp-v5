unit utils_async;

interface

uses
  Classes, SyncObjs
  {$IFDEF MSWINDOWS}
  , Windows
  {$ELSE}

  {$ENDIF}
  ;

{$IF defined(FPC) or (RTLVersion>=18))}
  {$DEFINE HAVE_INLINE}
{$IFEND HAVE_INLINE}

type
  TASyncWorker = class;
  TOnASyncEvent = procedure(pvASyncWorker: TASyncWorker) of object;
  TASyncWorker = class(TThread)
  private
    FData: Pointer;
    FDataObj: TObject;
    FDataTag: Integer;
    FOnAsyncEvent: TOnASyncEvent;
    procedure SetDataObj(const Value: TObject);
  public
    constructor Create(AOnAsyncEvent: TOnASyncEvent);
    procedure Execute; override;
    property Data: Pointer read FData write FData;
    property DataObj: TObject read FDataObj write SetDataObj;
    property DataTag: Integer read FDataTag write FDataTag;


    property Terminated;     
  end;

  TASyncInvoker = class(TObject)
  private
    FOnAsyncEvent: TOnASyncEvent;
    FTerminated: Boolean;
    FStopEvent:TEvent;
    FWaitEvent: TEvent;
    FWorker:TASyncWorker;
    procedure InnerASync(pvWorker:TASyncWorker);
  public
    constructor Create;
    destructor Destroy; override;
    procedure WaitForSleep(pvTime:Cardinal);

    procedure Start(pvASyncEvent: TOnASyncEvent; pvData: Pointer = nil;
        pvDataObject: TObject = nil);
    procedure Terminate;
    procedure WaitForStop;

    property Terminated: Boolean read FTerminated write FTerminated;
  end;

function ASyncInvoke(pvASyncProc: TOnASyncEvent; pvData: Pointer = nil;
    pvDataObject: TObject = nil; pvDataTag: Integer = 0): TASyncWorker;

function CreateManualEvent(pvInitState: Boolean = false): TEvent;

function tick_diff(tick_start, tick_end: Cardinal): Cardinal;

function GetTickCount: Cardinal;

{$IF RTLVersion<24}
function AtomicCmpExchange(var Target: Integer; Value: Integer;
  Comparand: Integer): Integer; {$IFDEF HAVE_INLINE} inline;{$ENDIF}
function AtomicIncrement(var Target: Integer): Integer;{$IFDEF HAVE_INLINE} inline;{$ENDIF}
function AtomicDecrement(var Target: Integer): Integer;{$IFDEF HAVE_INLINE} inline;{$ENDIF}
{$IFEND <XE5}


implementation



{$IF RTLVersion<24}
function AtomicCmpExchange(var Target: Integer; Value: Integer;
  Comparand: Integer): Integer; {$IFDEF HAVE_INLINE} inline;{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  Result := InterlockedCompareExchange(Target, Value, Comparand);
{$ELSE}
  Result := TInterlocked.CompareExchange(Target, Value, Comparand);
{$ENDIF}
end;

function AtomicIncrement(var Target: Integer): Integer;{$IFDEF HAVE_INLINE} inline;{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  Result := InterlockedIncrement(Target);
{$ELSE}
  Result := TInterlocked.Increment(Target);
{$ENDIF}
end;

function AtomicDecrement(var Target: Integer): Integer; {$IFDEF HAVE_INLINE} inline;{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  Result := InterlockedDecrement(Target);
{$ELSE}
  Result := TInterlocked.Decrement(Target);
{$ENDIF}
end;

{$IFEND <XE5}

/// <summary>
///   ��������TickCountʱ�����ⳬ��49������
///      ��л [��ɽ]�׺�һЦ  7041779 �ṩ
///      copy�� qsl����
/// </summary>
function tick_diff(tick_start, tick_end: Cardinal): Cardinal;
begin
  if tick_end >= tick_start then
    result := tick_end - tick_start
  else
    result := High(Cardinal) - tick_start + tick_end;
end;

function ASyncInvoke(pvASyncProc: TOnASyncEvent; pvData: Pointer = nil;
    pvDataObject: TObject = nil; pvDataTag: Integer = 0): TASyncWorker;
begin
  Result := TASyncWorker.Create(pvASyncProc);
  Result.Data := pvData;
  Result.DataObj := pvDataObject;
  Result.DataTag := pvDataTag;
  {$IFDEF UNICODE}
  Result.Start;
  {$ELSE}
  Result.Resume;
  {$ENDIF}

end;

function CreateManualEvent(pvInitState: Boolean = false): TEvent;
begin
  Result := TEvent.Create(nil, True, pvInitState, '');
end;

function GetTickCount: Cardinal;
begin
  {$IFDEF MSWINDOWS}
  Result := Windows.GetTickCount;
  {$ELSE}
  Result := TThread.GetTickCount;
  {$ENDIF}
end;

constructor TASyncWorker.Create(AOnAsyncEvent: TOnASyncEvent);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FOnAsyncEvent := AOnAsyncEvent;
end;

procedure TASyncWorker.Execute;
begin
  if Assigned(FOnAsyncEvent) then
  begin
    FOnAsyncEvent(Self);
  end;
end;

procedure TASyncWorker.SetDataObj(const Value: TObject);
begin
  FDataObj := Value;
end;

constructor TASyncInvoker.Create;
begin
  inherited Create;
  FStopEvent := TEvent.Create(nil, True, True, '');
  FWaitEvent := TEvent.Create(nil, True, true, '');
  FTerminated := true;
end;

destructor TASyncInvoker.Destroy;
begin
  FStopEvent.Free;
  FWaitEvent.Free;
  inherited;
end;

procedure TASyncInvoker.InnerASync(pvWorker:TASyncWorker);
begin
  FOnAsyncEvent(pvWorker);
  FStopEvent.SetEvent;
  FWorker := nil;
  FTerminated := True;
end;

procedure TASyncInvoker.Start(pvASyncEvent: TOnASyncEvent; pvData: Pointer =
    nil; pvDataObject: TObject = nil);
begin
  FTerminated := False;
  FStopEvent.ResetEvent;
  FOnAsyncEvent := pvASyncEvent;
  FWorker := ASyncInvoke(InnerASync, pvData, pvDataObject);
end;

procedure TASyncInvoker.Terminate;
begin
  if FWorker <> nil then FWorker.Terminate;
  FTerminated := True;
  FWaitEvent.SetEvent;
end;

procedure TASyncInvoker.WaitForSleep(pvTime:Cardinal);
begin
  FWaitEvent.ResetEvent;
  FWaitEvent.WaitFor(pvTime);
end;

procedure TASyncInvoker.WaitForStop;
begin
  FStopEvent.WaitFor(MaxInt);
end;

end.
