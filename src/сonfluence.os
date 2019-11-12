///////////////////////////////////////////////////////////////////
//
// Модуль интеграции с Confluence (https://ru.atlassian.com/software/confluence)
//
// (с) BIA Technologies, LLC	
//
///////////////////////////////////////////////////////////////////

#Использовать json

///////////////////////////////////////////////////////////////////

// ОписаниеПодключения
//	Создает структуру с набором параметров подключения.
//	Созданная структура в дальнейшем используется для всех операций
// 
// Параметры:
//  АдресСервера  	- Строка - Адрес (URL) сервера confluence. Например "https://conflunece.mydomain.ru"
//  Пользователь	- Строка - Имя пользователя для покдлючения
//  Пароль			- Строка - Пароль пользователя для подключения
//
// Возвращаемое значение:
//   Структура	- описание подключения
//	{
//		Пользователь,
//		Пароль,
//		АдресСервера
//	} 
//
Функция ОписаниеПодключения(АдресСервера = "", Пользователь = "", Пароль = "") Экспорт
	
	ПараметрыПодключения = Новый Структура;
	ПараметрыПодключения.Вставить("Пользователь", Пользователь);
	ПараметрыПодключения.Вставить("Пароль", Пароль);
	ПараметрыПодключения.Вставить("АдресСервера", АдресСервера);
	
	Возврат ПараметрыПодключения;
	
КонецФункции // ОписаниеПодключения()

///////////////////////////////////////////////////////////////////
// СТРАНИЦЫ
///////////////////////////////////////////////////////////////////

// НайтиСтраницуПоИмени
//	Ищет страницу в указанном пространстве по имени
// 
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Имя искомой страницы в указанном пространстве
//
// Возвращаемое значение:
//   Строка   - Идентификатор найденной страницы. Если страница не найдена, то будет возвращена пустая строка
//
Функция НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы) Экспорт
	
	Идентификатор = "";
	
	URL = ПолучитьURLОперации(КодПространства, ИмяСтраницы);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		ПарсерJSON = Новый ПарсерJSON;
		Ответ = ПарсерJSON.ПрочитатьJSON(РезультатЗапроса.Ответ);
		Результат = Ответ.Получить("results");
		Если Результат <> Неопределено И Результат.Количество() Тогда
			
			Результат0 = Результат[0];
			Идентификатор = Результат0.Получить("id");
			
		КонецЕсли; 
		
	Иначе
		
		ВызватьИсключение "Ошибка поиска страницы: " + КодПространства + "." + ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL);

	КонецЕсли;
	
	Возврат Идентификатор;
	
КонецФункции // НайтиСтраницуПоИмени() 

// ВерсияСтраницыПоИдентификатору
//	По идентификатору страницы получает ее версию
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор  			- Строка - Идентификатор страницы
//
// Возвращаемое значение:
//   Строка   - Версия страницы, если версии нет (как??), то вернется пустая строка
//
Функция ВерсияСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор) Экспорт
	
	Версия = "";
	URL = ПолучитьURLОперации(,, Идентификатор);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		ПарсерJSON = Новый ПарсерJSON;

		Ответ = ПарсерJSON.ПрочитатьJSON(РезультатЗапроса.Ответ);
		Результат = Ответ.Получить("version");
		Если Результат <> Неопределено Тогда
			
			Версия = Результат.Получить("number");               			
			
		КонецЕсли; 
		
	Иначе
		
		ВызватьИсключение "Ошибка получения версии страницы:" + Идентификатор + ТекстОшибки(РезультатЗапроса, URL);
		
	КонецЕсли;
	
	Возврат Версия;
	
КонецФункции // ВерсияСтраницыПоИдентификатору()

