import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../scope/app_state_scope.dart';
import '../calendar/calendar_screen.dart';
import '../tasks/task_list_screen.dart';

/// Цитата для главного экрана: автор и источник текста.
class _ScreenQuote {
  const _ScreenQuote({
    required this.text,
    required this.author,
    this.source,
  });

  final String text;
  final String author;
  final String? source;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selected = DateTime.now();
  DateTime _weekAnchor = DateTime.now(); // Monday of visible week
  Timer? _quoteTimer;
  int _quoteIndex = 0;
  final _quoteRandom = math.Random();

  /// Пул цитат: эпикур, стоа, коучи, бизнес, финансы, жизнь, todoLife, народная мудрость.

  static const _quotes = <_ScreenQuote>[
    // ——— Эпикур (не стоа) ———
    _ScreenQuote(
      text: 'Богат не тот, кто много имеет, а тот, кому мало нужно.',
      author: 'Эпикур',
    ),
    // ——— Народная мудрость (подпись автора в UI не показываем) ———
    _ScreenQuote(
      text: 'Дисциплина важнее мотивации.',
      author: 'Народная мудрость',
    ),
    _ScreenQuote(
      text: 'Успех — это сумма небольших усилий, повторяемых изо дня в день.',
      author: 'Роберт Колльер',
    ),
    // ——— Эпиктет, Марк Аврелий ———
    _ScreenQuote(
      text: 'Сначала скажи себе, каким ты хочешь быть, и затем делай, что нужно.',
      author: 'Эпиктет',
    ),
    _ScreenQuote(
      text: 'Счастье твоей жизни зависит от качества твоих мыслей.',
      author: 'Марк Аврелий',
    ),
    // ——— Коучи, наставники ———
    _ScreenQuote(
      text: 'Успех — это спокойное уверенное знание, что ты вложил в жизнь всё, чтобы стать лучшим, каким можешь быть.',
      author: 'Джон Вуден',
      source: 'тренер UCLA; пирамида успеха, интервью',
    ),
    _ScreenQuote(
      text: 'Побеждает не сила, а воля: не важен размер, важен характер.',
      author: 'Винс Ломбарди',
      source: 'NFL; публичные речи, 1960-е (по смыслу)',
    ),
    _ScreenQuote(
      text: 'Команда, которая доверяет друг другу, бьётся за общую ценность, а не за личный процент в статистике.',
      author: 'Фил Джексон',
      source: 'книга «11 колец»; опыт в NBA',
    ),
    _ScreenQuote(
      text: 'Тренер велит правде о прогрессе, не ободрению: ловите правду, не похвалу — так растёте.',
      author: 'Билл Кэмпбелл',
      source: 'наставник в Кремниевой долине; «Trillion Dollar Coach»',
    ),
    _ScreenQuote(
      text: 'Высшая мера власти — не власть над другими, а власть над собой: выбирайте реакции.',
      author: 'Тони Роббинс',
      source: 'семинары; «Разбуди великана внутри»',
    ),
    _ScreenQuote(
      text: 'Лидерство — это влияние, а не должность: влияние растёт, когда растут люди рядом с вами.',
      author: 'Джон Максвелл',
      source: '«21 незыблемый закон лидерства»',
    ),
    _ScreenQuote(
      text: 'Самая трудная лягушка съедайте первой: начинайте день с самого важного и нелюбимого дела.',
      author: 'Брайан Трейси',
      source: '«Съешьте лягушку!»',
    ),
    _ScreenQuote(
      text: 'Начинайте с конца в уме: сформулируйте цель ясно — тогда путь из шагов станет очевиднее.',
      author: 'Стивен Кови',
      source: '«7 навыков высокоэффективных людей»',
    ),
    _ScreenQuote(
      text: 'Производительность — не удача, а привычка: дисциплина ритуалов важнее вдохновения по расписанию.',
      author: 'Брендон Бёрчард',
      source: 'High Performance Habits; по смыслу',
    ),
    _ScreenQuote(
      text: 'Пока вы говорите себе «я не могу», вы натренировали сдачу: оспорьте внутренний сценарий — и движение начнётся.',
      author: 'Лес Браун',
      source: 'мотивационные речи, 1990-е (по смыслу)',
    ),
    _ScreenQuote(
      text: 'Без доверия команда бессильна: люди боятся уязвимости; с доверием спорят о деле, а не об эго.',
      author: 'Патрик Ленсиони',
      source: '«Пять пороков команды»',
    ),
    _ScreenQuote(
      text: 'Сначала поймите, куда ведёте людей, и подбирайте стиль: одна и та же манера на все ситуации не сработает.',
      author: 'Кен Бланшар',
      source: 'ситуационное лидерство; идеи «Одноминутного менеджера»',
    ),
    _ScreenQuote(
      text: 'Собственное имя для человека — самый важный для него звук: искренний интерес к другим открывает двери.',
      author: 'Дейл Карнеги',
      source: '«Как завоёвывать друзей…»; принцип внимания',
    ),
    _ScreenQuote(
      text: 'Система выигрывает у цели, если нет плана на неделю: смысл в ясных приоритетах, а не в длинных списках.',
      author: 'Майкл Хайатт',
      source: 'Full Focus Planner; блог и подкаст (по смыслу)',
    ),
    _ScreenQuote(
      text: 'Разгрузите голову: всё, что требует действия, вынесите в доверенную систему, а не в оперативную память мозга.',
      author: 'Дэвид Аллен',
      source: 'Getting Things Done; по смыслу GTD',
    ),
    _ScreenQuote(
      text: 'Глубокая работа — редкий навык, который даёт несоразмерно большой эффект в шумном мире срочного.',
      author: 'Кэл Ньюпорт',
      source: '«Deep Work»; по смыслу',
    ),
    _ScreenQuote(
      text: 'Если сказать «да» слишком многим, вы не скажете «да» сущему: выбирайте меньше, но по-настоящему важного.',
      author: 'Грег МакКеон',
      source: '«Эссенциализм» (Essentialism)',
    ),
    _ScreenQuote(
      text: 'Считайте 5-4-3-2-1 и стартуйте до того, как мозг успеет отговорить: действие ломает прокрастинацию.',
      author: 'Мел Роббинс',
      source: 'правило 5 секунд; «The 5 Second Rule»',
    ),
    _ScreenQuote(
      text: 'Успех — дисциплина, а не удача: сформулируйте, чего вы хотите, сделайте список и идите по нему ежедневно.',
      author: 'Джек Кэнфилд',
      source: '«Правила успеха»; по смыслу',
    ),
    _ScreenQuote(
      text: 'Вы получите от жизни то, к чему идёте с благодарностью и вежливым упорством, а не с жалобой на обстоятельства.',
      author: 'Зиг Зиглар',
      source: 'семинары и книги; по смыслу мотивации',
    ),
    _ScreenQuote(
      text: 'Владение смыслом — не теория: берите ответственность за слабые места команды и исправляйте без перекладывания вины.',
      author: 'Джоко Уилинк',
      source: '«Экстремальная ответственность»; SEAL, лидерство',
    ),
    _ScreenQuote(
      text: 'Когда вы захотите результата так же сильно, как воздуха, — сдвиг в действиях станет неизбежен.',
      author: 'Эрик Томас',
      source: 'мотивационные выступления; по смыслу',
    ),
    _ScreenQuote(
      text: 'То, во что вы убеждённо верите, тянет к цели: образ мыслей превращается в привычки и план.',
      author: 'Наполеон Хилл',
      source: '«Думай и богатей»; по смыслу',
    ),
    _ScreenQuote(
      text: 'Мы клоним жизнь к тому, о чём думаем дольше всего: круг идей, который кормите, и есть ваш курс.',
      author: 'Эрл Найтингейл',
      source: '«Самая необычная тайна»; по смыслу',
    ),
    _ScreenQuote(
      text: 'Любую задачу можно разложить на шаги: упор важнее идеального плана, который вы откладываете.',
      author: 'Мари Форлео',
      source: 'Everything is Figureoutable; по смыслу',
    ),
    _ScreenQuote(
      text: 'Документируйте путь, не ждите идеала: стабильный поток сильнее редкого шедевра, если строите бренд и доверие.',
      author: 'Гэри Вайнерчук',
      source: 'контент-стратегия; публичные выступления (по смыслу)',
    ),
    _ScreenQuote(
      text: 'Смысл важнее славы: если знаете, зачем встаёте, трудности становятся частью пути, а не приговором.',
      author: 'Джей Шетти',
      source: 'подкаст On Purpose; книги (по смыслу)',
    ),
    _ScreenQuote(
      text: 'Устойчивость — это страстная привязанность к долгой цели и упорные шаги, пока день слабый и день сильный сменяют друг друга.',
      author: 'Анджела Дакворт',
      source: 'Grit: сила страсти и упорства; по смыслу',
    ),
    _ScreenQuote(
      text: 'Смысл в том, не «талант или нет», а вера в то, что навыки растут от усилий: фиксированные убеждения тормозят, ростовые — подпитывают.',
      author: 'Кэрол Двек',
      source: '«Мышление будущего» (Mindset); по смыслу',
    ),
    _ScreenQuote(
      text: 'Сильнее контроль, смысл и мастерство, чем награда «палкой и морковкой» одни: внутренняя мотивация долговечнее.',
      author: 'Дэниел Пинк',
      source: 'Drive: удивительная правда о том, что нас мотивирует',
    ),
    _ScreenQuote(
      text: 'Слушайте так, как будто ваша сделка и репутация зависят от точного понимания, а не от следующей реплики.',
      author: 'Крис Восс',
      source: '«Никогда не разделяйте разницу»; переговоры',
    ),
    _ScreenQuote(
      text: 'Сила намеренности: каждый день спрашивайте, что движет вами — тогда мелкие шаги складываются в судьбу.',
      author: 'Опра Уинфри',
      source: 'интервью и The Oprah Winfrey Show; по смыслу',
    ),
    _ScreenQuote(
      text: 'Риски не избавляют от скуки, а учат: если путь вам важен, тяните команду вместо того чтобы прятать неудачу.',
      author: 'Ричард Брэнсон',
      source: 'Virgin, автобиографии и публичные письма (по смыслу)',
    ),
    _ScreenQuote(
      text: 'Пора выйти в мир, даже боясь: важен не тикет на совершенство, а ваша линия — что вы создаёте, когда рискуете уязвимостью.',
      author: 'Брене Браун',
      source: 'Dare to Lead; выступления TED (по смыслу)',
    ),
    _ScreenQuote(
      text: 'Побеждает не то, кто копит идеи, а кто выводит в свет: «достаточно хорошо» и публикация важнее бесконечной полировки.',
      author: 'Сет Годин',
      source: 'блог, Linchpin, The Practice; по смыслу',
    ),
    _ScreenQuote(
      text: 'Щедрость в обмене знаниями и вниманием к людям открывает двери: выигрыш не нулевой, когда инвестируете в других, не только в карму.',
      author: 'Адам Грант',
      source: 'Give and Take, Think Again; по смыслу',
    ),
    _ScreenQuote(
      text: 'Сделайте микро-шаг сегодня, не «завтра в понедельник»: большие цели складываются из экспериментов, которые не стыдно повторить.',
      author: 'Тим Феррисс',
      source: '«4-часовая рабочая неделя»; подкаст (по смыслу)',
    ),
    _ScreenQuote(
      text: 'Считайте, сколько вещей вам не всё равно: отсечь лишнее — взрослое решение, оно снимает с ума шум, а не «позитив мимо».',
      author: 'Марк Мэнсон',
      source: 'The Subtle Art of Not Giving a F*ck; по смыслу',
    ),
    _ScreenQuote(
      text: 'Сделайте «шаг вперёд, даже неловкий»: карьеру и смелые решения нельзя планировать, будучи вечно готовыми сидеть удобно.',
      author: 'Шерил Сэндберг',
      source: 'Lean In; круги поддержки, по смыслу',
    ),
    _ScreenQuote(
      text: 'Спросите себя, какой «жизнью по-хорошему» вы поживёте, если сегодня согласны на сиюминутный заработок, а не на долгий смысл.',
      author: 'Клейтон Кристенсен',
      source: 'How Will You Measure Your Life; по смыслу',
    ),
    _ScreenQuote(
      text: 'Ничто не вечно, даже ваша воля, если вопрос: не «силы воли», а крючки привычки, которые среда вам настроила.',
      author: 'Чарльз Духигг',
      source: 'The Power of Habit; по смыслу',
    ),
    _ScreenQuote(
      text: 'Совпадайте важные действия с удобным моментом, а сопротивление мешайте: меняйте контекст, не только обещайте «завтра».',
      author: 'Кэти Милкман',
      source: 'How to Change; наука о привычках, по смыслу',
    ),
    _ScreenQuote(
      text: 'Культура «съесть лягушку» с раннего утра — дисциплина, но смена курса требует увольнения от старых привычек, а не только роли.',
      author: 'Джон Коттер',
      source: 'Our Iceberg Is Melting; Leading Change; по смыслу',
    ),
    _ScreenQuote(
      text: 'Эффективный руководитель ориентируется на вклад, а не на шум занятости: спрашивайте, что сделано для миссии, а не сколько часов светили.',
      author: 'Питер Друкер',
      source: '«Эффективный руководитель»; по смыслу',
    ),
    _ScreenQuote(
      text: 'Инновация — это единственный стабильный вид конкурентного преимущества, если рынок не стоит на месте.',
      author: 'Питер Друкер',
      source: 'менеджмент и инновации; по смыслу',
    ),
    // ——— Бизнес-ораторы, лидерство ———
    _ScreenQuote(
      text: 'Фокус — это умение сказать «нет» сотням хороших вещей ради пары великолепных.',
      author: 'Стив Джобс',
      source: 'выпускная речь в Стэнфорде, 2005',
    ),
    _ScreenQuote(
      text: 'Покупают не продукт, а то, ради чего он существует: начинай с «зачем».',
      author: 'Саймон Синек',
      source: '«Start With Why»; золотой круг, TED',
    ),
    _ScreenQuote(
      text: 'Радикальная правда + радикальная прозрачность: так выдерживают кризисы, а не скрывают их.',
      author: 'Рэй Далио',
      source: '«Принципы: жизнь и работа»',
    ),
    _ScreenQuote(
      text: 'День первый, а не день второй: в организации должна оставаться любопытная новичковая душа.',
      author: 'Джефф Безос',
      source: 'письмо акционерам Amazon, концепция Day 1',
    ),
    _ScreenQuote(
      text: 'Ошибка, признанная и исправленная, сильнее сотни прикрытых: культура учится на слабых местах.',
      author: 'Сатья Наделла',
      source: 'книга «Обнови», Microsoft',
    ),
    _ScreenQuote(
      text: 'Успех — это обычно следствие применения основных вещей, а не тайн.',
      author: 'Джим Рон',
      source: 'аудиосеминары, 1980–90-е (по смыслу)',
    ),
    // ——— Финансы, инвестиции, учёт ———
    _ScreenQuote(
      text:
          'Не экономьте то, что осталось после трат — тратьте то, что осталось после сбережений.',
      author: 'Уоррен Баффет',
      source: 'письмо акционерам; «заплати себе в первую очередь» (по смыслу)',
    ),
    _ScreenQuote(
      text: 'Цена — что вы платите, ценность — что получаете: инвестиция в ясное различение окупается вечно.',
      author: 'Уоррен Баффет',
      source: 'письмо акционерам Berkshire Hathaway',
    ),
    _ScreenQuote(
      text: 'Не копи после расходов — откладывай до расходов: сначала «заплати себе».',
      author: 'Джордж С. Клейсон',
      source: '«Самый богатый человек в Вавилоне»',
    ),
    _ScreenQuote(
      text: 'Рынок — устройство переноса денег от нетерпеливых к терпеливым.',
      author: 'Уоррен Баффет',
      source: 'публичные выступления; цит. изложение',
    ),
    _ScreenQuote(
      text: 'Богатство — то, чего остаётся после вычитания внешнего: свобода от привязанности к деньгам стоит дороже счёта.',
      author: 'Навал Равикант',
      source: 'The Almanack of Naval Ravikant',
    ),
    _ScreenQuote(
      text: 'Инвестиции должны наиболее разумно, а не наиболее волнующе выглядеть: ведите сбережения скучно и регулярно.',
      author: 'Морган Хаусел',
      source: '«Психология денег» (The Psychology of Money)',
    ),
    // ——— Жизнь, смысл, отношение ———
    _ScreenQuote(
      text: 'Всё можно у человека отобрать, кроме одного — последнего свободного выбора: как отреагировать.',
      author: 'Виктор Франкл',
      source: '«…сказать жизни „да“» (логотерапия)',
    ),
    _ScreenQuote(
      text: 'Пока не примете ответственность за свою жизнь, вас везут, а не вы ведёте.',
      author: 'Эрик Берн',
      source: '«Игры, в которые играют люди» (по смыслу ответственного «Я»)',
    ),
    _ScreenQuote(
      text: 'Счастье — не цель, а побочный продукт осмысленного труда и внимания к реальным ценностям.',
      author: 'Виктор Франкл',
      source: '«Человек в поисках смысла»; эссе',
    ),
    _ScreenQuote(
      text: 'Пока сравниваешь с другими, спотыкаешься: единственный полезный эталон — вчерашний ты.',
      author: 'Джеймс Клир',
      source: '«Атомные привычки»; фокус на 1% улучшения',
    ),
    _ScreenQuote(
      text: 'Люби жизнь, которую имеешь, прежде чем иметь жизнь, в которой уверен: мир внутри важнее гонки за внешним.',
      author: 'Робин Шарма',
      source: '«Монах, который продал свой „феррари“» (по смыслу благодарности и выбора)',
    ),
    // ——— Оригинальные мысли (как в ранних версиях, автор todoLife) ———
    _ScreenQuote(text: 'Начни с малого — но начни сегодня.', author: 'todoLife'),
    _ScreenQuote(text: 'Делай важное первым.', author: 'todoLife'),
    _ScreenQuote(text: 'Системы побеждают настроение.', author: 'todoLife'),
    _ScreenQuote(text: 'Планируй, чтобы жить легче.', author: 'todoLife'),
    _ScreenQuote(text: 'Не жди идеального момента — создай его.', author: 'todoLife'),
    _ScreenQuote(text: 'Один шаг в день — это тоже путь.', author: 'todoLife'),
    _ScreenQuote(text: 'Дисциплина — это забота о будущем себе.', author: 'todoLife'),
    _ScreenQuote(text: 'Стабильность сильнее рывков.', author: 'todoLife'),
    _ScreenQuote(text: 'Побеждает тот, кто возвращается к делу.', author: 'todoLife'),
    _ScreenQuote(text: 'Маленькие привычки строят большие результаты.', author: 'todoLife'),
    _ScreenQuote(text: 'Доводи до конца хотя бы одну вещь.', author: 'todoLife'),
    _ScreenQuote(text: 'Сделай проще. Сделай сейчас.', author: 'todoLife'),
    _ScreenQuote(text: 'День — это единица победы.', author: 'todoLife'),
    _ScreenQuote(text: 'Сложные цели состоят из простых действий.', author: 'todoLife'),
    _ScreenQuote(text: 'Сначала порядок — потом скорость.', author: 'todoLife'),
    _ScreenQuote(text: 'Стабильно — значит надёжно.', author: 'todoLife'),
    _ScreenQuote(text: 'Действуй так, будто мотивация уже пришла.', author: 'todoLife'),
    _ScreenQuote(text: 'Не сравнивай. Улучшай.', author: 'todoLife'),
    _ScreenQuote(text: 'Сила в привычке.', author: 'todoLife'),
    _ScreenQuote(text: 'Управляй временем, а не настроение — собой.', author: 'todoLife'),
    _ScreenQuote(text: 'Каждый чек-лист — это ясность.', author: 'todoLife'),
    _ScreenQuote(text: 'Сначала здоровье, затем задачи.', author: 'todoLife'),
    _ScreenQuote(text: 'Тишина — это тоже прогресс.', author: 'todoLife'),
    _ScreenQuote(text: 'Не усложняй то, что можно выполнить.', author: 'todoLife'),
    _ScreenQuote(text: 'Задачи на бумаге — меньше тревоги в голове.', author: 'todoLife'),
    _ScreenQuote(text: 'Отдых — часть дисциплины.', author: 'todoLife'),
    _ScreenQuote(text: 'Делай по чуть-чуть, но каждый день.', author: 'todoLife'),
    _ScreenQuote(text: 'Накопление — это стратегия, не жертва.', author: 'todoLife'),
    _ScreenQuote(text: 'Бюджет — это свобода, а не ограничения.', author: 'todoLife'),
    _ScreenQuote(text: 'Твои деньги должны работать на тебя.', author: 'todoLife'),
    _ScreenQuote(text: 'Контроль начинается с учёта.', author: 'todoLife'),
    _ScreenQuote(text: 'Считай — и увидишь рост.', author: 'todoLife'),
    _ScreenQuote(text: 'Простые правила побеждают сложные планы.', author: 'todoLife'),
    _ScreenQuote(text: 'Рутина — это форма силы.', author: 'todoLife'),
    _ScreenQuote(text: 'Ничего не меняется, если ничего не менять.', author: 'todoLife'),
    _ScreenQuote(text: 'Сделай сегодня то, за что завтра скажешь спасибо.', author: 'todoLife'),
    _ScreenQuote(text: 'Вдохновение приходит в процессе.', author: 'todoLife'),
    _ScreenQuote(text: 'Сконцентрируйся на следующем шаге.', author: 'todoLife'),
    _ScreenQuote(text: 'Каждая задача — кирпич в твоём будущем.', author: 'todoLife'),
    _ScreenQuote(text: 'Упорядочи день — и появится энергия.', author: 'todoLife'),
    _ScreenQuote(text: 'Сделай минимум — и это уже победа.', author: 'todoLife'),
    _ScreenQuote(text: 'Пять минут — тоже время.', author: 'todoLife'),
    _ScreenQuote(text: 'Стабильный темп — лучший темп.', author: 'todoLife'),
    _ScreenQuote(text: 'Сомнение не делает дело.', author: 'todoLife'),
    _ScreenQuote(text: 'План без действия — просто желание.', author: 'todoLife'),
    _ScreenQuote(text: 'Действие лечит страх.', author: 'todoLife'),
    _ScreenQuote(text: 'Лучший тайм-менеджмент — приоритеты.', author: 'todoLife'),
    _ScreenQuote(text: 'Сначала главное — потом остальное.', author: 'todoLife'),
    _ScreenQuote(text: 'Окружай себя ясностью.', author: 'todoLife'),
    _ScreenQuote(text: 'Не откладывай лёгкое: оно становится тяжёлым.', author: 'todoLife'),
    _ScreenQuote(text: 'Сделай один звонок. Напиши одно сообщение. Сдвинь дело.', author: 'todoLife'),
    _ScreenQuote(text: 'Твоя цель любит регулярность.', author: 'todoLife'),
    _ScreenQuote(text: 'Меньше шума — больше результата.', author: 'todoLife'),
    _ScreenQuote(text: 'Сосредоточься на том, что можешь контролировать.', author: 'todoLife'),
    _ScreenQuote(text: 'Дисциплина — это выбор.', author: 'todoLife'),
    _ScreenQuote(text: 'Отмечай выполненное — мозг любит прогресс.', author: 'todoLife'),
    _ScreenQuote(text: 'Список дел — это карта, а не приговор.', author: 'todoLife'),
    _ScreenQuote(text: 'Если устал — замедлись, но не останавливайся.', author: 'todoLife'),
    _ScreenQuote(text: 'День без плана — день на автопилоте.', author: 'todoLife'),
    _ScreenQuote(text: 'Чистая голова начинается с чистого списка.', author: 'todoLife'),
    _ScreenQuote(text: 'Твоя дисциплина — твоя опора.', author: 'todoLife'),
    _ScreenQuote(text: 'Сначала постоянство, потом скорость.', author: 'todoLife'),
    _ScreenQuote(text: 'Сделай один маленький шаг прямо сейчас.', author: 'todoLife'),
    _ScreenQuote(text: 'Побеждает тот, кто не сдаётся на простом.', author: 'todoLife'),
    _ScreenQuote(text: 'Умение заканчивать — суперсила.', author: 'todoLife'),
    _ScreenQuote(text: 'Долгосрочно выигрывает терпеливый.', author: 'todoLife'),
    _ScreenQuote(text: 'Сначала фундамент, потом вершины.', author: 'todoLife'),
    _ScreenQuote(text: 'Сократи до сущности.', author: 'todoLife'),
    _ScreenQuote(text: 'Решение — это действие.', author: 'todoLife'),
    _ScreenQuote(text: 'Сделай сегодня на 1% лучше.', author: 'todoLife'),
    _ScreenQuote(text: 'Сильные привычки — тихие привычки.', author: 'todoLife'),
    _ScreenQuote(text: 'Записывай: память любит подводить.', author: 'todoLife'),
    _ScreenQuote(text: 'Время — твой главный актив.', author: 'todoLife'),
    _ScreenQuote(text: 'Свобода — это порядок в делах и деньгах.', author: 'todoLife'),
    _ScreenQuote(text: 'Если задача пугает — разбей её.', author: 'todoLife'),
    _ScreenQuote(text: 'Минимум действий > максимум размышлений.', author: 'todoLife'),
    _ScreenQuote(text: 'Дедлайн — это форма заботы о результате.', author: 'todoLife'),
    _ScreenQuote(text: 'Уважай своё время: ставь границы.', author: 'todoLife'),
    _ScreenQuote(text: 'Не нужно всё успеть — нужно успеть важное.', author: 'todoLife'),
    _ScreenQuote(text: 'Один список. Один день. Один шаг.', author: 'todoLife'),
    _ScreenQuote(text: 'Сначала ясность, потом мотивация.', author: 'todoLife'),
    _ScreenQuote(text: 'Проверяй план утром, благодарь себя вечером.', author: 'todoLife'),
    _ScreenQuote(text: 'Твои действия — твой характер.', author: 'todoLife'),
    _ScreenQuote(text: 'Привычка экономить — привычка побеждать.', author: 'todoLife'),
    _ScreenQuote(text: 'Сбережения — это уважение к будущему.', author: 'todoLife'),
    _ScreenQuote(text: 'Где внимание — там рост.', author: 'todoLife'),
    _ScreenQuote(text: 'Порядок — это роскошь, доступная каждому.', author: 'todoLife'),
    _ScreenQuote(text: 'Будь верен процессу.', author: 'todoLife'),
    _ScreenQuote(text: 'Путь строится шагами.', author: 'todoLife'),
    _ScreenQuote(text: 'Работай с тем, что есть — и станет больше.', author: 'todoLife'),
  ];

