unit AES;

interface
uses
  Windows, SysUtils, Classes, ElAES, math;

  function AESEncryptStr(strIn: string; AESKey: AnsiString): string;
  function AESDecyptStr(strIn: string; AESKey: AnsiString): string;

  procedure AESEncryptStream(StreamIn, StreamOut: TMemoryStream; AESKey: AnsiString);
  procedure AESDecyptStream(StreamIn, StreamOut: TMemoryStream; AESKey: AnsiString);

implementation

function StreamToHex(AStream: TMemoryStream): string;
var
  i: integer;
  p: PByte;
begin
  Result := '';
  // Go throught every single characters, and convert them
  // to hexadecimal...
  p := PByte(AStream.Memory);
  for i := 1 to AStream.Size do
  begin
    Result := Result + IntToHex( p^, 2 );
    Inc(p);
  end;
end;

procedure HexToStream(S: string; AStream: TMemoryStream);
var
  i: integer;
  p: Byte;
begin
  // Go throught every single hexadecimal characters, and convert
  // them to ASCII characters...
  AStream.Size := Length(S) div 2;
  AStream.Position := 0;

  for i := 1 to Length(S) do
  begin
    // Only process chunk of 2 digit Hexadecimal...
    if ((i mod 2) = 1) then
    begin
      p := StrToInt( '0x' + Copy( S, i, 2 ));
      AStream.WriteBuffer(p, 1);
    end;
  end;

  AStream.Position := 0;
end;

function AESEncryptStr(strIn: string; AESKey: AnsiString): string;
var
  Source: TMemoryStream;
  Dest: TMemoryStream;
  Key: TAESKey128;
begin
  // Encryption
  Source := TMemoryStream.Create();
  Dest := TMemoryStream.Create();
  try
    // Build Source
    Source.Size := SizeOf(Char) * (Length(strIn) + 1);
    Source.Position := 0;
    CopyMemory(Source.Memory, PChar(strIn), SizeOf(Char) * (Length(strIn) + 1));

    // Prepare key...
    FillChar( Key, SizeOf(Key), 0 );
    Move( PAnsiChar(AESKey)^, Key, Min( SizeOf( Key ), Length( AESKey)));

    // Start encryption...
    EncryptAESStreamECB( Source, 0, Key, Dest );

    // Display encrypted text using hexadecimals...
	  Result := StreamToHex(Dest);
  finally
    Source.Free;
    Dest.Free;
  end;
end;

function AESDecyptStr(strIn: string; AESKey: AnsiString): string;
var
  Source: TMemoryStream;
  Dest: TMemoryStream;
  Start, Stop: cardinal;
  Key: TAESKey128;
  EncryptedText: TStrings;
  S: AnsiString;
begin
  // Convert hexadecimal to a strings before decrypting...
  Source := TMemoryStream.Create();
  Dest := TMemoryStream.Create();
  try
    HexToStream(strIn, Source);

    // Prepare key...
    FillChar(Key, SizeOf(Key), 0);
    Move(PAnsiChar(AESKey)^, Key, Min(SizeOf(Key), Length(AESKey)));

    // Decrypt now...
    DecryptAESStreamECB(Source, 0, Key, Dest);

    // Display unencrypted text...
    Result := PChar(Dest.Memory);
  finally
    Source.Free;
    Dest.Free;
  end;
end;

procedure AESEncryptStream(StreamIn, StreamOut: TMemoryStream; AESKey: AnsiString);
var
  Key: TAESKey128;
begin
  // Prepare key...
  FillChar( Key, SizeOf(Key), 0 );
  Move(PAnsiChar(AESKey)^, Key, Min( SizeOf( Key ), Length( AESKey)));

  // Start encryption...
  EncryptAESStreamECB( StreamIn, 0, Key, StreamOut );
end;

procedure AESDecyptStream(StreamIn, StreamOut: TMemoryStream; AESKey: AnsiString);
var
  Key: TAESKey128;
begin
  // Prepare key...
  FillChar( Key, SizeOf(Key), 0 );
  Move(PAnsiChar(AESKey)^, Key, Min( SizeOf( Key ), Length( AESKey)));

  // Decrypt now...
  DecryptAESStreamECB(StreamIn, 0, Key, StreamOut);
end;

end.