// СодержимоеСтраницыПоИдентификатору
//	По идентификатору страницы получает ее содержимое
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор  			- Строка - Идентификатор страницы
//
// Возвращаемое значение:
//   Строка   - Тело страницы
//
Функция СодержимоеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор) Экспорт

	Тело = "";
	URL = ПолучитьURLОперации(,, Идентификатор) + "&expand=body.storage";
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		Регексп = Новый РегулярноеВыражение("""body"":{""storage"":{""value"":""([\w\W]*?)"",""representation"":""storage");
		Регексп.Многострочный = ИСТИНА;
		Ответ = Регексп.НайтиСовпадения(РезультатЗапроса.Ответ);
		Если Ответ.Количество() Тогда
			
			Тело = Ответ[0].Группы[1].Значение;
			
		КонецЕсли; 
		
	Иначе
		
		ВызватьИсключение "Ошибка получения версии страницы:" + Идентификатор + ТекстОшибки(РезультатЗапроса, URL);
		
	КонецЕсли;
	
	Возврат Тело;

КонецФункции // СодержимоеСтраницыПоИдентификатору()

// ПодчиненныеСтраницыПоИдентификатору
//	Возвращает таблицу с подчиненными страницами
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор  			- Строка - Идентификатор страницы
//
// Возвращаемое значение:
//   ТаблицаЗначений   - Таблица с подчиненными страницами
//	{
//		Наименование 	- Строка - Наименование страницы
//		Идентификатор 	- Строка - Идентификатор страницы
//	}
//
Функция ПодчиненныеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор) Экспорт
	
	ДочерниеСтраницы = Новый ТаблицаЗначений;
	ДочерниеСтраницы.Колонки.Добавить("Наименование");
	ДочерниеСтраницы.Колонки.Добавить("Идентификатор");
	
	URL = ПолучитьURLОперации(,, Идентификатор, "child/page");
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		ПарсерJSON = Новый ПарсерJSON;
		Ответ = ПарсерJSON.ПрочитатьJSON(РезультатЗапроса.Ответ);
		Результат = Ответ.Получить("results");
		Если Результат <> Неопределено Тогда			
			
			Для Каждого Запись Из Результат Цикл
				
				Дочка = ДочерниеСтраницы.Добавить();
				Дочка.Наименование = Запись.Получить("title");
				Дочка.Идентификатор = Запись.Получить("id");
				
			КонецЦикла
			
		КонецЕсли;
		
	Иначе
		
		ВызватьИсключение "Ошибка получения подчиненных страниц: " + Идентификатор + ТекстОшибки(РезультатЗапроса, URL);
		
	КонецЕсли;
	
	Возврат ДочерниеСтраницы;
	
КонецФункции // ПодчиненныеСтраницыПоИдентификатору()

// СоздатьСтраницу
//	Создает новую страницу в указанном пространстве
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Наименование страницы (заголовок)
//  Содержимое  			- Строка - Содержимое (тело) страницы. Текст должен обработан, т.е. экранированы спец символы для помещения в JSON
//  ИдентификаторРодителя	- Строка - идентификатор родительской страницы
//
// Возвращаемое значение:
//   Строка   - Идентификатор созданной страницы
//
Функция СоздатьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы, Содержимое, ИдентификаторРодителя = "") Экспорт
	
	ИдентификаторСтраницы = "";
	
	URL = ПолучитьURLОперации();
	ТелоЗапроса = "
	|{
	|""type"": ""page"",
	|""title"": """ + ИмяСтраницы + """,
	|""space"": {""key"":""" + КодПространства + """},";
	
	Если Не ПустаяСтрока(ИдентификаторРодителя) Тогда
		
		ТелоЗапроса = ТелоЗапроса + "
		|""ancestors"":[{""id"":" + ИдентификаторРодителя + "}],";
		
	КонецЕсли;
	
	ТелоЗапроса = ТелоЗапроса + "
	|""body"": {""storage"":
	|	{
	|		""value"":""" + Содержимое + """
	|	,""representation"":""storage""
	|	}}
	|}";
	
	ИдентификаторСтраницы = "";
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "POST", URL, ТелоЗапроса);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		ИдентификаторСтраницы = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
		
	Иначе
		
		ВызватьИсключение "Ошибка создания страницы:" + КодПространства + "." + ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL);
		
	КонецЕсли;
	
	Возврат ИдентификаторСтраницы;
	
КонецФункции // СоздатьСтраницу() 

// ОбновитьСтраницу
//	Выполняет обновление существующей страницы
//
// Параметры:
//  ПараметрыПодключения  			- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  				- Строка - Код пространства confluence
//  ИмяСтраницы  					- Строка - Наименование страницы (заголовок)
//  Идентификатор					- Строка - идентификатор страницы. Если идентификатор указан, 
//										то при обновлении страницы наименование будет установлено из параметра ИмяСтраницы
//  Содержимое  					- Строка - Содержимое (тело) страницы. Текст должен обработан, т.е. экранированы спец символы для помещения в JSON
//	ОбновитьПриИзмененииСодержимого - Булево - обновлять страницу, только если содержимое изменилось, иначе всегда обновлять
//
// Возвращаемое значение:
//   Строка   - Идентификатор обновленной страницы
//
Функция ОбновитьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы = "", Знач Идентификатор = "", Содержимое = "", ОбновитьПриИзмененииСодержимого = ЛОЖЬ) Экспорт
	
	Если ПустаяСтрока(ИмяСтраницы) И ПустаяСтрока(Идентификатор) Тогда
		
		ВызватьИсключение "Ошибка обновления страницы: " + КодПространства + "." + ИмяСтраницы +
		"Ответ: не указаны имя страницы и идентификатор";
		
	КонецЕсли;
	
	Если ПустаяСтрока(Идентификатор) Тогда
		
		Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
		
		Если ПустаяСтрока(Идентификатор) Тогда
			
			ВызватьИсключение "Ошибка обновления страницы: " + КодПространства + "." + ИмяСтраницы +
			"Ответ: не найдена страница";
			
		КонецЕсли;
		
	КонецЕсли;
	
	Если ОбновитьПриИзмененииСодержимого Тогда

		ТекущееСодержимое = СодержимоеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор);
		Регексп = Новый РегулярноеВыражение("id=\\""([a-z0-9-]{36})\\""\ ac\:name"); // идентификаторы плагинов меняются
		Регексп.Многострочный = ИСТИНА;
		ТекущееСодержимое = Регексп.Заменить(ТекущееСодержимое, "NONE");
		ВрСодержимое = Регексп.Заменить(Содержимое, "NONE");
		Если СтрСравнить(СокрЛП(ТекущееСодержимое), СокрЛП(ВрСодержимое)) = 0 Тогда

			Возврат Идентификатор;

		КонецЕсли;
		
	КонецЕсли;

	URL = ПолучитьURLОперации(,, Идентификатор);
	Версия = ВерсияСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор);	
	Версия = Формат(Число(Версия) + 1, "ЧГ=");
	
	ТелоЗапроса = "
	|{
	|""type"": ""page"",
	|""title"": """ + ИмяСтраницы + """,";
	
	Если НЕ ПустаяСтрока(Содержимое) Тогда
		
		ТелоЗапроса = ТелоЗапроса + "
		|""body"": {""storage"":
		|	{
		|		""value"":""" + Содержимое + """
		|	,""representation"":""storage""
		|	}},";
		
	КонецЕсли;
	
	ТелоЗапроса = ТелоЗапроса + "
	|""version"":{""number"":" + Версия + "}
	|}";
	
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "PUT", URL, ТелоЗапроса);
	
	Если РезультатЗапроса.КодСостояния <> 200 Тогда
		
		ВызватьИсключение "Ошибка обновления страницы:" + КодПространства + "." + ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL);
		
	КонецЕсли;
	
	Возврат Идентификатор;
	
КонецФункции // ОбновитьСтраницу()

// СоздатьСтраницуИлиОбновить
//	Создает страницу, если же страница существует, то обновляет
//
// Параметры:
//  ПараметрыПодключения  			- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  				- Строка - Код пространства confluence
//  ИмяСтраницы  					- Строка - Наименование страницы (заголовок)
//  Содержимое  					- Строка - Содержимое (тело) страницы. Текст должен обработан, т.е. экранированы спец символы для помещения в JSON
//  ИдентификаторРодителя			- Строка - идентификатор родительской страницы
//	ОбновитьПриИзмененииСодержимого - Булево - обновлять страницу, только если содержимое изменилось, иначе всегда обновлять
//
// Возвращаемое значение:
//   Строка   - Идентификатор созданной / обновленной страницы
//
Функция СоздатьСтраницуИлиОбновить(ПараметрыПодключения, КодПространства, ИмяСтраницы, Содержимое, ИдентификаторРодителя = "", ОбновитьПриИзмененииСодержимого = ЛОЖЬ)Экспорт
	
	Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
	
	Если Не ПустаяСтрока(Идентификатор) Тогда
		
		Идентификатор = ОбновитьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы, Идентификатор, Содержимое, ОбновитьПриИзмененииСодержимого);

	Иначе

		Идентификатор = СоздатьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы, Содержимое, ИдентификаторРодителя);

	КонецЕсли;
	
	Возврат Идентификатор;
	
КонецФункции // СоздатьСтраницуИлиОбновить()

// УдалитьСтраницу
//	Удаляет существующую страницу 
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Наименование страницы (заголовок)
//  Идентификатор			- Строка - Идентификатор страницы
//	УдалятьПодчиненные		- Булево - признак необходимости удаления подчиненых страниц.
//								Если данный параметр = ЛОЖЬ и есть подчиненные страницы, то удаление не будет выполнено
//								и будет вызвано исключение
//
Процедура УдалитьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы = "", Знач Идентификатор = "", УдалятьПодчиненные = ЛОЖЬ) Экспорт
	
	Если ПустаяСтрока(Идентификатор) Тогда
		
		Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
		
		Если ПустаяСтрока(Идентификатор) Тогда
			
			ВызватьИсключение "Ошибка удаления страницы: " + КодПространства + "." + ИмяСтраницы +
			"Ответ: не найдена страница";
			
		КонецЕсли;
		
	КонецЕсли;

	ПодчиненныеСтраницы = ПодчиненныеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор);

	Если ПодчиненныеСтраницы.Количество() И НЕ УдалятьПодчиненные Тогда
		
		ВызватьИсключение "Ошибка удаления страницы: " + КодПространства + "." + ИмяСтраницы +
			"Ответ: есть подчиненные страницы";

	КонецЕсли; 

	Для Каждого Страница Из ПодчиненныеСтраницы Цикл

		УдалитьСтраницу(ПараметрыПодключения, КодПространства, Страница.Наименование, Страница.Идентификатор, УдалятьПодчиненные); 

	КонецЦикла;
	
	URL = ПолучитьURLОперации(,, Идентификатор);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "DELETE", URL);
	Если НЕ (РезультатЗапроса.КодСостояния = 200 И РезультатЗапроса.КодСостояния = 204) Тогда
			
		ВызватьИсключение "Ошибка обновления страницы:" + КодПространства + "." + ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL);
		
	КонецЕсли;
	
КонецПроцедуры // УдалитьСтраницу()

// ПрикрепитьМеткуКСтранице
//	Заменяет метки страницы указанной
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор			- Строка - Идентификатор страницы
//	Метка					- Строка - Метка, которую необходимо прикрепить								
//
// Возвращаемое значение:
//   Булево   - Успех операции
//
Функция ПрикрепитьМеткуКСтранице(ПараметрыПодключения, Идентификатор, Метка) Экспорт
		
	URL = ПолучитьURLОперации(,, Идентификатор, "label");
	ТелоЗапроса = "[{""prefix"":""global"", ""name"":""" + Метка + """}]";
	
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "POST", URL, ТелоЗапроса);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		Результат = Истина;
		
	Иначе
		
		ВызватьИсключение "Ошибка прикрепления метки:" + ТекстОшибки(РезультатЗапроса, URL);

		Результат = Ложь;

	КонецЕсли;

	Возврат Результат;

КонецФункции

Функция ПреобразоватьMarkdownToConfluence(ПараметрыПодключения, СодержимоеMarkdown) Экспорт

	Идентификатор = "";
	
	URLОперации = "rest/tinymce/1/markdownxhtmlconverter";
	
	ПараметрыОперации = Новый Структура();
	ПараметрыОперации.Вставить("wiki", СодержимоеMarkdown);

	Тело = СтрокаJSON(ПараметрыОперации);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "POST", URLОперации, Тело, "text/html; charset=UTF-8");
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		Возврат РезультатЗапроса.Ответ;
		
	Иначе
		
		ВызватьИсключение "Ошибка преобразования markdown → html" + ТекстОшибки(РезультатЗапроса, URLОперации);
		
	КонецЕсли;
	
	Возврат Идентификатор;

КонецФункции

Функция АдресСтраницы(КодПространства, ИмяСтраницы = "", Идентификатор = "", ИдентификаторРодителя = "") Экспорт
	
	Адрес = Новый Структура;
	
	Адрес.Вставить("КодПространства", 		КодПространства);
	Адрес.Вставить("ИмяСтраницы", 			ИмяСтраницы);
	Адрес.Вставить("Идентификатор", 		Идентификатор);
	Адрес.Вставить("ИдентификаторРодителя", ИдентификаторРодителя);
	
	Возврат Адрес;
	
КонецФункции

Функция Создать(ПараметрыПодключения, АдресСтраницы, Содержимое = Неопределено) Экспорт
	
	HTTPМетод = "PUT";

	ПараметрыКоманды = ПараметрыСозданияОбновления(ПараметрыПодключения, АдресСтраницы, Содержимое, , HTTPМетод);
	
	URL = ПолучитьURLОперации();
	
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, HTTPМетод, URL, СтрокаJSON(ПараметрыКоманды));
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		ИдентификаторСтраницы = НайтиСтраницуПоИмени(ПараметрыПодключения, АдресСтраницы.КодПространства, АдресСтраницы.ИмяСтраницы);
		
	Иначе
		
		ВызватьИсключение СтрШаблон("Ошибка создания страницы: %1.%2%3",
			АдресСтраницы.КодПространства, 
			АдресСтраницы.ИмяСтраницы, 
			ТекстОшибки(РезультатЗапроса, URL));
		
	КонецЕсли;
	
	Возврат ИдентификаторСтраницы;

КонецФункции

Функция Обновить(ПараметрыПодключения, АдресСтраницы, Содержимое = Неопределено, ОбновитьПриИзмененииСодержимого = Ложь) Экспорт
	
	Если ПустаяСтрока(АдресСтраницы.ИмяСтраницы) И ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
		
		ВызватьИсключение "Ошибка обновления страницы: " + АдресСтраницы.КодПространства + "." + АдресСтраницы.ИмяСтраницы +
		"Ответ: не указаны имя страницы и идентификатор";
		
	КонецЕсли;
	
	Если ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
		
		АдресСтраницы.Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, АдресСтраницы.КодПространства, АдресСтраницы.ИмяСтраницы);
		
		Если ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
			
			ВызватьИсключение "Ошибка обновления страницы: " + АдресСтраницы.КодПространства + "." + АдресСтраницы.ИмяСтраницы +
			"Ответ: не найдена страница";
			
		КонецЕсли;
		
	КонецЕсли;
	
	Если ОбновитьПриИзмененииСодержимого Тогда

		ТекущееСодержимое = СодержимоеСтраницыПоИдентификатору(ПараметрыПодключения, АдресСтраницы.Идентификатор);
		Регексп = Новый РегулярноеВыражение("id=\\""([a-z0-9-]{36})\\""\ ac\:name"); // идентификаторы плагинов меняются
		Регексп.Многострочный = Истина;
		ТекущееСодержимое = Регексп.Заменить(ТекущееСодержимое, "NONE");
		ВрСодержимое = Регексп.Заменить(Содержимое, "NONE");
		Если СтрСравнить(СокрЛП(ТекущееСодержимое), СокрЛП(ВрСодержимое)) = 0 Тогда

			Возврат АдресСтраницы.Идентификатор;

		КонецЕсли;
		
	КонецЕсли;

	URL = ПолучитьURLОперации(, , АдресСтраницы.Идентификатор);
	Версия = ВерсияСтраницыПоИдентификатору(ПараметрыПодключения, АдресСтраницы.Идентификатор);	
	Версия = Формат(Число(Версия) + 1, "ЧГ=");
	
	HTTPМетод = "PUT";

	ПараметрыКоманды = ПараметрыСозданияОбновления(ПараметрыПодключения, АдресСтраницы, Содержимое, Версия, HTTPМетод);
	
	ТелоЗапроса = СтрокаJSON(ПараметрыКоманды);
	
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, HTTPМетод, URL, ТелоЗапроса);
	
	Если РезультатЗапроса.КодСостояния <> 200 Тогда
		
		ВызватьИсключение "Ошибка обновления страницы:" + АдресСтраницы.КодПространства + "." + АдресСтраницы.ИмяСтраницы + ТекстОшибки(РезультатЗапроса, URL);
		
	КонецЕсли;
	
	Возврат АдресСтраницы.Идентификатор;
	
КонецФункции // ОбновитьСтраницу()

Функция ПараметрыСозданияОбновления(ПараметрыПодключения, Адрес, Содержимое, Версия = Неопределено, HTTPМетод = Неопределено)

	ПараметрыКоманды = Новый Структура();
	ПараметрыКоманды.Вставить("type", "page");
	ПараметрыКоманды.Вставить("title", Адрес.ИмяСтраницы);
	ПараметрыКоманды.Вставить("space", Новый Структура("key", Адрес.КодПространства));
	
	Если Версия <> Неопределено Тогда
		
		ПараметрыКоманды.Вставить("version", Новый Структура("number", Версия));

	КонецЕсли;
	
	Если Не ПустаяСтрока(Адрес.ИдентификаторРодителя) Тогда
		Родители = Новый Массив();
		Родители.Добавить(Новый Структура("id", Адрес.ИдентификаторРодителя));
		ПараметрыКоманды.Вставить("ancestors", Родители);
	КонецЕсли;
	
	Если ТипЗнч(Содержимое) = Тип("Структура") И Содержимое.Свойство("Значение") Тогда
		
		Значение = Содержимое.Значение;
		
		Если Содержимое.Свойство("Формат") Тогда
			Формат = Содержимое.Формат;
		Иначе
			Формат = "confluence";
		КонецЕсли;
		
	ИначеЕсли ЗначениеЗаполнено(Содержимое) Тогда
		
		Значение = Содержимое;
		Формат = "confluence";

	КонецЕсли;

	Если ЗначениеЗаполнено(Значение) Тогда

		Если Формат = "markdown" Тогда
			
			Значение = ПреобразоватьMarkdownToConfluence(ПараметрыПодключения, Значение);
			ТелоСтраницы = Новый Структура("editor", Новый Структура("value, representation", Значение, "editor"));
			
			Если Версия = Неопределено Тогда
				
				HTTPМетод = "POST"; // Создание страниц в markdown через POST остальное PUT
				
			КонецЕсли;

		Иначе
			
			ТелоСтраницы = Новый Структура("storage", Новый Структура("value, representation", Значение, "storage"));

		КонецЕсли;
		
		ПараметрыКоманды.Вставить("body", ТелоСтраницы);

	КонецЕсли;

	Возврат ПараметрыКоманды;

КонецФункции

Функция СоздатьИлиОбновить(ПараметрыПодключения, АдресСтраницы, Содержимое, ОбновитьПриИзмененииСодержимого) Экспорт
	
	Если ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
		
		АдресСтраницы.Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, АдресСтраницы.КодПространства, АдресСтраницы.ИмяСтраницы);
		
	КонецЕсли;

	Если Не ПустаяСтрока(АдресСтраницы.Идентификатор) Тогда
		
		Идентификатор = Обновить(
			ПараметрыПодключения, 
			АдресСтраницы,
			Содержимое, 
			ОбновитьПриИзмененииСодержимого);

	Иначе

		АдресСтраницы.Идентификатор = Создать(ПараметрыПодключения, АдресСтраницы, Содержимое);
		
	КонецЕсли;

	Возврат АдресСтраницы.Идентификатор;

КонецФункции

///////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЙ ФУНКЦИОНАЛ
///////////////////////////////////////////////////////////////////

Функция ПолучитьURLОперации(КодПространства = "", ИмяСтраницы = "", Идентификатор = "", Операция = "")
	
	URLОперации = "rest/api/content/";
	КлючАвторизации = "?os_authType=basic";
	Если ПустаяСтрока(Идентификатор) Тогда
		
		URLОперации = URLОперации + КлючАвторизации;
		Если Не ПустаяСтрока(КодПространства) Тогда
			
			URLОперации = URLОперации + "&spaceKey=" + КодПространства;
			
		КонецЕсли;
		
		Если Не ПустаяСтрока(ИмяСтраницы) Тогда
			
			URLОперации = URLОперации + "&title=" + КодироватьСтроку(ИмяСтраницы, СпособКодированияСтроки.КодировкаURL);
			
		КонецЕсли;
		
	Иначе
		
		URLОперации = URLОперации + Идентификатор + ?(ПустаяСтрока(Операция), "", "/" + Операция) + "/" + КлючАвторизации;
		
	КонецЕсли;
	
	Возврат URLОперации;
	
КонецФункции // ПолучитьURLОперации() 

Функция ВыполнитьHTTPЗапрос(ПараметрыПодключения, Метод, URL, ТелоЗапроса = "", Accept = "application/json; charset=UTF-8")
	
	HTTPЗапрос = Новый HTTPЗапрос;
	HTTPЗапрос.Заголовки.Вставить("Content-Type", "application/json; charset=UTF-8");
	HTTPЗапрос.Заголовки.Вставить("Accept", Accept);
	
	HTTPЗапрос.АдресРесурса = URL;

	Если Не ПустаяСтрока(ТелоЗапроса) Тогда
		
		HTTPЗапрос.УстановитьТелоИзСтроки(ТелоЗапроса, КодировкаТекста.UTF8);
		
	КонецЕсли;
	
	HTTP = Новый HTTPСоединение(ПараметрыПодключения.АдресСервера, , 
								ПараметрыПодключения.Пользователь,
								ПараметрыПодключения.Пароль);
								
	Сообщить(СтрШаблон("%1: %2/%3", Метод, ПараметрыПодключения.АдресСервера, URL));
								
	Если СтрСравнить(Метод, "GET") = 0 Тогда
		
		Ответ = HTTP.Получить(HTTPЗапрос);
		
	ИначеЕсли СтрСравнить(Метод, "POST") = 0 Тогда
		
		Ответ = HTTP.ОтправитьДляОбработки(HTTPЗапрос);
		
	ИначеЕсли СтрСравнить(Метод, "PUT") = 0 Тогда
		
		Ответ = HTTP.Записать(HTTPЗапрос);
		
	ИначеЕсли СтрСравнить(Метод, "DELETE") = 0 Тогда
		
		Ответ = HTTP.Удалить(HTTPЗапрос);
		
	Иначе
		
		ВызватьИсключение СтрШаблон("Неизвестный метод: '%1'", Метод);
		
	КонецЕсли;
	
	Возврат Новый Структура("Ответ, КодСостояния", Ответ.ПолучитьТелоКакСтроку(КодировкаТекста.UTF8), Ответ.КодСостояния);
	
КонецФункции // ВыполнитьHTTPЗапрос()

Функция СтрокаJSON(Значение)
	
	ПараметрыЗаписи = Новый ПараметрыЗаписиJSON(Ложь, , Истина, , , , , , Истина);
	Запись = Новый ЗаписьJSON();
	Запись.УстановитьСтроку();
	
	ЗаписатьJSON(Запись, Значение);
	
	Возврат Запись.Закрыть();

КонецФункции

Функция ТекстОшибки(РезультатЗапроса, URL)

	Возврат СтрШаблон(
	"
	|Запрос: %1
	|КодСостояния: %2
	|Ответ: %3", URL, РезультатЗапроса.КодСостояния, РезультатЗапроса.Ответ);
	
КонецФункции