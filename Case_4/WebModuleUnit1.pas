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
  'Integrated Security=SSPI;' +  // используем Windows-аутентификацию
  'Data Source=DESKTOP-PSECSVQ\SQLEXPRESS;' +  // например, localhost или localhost\SQLEXPRESS
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
      Response.Content := '<html><body><h2>Ошибка: заполните все поля.</h2></body></html>';
      Response.ContentType := 'text/html';
      Handled := True;
      Exit;
    end;

    // Поиск пациента
    ADOQueryPatients.Close;
    ADOQueryPatients.SQL.Text := 'SELECT ID_пациента FROM Пациенты WHERE ФИО_пациента = :name AND Телефон = :phone';
    ADOQueryPatients.Parameters.ParamByName('name').Value := patientName;
    ADOQueryPatients.Parameters.ParamByName('phone').Value := patientPhone;
    ADOQueryPatients.Open;

    if ADOQueryPatients.Eof then
    begin
      // Новый пациент
      ADOQueryPatients.Close;
      ADOQueryPatients.SQL.Text := 'INSERT INTO Пациенты (ФИО_пациента, Телефон) VALUES (:name, :phone)';
      ADOQueryPatients.Parameters.ParamByName('name').Value := patientName;
      ADOQueryPatients.Parameters.ParamByName('phone').Value := patientPhone;
      ADOQueryPatients.ExecSQL;

      // Получение ID нового пациента
      ADOQueryPatients.Close;
      ADOQueryPatients.SQL.Text := 'SELECT ID_пациента FROM Пациенты WHERE ФИО_пациента = :name AND Телефон = :phone';
      ADOQueryPatients.Parameters.ParamByName('name').Value := patientName;
      ADOQueryPatients.Parameters.ParamByName('phone').Value := patientPhone;
      ADOQueryPatients.Open;
    end;

    patientID := ADOQueryPatients.FieldByName('ID_пациента').AsInteger;

    // Добавление записи
    ADOQueryBooking.Close;
    ADOQueryBooking.SQL.Text := 'INSERT INTO Запись (ID_врача, ID_пациента) VALUES (:doctorID, :patientID)';
    ADOQueryBooking.Parameters.ParamByName('doctorID').Value := doctorID;
    ADOQueryBooking.Parameters.ParamByName('patientID').Value := patientID;
    ADOQueryBooking.ExecSQL;

    Response.Content :=
      '<html><body><h2>Запись успешно добавлена!</h2>' +
      '<a href="/">Вернуться на главную</a></body></html>';
    Response.ContentType := 'text/html';
    Handled := True;
    Exit;
  end;

  // GET-запрос — показать форму
  doctorID := StrToIntDef(Request.QueryFields.Values['id'], 0);
  if doctorID = 0 then
  begin
    Response.Content := '<html><body><h2>Ошибка: не указан врач.</h2></body></html>';
    Response.ContentType := 'text/html';
    Handled := True;
    Exit;
  end;

  html :=
    '<html><body>' +
    Format('<h1>Запись к врачу #%d</h1>', [doctorID]) +
    '<form method="POST" action="/booking">' +
    Format('<input type="hidden" name="doctorid" value="%d">', [doctorID]) +
    'ФИО пациента: <input type="text" name="patientname"><br>' +
    'Телефон пациента: <input type="text" name="patientphone"><br>' +
    '<input type="submit" value="Записаться">' +
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
    '<html><head><title>Список врачей</title></head><body>' +
    '<h1>Список врачей</h1><ul>';

  ADOQueryDoctors.Close;
  ADOQueryDoctors.SQL.Text := 'SELECT ID_врача, ФИО_врача, Специализация FROM Врачи';
  ADOQueryDoctors.Open;

  while not ADOQueryDoctors.Eof do
  begin
    Response.Content := Response.Content + Format(
      '<li>%s — %s — <a href="/booking?id=%d">Записаться</a></li>',
      [ADOQueryDoctors.FieldByName('ФИО_врача').AsString,
       ADOQueryDoctors.FieldByName('Специализация').AsString,
       ADOQueryDoctors.FieldByName('ID_врача').AsInteger]);
    ADOQueryDoctors.Next;
  end;

  Response.Content := Response.Content + '</ul></body></html>';
  Response.ContentType := 'text/html';
  Handled := True;
end;

end.
