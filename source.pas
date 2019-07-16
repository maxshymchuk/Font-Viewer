uses
  SysUtils;

type
  TArray = array of string;

var
  info: TSearchRec;
  fSize, i, fontNum: longint;
  currentHTML, currentCSS: text;
  currentLetter: char;
  fonts, content: TArray;
  fvDir: string;

function getFileName(s: string): string;
var
  i: longint;
begin
  Result := '';
  for i := length(s) downto 1 do begin
    if s[i] = '/' then exit;
    Result := s[i] + Result;
  end;
end;

procedure quickSort(var a: array of string; l, r: longint);
var
  i, j: longint;
  k, temp: string;
begin
  i := l;
  j := r;
  k := upperCase(getFileName(a[(i+j) shr 1]));
  repeat
    while upperCase(getFileName(a[i])) < k do
      i := i + 1;
    while upperCase(getFileName(a[j])) > k do
      j := j - 1;
    if i <= j then
      begin
        temp := a[i];
        a[i] := a[j];
        a[j] := temp;
        i := i + 1;
        j := j - 1;
      end;
  until i > j;
  if i < r then quickSort(a, i, r);
  if j > l then quickSort(a, l, j);
end;

function checkExt(str: string): boolean;
var
  exts: array[0..1] of string = ('.ttf', '.otf');
  i, j: longint;
begin
  CheckExt := false;
  for i := length(str) downto 1 do
    if str[i] = '.' then
      for j := 0 to 1 do
        if str[i..length(str)] = exts[j] then
          begin
            CheckExt := true;
            Exit;
          end;
end;

function push(arr: array of string; num: string): TArray;
var
  temp: array of string;
  i: longint;
begin
  SetLength(temp, length(arr) + 1);
  for i := 0 to high(arr) do
    temp[i] := arr[i];
  temp[high(temp)] := num;
  Result := temp;
end;

function find(l: char; a: array of string): longint;
var
  i: longint;
begin
  Result := -1;
  for i := 0 to high(a) do
    if a[i, 1] = l then begin
      Result := i;
      exit;
    end;
end;

function upCase(l: char): char;
begin
  Result := l;
  if ord(l) in [97..122] then
    Result := chr(ord(l) - 32);
end;

function checkLetter(l: char): char;
begin
  l := upCase(l);
  Result := '#';
  if ord(l) in [65..90] then
    Result := l;
end;

function isDirCreated(): boolean;
begin
  Result := false;
  try
    mkdir(fvDir);
    mkdir(fvDir + '/pages');
  except
    writeln('ERROR: Can''t write on disk!');
    readln;
    halt;
  end;
  Result := true;
end;

procedure createFile(n: byte);
begin
  if n = 0 then
    assign(currentHTML, fvDir + '/index.html')
  else
    assign(currentHTML, fvDir + '/pages/' + currentLetter + '.html');
end;

function initHTML(n: longint): string;
var
  path: string = '../';
  function checkName(n: longint):string;
  begin
    Result := currentLetter;
    if n = 0 then
      Result := 'index';
  end;
begin
  if n = 0 then
    path := '';
  Result :=
    '<!DOCTYPE html>' + #13 +
    '<html lang="">' + #13 +
    '<head>' + #13 +
    '<meta http-equiv="content-language" content="en">' + #13 +
    '<meta charset="utf-8">' + #13 +
    '<title>FontViewer "' + checkName(n) + '.html"</title>' + #13 +
    '<link rel="stylesheet" href="' + path + 'style.css">' + #13 +
    '</head>' + #13 +
    '<body>';
end;

function getFontList(): string;
var
  temp: string;
  i: longint;
begin
  for i := 0 to high(fonts) do
    temp := temp +
      '@font-face{font-family:' + getFileName(fonts[i][1..length(fonts[i]) - 4]) + ';src:url("../' + fonts[i] + '")}' + #13;
  Result := temp;
end;

function getMenu(n: longint): string;
var
  i: longint;
  temp: string = '<div class="menu">' + #13;
  function checkFilePath(i, n: longint): string;
  begin
    if n = 0 then begin
      if i = 0 then
        Result := 'index'
      else
        Result := 'pages/' + content[i]
    end else begin
      if i = 0 then
        Result := '../index'
      else
        Result := content[i];
    end;
  end;
  function isSelected(): string;
  begin
    Result := '';
    if content[i] = currentLetter then
      Result := ' style="color:#FF0000"';
  end;
begin
  for i := 0 to high(content) do
    temp := temp + '<a href="' + checkFilePath(i, n) + '.html"' + isSelected() + '>' + content[i] + '</a>' + #13;
  Result := temp + '</div>';
end;

function getContent(n: longint): string;
var
  fName, fNameExt, temp: string;
  i: longint;
