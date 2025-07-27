unit WebModuleUnit1;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp,
  Data.Win.ADODB, Data.DB;

type
  TWebModule1 = class(TWebModule)
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModuleCreate(Sender: TObject);
  private
    ADOConnection1: TADOConnection;
    ADOQueryDoctors: TADOQuery;
    ADOQueryPatients: TADOQuery;
    ADOQueryBooking: TADOQuery;

    procedure WebModuleBookingHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  public
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TWebModule1.WebModuleCreate(Sender: TObject);
begin
  ADOConnection1 := TADOConnection.Create(Self);
  ADOConnection1.LoginPrompt := False;
  ADOConnection1.ConnectionString :=
  'Provider=SQLOLEDB.1;' +
  'Integrated Security=SSPI;' +  // ���������� Windows-��������������
  'Data Source=DESKTOP-PSECSVQ\SQLEXPRESS;' +  // ��������, localhost ��� localhost\SQLEXPRESS
  'Initial Catalog=DoctorBookingDB;';

  ADOConnection1.Connected := True;

  ADOQueryDoctors := TADOQuery.Create(Self);
  ADOQueryDoctors.Connection := ADOConnection1;

  ADOQueryPatients := TADOQuery.Create(Self);
  ADOQueryPatients.Connection := ADOConnection1;

  ADOQueryBooking := TADOQuery.Create(Self);
  ADOQueryBooking.Connection := ADOConnection1;
end;

procedure TWebModule1.WebModuleBookingHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  doctorID, patientID: Integer;
  patientName, patientPhone: string;
  html: string;
begin
  if Request.Method = 'POST' then
  begin
    doctorID := StrToIntDef(Request.ContentFields.Values['doctorid'], 0);
    patientName := Request.ContentFields.Values['patientname'];
    patientPhone := Request.ContentFields.Values['patientphone'];

    if (doctorID = 0) or (patientName = '') or (patientPhone = '') then
    begin
      Response.Content := '<html><body><h2>������: ��������� ��� ����.</h2></body></html>';
      Response.ContentType := 'text/html';
      Handled := True;
      Exit;
    end;

    // ����� ��������
    ADOQueryPatients.Close;
    ADOQueryPatients.SQL.Text := 'SELECT ID_�������� FROM �������� WHERE ���_�������� = :name AND ������� = :phone';
    ADOQueryPatients.Parameters.ParamByName('name').Value := patientName;
    ADOQueryPatients.Parameters.ParamByName('phone').Value := patientPhone;
    ADOQueryPatients.Open;

    if ADOQueryPatients.Eof then
    begin
      // ����� �������
      ADOQueryPatients.Close;
      ADOQueryPatients.SQL.Text := 'INSERT INTO �������� (���_��������, �������) VALUES (:name, :phone)';
      ADOQueryPatients.Parameters.ParamByName('name').Value := patientName;
      ADOQueryPatients.Parameters.ParamByName('phone').Value := patientPhone;
      ADOQueryPatients.ExecSQL;

      // ��������� ID ������ ��������
      ADOQueryPatients.Close;
      ADOQueryPatients.SQL.Text := 'SELECT ID_�������� FROM �������� WHERE ���_�������� = :name AND ������� = :phone';
      ADOQueryPatients.Parameters.ParamByName('name').Value := patientName;
      ADOQueryPatients.Parameters.ParamByName('phone').Value := patientPhone;
      ADOQueryPatients.Open;
    end;

    patientID := ADOQueryPatients.FieldByName('ID_��������').AsInteger;

    // ���������� ������
    ADOQueryBooking.Close;
    ADOQueryBooking.SQL.Text := 'INSERT INTO ������ (ID_�����, ID_��������) VALUES (:doctorID, :patientID)';
    ADOQueryBooking.Parameters.ParamByName('doctorID').Value := doctorID;
    ADOQueryBooking.Parameters.ParamByName('patientID').Value := patientID;
    ADOQueryBooking.ExecSQL;

    Response.Content :=
      '<html><body><h2>������ ������� ���������!</h2>' +
      '<a href="/">��������� �� �������</a></body></html>';
    Response.ContentType := 'text/html';
    Handled := True;
    Exit;
  end;

  // GET-������ � �������� �����
  doctorID := StrToIntDef(Request.QueryFields.Values['id'], 0);
  if doctorID = 0 then
  begin
    Response.Content := '<html><body><h2>������: �� ������ ����.</h2></body></html>';
    Response.ContentType := 'text/html';
    Handled := True;
    Exit;
  end;

  html :=
    '<html><body>' +
    Format('<h1>������ � ����� #%d</h1>', [doctorID]) +
    '<form method="POST" action="/booking">' +
    Format('<input type="hidden" name="doctorid" value="%d">', [doctorID]) +
    '��� ��������: <input type="text" name="patientname"><br>' +
    '������� ��������: <input type="text" name="patientphone"><br>' +
    '<input type="submit" value="����������">' +
    '</form>' +
    '</body></html>';

  Response.Content := html;
  Response.ContentType := 'text/html';
  Handled := True;
end;

procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  if Request.PathInfo.StartsWith('/booking') then
  begin
    WebModuleBookingHandlerAction(Sender, Request, Response, Handled);
    Exit;
  end;

  Response.Content :=
    '<html><head><title>������ ������</title></head><body>' +
    '<h1>������ ������</h1><ul>';

  ADOQueryDoctors.Close;
  ADOQueryDoctors.SQL.Text := 'SELECT ID_�����, ���_�����, ������������� FROM �����';
  ADOQueryDoctors.Open;

  while not ADOQueryDoctors.Eof do
  begin
    Response.Content := Response.Content + Format(
      '<li>%s � %s � <a href="/booking?id=%d">����������</a></li>',
      [ADOQueryDoctors.FieldByName('���_�����').AsString,
       ADOQueryDoctors.FieldByName('�������������').AsString,
       ADOQueryDoctors.FieldByName('ID_�����').AsInteger]);
    ADOQueryDoctors.Next;
  end;

  Response.Content := Response.Content + '</ul></body></html>';
  Response.ContentType := 'text/html';
  Handled := True;
end;

end.
