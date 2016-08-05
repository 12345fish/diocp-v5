(*
 *	 Unit owner: d10.�����
 *	       blog: http://www.cnblogs.com/dksoft
 *     homePage: www.diocp.org
 *
 *   2015-04-13 13:03:47
 *     ͨ�ö����
 *
 *)
unit utils_objectPool;

interface

uses
  utils_queues, Windows, SysUtils;

type
{$IFDEF UNICODE}
  TOnCreateObjectEvent = reference to function:TObject;
{$ELSE}
  TOnCreateObjectEvent = function:TObject of object;
{$ENDIF}

  TObjectPool = class(TObject)
  private
    FName: String;
    FUsingCount: Integer;

    FObjectList: TBaseQueue;
    FOnCreateObjectEvent: TOnCreateObjectEvent;
    FCount: Integer;
    FOutTime: Integer;
    FReleaseTime: Integer;
  public
    constructor Create(AOnCreateObjectEvent: TOnCreateObjectEvent);

    destructor Destroy; override;

    /// <summary>
    ///   ������󣬷��̰߳�ȫ
    /// </summary>
    procedure Clear;
    
    /// <summary>
    ///   �ȴ����ж���黹
    /// </summary>
    function WaitFor(pvTimeOut: Cardinal): Boolean;


    /// <summary>
    ///   ��ȡ����
    /// </summary>
    function GetObject:TObject;

    /// <summary>
    ///   �黹����
    /// </summary>
    procedure ReleaseObject(pvObject:TObject);

    /// <summary>
    ///   ����ʹ������
    /// </summary>
    property UsingCount: Integer read FUsingCount;

    /// <summary>
    ///   ��������
    /// </summary>
    property Count: Integer read FCount;

    /// <summary>
    ///   ���ƣ��������ڼ�ص���
    /// </summary>
    property Name: String read FName write FName;


    /// <summary>
    ///  �������
    /// </summary>
    property OutTime: Integer read FOutTime write FOutTime;

    /// <summary>
    ///   ���ش���
    /// </summary>
    property ReleaseTime: Integer read FReleaseTime write FReleaseTime;








    /// <summary>
    ///   ���������¼�
    /// </summary>
    property OnCreateObjectEvent: TOnCreateObjectEvent read FOnCreateObjectEvent
        write FOnCreateObjectEvent;



  end;

implementation

var
  __ProcessIDStr :String;

procedure WriteFileMsg(pvMsg:String; pvFilePre:string);
var
  lvFileName, lvBasePath:String;
  lvLogFile: TextFile;
begin
  try
    lvBasePath :=ExtractFilePath(ParamStr(0)) + 'log';
    ForceDirectories(lvBasePath);
    lvFileName :=lvBasePath + '\' + __ProcessIDStr+ '_' + pvFilePre +
     FormatDateTime('mmddhhnn', Now()) + '.log';

    AssignFile(lvLogFile, lvFileName);
    if (FileExists(lvFileName)) then
      append(lvLogFile)
    else
      rewrite(lvLogFile);

    writeln(lvLogFile, pvMsg);
    flush(lvLogFile);
    CloseFile(lvLogFile);
  except
    ;
  end;
end;

procedure TObjectPool.Clear;
begin
  FUsingCount := 0;
  FCount := 0;
  FObjectList.FreeDataObject;
  FObjectList.Clear;
end;

constructor TObjectPool.Create(AOnCreateObjectEvent: TOnCreateObjectEvent);
begin
  inherited Create;
  FCount := 0;
  FUsingCount := 0;
  FObjectList := TBaseQueue.Create();
  FOnCreateObjectEvent := AOnCreateObjectEvent;
end;

destructor TObjectPool.Destroy;
begin
  FObjectList.FreeDataObject;
  FObjectList.Free;
  inherited Destroy;
end;

function TObjectPool.GetObject: TObject;
begin
  Result := FObjectList.DeQueue;
  if Result = nil then
  begin
    Assert(Assigned(FOnCreateObjectEvent));
    Result := FOnCreateObjectEvent();
    Assert(Result <> nil);
    InterlockedIncrement(FCount);
  end;
  InterlockedIncrement(FUsingCount);
  
  InterlockedIncrement(FOutTime);

end;

procedure TObjectPool.ReleaseObject(pvObject:TObject);
begin
  FObjectList.EnQueue(pvObject);
  InterlockedDecrement(FUsingCount);
  InterlockedIncrement(FReleaseTime);
end;

function TObjectPool.WaitFor(pvTimeOut: Cardinal): Boolean;
var
  l:Cardinal;
  c:Integer;
begin
  l := GetTickCount;
  c := FUsingCount;
  while (c > 0) do
  begin
    {$IFDEF MSWINDOWS}
    SwitchToThread;
    {$ELSE}
    TThread.Yield;
    {$ENDIF}

    if GetTickCount - l > pvTimeOut then
    begin
      WriteFileMsg(Format('(%s)WaitFor �ȴ���ʱ, ��ǰδ�黹����:%d', [FName, c]), 'WaitFor');
      Break;
    end;
    c := FUsingCount;
  end;

  Result := FUsingCount = 0;
end;

initialization
  __ProcessIDStr := IntToStr(GetCurrentProcessId);

end.
