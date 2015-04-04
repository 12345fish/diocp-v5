(*
 *	 Unit owner: D10.Mofen
 *         homePage: http://www.diocp.org
 *	       blog: http://www.cnblogs.com/dksoft
 *
 *   2015-02-22 08:29:43
 *     DIOCP-V5 ����
 *
 *
 *)
unit diocp.coder.tcpServer;

interface

// call DoContextAction procedure with qworker
{.$DEFINE QDAC_QWorker}

{$IFDEF DEBUG}
  {$DEFINE DEBUG_ON}
{$ENDIF}

uses
  diocp.tcp.server, utils.buffer, SysUtils, Classes,
  diocp.coder.baseObject, utils.queues, utils.locker
  {$IFDEF QDAC_QWorker}
    , qworker
  {$ELSE}
    , diocp.task
  {$ENDIF}
  ;

type
  TDiocpCoderSendRequest = class(TIocpSendRequest)
  private
    FMemBlock:PMemoryBlock;
  protected
    procedure ResponseDone; override;
    procedure CancelRequest;override;
  end;

  TIOCPCoderClientContext = class(diocp.tcp.server.TIOCPClientContext)
  private
    ///  ���ڷ��͵�BufferLink
    FCurrentSendBufferLink: TBufferLink;

    // �����Ͷ���<TBufferLink����>
    FSendingQueue: TSimpleQueue;

    FrecvBuffers: TBufferLink;
    FStateINfo: String;
    function GetStateINfo: String;
   {$IFDEF QDAC_QWorker}
    procedure OnExecuteJob(pvJob:PQJob);
   {$ELSE}
    procedure OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
   {$ENDIF}
  protected
    procedure add2Buffer(buf:PAnsiChar; len:Cardinal);
    procedure clearRecvedBuffer;
    function decodeObject: TObject;
    procedure OnRecvBuffer(buf: Pointer; len: Cardinal; ErrCode: WORD); override;
    
    procedure RecvBuffer(buf:PAnsiChar; len:Cardinal); virtual;

    procedure DoCleanUp;override;
  protected
    /// <summary>
    ///   �ӷ��Ͷ�����ȡ��һ��Ҫ���͵Ķ�����з���
    /// </summary>
    procedure CheckStartPostSendBufferLink;

    /// <summary>
    ///   Ͷ����ɺ󣬼���Ͷ����һ������,
    ///     ֻ��HandleResponse�е���
    /// </summary>
    procedure PostNextSendRequest; override;
  public
    constructor Create;override;

    destructor Destroy; override;

    /// <summary>
    ///   ���յ�һ�����������ݰ�
    /// </summary>
    /// <param name="pvDataObject"> (TObject) </param>
    procedure DoContextAction(const pvDataObject:TObject); virtual;

    /// <summary>
    ///   ��д����(���Ͷ����ͻ���, ����ý��������н���)
    /// </summary>
    /// <param name="pvDataObject"> Ҫ��д�Ķ��� </param>
    procedure WriteObject(const pvDataObject:TObject);

    /// <summary>
    ///   received buffer
    /// </summary>
    property Buffers: TBufferLink read FrecvBuffers;

    /// <summary>
    ///
    /// </summary>
    property StateINfo: String read GetStateINfo write FStateINfo;
  end;



  TOnContextAction = procedure(pvClientContext:TIOCPCoderClientContext;
      pvObject:TObject) of object;

  {$IF RTLVersion>22}
  // thanks: �����ٷ�19183455
  //  vcl for win64
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  {$IFEND}
  TDiocpCoderTcpServer = class(TDiocpTcpServer)
  private
    FInnerEncoder: TIOCPEncoder;
    FInnerDecoder: TIOCPDecoder;

    FEncoder: TIOCPEncoder;
    FDecoder: TIOCPDecoder;
    FLogicWorkerNeedCoInitialize: Boolean;
    FOnContextAction: TOnContextAction;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>
    ///   ע��������ͽ�������
    /// </summary>
    procedure registerCoderClass(pvDecoderClass:TIOCPDecoderClass;
        pvEncoderClass:TIOCPEncoderClass);

    /// <summary>
    ///   register Decoder instance
    /// </summary>
    /// <param name="pvDecoder"> (TIOCPDecoder) </param>
    procedure registerDecoder(pvDecoder:TIOCPDecoder);

    /// <summary>
    ///   register Encoder instance
    /// </summary>
    /// <param name="pvEncoder"> (TIOCPEncoder) </param>
    procedure registerEncoder(pvEncoder:TIOCPEncoder);

  published

    /// <summary>
    ///   �����߼��߳�ִ���߼�ǰִ��CoInitalize
    /// </summary>
    property LogicWorkerNeedCoInitialize: Boolean read FLogicWorkerNeedCoInitialize write FLogicWorkerNeedCoInitialize;

    /// <summary>
    ///   �յ�һ�����������ݰ���ִ���¼�(��IocpTask/Qworker�߳��д���)
    /// </summary>
    property OnContextAction: TOnContextAction read FOnContextAction write
        FOnContextAction;




  end;



