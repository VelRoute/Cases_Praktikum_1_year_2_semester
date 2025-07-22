BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "Вид транспорта" (
	"ID транспорта"	INTEGER,
	"Вид Транспорта"	TEXT,
	"Название Компании"	TEXT,
	PRIMARY KEY("ID транспорта" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "Клиенты" (
	"ID клиента"	INTEGER,
	"Имя клиента"	TEXT,
	"Телефон"	TEXT,
	"E-mail"	TEXT,
	PRIMARY KEY("ID клиента" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "Отели" (
	"ID отеля"	INTEGER,
	"Название отеля"	TEXT,
	"Количество звезд"	INTEGER,
	"Город расположения"	TEXT,
	PRIMARY KEY("ID отеля" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "Направления" (
	"ID направления"	INTEGER,
	"Название направления"	TEXT,
	"Страна направления"	TEXT,
	PRIMARY KEY("ID направления" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "Заказы" (
	"ID заказа"	INTEGER,
	"ID клиента"	INTEGER,
	"ID отеля"	INTEGER,
	"ID направления"	INTEGER,
	"ID транспорта"	INTEGER,
	FOREIGN KEY("ID направления") REFERENCES "Направления"("ID направления"),
	FOREIGN KEY("ID транспорта") REFERENCES "Вид транспорта"("ID транспорта"),
	FOREIGN KEY("ID отеля") REFERENCES "Отели"("ID отеля"),
	FOREIGN KEY("ID клиента") REFERENCES "Клиенты"("ID клиента"),
	PRIMARY KEY("ID заказа" AUTOINCREMENT)
);
COMMIT;
