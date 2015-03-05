(*
 *	 Unit owner: d10.�����
 *	       blog: http://www.cnblogs.com/dksoft
 *     homePage: www.diocp.org
 *
 *   2015-03-05 12:53:38
 *     �޸�URLEncode��URLDecode��Anddriod��UNICODE�µ��쳣
 *
 *   2015-02-22 08:29:43
 *     DIOCP-V5 ����
 *
 *)
 
unit utils.strings;

interface

uses
  Classes, SysUtils;

type
{$IFDEF MSWINDOWS}  // Windowsƽ̨�������ʹ��AnsiString
  URLString = AnsiString;
  URLChar = AnsiChar;
{$ELSE}
  // andriod����ʹ��
  URLString = String;
  URLChar = Char;
  {$DEFINE UNICODE_URL}
{$ENDIF}


/// <summary>
///   �����ַ�
/// </summary>
/// <returns>
///   �����������ַ�
/// </returns>
/// <param name="p"> ��ʼ���λ�� </param>
/// <param name="pvChars"> ������Щ�ַ���ֹͣ��Ȼ�󷵻� </param>
function SkipUntil(var p:PChar; pvChars: TSysCharSet): Integer;


/// <summary>
///   �����ַ�
/// </summary>
/// <returns> Integer
/// </returns>
/// <param name="p"> (PChar) </param>
/// <param name="pvChars"> (TSysCharSet) </param>
function SkipChars(var p:PChar; pvChars: TSysCharSet): Integer;


/// <summary>
///   ����߿�ʼ��ȡ�ַ�
/// </summary>
/// <returns> Integer
/// </returns>
/// <param name="p"> (PChar) </param>
/// <param name="pvChars"> (TSysCharSet) </param>
function LeftUntil(var p:PChar; pvChars: TSysCharSet): string;

/// <summary>
///   ����SpliterChars���ṩ���ַ������зָ��ַ��������뵽Strings��
///     * �����ַ�ǰ��Ŀո�
/// </summary>
/// <returns>
///   ���طָ�ĸ���
/// </returns>
/// <param name="s"> Դ�ַ��� </param>
/// <param name="pvStrings"> ��������ַ����б� </param>
/// <param name="pvSpliterChars"> �ָ��� </param>
function SplitStrings(s:String; pvStrings:TStrings; pvSpliterChars
    :TSysCharSet): Integer;

/// <summary>
///   URL���ݽ���,
///    Get��Post�����ݶ�������url����
/// </summary>
/// <returns>
///   ���ؽ�����URL����
/// </returns>
/// <param name="ASrc"> ԭʼ���� </param>
/// <param name="pvIsPostData"> Post��ԭʼ������ԭʼ�Ŀո񾭹�UrlEncode����+�� </param>
function URLDecode(const ASrc: URLString; pvIsPostData: Boolean = true):URLString;

/// <summary>
///  �����ݽ���URL����
/// </summary>
/// <returns>
///   ����URL����õ�����
/// </returns>
/// <param name="S"> ��Ҫ��������� </param>
/// <param name="pvIsPostData"> Post��ԭʼ������ԭʼ�Ŀո񾭹�UrlEncode����+�� </param>
function URLEncode(S: string; pvIsPostData: Boolean = true): URLString;



implementation

{$if CompilerVersion < 20}
function CharInSet(C: Char; const CharSet: TSysCharSet): Boolean;
begin
  Result := C in CharSet;
end;
{$ifend}


function SkipUntil(var p:PChar; pvChars: TSysCharSet): Integer;
var
  ps: PChar;
begin
  ps := p;
  while p^ <> #0 do
  begin
    if CharInSet(p^, pvChars) then
      Break
    else
      Inc(P);
  end;
  Result := p - ps;
end;

function LeftUntil(var p:PChar; pvChars: TSysCharSet): string;
var
  ps: PChar;
  l:Integer;
begin
  ps := p;
  while p^ <> #0 do
  begin
    if CharInSet(p^, pvChars) then
      Break
    else
      Inc(P);
  end;
  l := p-ps;
  if l = 0 then
  begin
    Result := '';
  end else
  begin
    SetLength(Result, l);
    if SizeOf(Char) = 1 then
    begin
      Move(ps^, PChar(Result)^, l);
    end else
    begin
      l := l shl 1;
      Move(ps^, PChar(Result)^, l);
    end;
  end;
end;

function SkipChars(var p:PChar; pvChars: TSysCharSet): Integer;
var
  ps: PChar;
begin
  ps := p;
  while p^ <> #0 do
  begin
    if CharInSet(p^, pvChars) then
      Inc(P)
    else
      Break;
  end;
  Result := p - ps;