implementation

uses
  utils.safeLogger;

constructor TIOCPCoderClientContext.Create;
begin
  inherited Create;
  FSendingQueue := TSimpleQueue.Create();
  FrecvBuffers := TBufferLink.Create();
end;

destructor TIOCPCoderClientContext.Destroy;
begin
  if IsDebugMode then
  begin
    Assert(FSendingQueue.size = 0);
  end;

  FSendingQueue.Free;
  FrecvBuffers.Free;
  inherited Destroy;
end;

procedure TIOCPCoderClientContext.DoCleanUp;
begin
  /// ����ǰ���Ͷ���
  if FCurrentSendBufferLink <> nil then
  begin
    FCurrentSendBufferLink.Free;
  end;

  // �����ͷŴ����Ͷ��е�BufferLinkʵ�� 
  FSendingQueue.FreeDataObject;                    

  // �����Ѿ����ջ�������
  FrecvBuffers.clearBuffer;
  inherited;
end;

procedure TIOCPCoderClientContext.add2Buffer(buf: PAnsiChar; len: Cardinal);
begin
  //add to context receivedBuffer
  FrecvBuffers.AddBuffer(buf, len);
end;

procedure TIOCPCoderClientContext.CheckStartPostSendBufferLink;
var
  lvMemBlock:PMemoryBlock;
  lvValidCount, lvDataLen: Integer;
  lvSendRequest:TDiocpCoderSendRequest;
begin
  lvDataLen := 0;
  lock();
  try
    // �����ǰ����BufferΪnil ���˳�
    if FCurrentSendBufferLink = nil then Exit;

    // ��ȡ��һ��
    lvMemBlock := FCurrentSendBufferLink.FirstBlock;

    lvValidCount := FCurrentSendBufferLink.validCount;
    if (lvValidCount = 0) or (lvMemBlock = nil) then
    begin
      // �ͷŵ�ǰ�������ݶ���
      FCurrentSendBufferLink.Free;
            
      // �����ǰ�� û���κ�����, ���ȡ��һ��Ҫ���͵�BufferLink
      FCurrentSendBufferLink := TBufferLink(FSendingQueue.DeQueue);
      // �����ǰ����BufferΪnil ���˳�
      if FCurrentSendBufferLink = nil then Exit;

      // ��ȡ��Ҫ���͵�һ������
      lvMemBlock := FCurrentSendBufferLink.FirstBlock;
      
      lvValidCount := FCurrentSendBufferLink.validCount;
      if (lvValidCount = 0) or (lvMemBlock = nil) then
      begin  // û����Ҫ���͵�������
        FCurrentSendBufferLink := nil;  // û��������, �´�ѹ��ʱִ���ͷ�
        exit;      
      end; 
    end;
    if lvValidCount > lvMemBlock.DataLen then
    begin
      lvDataLen := lvMemBlock.DataLen;
    end else
    begin
      lvDataLen := lvValidCount;
    end;


  finally
    unLock();
  end;

  if lvDataLen > 0 then
  begin
    // �ӵ�ǰBufferLink���Ƴ��ڴ��
    FCurrentSendBufferLink.RemoveBlock(lvMemBlock);

    lvSendRequest := TDiocpCoderSendRequest(GetSendRequest);
    lvSendRequest.FMemBlock := lvMemBlock;
    lvSendRequest.SetBuffer(lvMemBlock.Memory, lvDataLen, dtNone);
    if InnerPostSendRequestAndCheckStart(lvSendRequest) then
    begin
      // Ͷ�ݳɹ� �ڴ����ͷ���HandleResponse��
    end else
    begin
      lvSendRequest.UnBindingSendBuffer;
      lvSendRequest.FMemBlock := nil;
      lvSendRequest.CancelRequest;

      /// �ͷŵ��ڴ��
      FreeMemBlock(lvMemBlock);
      
      TDiocpCoderTcpServer(FOwner).ReleaseSendRequest(lvSendRequest);
    end;
  end;          
