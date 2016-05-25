unit diocp.session;

interface

uses
  utils_hashs, SysUtils, Windows, Classes;

type
  TSessionItem = class(TObject)
  private
    FSessionID: string;
    // ��󽻻����ݵ�ʱ���
    FLastActivity: Cardinal;
  public
    constructor Create; virtual;
    procedure DoActivity;

    /// <summary>
    ///   �Ͽ� SessionʧЧ, �Ƴ��б�׼���ͷ�SessionItemʱִ��
    /// </summary>
    procedure OnDisconnect; virtual;
  public
    property SessionID: string read FSessionID;
  end;

  TSessionItemClass = class of TSessionItem;

  TSessions = class(TObject)
  private
    FItemClass: TSessionItemClass;
    FList: TDHashTableSafe;
  public
    constructor Create(AItemClass: TSessionItemClass);
    destructor Destroy; override;

    /// <summary>
    ///   ����Session
    /// </summary>
    function FindSession(pvSessionID:string): TSessionItem;

    procedure GetSessionList(pvList:TList);

    /// <summary>
    ///   ���Ҳ�����Session,����������򴴽�һ���µ�Session
    /// </summary>
    /// <returns> TSessionItem
    /// </returns>
    /// <param name="pvSessionID"> (string) </param>
    function CheckSession(pvSessionID:string): TSessionItem;
    /// <summary>
    /// �Ƴ�ָ���ĻỰ(��Ự����ʱ)
    /// </summary>
    /// <param name="ASID"></param>
    procedure RemoveSession(const ASID: string);
    /// <summary>
    ///   ��ʱ���, �������Timeoutָ����ʱ�仹û���κ����ݽ������ݼ�¼��
    ///     �ͽ��йر�����
    ///   ʹ��ѭ����⣬������кõķ�������ӭ�ύ���ı������
    /// </summary>
    procedure KickOut(pvTimeOut:Cardinal = 60000);
  end;

implementation


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

function TSessions.CheckSession(pvSessionID:string): TSessionItem;
begin
  Assert(FItemClass <> nil);
  FList.Lock;
  Result := TSessionItem(FList.ValueMap[pvSessionID]);
  if Result = nil then
  begin
    Result := FItemClass.Create;
    Result.FSessionID := pvSessionID;
    FList.ValueMap[pvSessionID] := Result;
  end;
  FList.unLock;
  Result.DoActivity;
end;

constructor TSessions.Create(AItemClass: TSessionItemClass);
begin
  inherited Create;
  FList := TDHashTableSafe.Create();
  FItemClass := AItemClass;
end;

destructor TSessions.Destroy;
begin
  FList.FreeAllDataAsObject;
  FreeAndNil(FList);
  inherited Destroy;
end;

function TSessions.FindSession(pvSessionID:string): TSessionItem;
begin
  FList.Lock;
  Result := TSessionItem(FList.ValueMap[pvSessionID]);
  FList.unLock;
end;

procedure TSessions.GetSessionList(pvList:TList);
begin
  FList.Lock;
  FList.GetDatas(pvList);
  FList.unLock;
end;

procedure TSessions.KickOut(pvTimeOut:Cardinal = 60000);
var
  lvNowTickCount:Cardinal;
  lvBucket, lvNextBucket:PDHashData;
  I:Integer;
  lvContext : TSessionItem;
  lvDeleteList:TStrings;
  lvObj:TObject;
begin
  lvNowTickCount := GetTickCount;
  lvDeleteList := TStringList.Create;
  FList.Lock();
  try
    for I := 0 to FList.BucketSize - 1 do
    begin
      lvBucket := FList.Buckets[I];
      while lvBucket<>nil do
      begin
        lvNextBucket := lvBucket.Next;
        if lvBucket.Data <> nil then
        begin
          lvContext := TSessionItem(lvBucket.Data);
          if lvContext.FLastActivity <> 0 then
          begin
            if tick_diff(lvContext.FLastActivity, lvNowTickCount) > pvTimeOut then
            begin
              lvDeleteList.AddObject(lvContext.FSessionID, lvContext);
            end;
          end;
        end;
        lvBucket:= lvNextBucket;
      end;
    end;

    /// �������
    for i := 0 to lvDeleteList.Count - 1 do
    begin
      lvObj := lvDeleteList.Objects[i];
      FList.Remove(lvDeleteList[i]);
      TSessionItem(lvObj).OnDisconnect;
      TObject(lvObj).Free;
    end;
  finally
    FList.unLock;
    lvDeleteList.Free;
  end;
end;

procedure TSessions.RemoveSession(const ASID: string);
var
  lvContext: TSessionItem;
begin
  FList.Lock;
  try
    lvContext := TSessionItem(FList.ValueMap[ASID]);
    FList.Remove(ASID);
    lvContext.OnDisconnect;
    lvContext.Free;
  finally
    FList.UnLock;
  end;
end;

constructor TSessionItem.Create;
begin
  inherited;
end;

{ TSessionItem }

procedure TSessionItem.DoActivity;
begin
  FLastActivity := GetTickCount;
end;

procedure TSessionItem.OnDisconnect;
begin
  
end;

end.