end;


function SplitStrings(s:String; pvStrings:TStrings; pvSpliterChars
    :TSysCharSet): Integer;
var
  p:PChar;
  lvValue : String;
begin
  p := PChar(s);
  Result := 0;
  while True do
  begin
    // �����հ�
    SkipChars(p, [' ']);
    lvValue := LeftUntil(P, pvSpliterChars);
    if lvValue = '' then exit;
    // �����ָ���
    SkipChars(p, pvSpliterChars);

    // ��ӵ��б���
    pvStrings.Add(lvValue);
    inc(Result);
  end;
end;


function URLDecode(const ASrc: URLString; pvIsPostData: Boolean = true): URLString;
var
  i, j: integer;
  {$IFDEF UNICODE_URL}
  lvRawBytes:TBytes;
  lvSrcBytes:TBytes;
  {$ENDIF}
begin

  {$IFDEF UNICODE_URL}
  SetLength(lvRawBytes, Length(ASrc));   // Ԥ������һ���ַ���������־
  lvSrcBytes := TEncoding.ANSI.GetBytes(ASrc);
  j := 0;  // ��0��ʼ
  i := 0;
  while i <= Length(ASrc) do
  begin
    if (pvIsPostData) and (lvSrcBytes[i] = 43) then   //43(+) �ű�ɿո�, Post��ԭʼ����������� �ո�ʱ���� +��
    begin
      lvRawBytes[j] := 32; // Ord(' ');
    end else if lvSrcBytes[i] <> 37 then      //'%' = 37
    begin
      lvRawBytes[j] :=lvSrcBytes[i];
    end else
    begin
      Inc(i); // skip the % char
      try
      lvRawBytes[j] := StrToInt('$' +URLChar(lvSrcBytes[i]) + URLChar(lvSrcBytes[i+1]));
      except end;
      Inc(i, 1);  // ������һ���ַ�.

    end;
    Inc(i);
    Inc(j);
  end;
  SetLength(lvRawBytes, j);
  Result := TEncoding.ANSI.GetString(lvRawBytes);
  {$ELSE}
  SetLength(Result, Length(ASrc));   // Ԥ������һ���ַ���������־
  j := 1;  // ��1��ʼ
  i := 1;
  while i <= Length(ASrc) do
  begin
    if (pvIsPostData) and (ASrc[i] = '+') then   // + �ű�ɿո�, Post��ԭʼ����������� �ո�ʱ���� +��
    begin
      Result[j] := ' ';
    end else if ASrc[i] <> '%' then
    begin
      Result[j] := ASrc[i];
    end else 
    begin
      Inc(i); // skip the % char
      try
      Result[j] := URLChar(StrToInt('$' + ASrc[i] + ASrc[i+1]));
      except end;
      Inc(i, 1);  // ������һ���ַ�.

    end;
    Inc(i);
    Inc(j);
  end;
  SetLength(Result, j - 1);
  {$ENDIF}

end;




function URLEncode(S: string; pvIsPostData: Boolean = true): URLString;
var
  i: Integer; // loops thru characters in string
  {$IFDEF UNICODE_URL}
  lvRawBytes:TBytes;
  {$ENDIF}
begin
  {$IFDEF UNICODE_URL}
  lvRawBytes := TEncoding.ANSI.GetBytes(S);
  for i := 0 to Length(lvRawBytes) - 1 do
  begin
    case lvRawBytes[i] of
      //'A' .. 'Z', 'a'.. 'z', '0' .. '9', '-', '_', '.':
      65..90, 97..122, 48..57, 45, 95, 46:
        Result := Result + URLChar(lvRawBytes[i]);
      //' ':
      32:
        if pvIsPostData then
        begin     // Post��������ǿո���Ҫ����� +
          Result := Result + '+';
        end else
        begin
          Result := Result + '%20';
        end
    else
      Result := Result + '%' + SysUtils.IntToHex(lvRawBytes[i], 2);
    end;
  end;
  {$ELSE}
  Result := '';
  for i := 1 to Length(S) do
  begin
    case S[i] of
      'A' .. 'Z', 'a' .. 'z', '0' .. '9', '-', '_', '.':
        Result := Result + S[i];
      ' ':
        if pvIsPostData then
        begin     // Post��������ǿո���Ҫ����� +
          Result := Result + '+';
        end else
        begin
          Result := Result + '%20';
        end
    else
      Result := Result + '%' + SysUtils.IntToHex(Ord(S[i]), 2);
    end;
  end;
  {$ENDIF}
end;

end.
