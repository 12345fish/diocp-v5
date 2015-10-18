unit diocp_ex_strObjectCoder;

interface

uses
  diocp.coder.baseObject, diocp.tcp.server, Classes, SysUtils, utils.buffer;

type
  TMessageHead = packed record
    HEAD_FLAG : Word;
    DATA_LEN  : Integer;
    RESERVE   : array[0..7] of Byte;  // ����λ
  end;
  PMessageHead = ^TMessageHead;

const
  HEAD_SIZE  = SizeOf(TMessageHead);
  PACK_FLAG = $D10;
  MAX_OBJECT_SIZE = 1024 * 1024 * 50;  //�������С 50M , ���������Ϊ����İ���


type
  TStringObject = class(TObject)
  private
    FDataString: String;
  public
    property DataString: String read FDataString write FDataString;
  end;

type
  TDiocpStrObjectDecoder = class(TIOCPDecoder)
  public
    /// <summary>
    ///   �����յ�������,����н��յ�����,���ø÷���,���н���
    /// </summary>
    /// <returns>
    ///   ���ؽ���õĶ���
    /// </returns>
    /// <param name="inBuf"> ���յ��������� </param>
    function Decode(const inBuf: TBufferLink; pvContext: TObject): TObject;
        override;
  end;


  TDiocpStrObjectEncoder = class(TIOCPEncoder)
  public
    /// <summary>
    ///   ����Ҫ�����Ķ���
    /// </summary>
    /// <param name="pvDataObject"> Ҫ���б���Ķ��� </param>
    /// <param name="ouBuf"> ����õ����� </param>
    procedure Encode(pvDataObject:TObject; const ouBuf: TBufferLink); override;
  end;

function verifyData(const buf; len:Cardinal): Cardinal;

implementation

uses
  utils.byteTools;

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




function TDiocpStrObjectDecoder.Decode(const inBuf: TBufferLink; pvContext:
    TObject): TObject;
var
  lvValidCount, lvReadL:Integer;
  lvHead :TMessageHead;
  lvVerifyValue, lvVerifyDataValue:Cardinal;
  lvBytes:TBytes;
begin
  Result := nil;

  //��������е����ݳ��Ȳ�����ͷ���ȣ�
  lvValidCount := inBuf.validCount;   //pack_flag + reserve(4) + len
  if (lvValidCount < HEAD_SIZE) then
  begin
    Exit;
  end;

  //��¼��ȡλ��
  inBuf.markReaderIndex;
  inBuf.readBuffer(@lvHead, HEAD_SIZE);

  if lvHead.HEAD_FLAG <> PACK_FLAG then
  begin
    //����İ�����
    Result := TObject(-1);
    exit;
  end;

  if lvHead.DATA_LEN > 0 then
  begin
    //�ļ�ͷ���ܹ���
    if lvHead.DATA_LEN > MAX_OBJECT_SIZE  then
    begin
      Result := TObject(-1);
      exit;
    end;

    if inBuf.validCount < lvHead.DATA_LEN then
    begin
      //����buf�Ķ�ȡλ��
      inBuf.restoreReaderIndex;
      exit;
    end;

    SetLength(lvBytes, lvHead.DATA_LEN + 1);  // ��һ��������
    inBuf.readBuffer(@lvBytes[0], lvHead.DATA_LEN);

    Result := TStringObject.Create;
    TStringObject(Result).FDataString := Utf8ToAnsi(PAnsiChar(@lvBytes[0]));
  end else
  begin
    Result := nil;
  end;
end;

{ TDiocpStrObjectEncoder }

procedure TDiocpStrObjectEncoder.Encode(pvDataObject: TObject;
  const ouBuf: TBufferLink);
var
  lvDataLen:Integer;
  lvHead :TMessageHead;
  lvRawString:AnsiString;
begin
  lvHead.HEAD_FLAG := PACK_FLAG;

  lvRawString :=UTF8Encode(TStringObject(pvDataObject).FDataString);
  lvDataLen := Length(lvRawString);
  lvHead.DATA_LEN := lvDataLen;
  

  if lvDataLen > MAX_OBJECT_SIZE then
  begin
    raise Exception.CreateFmt('���ݰ�̫��,����ҵ���ֲ���,������ݰ�[%d]!', [MAX_OBJECT_SIZE]);
  end;


  // HEAD
  ouBuf.AddBuffer(@lvHead, HEAD_SIZE);
  ouBuf.AddBuffer(PAnsiChar(lvRawString), lvDataLen);
end;

end.