begin
  i := n;
  temp := '';
  while (i < length(fonts)) and (checkLetter(getFileName(fonts[i])[1]) = currentLetter) do begin
    fNameExt := getFileName(fonts[i]);
    fName := fNameExt[1..length(fNameExt) - 4];
    temp := temp +
      '<div class="panel" title="' + fonts[i] + '">' + #13 +
      '<input type="checkbox" id="checkbox' + IntToStr(i) + '">' + #13 +
      '<label class="checkbox" for="checkbox' + IntToStr(i) + '">' + #13 +
      '<div class="marker">▼</div>' + #13 +
      '<div style="font-family: ' + fName + '">' + fNameExt + '</div>' + #13 +
      '<div style="font-family: ' + fName + '">!&quot;#$%&amp;&#39;()*+,-./0123456789:;&lt;=&gt;?@</div>' + #13 +
      '<div style="font-family: ' + fName + '">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz</div>' + #13 +
      '<input style="font-family: ' + fName + '" type="text" class="inputText" placeholder="Type something...">' + #13 +
      '</label>' + #13 +
      '</div>' + #13;
    i := i + 1;
  end;
  fontNum := i;
  Result := temp;
end;

procedure FindFonts(dir: string);
var
  SR: TSearchRec;
  FindRes: longint;
  letter: char;
begin
  FindRes := FindFirst(dir + '*.*', faAnyFile, SR);
  while FindRes = 0 do begin
    if ((SR.Attr and faDirectory) = faDirectory) and ((SR.name = '.') or (SR.name = '..')) then begin
      FindRes := FindNext(SR);
      Continue;
    end;
    if ((SR.Attr and faDirectory) = faDirectory) then begin
      FindFonts(dir + SR.name + '/');
      FindRes := FindNext(SR);
      Continue;
    end;
    if CheckExt(SR.name) then begin
      letter := checkLetter(SR.name[1]);
      if find(letter, content) = -1 then
        content := push(content, letter);
      fonts := push(fonts, dir + SR.name);
      FindRes := FindNext(SR);
      Continue;
    end;
    FindRes := FindNext(SR);
  end;
  FindClose(SR);
end;

function getCSS(): string;
begin
  Result :=
    'html{font-size:' + IntToStr(fSize) + 'px;font-family:ARIAL}' + #13 +
    'body{padding-top:2rem;height:100%;margin:0;cursor:default;background-color:#FFF}' + #13 +
    '.panel{clear:both}' + #13 +
    '.panel > input{display:none}' + #13 +
    '.panel input:checked + .checkbox{height:8rem;box-shadow:0 3px 10px 0 rgba(0,0,0,.2)}' + #13 +
    '.panel input:checked + .checkbox .marker{transform: rotate(180deg)}' + #13 +
    '.checkbox{padding:0 20px;display:block;height:2rem;line-height:2rem;overflow: hidden;transition:all 0.3s ease-in-out}' + #13 +
    '.marker{font-size:.5em;float:right;margin-top:1.5em;width:1em;line-height:1em;transition:transform 0.3s ease-in-out}' + #13 +
    '.inputText{background:none;width:75%;font-size:1rem;padding-bottom:.1rem;border:0;border-bottom:1px solid #000;height:1rem}' + #13 +
    '.menu{box-shadow:0 3px 10px 0 rgba(0,0,0,.2);background-color:#FFF;position:fixed;top:0;left:0;right:0;display:flex;justify-content:center;align-items:center;flex-wrap:wrap;min-height:40px}' + #13 +
    '.menu > a{font-size:20px;display:inline-block;color:#000;text-decoration:none;padding:0 10px;transition:color 0.3s ease-in-out}' + #13 +
    '.menu > a:hover{color:#FF0000}';
end;

begin
  fvDir := '!FontViewer';
  fontNum := 0;
  setLength(fonts, 0);
  setLength(content, 0);
  currentLetter := #0;
  writeln('Font Viewer');
  writeln;
  repeat
    write('Font Size (px): ');
    readln(fSize);
  until fSize > 0;
  writeln;
  write('Searching');
  FindFonts('');
  FindClose(info);
  writeln;
  writeln;
  if (length(fonts) > 0) and (isDirCreated()) then begin
    write('Sorting');
    quickSort(fonts, 0, high(fonts));
    quickSort(content, 0, high(content));
    writeln;
    for i := 0 to high(content) do begin
      currentLetter := content[i, 1];
      createFile(i);
      rewrite(currentHTML);
      writeln(currentHTML, initHTML(i));
      writeln(currentHTML, getMenu(i));
      writeln(currentHTML, getContent(fontNum));
      writeln(currentHTML, '</body>', #13, '</html>');
      close(currentHTML);
    end;
    assign(currentCSS, fvDir + '/style.css');
    rewrite(currentCSS);
    writeln(currentCSS, getFontList());
    write(currentCSS, getCSS());
    close(currentCSS);
    writeln;
    writeln(length(fonts), ' fonts found');
    writeln;
    write('>> ' + fvDir + '/index.html');
  end else write('Fonts not found');
  readln;
end.