end;

procedure TIOCPCoderClientContext.clearRecvedBuffer;
begin
  if FrecvBuffers.validCount = 0 then
  begin
    FrecvBuffers.clearBuffer;
  end else
  begin
    FrecvBuffers.clearHaveReadBuffer;
  end;
end;

procedure TIOCPCoderClientContext.DoContextAction(const pvDataObject:TObject);
begin

end;

function TIOCPCoderClientContext.decodeObject: TObject;
begin
  Result := TDiocpCoderTcpServer(Owner).FDecoder.Decode(FrecvBuffers, Self);
end;

function TIOCPCoderClientContext.GetStateINfo: String;
begin
  Result := FStateINfo;
end;



procedure TIOCPCoderClientContext.OnRecvBuffer(buf: Pointer; len: Cardinal;
  ErrCode: WORD);
begin
  RecvBuffer(buf, len);
end;

procedure TIOCPCoderClientContext.PostNextSendRequest;
begin
  inherited PostNextSendRequest;
  CheckStartPostSendBufferLink;
end;

{$IFDEF QDAC_QWorker}
procedure TIOCPCoderClientContext.OnExecuteJob(pvJob: PQJob);
var
  lvObj:TObject;
begin
//  if TDiocpCoderTcpServer(Owner).FLogicWorkerNeedCoInitialize then
//    pvJob.
    
  lvObj := TObject(pvJob.Data);
  try
    DoContextAction(lvObj);
  finally
    lvObj.Free;
  end;
end;
{$ELSE}

procedure TIOCPCoderClientContext.OnExecuteJob(pvTaskRequest: TIocpTaskRequest);
var
  lvObj:TObject;
begin
  try
    if TDiocpCoderTcpServer(Owner).FLogicWorkerNeedCoInitialize then
      pvTaskRequest.iocpWorker.checkCoInitializeEx();

    lvObj := TObject(pvTaskRequest.TaskData);
    try
      DoContextAction(lvObj);
    finally
      lvObj.Free;
    end;
  except
   on E:Exception do
    begin
      if FOwner = nil then
      begin
        sfLogger.logMessage('�ػ����߼��쳣:' + e.Message);
      end else
      begin
        FOwner.LogMessage('�ػ����߼��쳣:' + e.Message);
      end;
    end;
  end;
end;
{$ENDIF}

procedure TIOCPCoderClientContext.RecvBuffer(buf:PAnsiChar; len:Cardinal);
var
  lvObject:TObject;
