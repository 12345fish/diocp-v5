unit diocp_ex_StreamCoder;

interface

uses
  diocp_coder_baseObject, Classes, SysUtils, utils_buffer, utils_BufferPool, diocp_ex_streamProtocol;

type
  TIOCPStreamDecoder = class(TDiocpDecoder)
  private
    FBuf: PByte;
    FLength: Integer;
    FStreamObj: TDiocpStreamObject;
  public
    constructor Create; override;
    destructor Destroy; override;
    /// <summary>
    ///   ��������
    /// </summary>
    procedure SetRecvBuffer(const buf:Pointer; len:Cardinal); override;

    /// <summary>
    ///   ��ȡ����õ�����
    /// </summary>
    function GetData: Pointer; override;


    /// <summary>
    ///   �ͷŽ���õ�����
    /// </summary>
    procedure ReleaseData(const pvData:Pointer); override;

    /// <summary>
    ///   �����յ�������,����н��յ�����,���ø÷���,���н���
    /// </summary>
    /// <returns>
    ///   0����Ҫ���������
    ///   1: ����ɹ�
    ///  -1: ����ʧ��
    /// </returns>
    /// <param name="inBuf"> ���յ��������� </param>
    function Decode: Integer; override;
  end;


  TIOCPStreamEncoder = class(TDiocpEncoder)
  public
    /// <summary>
    ///   ����Ҫ���͵Ķ���
    /// </summary>
    /// <param name="pvDataObject"> Ҫ���б���Ķ��� </param>
    /// <param name="pvBufWriter"> ����д�� </param>
    procedure Encode(const pvDataObject: Pointer; const pvBufWriter: TBlockBuffer);
        override;
  end;

function verifyData(const buf; len:Cardinal): Cardinal;

implementation

uses
  utils_byteTools;

function verifyData(const buf; len: Cardinal): Cardinal;
var
  i:Cardinal;
  p:PByte;
begin
  i := 0;
  Result := 0;
  p := PByte(@buf);
  while i < len do
  begin
    Result := Result + p^;
    Inc(p);
    Inc(i);
  end;
end;

const
  PACK_FLAG = $D10;

  //PACK_FLAG  + CRC_VALUE + STREAM_LEN + STREAM_DATA

  MAX_OBJECT_SIZE = 1024 * 1024 * 10;  //�������С 10M , ����10M �����Ϊ����İ���



constructor TIOCPStreamDecoder.Create;
begin
  inherited Create;
  FStreamObj := TDiocpStreamObject.Create();
end;

destructor TIOCPStreamDecoder.Destroy;
begin
  FreeAndNil(FStreamObj);
  inherited Destroy;
end;

function TIOCPStreamDecoder.Decode: Integer;
begin
  Result := 0;
  while FLength > 0 do
  begin
    Result := FStreamObj.InputBuffer(FBuf^);
    Inc(FBuf);
    Dec(FLength);
    if Result <> 0 then
    begin
      Break;
    end;
  end;
end;

function TIOCPStreamDecoder.GetData: Pointer;
begin
  Result := FStreamObj.Content;
end;

procedure TIOCPStreamDecoder.SetRecvBuffer(const buf:Pointer; len:Cardinal);
begin
  FBuf := PByte(buf);
  FLength := len;
end;

procedure TIOCPStreamDecoder.ReleaseData(const pvData:Pointer);
begin
  inherited;
end;

{ TIOCPStreamEncoder }

procedure TIOCPStreamEncoder.Encode(const pvDataObject: Pointer; const
    pvBufWriter: TBlockBuffer);
var
  lvPACK_FLAG: WORD;
  lvDataLen, lvWriteIntValue: Integer;
  lvBuf: TBytes;
  lvVerifyValue:Cardinal;
begin
  lvPACK_FLAG := PACK_FLAG;

  TStream(pvDataObject).Position := 0;

  if TStream(pvDataObject).Size > MAX_OBJECT_SIZE then
  begin
    raise Exception.CreateFmt('���ݰ�̫��,����ҵ���ֲ���,������ݰ�[%d]!', [MAX_OBJECT_SIZE]);
  end;



  pvBufWriter.Append(@lvPACK_FLAG,2);

  lvDataLen := TStream(pvDataObject).Size;
  SetLength(lvBuf, lvDataLen);

  TStream(pvDataObject).Read(lvBuf[0], lvDataLen);
  lvVerifyValue := verifyData(lvBuf[0], lvDataLen);

  pvBufWriter.Append(@lvVerifyValue,SizeOf(lvVerifyValue));
  lvWriteIntValue := TByteTools.swap32(lvDataLen);

  pvBufWriter.Append(@lvWriteIntValue, SizeOf(lvWriteIntValue));
  pvBufWriter.Append(@lvbuf[0],lvDataLen);

  
end;

end.
