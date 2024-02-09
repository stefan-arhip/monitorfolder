unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ComObj, Variants, EditBtn, IniPropStorage, Spin, Clipbrd, LCLVersion;

type

  { TfMain }

  TfMain = class(TForm)
    fsFileSizeMax: TFloatSpinEdit;
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    laCPUTarget: TLabel;
    laFPC: TLabel;
    laLazarus: TLabel;
    ListView1: TListView;
    meRecipients: TMemo;
    MonitorizedFolder: TDirectoryEdit;
    PageControl1: TPageControl;
    SmtpAuthenticate: TCheckBox;
    SmtpConnectionTimeout: TSpinEdit;
    SmtpPassword: TEdit;
    SmtpSender: TEdit;
    SmtpSendUsing: TSpinEdit;
    SmtpServerName: TEdit;
    SmtpServerPort: TSpinEdit;
    SmtpSsl: TCheckBox;
    SmtpUsername: TEdit;
    seFileCountMax: TSpinEdit;
    StatusBar1: TStatusBar;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    tbCards: TToolBar;
    tbEmail: TToolButton;
    tbSearch: TToolButton;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tbEmailClick(Sender: TObject);
    procedure tbSearchClick(Sender: TObject);
  private
    { private declarations }
    Path: string;
    FilesCount, FilesSize: int64;
  public
    { public declarations }
  end;

var
  fMain: TfMain;

implementation

{$R *.lfm}

{ TfMain }

procedure TfMain.tbSearchClick(Sender: TObject);
var
  sR: TSearchRec;
begin
  ListView1.Items.Clear;
  Path := IncludeTrailingBackslash(MonitorizedFolder.Text);
  FilesCount := 0;
  FilesSize := 0;
  if FindFirst(Path + '*.*', faAnyFile - faDirectory, sR) = 0 then
  try
    repeat
      with ListView1.Items.Add do
      begin
        //sL.Add(Path+ sR.Name);
        Caption := IntToStr(ListView1.Items.Count);
        SubItems.Add(sR.Name);
        SubItems.Add(Format('%f', [sR.Size / 1024 / 1024]));
        SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn',
          FileDateToDateTime(sR.Time)));
      end;
      Inc(FilesCount);
      FilesSize := FilesSize + sR.Size;
    until FindNext(sR) <> 0;
  finally
    FindClose(sR);
  end;

  StatusBar1.Panels[0].Text := Format('%d files', [FilesCount]);
  StatusBar1.Panels[1].Text := Format('%f MB', [FilesSize / 1024 / 1024]);
  tbEmail.Enabled := True;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  fMain.laLazarus.Caption := 'Lazarus: ' + lcl_version;
  fMain.laFPC.Caption := 'FPC: ' + {$I %FPCVersion%};
  fMain.laCPUTarget.Caption := 'CPU Target: ' + {$I %FPCTarget%};

  PageControl1.PageIndex := 0;
  ListView1.Items.Clear;
  StatusBar1.Panels[0].Text := '';
  StatusBar1.Panels[1].Text := '';
  StatusBar1.Panels[2].Text := '';
end;

procedure TfMain.FormActivate(Sender: TObject);
var
  b: boolean;
begin
  if (ParamCount = 1) and (ParamStr(1) = 'automat') then
  begin
    tbSearchClick(Sender);
    b := False;
    b := b or (FilesSize / 1024 / 1024 / 1024 >= fsFileSizeMax.Value);
    b := b or (FilesCount >= seFileCountMax.Value);
    if b then
      tbEmailClick(Sender);
    Application.Terminate;
  end;
end;

procedure TfMain.tbEmailClick(Sender: TObject);
const
  Cdo = 'http://schemas.microsoft.com/cdo/configuration/';
var
  Email, _EmailBody: olevariant;
  _Style: shortstring;
  i, j: integer;