begin
  add2Buffer(buf, len);

  self.StateINfo := '���յ�����,׼�����н���';

  ////����һ���յ������ʱ����ֻ������һ���߼��Ĵ���(DoContextAction);
  ///  2013��9��26�� 08:57:20
  ///    ��лȺ��JOE�ҵ�bug��
  while True do
  begin
    //����ע��Ľ�����<���н���>
    lvObject := decodeObject;
    if Integer(lvObject) = -1 then
    begin
      /// ����İ���ʽ, �ر�����
      DoDisconnect;
      exit;
    end else if lvObject <> nil then
    begin
      try
        self.StateINfo := '����ɹ�,׼������dataReceived�����߼�����';


        if Assigned(TDiocpCoderTcpServer(Owner).FOnContextAction) then
          TDiocpCoderTcpServer(Owner).FOnContextAction(Self, lvObject);


       {$IFDEF QDAC_QWorker}
         Workers.Post(OnExecuteJob, lvObject);
       {$ELSE}
         iocpTaskManager.PostATask(OnExecuteJob, lvObject);
       {$ENDIF}
      except
        on E:Exception do
        begin
          Owner.LogMessage('�ػ����߼��쳣!' + e.Message);
        end;
      end;
    end else
    begin
      //������û�п���ʹ�õ��������ݰ�,����ѭ��
      Break;
    end;
  end;

  //������<���û�п��õ��ڴ��>����
  clearRecvedBuffer;
end;



procedure TIOCPCoderClientContext.WriteObject(const pvDataObject:TObject);
var
  lvOutBuffer:TBufferLink; 
  lvStart:Boolean;
begin
  lvStart := false;
  if not Active then Exit;

  if self.LockContext('WriteObject', Self) then
  try
    lvOutBuffer := TBufferLink.Create;
    try
      TDiocpCoderTcpServer(Owner).FEncoder.Encode(pvDataObject, lvOutBuffer);
      lock();
      try
        if FSendingQueue.size >= TDiocpCoderTcpServer(Owner).MaxSendingQueueSize then
        begin
          raise Exception.Create('Out of MaxSendingQueueSize!!!');
        end;
        FSendingQueue.EnQueue(lvOutBuffer);
        if FCurrentSendBufferLink = nil then
        begin
          FCurrentSendBufferLink := TBufferLink(FSendingQueue.DeQueue);
          lvStart := true;
        end;
      finally
        unLock;
      end;
    except
      lvOutBuffer.Free;
      raise;           
    end;
    
    if lvStart then
    begin
      CheckStartPostSendBufferLink;
    end;
  finally
    self.unLockContext('WriteObject', Self);
  end;    
end;

constructor TDiocpCoderTcpServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClientContextClass := TIOCPCoderClientContext;
  
  FIocpSendRequestClass := TDiocpCoderSendRequest;
end;

destructor TDiocpCoderTcpServer.Destroy;
begin
  if FInnerDecoder <> nil then FInnerDecoder.Free;
  if FInnerEncoder <> nil then FInnerEncoder.Free;
  inherited Destroy;
end;

procedure TDiocpCoderTcpServer.registerCoderClass(pvDecoderClass: TIOCPDecoderClass;
    pvEncoderClass: TIOCPEncoderClass);
begin
  if FInnerDecoder <> nil then
  begin
    raise Exception.Create('�Ѿ�ע���˽�������');
  end;

  FInnerDecoder := pvDecoderClass.Create;
  registerDecoder(FInnerDecoder);

  if FInnerEncoder <> nil then
  begin
    raise Exception.Create('�Ѿ�ע���˱�������');
  end;
  FInnerEncoder := pvEncoderClass.Create;
  registerEncoder(FInnerEncoder);
end;

{ TDiocpCoderTcpServer }

procedure TDiocpCoderTcpServer.registerDecoder(pvDecoder: TIOCPDecoder);
begin
  FDecoder := pvDecoder;
end;

procedure TDiocpCoderTcpServer.registerEncoder(pvEncoder: TIOCPEncoder);
begin
  FEncoder := pvEncoder;
end;



{ TDiocpCoderSendRequest }

procedure TDiocpCoderSendRequest.CancelRequest;
begin
  if FMemBlock <> nil then
  begin
    FreeMemBlock(FMemBlock);
    FMemBlock := nil;
  end;
  inherited;  
end;

procedure TDiocpCoderSendRequest.ResponseDone;
begin
  if FMemBlock <> nil then
  begin
    FreeMemBlock(FMemBlock);
    FMemBlock := nil;
  end;
  inherited;
end;

end.
