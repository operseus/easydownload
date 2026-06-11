program EasyDownload;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // LCL widgetset
  Forms,
  applang,
  engine,
  themebtn,
  thememanager,
  updater,
  main,
  settingsform;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'EasyDownload';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