begin
  if not tbEmail.Enabled then
    Exit;

  Email := ComObj.CreateOleObject('CDO.Message');
  Email.From := shortstring(SmtpSender.Text);
  Email.&To := '';
  for i := 1 to meRecipients.Lines.Count do
    Email.&To := Email.&To + shortstring(meRecipients.Lines[i - 1] + ';');
  //Email.CC:= '';
  //Email.BCC:= '';
  Email.Subject := shortstring(Format('%s - [%d files, %f MB]',
    [fMain.Caption, FilesCount, FilesSize / 1024 / 1024]));

  _EmailBody := '<html><head>' + '<Style Type="Text/Css">'#13 +
    '<!--'#13 + 'table,th,td {'#13 + 'border:1px solid #000000;'#13 +
    'border-collapse: collapse;'#13 + 'padding:2px;'#13 +
    'text-align:left;'#13 + 'width:1px;'#13 + 'white-space:nowrap;}'#13 +
    'p.title{Font-Family:Arial;Font-Size:10pt;Font-Weight:900;Color:#ff0000}'#13 +
    'td.title{Font-Family:Arial;Font-Size:10pt;Font-Weight:900;Color:#000000;background-color:#99bfff;text-align:center}'#13
    + 'td.odd{Font-Family:Arial;Font-Size:10pt;Font-Weight:000;Color:#000000;background-color:#d5faff;text-align:right}'#13 + 'td.even{Font-Family:Arial;Font-Size:10pt;Font-Weight:000;Color:#000000;background-color:#fffff;text-align:right}'#13 + 'p.legend{Font-Family:Arial;Font-Size:10pt;Font-Weight:000;font-style:italic;Color:#cccccc}'#13 + '-->'#13 + '</Style>'#13 + '</head><body>'#13;

  _EmailBody := _EmailBody + shortstring(
    Format('<b><p class="title">%d files with size %f MB in folder <b>%s</b></p></b>'#13,
    [FilesCount, FilesSize / 1024 / 1024, MonitorizedFolder.Text]));
  _EmailBody := _EmailBody + shortstring('<table width=100%>'#13);

  _EmailBody := _EmailBody + shortstring('<tr>'#13);
  for j := 1 to ListView1.ColumnCount do
    _EmailBody := _EmailBody +
      shortstring(Format('<td class="title">%s</td>'#13,
      [ListView1.Column[j - 1].Caption]));
  _EmailBody := _EmailBody + shortstring('</tr>'#13);

  for i := 1 to ListView1.Items.Count do
  begin
    if Odd(i) then
      _Style := 'odd'
    else
      _Style := 'even';
    _EmailBody := _EmailBody +
      shortstring(Format('<tr><td class="%s">%d</td>'#13, [_Style, i]));
    for j := 1 to ListView1.ColumnCount - 1 do
      _EmailBody := _EmailBody +
        shortstring(Format('<td class="%s">%s</td>'#13,
        [_Style, ListView1.Items[i - 1].SubItems[j - 1]]));
    _EmailBody := _EmailBody + shortstring('</tr>'#13);
  end;
  _EmailBody := _EmailBody + shortstring('</table><br><br>'#13);

  _EmailBody := _EmailBody + shortstring(
    '<p class="legend">Email sent from Monitor Folder created by Stefan ARHIP</p>' +
    '</body></html>');
  Email.HtmlBody := _EmailBody;

  Email.Configuration.Fields.Item(Cdo + 'sendusing') := SmtpSendUsing.Value;
  Email.Configuration.Fields.Item(Cdo + 'smtpserver') :=
    shortstring(SmtpServerName.Text);
  Email.Configuration.Fields.Item(Cdo + 'smtpserverport') := SmtpServerPort.Value;
  Email.Configuration.Fields.Item(Cdo + 'smtpusessl') := SmtpSsl.Checked;
  Email.Configuration.Fields.Item(Cdo + 'smtpauthenticate') :=
    SmtpAuthenticate.Checked;
  Email.Configuration.Fields.Item(Cdo + 'sendusername') :=
    shortstring(SmtpUsername.Text);
  Email.Configuration.Fields.Item(Cdo + 'sendpassword') :=
    shortstring(SmtpPassword.Text);
  Email.Configuration.Fields.Item(Cdo + 'smtpconnectiontimeout') :=
    SmtpConnectionTimeout.Value;
  Email.Configuration.Fields.Update;

  try
    Email.Send;
    StatusBar1.Panels[2].Text := '  message sent';
  except
    StatusBar1.Panels[2].Text := '  error trying to send message';
  end;
end;

end.