  void _nextQuote() {
    final n = _quotes.length;
    if (n == 0) return;
    setState(() {
      if (n == 1) {
        _quoteIndex = 0;
        return;
      }
      int next;
      do {
        next = _quoteRandom.nextInt(n);
      } while (next == _quoteIndex);
      _quoteIndex = next;
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selected = today;
    _weekAnchor = _startOfWeek(today);
    if (_quotes.isNotEmpty) {
      _quoteIndex = _quoteRandom.nextInt(_quotes.length);
    }
    _quoteTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _nextQuote();
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  DateTime _startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final mondayIndex = (day.weekday + 6) % 7; // Monday=0
    return day.subtract(Duration(days: mondayIndex));
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // (Intentionally unused for now) Keep today key available for future Home widgets.
    // ignore: unused_local_variable
    final daily = appState.tasks(TaskKind.daily);
    // ignore: unused_local_variable
    final dailyLeft = daily.where((t) => t.done == false).toList(growable: false);
    // ignore: unused_local_variable
    final eventsList = appState.eventsForDateKey(dateKey);
    final topTitle = 'TODO LIFE';
    final topSubtitle = 'ПЛАН И ДИСЦИПЛИНА';

    final selected = DateTime(_selected.year, _selected.month, _selected.day);
    final weekStart = _startOfWeek(_weekAnchor);
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final selectedKey = _dateKey(selected);
    final selectedEvents = appState.eventsForDateKey(selectedKey);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/home_bg.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xC8000000),
                  Color(0x8A000000),
                  Color(0x66000000),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep spacing consistent across screens.

                return Stack(
                  children: [
                    // (Removed) left vertical label per request.

                    // Top-left title block
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 2.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            topSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                              letterSpacing: 2.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // (Removed) Big metric + mode buttons per request.

                    // Motivation quote (auto-rotate every 30s)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 110,
                      bottom: 210,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _QuoteView(
                              key: ValueKey('quote_$_quoteIndex'),
                              quote: _quotes[_quoteIndex],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom: calendar strip + events summary
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _BottomCalendar(
                        today: today,
                        selected: selected,
                        weekDays: weekDays,
                        hasEvents: (d) => appState.hasEventsForDateKey(_dateKey(d)),
                        onSelect: (d) async {
                          setState(() {
                            _selected = d;
                            _weekAnchor = _startOfWeek(d);
                          });
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CalendarEventEditScreen(date: d),
                            ),
                          );
                        },
                        onPrevWeek: () => setState(() {
                          _weekAnchor = _weekAnchor.subtract(const Duration(days: 7));
                        }),
                        onNextWeek: () => setState(() {
                          _weekAnchor = _weekAnchor.add(const Duration(days: 7));
                        }),
                        onToday: () => setState(() {
                          _selected = today;
                          _weekAnchor = _startOfWeek(today);
                        }),
                        events: selectedEvents,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _QuoteView extends StatelessWidget {
  const _QuoteView({super.key, required this.quote});

  final _ScreenQuote quote;

  static String _attributionLine(_ScreenQuote q) {
    final a = q.author.toLowerCase();
    if (a == 'todolife' || a == 'народная мудрость') return '';
    if (q.source == null || q.source!.isEmpty) return q.author;
    return '${q.author} · ${q.source}';
  }

  @override
  Widget build(BuildContext context) {
    // Keep layout robust for small heights (e.g. tests / web resize).
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxHeight < 140;
        final quoteSize = compact ? 18.0 : 22.0;
        final quoteLines = compact ? 3 : 4;
        final authorSize = compact ? 9.0 : 10.0;
        final gap = compact ? 6.0 : 10.0;
        final attribution = _attributionLine(quote);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“${quote.text}”',
              maxLines: quoteLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: quoteSize,
                height: 1.16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            if (attribution.isNotEmpty) ...[
              SizedBox(height: gap),
              Text(
                attribution,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: authorSize,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BottomCalendar extends StatelessWidget {
  const _BottomCalendar({
    required this.today,
    required this.selected,
    required this.weekDays,
    required this.hasEvents,
    required this.onSelect,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onToday,
    required this.events,
  });

  final DateTime today;
  final DateTime selected;
  final List<DateTime> weekDays;
  final bool Function(DateTime) hasEvents;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;
  final List<dynamic> events; // CalendarEvent, but avoid import cycle here.

  @override
  Widget build(BuildContext context) {
    final dateText =
        DateFormat('d MMMM yyyy', 'ru_RU').format(selected).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevWeek,
                icon: Icon(
                  Icons.chevron_left,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              Expanded(
                child: Text(
                  dateText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 11,
                    letterSpacing: 2.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: onToday,
                child: Text(
                  'СЕГОДНЯ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 10,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextWeek,
                icon: Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 120) return;
              if (v > 0) {
                onPrevWeek();
              } else {
                onNextWeek();
              }
            },
            child: Row(
              children: [
                for (final d in weekDays) ...[
                  Expanded(
                    child: _MiniDay(
                      date: d,
                      isToday: d.year == today.year &&
                          d.month == today.month &&
                          d.day == today.day,
                      selected: d.year == selected.year &&
                          d.month == selected.month &&
                          d.day == selected.day,
                      hasEvents: hasEvents(d),
                      onTap: () => onSelect(d),
                    ),
                  ),
                  if (d != weekDays.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (events.isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                // Open day details via existing CalendarDayScreen.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CalendarDayScreen(date: selected),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'СОБЫТИЙ: ${events.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 9,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (events.first as dynamic).title.toString().toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 9,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Text(
                'СОБЫТИЙ НЕТ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 9,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniDay extends StatelessWidget {
  const _MiniDay({
    required this.date,
    required this.isToday,
    required this.selected,
    required this.hasEvents,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool selected;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.22);
    final fg = selected ? Colors.white : Colors.white.withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: border, width: selected ? 1.2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EE', 'ru_RU').format(date).toUpperCase(),
              style: TextStyle(
                color: fg,
                fontSize: 9,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: fg,
                fontSize: 13,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 4,
              width: 4,
              decoration: BoxDecoration(
                color: hasEvents
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 4),
              Container(
                height: 1,
                width: 16,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

