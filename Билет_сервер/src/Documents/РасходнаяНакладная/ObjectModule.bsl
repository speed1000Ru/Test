Процедура ОбработкаПроведения(Отказ, РежимПроведения)
	
	//Оперативный учет
	Движения.ОстаткиНоменклатуры.Записывать=Истина;
	Движения.ОстаткиНоменклатуры.БлокироватьДляИзменения=Истина;
	Движения.ОстаткиНоменклатуры.Очистить();
	Движения.ОстаткиНоменклатуры.Записать();

	Блокировка=Новый БлокировкаДанных;
	ЭлементБлокировки=Блокировка.Добавить("РегистрНакопления.ОстаткиНоменклатуры");
	ЭлементБлокировки.ИсточникДанных=СписокНоменклатуры;
	ЭлементБлокировки.ИспользоватьИзИсточникаДанных("Номенклатура", "Номенклатура");
	Блокировка.Заблокировать();

	Запрос=Новый Запрос;
	Запрос.Текст=
	"ВЫБРАТЬ
	|	МИНИМУМ(РасходнаяНакладнаяСписокНоменклатуры.НомерСтроки) КАК НомерСтроки,
	|	РасходнаяНакладнаяСписокНоменклатуры.Номенклатура КАК Номенклатура,
	|	СУММА(РасходнаяНакладнаяСписокНоменклатуры.Количество) КАК Количество
	|ПОМЕСТИТЬ ТабЧасть
	|ИЗ
	|	Документ.РасходнаяНакладная.СписокНоменклатуры КАК РасходнаяНакладнаяСписокНоменклатуры
	|ГДЕ
	|	РасходнаяНакладнаяСписокНоменклатуры.Ссылка = &Ссылка
	|	И НЕ РасходнаяНакладнаяСписокНоменклатуры.Номенклатура.Услуга
	|СГРУППИРОВАТЬ ПО
	|	РасходнаяНакладнаяСписокНоменклатуры.Номенклатура
	|
	|ИНДЕКСИРОВАТЬ ПО
	|	Номенклатура
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ТабЧасть.НомерСтроки КАК НомерСтроки,
	|	ТабЧасть.Номенклатура КАК Номенклатура,
	|	ТабЧасть.Количество КАК Количество,
	|	ТабЧасть.Номенклатура.Представление,
	|	ОстаткиНоменклатурыОстатки.Партия,
	|	ЕСТЬNULL(ОстаткиНоменклатурыОстатки.КоличествоОстаток, 0) КАК КоличествоОстаток,
	|	ЕСТЬNULL(ОстаткиНоменклатурыОстатки.СуммаОстаток, 0) КАК СуммаОстаток
	|ИЗ
	|	ТабЧасть КАК ТабЧасть
	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.ОстаткиНоменклатуры.Остатки(&МоментИтогов, Номенклатура В
	|			(ВЫБРАТЬ
	|				Т.Номенклатура
	|			ИЗ
	|				ТабЧасть КАК Т)) КАК ОстаткиНоменклатурыОстатки
	|		ПО ТабЧасть.Номенклатура = ОстаткиНоменклатурыОстатки.Номенклатура
	|
	|УПОРЯДОЧИТЬ ПО
	|	ОстаткиНоменклатурыОстатки.Партия.МоментВремени
	|ИТОГИ
	|	МАКСИМУМ(НомерСтроки),
	|	МАКСИМУМ(Количество),
	|	СУММА(КоличествоОстаток)
	|ПО
	|	Номенклатура";

	ЗАпрос.УстановитьПараметр("Ссылка", Ссылка);
	Запрос.УстановитьПараметр("МоментИтогов", МоментВремени());

	ВыборкаНоменклатура=Запрос.Выполнить().Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
	Пока ВыборкаНоменклатура.Следующий() Цикл
		Превышение=ВыборкаНоменклатура.Количество - ВыборкаНоменклатура.КоличествоОстаток;
		Если Превышение > 0 Тогда
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = "Превышение остатка по номенклатуре " + ВыборкаНоменклатура.НоменклатураПредставление
				+ " в количестве " + Превышение;
			Сообщение.Поле = "Объект.СписокНоменклатуры[" + (ВыборкаНоменклатура.НомерСтроки - 1) + "].Количество";
			Сообщение.Сообщить();
			Отказ=Истина;
		КонецЕсли;

		Если Отказ Тогда
			Продолжить;
		КонецЕсли;

		ОсталосьСписать = ВыборкаНоменклатура.Количество;

		Выборка=ВыборкаНоменклатура.Выбрать();
		Пока Выборка.Следующий() И ОсталосьСписать <> 0 Цикл
			Списываем=Мин(Выборка.КоличествоОстаток, ОсталосьСписать);
			Движение=Движения.ОстаткиНоменклатуры.ДобавитьРасход();
			Движение.Период=Дата;
			Движение.Номенклатура=Выборка.Номенклатура;
			Движение.Партия=Выборка.Партия;
			Движение.Количество=Списываем;

			Если Списываем = Выборка.КОличествоОстаток Тогда
				Движение.Сумма=Выборка.СуммаОстаток;
			Иначе
				Движение.Сумма=Списываем / Выборка.КоличествоОстаток * Выборка.СуммаОстаток;
			КонецЕсли;

			ОсталосьСписать=ОсталосьСписать - Списываем;

		КонецЦикла;
	КонецЦикла;
	
	
	//Бухаглтерский учет
	Движения.Управленческий.Записывать=Истина;
	Движения.Управленческий.Очистить();

	ВалютаДоговора = Договор.Валюта;
	КурсВалюты = РегистрыСведений.КурсыВалют.ПолучитьПоследнее(МоментВремени(), Новый Структура("Валюта",
		ВалютаДоговора)).Курс;
	Если Не ЗначениеЗаполнено(КурсВалюты) Тогда
		КурсВалюты=1;
	КонецЕсли;

	Проводка = Движения.Управленческий.Добавить();
	Проводка.Период=Дата;
	Проводка.СчетДт=ПланыСчетов.Управленческий.Покупатели;
	Проводка.СчетКт=ПланыСчетов.Управленческий.ПрибылиУбытки;
	Проводка.СубконтоДт[ПланыВидовХарактеристик.ВидыСубконто.Контрагент]=Контрагент;
	Проводка.СубконтоДт[ПланыВидовХарактеристик.ВидыСубконто.Договор]=Договор;
	Проводка.СуммаВалютнаяДт=СуммаДокумента;
	Проводка.Сумма=СуммаДокумента * КурсВалюты;

КонецПроцедуры

Процедура ПередЗаписью(Отказ, РежимЗаписи, РежимПроведения)
	//СуммаДокумента=СписокНоменклатуры.Итог("Сумма");
КонецПроцедуры
