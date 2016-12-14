(*
 *	 Unit owner: d10.�����
 *	       blog: http://www.cnblogs.com/dksoft
 *     homePage: www.diocp.org
 *
 *   2015-02-22 08:29:43
 *     DIOCP-V5 ����
 *
 *)
 
unit diocp_coder_baseObject;

interface

uses
  diocp_tcp_server, utils_buffer, utils_queues, utils_BufferPool;

type
{$if CompilerVersion< 18.5}
  TBytes = array of Byte;
{$IFEND}

  TIOCPDecoder = class(TObject)
  public
    /// <summary>
    ///   �����յ�������,����н��յ�����,���ø÷���,���н���
    /// </summary>
    /// <returns>
    ///   ���ؽ���õĶ���
    /// </returns>
    /// <param name="inBuf"> ���յ��������� </param>
    function Decode(const inBuf: TBufferLink; pvContext: TObject): TObject;
        virtual; abstract;
  end;

  TIOCPDecoderClass = class of TIOCPDecoder;

  TIOCPEncoder = class(TObject)
  public
    /// <summary>
    ///   ����Ҫ���͵Ķ���
    /// </summary>
    /// <param name="pvDataObject"> Ҫ���б���Ķ��� </param>
    /// <param name="ouBuf"> ����õ����� </param>
    procedure Encode(pvDataObject: TObject; const ouBuf: TBufferLink); virtual;
        abstract;
  end;

  TIOCPEncoderClass = class of TIOCPEncoder;


  TDiocpEncoder = class(TObject)
  protected
    FContext:TObject;
  public
    procedure SetContext(const pvContext:TObject);

    /// <summary>
    ///   ����Ҫ���͵Ķ���
    /// </summary>
    /// <param name="pvDataObject"> Ҫ���б���Ķ��� </param>
    /// <param name="pvBufWriter"> ����д�� </param>
    procedure Encode(const pvDataObject: Pointer; const pvBufWriter: TBlockBuffer);
        virtual; abstract;
  end;

  
  TDiocpEncoderClass = class of TDiocpEncoder;

  /// <summary>
  ///  ������
  /// </summary>
  TDiocpDecoder = class(TObject)
  protected
    FContext:TObject;
  public
    constructor Create; virtual;

    procedure SetContext(const pvContext:TObject);

    /// <summary>
    ///   ��������
    /// </summary>
    procedure SetRecvBuffer(const buf:Pointer; len:Cardinal); virtual; abstract;

    /// <summary>
    ///   ��ȡ����õ�����
    /// </summary>
    function GetData:Pointer; virtual; abstract;


    /// <summary>
    ///   �ͷŽ���õ�����
    /// </summary>
    procedure ReleaseData(const pvData:Pointer); virtual; abstract;

    /// <summary>
    ///   �����յ�������,����н��յ�����,���ø÷���,���н���
    /// </summary>
    /// <returns>
    ///   0����Ҫ���������
    ///   1: ����ɹ�
    ///  -1: ����ʧ��
    /// </returns>
    /// <param name="inBuf"> ���յ��������� </param>
    function Decode(): Integer;  virtual; abstract;

  end;

  TDiocpDecoderClass = class of TDiocpDecoder;

implementation

constructor TDiocpDecoder.Create;
begin
  inherited;
end;

procedure TDiocpDecoder.SetContext(const pvContext:TObject);
begin
  FContext := pvContext;
end;

{ TDiocpEncoder }

procedure TDiocpEncoder.SetContext(const pvContext: TObject);
begin
  FContext := pvContext;
end;

end.
