import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class AurenExtraGamesScreen extends StatefulWidget {
  const AurenExtraGamesScreen({super.key});
  @override State<AurenExtraGamesScreen> createState() => _AurenExtraGamesScreenState();
}

class _AurenExtraGamesScreenState extends State<AurenExtraGamesScreen> {
  int _selected = 0;
  final _games = const [
    ('Memory', Icons.grid_view_rounded),
    ('Quiz', Icons.quiz_outlined),
    ('Reaction', Icons.touch_app_outlined),
    ('Dice Duel', Icons.casino_outlined),
    ('Higher / Lower', Icons.swap_vert_rounded),
    ('Word Scramble', Icons.abc_rounded),
    ('2048', Icons.apps_rounded),
    ('Simon', Icons.pattern_rounded), ('Math Sprint', Icons.calculate_outlined), ('Number Guess', Icons.numbers_rounded),
    ('Coin Flip', Icons.toll_outlined), ('Target Tap', Icons.my_location_outlined), ('Hangman', Icons.text_fields_rounded),
    ('Word Chain', Icons.link_rounded), ('Color Match', Icons.palette_outlined), ('Odd One Out', Icons.filter_1_outlined), ('Quick Count', Icons.timer_outlined),
    ('⚔️ Arena Duel', Icons.sports_kabaddi), ('🥊 Punch Rush', Icons.sports_mma), ('🛡️ Shield Block', Icons.shield_outlined), ('🏹 Archer Aim', Icons.gps_fixed), ('⚡ Battle Reflex', Icons.flash_on),
    ('⚽ Penalty King', Icons.sports_soccer), ('🏀 Hoops', Icons.sports_basketball), ('🏃 Sprint', Icons.directions_run), ('🎾 Tennis Rally', Icons.sports_tennis), ('🚴 Cycling', Icons.directions_bike),
    ('🧩 Logic Grid', Icons.extension), ('🔢 Number Matrix', Icons.grid_4x4), ('♟️ Strategy', Icons.psychology), ('🧠 Pattern Logic', Icons.hub), ('🔐 Code Breaker', Icons.lock_outline),
    ('🃏 Memory Match+', Icons.style), ('🧠 Sequence Recall', Icons.psychology_alt), ('🔵 Color Memory', Icons.circle), ('🧩 Pair Recall', Icons.grid_view), ('👀 Flash Memory', Icons.visibility),
    ('🔥 AUREN Arena', Icons.local_fire_department),
    ('🗺️ Lost World', Icons.explore), ('🏜️ Desert Quest', Icons.landscape), ('🌊 Ocean Explorer', Icons.water), ('🌲 Wild Trails', Icons.forest), ('🚀 Beyond Earth', Icons.rocket_launch), ('🏙️ AUREN City', Icons.location_city),
  ];

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Mini Games')),
      body: Column(children: [
        SizedBox(
          height: 62,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: _games.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChoiceChip(
              selected: _selected == i,
              avatar: Icon(_games[i].$2, size: 18),
              label: Text(_games[i].$1),
              onSelected: (_) => setState(() => _selected = i),
            ),
          ),
        ),
        Expanded(child: _selected < 7 ? IndexedStack(index: _selected, children: const [
          _MemoryGame(), _QuizGame(), _ReactionGame(), _DiceDuelGame(),
          _HigherLowerGame(), _WordScrambleGame(), _TwentyFortyEightGame(),
        ]) : _selected < 17 ? _TenMoreGamesPanel(initialIndex: _selected - 7) : _selected < 38 ? _CategoryGamesPanel(initialIndex: _selected - 17) : _AdventureGamesPanel(initialIndex: _selected - 38)),
      ]),
    );
  }
}

class _MemoryGame extends StatefulWidget {
  const _MemoryGame();
  @override State<_MemoryGame> createState() => _MemoryGameState();
}
class _MemoryGameState extends State<_MemoryGame> {
  final _rng = Random();
  late List<String> _cards;
  List<int> _open = [];
  final Set<int> _matched = {};
  int _moves = 0;
  bool _locked = false;
  final _symbols = const ['🌟','🚀','🎮','🔥','💎','🌙','⚡','🎯'];

  @override void initState() { super.initState(); _reset(); }
  void _reset() {
    _cards = [..._symbols, ..._symbols]..shuffle(_rng);
    _open = []; _matched.clear(); _moves = 0; _locked = false;
  }
  void _tap(int i) {
    if (_locked || _matched.contains(i) || _open.contains(i)) return;
    setState(() => _open.add(i));
    if (_open.length == 2) {
      _moves++;
      final a = _open[0], b = _open[1];
      if (_cards[a] == _cards[b]) {
        setState(() { _matched..add(a)..add(b); _open.clear(); });
      } else {
        _locked = true;
        Future.delayed(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          setState(() { _open.clear(); _locked = false; });
        });
      }
    }
  }
  @override Widget build(BuildContext context) => _GamePage(
    title: 'Memory', subtitle: 'طابق الرموز بأقل عدد من الحركات.',
    top: Text('الحركات: ${_moves} • المطابق: ${_matched.length ~/ 2}/8'),
    child: GridView.builder(
      padding: const EdgeInsets.all(8), shrinkWrap: true, itemCount: 16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (_, i) {
        final visible = _open.contains(i) || _matched.contains(i);
        return FilledButton(onPressed: () => _tap(i),
          child: Text(visible ? _cards[i] : '?', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)));
      },
    ),
    action: OutlinedButton.icon(onPressed: () => setState(_reset), icon: const Icon(Icons.refresh), label: const Text('إعادة')),
  );
}

class _QuizGame extends StatefulWidget {
  const _QuizGame();
  @override State<_QuizGame> createState() => _QuizGameState();
}
class _QuizGameState extends State<_QuizGame> {
  final _questions = const [
    ('ما هو الكوكب المعروف بالكوكب الأحمر؟',['الأرض','المريخ','الزهرة','المشتري'],1),
    ('كم عدد ألوان قوس قزح التقليدية؟',['5','6','7','8'],2),
    ('ما عاصمة اليابان؟',['طوكيو','كيوتو','أوساكا','نارا'],0),
    ('ما أكبر محيط على الأرض؟',['الأطلسي','الهندي','المتجمد','الهادئ'],3),
    ('ما لغة AUREN البرمجية الأساسية في الواجهة؟',['Dart','Java','Swift','Go'],0),
    ('كم ضلعاً للمثلث؟',['2','3','4','5'],1),
    ('أي حيوان يُعرف بسفينة الصحراء؟',['الحصان','الجمل','الفيل','الذئب'],1),
    ('ما ناتج 8 × 7؟',['54','56','64','72'],1),
  ];
  int _index = 0, _score = 0;
  void _answer(int i) {
    if (_index >= _questions.length) return;
    if (i == _questions[_index].$3) _score++;
    setState(() => _index++);
  }
  void _reset() => setState(() { _index = 0; _score = 0; });
  @override Widget build(BuildContext context) {
    if (_index >= _questions.length) {
      return _GamePage(title: 'Quiz', subtitle: 'اختبر معلوماتك بسرعة.', child: Column(children: [
        const Icon(Icons.emoji_events, size: 64), const SizedBox(height: 12),
        Text('نتيجتك ${_score}/${_questions.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      ]), action: FilledButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('جولة جديدة')));
    }
    final q = _questions[_index];
    return _GamePage(title: 'Quiz', subtitle: 'السؤال ${_index + 1} من ${_questions.length}',
      top: LinearProgressIndicator(value: (_index + 1) / _questions.length),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(q.$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        for (var i = 0; i < q.$2.length; i++) ...[
          FilledButton.tonal(onPressed: () => _answer(i), child: Text(q.$2[i])),
          const SizedBox(height: 8),
        ],
      ]));
  }
}

class _ReactionGame extends StatefulWidget {
  const _ReactionGame();
  @override State<_ReactionGame> createState() => _ReactionGameState();
}
class _ReactionGameState extends State<_ReactionGame> {
  final _rng = Random();
  Timer? _timer;
  bool _ready = false, _go = false;
  int? _started;
  String _message = 'اضغط ابدأ ثم انتظر الإشارة';
  void _start() {
    _timer?.cancel();
    setState(() { _ready = true; _go = false; _message = 'انتظر… لا تضغط الآن!'; });
    _timer = Timer(Duration(milliseconds: 1200 + _rng.nextInt(2600)), () {
      if (!mounted) return;
      setState(() { _go = true; _started = DateTime.now().microsecondsSinceEpoch; _message = 'اضغط الآن!'; });
    });
  }
  void _tap() {
    if (!_ready) return;
    if (!_go) { _timer?.cancel(); setState(() { _ready = false; _message = 'مبكر جداً 😄'; }); return; }
    final ms = (DateTime.now().microsecondsSinceEpoch - (_started ?? 0)) ~/ 1000;
    setState(() { _ready = false; _go = false; _message = '${ms} ms — حاول تحطم رقمك!'; });
  }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) => _GamePage(
    title: 'Reaction Battle', subtitle: 'اختبر سرعة رد فعلك.',
    child: GestureDetector(onTap: _tap,
      child: Container(height: 260, alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
          color: _go ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest),
        child: Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)))),
    action: FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: const Text('ابدأ')),
  );
}

class _DiceDuelGame extends StatefulWidget {
  const _DiceDuelGame();
  @override State<_DiceDuelGame> createState() => _DiceDuelGameState();
}
class _DiceDuelGameState extends State<_DiceDuelGame> {
  final _rng = Random();
  int _you = 0, _ai = 0, _round = 0, _youWins = 0, _aiWins = 0;
  void _roll() {
    final a = 1 + _rng.nextInt(6), b = 1 + _rng.nextInt(6);
    setState(() { _you = a; _ai = b; _round++; if (a > b) _youWins++; if (b > a) _aiWins++; });
  }
  @override Widget build(BuildContext context) => _GamePage(title: 'Dice Duel', subtitle: 'ارمِ النرد وتغلب على AUREN.',
    top: Text('جولات: ${_round} • أنت: ${_youWins} • AUREN: ${_aiWins}', style: const TextStyle(fontWeight: FontWeight.w800)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_die('أنت', _you), _die('AUREN', _ai)]),
    action: FilledButton.icon(onPressed: _roll, icon: const Icon(Icons.casino), label: const Text('ارمِ النرد')));
  Widget _die(String name, int n) => Column(children: [
    Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
    Text(n == 0 ? '🎲' : const ['','⚀','⚁','⚂','⚃','⚄','⚅'][n], style: const TextStyle(fontSize: 64)),
  ]);
}

class _HigherLowerGame extends StatefulWidget {
  const _HigherLowerGame();
  @override State<_HigherLowerGame> createState() => _HigherLowerGameState();
}
class _HigherLowerGameState extends State<_HigherLowerGameState> {
  final _rng = Random();
  int _current = 50, _next = 0, _score = 0, _best = 0;
  void _guess(bool higher) {
    if (_next == 0) { setState(() => _next = 1 + _rng.nextInt(99)); return; }
    final correct = higher ? _next > _current : _next < _current;
    setState(() {
      if (correct) { _score++; _current = _next; _next = 0; }
      else { _best = max(_best, _score); _score = 0; _current = 50; _next = 0; }
    });
  }
  @override Widget build(BuildContext context) => _GamePage(title: 'Higher / Lower', subtitle: 'هل الرقم القادم أعلى أم أقل؟',
    child: Column(children: [
      Text('${_current}', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900)),
      Text('النقاط: ${_score} • الأفضل: ${_best}'),
      const SizedBox(height: 12),
      if (_next != 0) Text('الرقم القادم: ${_next}', style: const TextStyle(fontWeight: FontWeight.w800))
      else const Text('اختر توقعك لبدء الجولة.'),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: FilledButton.tonal(onPressed: () => _guess(false), child: const Text('أقل ↓'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: () => _guess(true), child: const Text('أعلى ↑'))),
      ]),
    ]));
}

class _WordScrambleGame extends StatefulWidget {
  const _WordScrambleGame();
  @override State<_WordScrambleGame> createState() => _WordScrambleGameState();
}
class _WordScrambleGameState extends State<_WordScrambleGame> {
  final _rng = Random();
  final _words = const ['AUREN','SUDAN','FLUTTER','PLANET','MUSIC','GAMING','FRIEND','FUTURE'];
  late String _word, _scrambled;
  final _controller = TextEditingController();
  int _score = 0;
  @override void initState() { super.initState(); _newWord(); }
  void _newWord() {
    _word = _words[_rng.nextInt(_words.length)];
    final chars = _word.split('')..shuffle(_rng);
    _scrambled = chars.join();
    if (_scrambled == _word && _word.length > 1) _scrambled = _word.split('').reversed.join();
  }
  void _check() {
    final ok = _controller.text.trim().toUpperCase() == _word;
    setState(() { if (ok) _score++; _newWord(); _controller.clear(); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'صحيح! 🎉' : 'ليست الإجابة الصحيحة.')));
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => _GamePage(title: 'Word Scramble', subtitle: 'رتّب الحروف واكتشف الكلمة.',
    top: Text('النقاط: ${_score}', style: const TextStyle(fontWeight: FontWeight.w800)),
    child: Column(children: [
      Text(_scrambled, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 4)),
      const SizedBox(height: 16),
      TextField(controller: _controller, textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'إجابتك', border: OutlineInputBorder()), onSubmitted: (_) => _check()),
    ]),
    action: FilledButton.icon(onPressed: _check, icon: const Icon(Icons.check), label: const Text('تحقق')));
}

class _TwentyFortyEightGame extends StatefulWidget {
  const _TwentyFortyEightGame();
  @override State<_TwentyFortyEightGame> createState() => _TwentyFortyEightGameState();
}
class _TwentyFortyEightGameState extends State<_TwentyFortyEightGame> {
  final _rng = Random();
  late List<int> _board;
  int _score = 0;
  @override void initState() { super.initState(); _reset(); }
  void _reset() { _board = List.filled(16, 0); _score = 0; _spawn(); _spawn(); }
  void _spawn() {
    final empty = [for (var i = 0; i < 16; i++) if (_board[i] == 0)];
    if (empty.isEmpty) return;
    _board[empty[_rng.nextInt(empty.length)]] = _rng.nextInt(10) == 0 ? 4 : 2;
  }
  List<int> _mergeLine(List<int> line) {
    final a = line.where((e) => e != 0).toList(), out = <int>[];
    for (var i = 0; i < a.length; i++) {
      if (i + 1 < a.length && a[i] == a[i + 1]) { out.add(a[i] * 2); _score += a[i] * 2; i++; }
      else { out.add(a[i]); }
    }
    while (out.length < 4) out.add(0);
    return out;
  }
  void _move(String dir) {
    final old = List<int>.from(_board);
    final rows = [for (var r = 0; r < 4; r++) _board.sublist(r * 4, r * 4 + 4)];
    List<List<int>> work;
    if (dir == 'left') work = rows.map(_mergeLine).toList();
    else if (dir == 'right') work = rows.map((r) => _mergeLine(r.reversed.toList()).reversed.toList()).toList();
    else {
      work = List.generate(4, (c) {
        final col = [for (var r = 0; r < 4; r++) rows[r][c]];
        return dir == 'up' ? _mergeLine(col) : _mergeLine(col.reversed.toList()).reversed.toList();
      });
      final next = List.filled(16, 0);
      for (var c = 0; c < 4; c++) for (var r = 0; r < 4; r++) next[r * 4 + c] = work[c][r];
      work = [for (var r = 0; r < 4; r++) next.sublist(r * 4, r * 4 + 4)];
    }
    final next = [for (final row in work) ...row];
    var changed = false;
    for (var i = 0; i < 16; i++) if (old[i] != next[i]) changed = true;
    if (!changed) return;
    setState(() { _board = next; _spawn(); });
  }
  @override Widget build(BuildContext context) => _GamePage(title: '2048', subtitle: 'حرّك البلاطات وحاول الوصول إلى 2048.',
    top: Text('النقاط: ${_score}', style: const TextStyle(fontWeight: FontWeight.w800)),
    child: Column(children: [
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 16,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
        itemBuilder: (_, i) => Container(alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Theme.of(context).colorScheme.surfaceContainerHighest),
          child: Text(_board[i] == 0 ? '' : '${_board[i]}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        IconButton.filledTonal(onPressed: () => _move('left'), icon: const Icon(Icons.arrow_back)),
        IconButton.filledTonal(onPressed: () => _move('up'), icon: const Icon(Icons.arrow_upward)),
        IconButton.filledTonal(onPressed: () => _move('down'), icon: const Icon(Icons.arrow_downward)),
        IconButton.filledTonal(onPressed: () => _move('right'), icon: const Icon(Icons.arrow_forward)),
      ]),
    ]),
    action: OutlinedButton.icon(onPressed: () => setState(_reset), icon: const Icon(Icons.refresh), label: const Text('إعادة')));
}

class _GamePage extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final Widget? top, action;
  const _GamePage({required this.title, required this.subtitle, required this.child, this.top, this.action});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    const SizedBox(height: 4), Text(subtitle),
    if (top != null) ...[const SizedBox(height: 14), top!],
    const SizedBox(height: 16),
    Card(child: Padding(padding: const EdgeInsets.all(16), child: child)),
    if (action != null) ...[const SizedBox(height: 14), action!],
  ]);
}

class _CategoryGamesPanel extends StatefulWidget {
  final int initialIndex;
  const _CategoryGamesPanel({required this.initialIndex});
  @override State<_CategoryGamesPanel> createState()=>_CategoryGamesPanelState();
}
class _CategoryGamesPanelState extends State<_CategoryGamesPanel>{
  final _rng=Random(); late int _game; int _score=0,_streak=0,_a=0,_b=0,_target=0; List<int> _memory=[]; String _message='ابدأ!';
  @override void initState(){super.initState();_game=widget.initialIndex;_newRound();}
  void _newRound(){_a=1+_rng.nextInt(9);_b=1+_rng.nextInt(9);_target=1+_rng.nextInt(9);_memory=List.generate(6,(_)=>_rng.nextInt(4));_message='اختبر نفسك';}
  void _hit(bool ok){setState((){if(ok){_score++;_streak++;_message='ممتاز! 🔥';}else{_streak=0;_message='حاول مرة أخرى';}_newRound();});}
  @override Widget build(BuildContext context){
    final names=['Arena Duel','Punch Rush','Shield Block','Archer Aim','Battle Reflex','Penalty King','Hoops','Sprint','Tennis Rally','Cycling','Logic Grid','Number Matrix','Strategy','Pattern Logic','Code Breaker','Memory Match+','Sequence Recall','Color Memory','Pair Recall','Flash Memory','AUREN Arena'];
    Widget body; String cat;
    if(_game<5){cat='⚔️ ألعاب قتالية';body=_combat();}else if(_game<10){cat='🏆 ألعاب رياضية';body=_sport();}else if(_game<15){cat='🧠 ألعاب تفكير';body=_thinking();}else if(_game<20){cat='👀 ألعاب ذاكرة';body=_memory();}else{cat='🔥 اللعبة الجاذبة';body=_arena();}
    return ListView(padding:const EdgeInsets.all(16),children:[Text(cat,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:6),Text('النقاط: $_score • السلسلة: $_streak'),const SizedBox(height:14),
      Wrap(spacing:6,runSpacing:6,children:[for(var i=0;i<names.length;i++)ChoiceChip(label:Text(names[i]),selected:_game==i,onSelected:(_)=>setState((){_game=i;_newRound();}))]),const SizedBox(height:16),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:body)),const SizedBox(height:12),FilledButton.icon(onPressed:()=>setState((){_score=0;_streak=0;_newRound();}),icon:const Icon(Icons.refresh),label:const Text('إعادة'))]);
  }
  Widget _combat(){final l=['ضربة سريعة','ضربة قوية','تفادي','صد'];return Column(children:[const Text('🥊',style:TextStyle(fontSize:62)),const Text('اقرأ الهجمة واختر الرد الصحيح'),const SizedBox(height:12),Wrap(spacing:8,children:[for(var i=0;i<4;i++)FilledButton.tonal(onPressed:()=>_hit(i==(_a%4)),child:Text(l[i]))]),Text(_message)]);}
  Widget _sport(){final s=_game-5;final l=s==0?['يسار','وسط','يمين']:s==1?['رمي بعيد','رمي متوسط','رمي قريب']:s==2?['انطلق','قفزة','اندفاع']:s==3?['يسار','وسط','يمين']:['دواسة سريعة','دواسة ثابتة','تغيير مسار'];return Column(children:[Text(['⚽','🏀','🏃','🎾','🚴'][s],style:const TextStyle(fontSize:60)),Text(_message),Wrap(spacing:8,children:[for(var i=0;i<3;i++)FilledButton.tonal(onPressed:()=>_hit(i==(_a%3)),child:Text(l[i]))])]);}
  Widget _thinking(){final t=_game-10;if(t==0)return _choice('أكمل النمط: ${_a} → ${(_a+2)%10} → ${(_a+4)%10} → ?',['${(_a+6)%10}','${(_a+5)%10}','${(_a+3)%10}'],0);if(t==1)return _choice('اختر الرقم الأكبر',[_a,_b,_a+_b],2);if(t==2)return _choice('أي خطة تكسب؟',['هجوم','دفاع','تفادي'],_a%3);if(t==3)return _choice('أين المختلف؟',['●●●','●○●','●●●'],1);return _choice('فك الشفرة: ${_a} + ${_b} = ?',[_a+_b,_a+_b+1,_a+_b-1],0);}
  Widget _choice(String title,List<dynamic> v,int c)=>Column(children:[Text(title,textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:10),Wrap(spacing:8,children:[for(var i=0;i<v.length;i++)FilledButton.tonal(onPressed:()=>_hit(i==c),child:Text('${v[i]}'))])]);
  Widget _memory(){final k=_game-15;if(k==0)return Column(children:[const Text('احفظ التسلسل ثم اختر آخر رقم'),Text(_memory.map((e)=>e+1).join(' • '),style:const TextStyle(fontSize:27,fontWeight:FontWeight.w900)),Wrap(spacing:8,children:[for(var n=1;n<=4;n++)FilledButton.tonal(onPressed:()=>_hit(n==_memory.last+1),child:Text('${n}'))])]);if(k==1)return _choice('ما الرقم الأول؟',[1,2,3,4],_memory.first);if(k==2)return _choice('تذكر اللون الأول',['🔴','🟢','🔵','🟡'],_memory.first);if(k==3)return _choice('تذكر الموضع',['1','2','3'],_memory[2]%3);return Column(children:[const Text('FLASH MEMORY',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),Text('احفظ الرقم: $_target',style:const TextStyle(fontSize:30)),FilledButton(onPressed:()=>_hit(true),child:const Text('أتذكره!'))]);}
  Widget _arena(){final a=['⚔️ هجوم','🛡️ دفاع','⚡ تفادي','🎯 ضربة دقيقة'];return Column(children:[const Text('🔥 AUREN ARENA',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),const Text('جولة سريعة ضد AUREN — اصنع أطول سلسلة.'),const SizedBox(height:12),Text('هجمة الخصم: ${a[_a%4]}'),Wrap(spacing:8,children:[for(var i=0;i<4;i++)FilledButton.tonal(onPressed:()=>_hit(i==((_a+1)%4)),child:Text(a[i]))]),Text(_message)]);}
}

class _TenMoreGamesPanel extends StatefulWidget {
  final int initialIndex;
  const _TenMoreGamesPanel({required this.initialIndex});
  @override State<_TenMoreGamesPanel> createState()=>_TenMoreGamesPanelState();
}
class _TenMoreGamesPanelState extends State<_TenMoreGamesPanel>{
  int _game=0,_score=0,_number=50,_target=50,_heads=0,_tails=0,_mathA=2,_mathB=3,_mathAnswer=5,_seconds=20,_targetScore=0,_hangWrong=0,_odd=0,_color=0,_count=5;
  final _rng=Random(); final _input=TextEditingController();
  @override void initState(){super.initState();_game=widget.initialIndex;} String _word='AUREN',_last='AUREN',_msg='ابدأ اللعبة';
  Timer? _timer;
  final _words=['AUREN','SUDAN','FLUTTER','MUSIC','PLANET'];
  void _reset(){_score=0;_number=50;_target=1+_rng.nextInt(100);_heads=0;_tails=0;_seconds=20;_targetScore=0;_hangWrong=0;_last='AUREN';_msg='ابدأ اللعبة';_newMath();_newRound();setState((){});}
  void _newMath(){_mathA=1+_rng.nextInt(12);_mathB=1+_rng.nextInt(12);_mathAnswer=_mathA+_mathB;}
  void _newRound(){_odd=_rng.nextInt(9);_color=_rng.nextInt(4);_count=2+_rng.nextInt(9);}
  void _math(int n){if(n==_mathAnswer){_score++;_newMath();setState((){});}}
  void _guess(int n){if(n==_target){_score++;_target=1+_rng.nextInt(100);_msg='🎉 صحيح!';}else{_msg=n<_target?'أعلى ↑':'أقل ↓';}setState((){});}
  void _flip(){final h=_rng.nextBool();if(h)_heads++;else _tails++;_msg=h?'🟡 صورة':'⚪ كتابة';setState((){});}
  void _target(){_targetScore++;setState((){});}
  void _hang(String l){if(_word.contains(l)){_msg='حرف صحيح';}else{_hangWrong++;_msg='حرف غير صحيح';}setState((){});}
  void _chain(){final w=_input.text.trim().toUpperCase();if(w.length>1&&w[0]==_last[_last.length-1]&&w!=_last){_last=w;_score++;_input.clear();_msg='صحيح!';}else{_msg='ابدأ بحرف '+_last[_last.length-1];}setState((){});}
  void _pickColor(int i){if(i==_color)_score++;_newRound();setState((){});}
  void _oddPick(int i){if(i==_odd)_score++;_newRound();setState((){});}
  void _quick(int n){if(n==_count)_score++;_newRound();setState((){});}
  @override void dispose(){_timer?.cancel();_input.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final names=['Simon','Math Sprint','Number Guess','Coin Flip','Target Tap','Hangman','Word Chain','Color Match','Odd One Out','Quick Count'];
    Widget body;
    switch(_game){
      case 0: body=Column(children:[Text('النمط: '+(_score%2==0?'🔵 🟢 🟡':'🟢 🔴 🟡'),style:const TextStyle(fontSize:28)),const SizedBox(height:14),Wrap(spacing:8,children:[for(var i=0;i<4;i++)FilledButton.tonal(onPressed:(){if(i==(_score%4)){_score++;setState((){});}else{_msg='حاول مرة أخرى';setState((){});}},child:Text(['🔵','🟢','🟡','🔴'][i]))])]);break;
      case 1: body=Column(children:[Text(_mathA.toString()+' + '+_mathB.toString()+' = ?',style:const TextStyle(fontSize:32,fontWeight:FontWeight.w900)),Wrap(spacing:8,children:[for(var n in [_mathAnswer-2,_mathAnswer-1,_mathAnswer,_mathAnswer+1])FilledButton.tonal(onPressed:()=>_math(n),child:Text(n.toString()))])]);break;
      case 2: body=Column(children:[Text(_msg),TextField(keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'خمن 1-100',border:OutlineInputBorder()),onSubmitted:(v){final n=int.tryParse(v);if(n!=null)_guess(n);})]);break;
      case 3: body=Column(children:[Text(_msg,style:const TextStyle(fontSize:50)),Text('صورة: '+_heads.toString()+' • كتابة: '+_tails.toString())]);break;
      case 4: body=Column(children:[Text('🎯',style:const TextStyle(fontSize:70)),Text('النقاط: '+_targetScore.toString()),FilledButton(onPressed:_target,child:const Text('اضغط الهدف'))]);break;
      case 5: body=Column(children:[Text(_word.split('').map((x)=>x==' '? ' ': ' _ ').join()),Text('أخطاء: '+_hangWrong.toString()+'/6'),Wrap(spacing:4,children:[for(final l in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))OutlinedButton(onPressed:()=>_hang(l),child:Text(l))])]);break;
      case 6: body=Column(children:[Text('آخر كلمة: '+_last),TextField(controller:_input,textCapitalization:TextCapitalization.characters,onSubmitted:(_){_chain();},decoration:const InputDecoration(labelText:'كلمة تبدأ بآخر حرف',border:OutlineInputBorder()))]);break;
      case 7: body=Column(children:[Text(['أحمر','أخضر','أزرق','أصفر'][_color],style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900)),Wrap(spacing:8,children:[for(var i=0;i<4;i++)FilledButton.tonal(onPressed:()=>_pickColor(i),child:Text(['أحمر','أخضر','أزرق','أصفر'][i]))])]);break;
      case 8: body=GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:9,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:8,mainAxisSpacing:8),itemBuilder:(_,i)=>FilledButton.tonal(onPressed:()=>_oddPick(i),child:Text(i==_odd?'🔷':'🔹',style:const TextStyle(fontSize:28))));break;
      default: body=Column(children:[Text('عدد النجوم: '+_count.toString(),style:const TextStyle(fontSize:26)),Wrap(spacing:8,children:[for(var n=2;n<=10;n++)FilledButton.tonal(onPressed:()=>_quick(n),child:Text(n.toString()))])]);
    }
    return ListView(padding:const EdgeInsets.all(16),children:[Text('21 لعبة جديدة',style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:8),Wrap(spacing:6,runSpacing:6,children:[for(var i=0;i<names.length;i++)ChoiceChip(label:Text(names[i]),selected:_game==i,onSelected:(_){setState(()=>_game=i);})]),const SizedBox(height:16),Card(child:Padding(padding:const EdgeInsets.all(16),child:body)),const SizedBox(height:12),FilledButton.icon(onPressed:_reset,icon:const Icon(Icons.refresh),label:const Text('إعادة'))]);
  }
}

class _Auren3DQuickPanel extends StatefulWidget {
  final String title; final Auren3DWorldPreset preset;
  const _Auren3DQuickPanel({required this.title, required this.preset});
  @override State<_Auren3DQuickPanel> createState()=>_Auren3DQuickPanelState();
}
class _Auren3DQuickPanelState extends State<_Auren3DQuickPanel>{
  double _x=0,_y=0; int _score=0;
  void _move(double x,double y)=>setState(()=>{_x=(_x+x).clamp(-8,8),_y=(_y+y).clamp(-8,8),_score++});
  @override Widget build(BuildContext context)=>Column(children:[
    SizedBox(height:330,child:ClipRRect(borderRadius:BorderRadius.circular(22),child:CustomPaint(painter:_Auren3DGamePainter(preset:widget.preset,x:_x,y:_y),child:const SizedBox.expand()))),
    const SizedBox(height:10),Text(widget.title+' • نقاط: '+_score.toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
    Wrap(spacing:8,children:[
      IconButton.filledTonal(onPressed:()=>_move(0,-1),icon:const Icon(Icons.arrow_upward)),
      IconButton.filledTonal(onPressed:()=>_move(-1,0),icon:const Icon(Icons.arrow_back)),
      IconButton.filledTonal(onPressed:()=>_move(1,0),icon:const Icon(Icons.arrow_forward)),
      IconButton.filledTonal(onPressed:()=>_move(0,1),icon:const Icon(Icons.arrow_downward)),
    ])
  ]);
}
class _Auren3DGamePainter extends CustomPainter{
 final Auren3DWorldPreset preset; final double x,y;
 const _Auren3DGamePainter({required this.preset,required this.x,required this.y});
 Offset p(Offset v,Size s,[double h=0]){final depth=(8+v.dy).clamp(2.0,20.0),scale=s.shortestSide*.10/depth;return Offset(s.width/2+v.dx*scale,s.height*.62-(h-v.dy*.35)*scale);}
 void box(Canvas c,Size s,double x,double y,double w,double d,double h){
   final q=[p(Offset(x,y),s),p(Offset(x+w,y),s),p(Offset(x+w,y+d),s),p(Offset(x,y+d),s)],t=[p(Offset(x,y),s,h),p(Offset(x+w,y),s,h),p(Offset(x+w,y+d),s,h),p(Offset(x,y+d),s,h)];
   final a=Paint()..color=const Color(0xFF4F5680),b=Paint()..color=const Color(0xFF737BA8);
   c.drawPath(Path()..addPolygon([q[0],q[1],t[1],t[0]],true),a);c.drawPath(Path()..addPolygon([q[1],q[2],t[2],t[1]],true),a);c.drawPath(Path()..addPolygon([q[2],q[3],t[3],t[2]],true),a);c.drawPath(Path()..addPolygon(t,true),b);
 }
 @override void paint(Canvas c,Size s){
   c.drawRect(Offset.zero&s,Paint()..color=const Color(0xFF080A12)); final ground=Paint()..color=const Color(0xFF1A2030);
   c.drawPath(Path()..addPolygon([p(const Offset(-30,-20),s),p(const Offset(30,-20),s),p(const Offset(30,20),s),p(const Offset(-30,20),s)],true),ground);
   for(var i=-6;i<=6;i++){final g=Paint()..color=const Color(0xFF343A55);c.drawLine(p(Offset(i*4,-18),s),p(Offset(i*4,18),s),g);c.drawLine(p(Offset(-24,i*4),s),p(Offset(24,i*4),s),g);}
   if(preset==Auren3DWorldPreset.city||preset==Auren3DWorldPreset.arena)for(var i=0;i<6;i++)box(c,s,-18+(i%3)*12,-10+(i~/3)*12,7,6,6+(i%3)*3);
   if(preset==Auren3DWorldPreset.sports)box(c,s,-18,-10,36,20,.3);
   if(preset==Auren3DWorldPreset.desert)for(var i=0;i<5;i++)box(c,s,-20+i*9,7-(i%2)*8,6,5,1+i%3);
   c.drawCircle(p(Offset(x,y),s,4),9,Paint()..color=const Color(0xFFE9ECFF));
 }
 @override bool shouldRepaint(covariant _Auren3DGamePainter o)=>o.x!=x||o.y!=y||o.preset!=preset;
}

class _AdventureGamesPanel extends StatefulWidget {
  final int initialIndex;
  const _AdventureGamesPanel({required this.initialIndex});
  @override State<_AdventureGamesPanel> createState() => _AdventureGamesPanelState();
}

class _AdventureGamesPanelState extends State<_AdventureGamesPanel> {
  late int _game;
  int _step = 0, _coins = 0, _energy = 10;
  final _rng = Random();
  @override void initState() { super.initState(); _game = widget.initialIndex; }
  void _reset() => setState(() { _step = 0; _coins = 0; _energy = 10; });
  void _act() { if (_energy <= 0) return; setState(() { _step++; _energy--; _coins += 10 + _rng.nextInt(21); }); }
  @override Widget build(BuildContext context) {
    const names = ['🗺️ Lost World','🏜️ Desert Quest','🌊 Ocean Explorer','🌲 Wild Trails','🚀 Beyond Earth','🏙️ AUREN City'];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(names[_game], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      Text('المستوى ${1 + _step ~/ 5} • 🪙 $_coins • ⚡ $_energy'),
      const SizedBox(height: 14),
      Wrap(spacing: 6, runSpacing: 6, children: [for (var i=0;i<names.length;i++) ChoiceChip(label: Text(names[i]), selected: _game==i, onSelected: (_) => setState(() { _game=i; _step=0; }))]),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: _body())),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _act, icon: const Icon(Icons.explore), label: Text(_button())),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('رحلة جديدة')),
    ]);
  }
  String _button() {
    if (_energy <= 0) return 'استرح وأعد الرحلة';
    const b=['استكشف المنطقة','اعبر الصحراء','اكتشف المحيط','تتبع الدرب','استكشف الكوكب','تحرك داخل المدينة'];
    return b[_game];
  }
  Widget _body() {
    const titles=['العالم المفقود','رحلة الصحراء','مستكشف المحيط','دروب البرية','ما وراء الأرض'];
    const desc=['استكشف الجزر، اعثر على الآثار وافتح المناطق السرية.','أوصل القافلة إلى الواحة واجمع الأدلة عن المدينة الأثرية.','أبحر ثم غص لاكتشاف الجزر والآثار الغارقة.','اتبع آثار الحيوانات واعثر على القمة والمناطق النادرة.','اجمع الموارد، طوّر المركبة واكتشف كوكباً مجهولاً.'];
    const places=[['🏝️ جزيرة البداية','🏺 معبد قديم','💎 كهف البلور','🗿 المدينة المفقودة'],['🏕️ المخيم','💧 الواحة','🐪 طريق القافلة','🏺 المدينة المدفونة'],['🚤 الميناء','🏝️ الجزيرة','🤿 موقع الغوص','🗿 المدينة الغارقة'],['🌲 الغابة','🦌 مسار الحياة البرية','🏕️ المخيم','🏔️ القمة'],['🚀 محطة الإطلاق','🪐 الكوكب','⛏️ حقل الموارد','🛰️ القاعدة']];
    if (_game < 5) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titles[_game], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(desc[_game]), const SizedBox(height: 12),
      ...List.generate(4,(i)=>ListTile(contentPadding:EdgeInsets.zero,leading:Icon(_step>i?Icons.check_circle:Icons.radio_button_unchecked),title:Text(places[_game][i]),subtitle:Text(_step>i?'تم اكتشافها':'اكتشفها في الرحلة'))),
    ]);
    final x=_step%5,y=(_step~/5)%5;
    return Column(children: [
      const Text('🏙️ AUREN CITY',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
      const Text('مدينة مفتوحة مصغرة: استكشف، اعمل، اجمع المال وافتح مناطق جديدة.'),
      const SizedBox(height:12),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:25,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:5,crossAxisSpacing:5,mainAxisSpacing:5),itemBuilder:(_,i){final px=i%5,py=i~/5;final player=px==x&&py==y;final mark=i==6?'🏢':i==18?'🏪':i==22?'🏦':i==12?'🏠':'·';return Container(alignment:Alignment.center,decoration:BoxDecoration(borderRadius:BorderRadius.circular(10),color:Theme.of(context).colorScheme.surfaceContainerHighest),child:Text(player?'🧑':mark,style:const TextStyle(fontSize:24)));}),
      const SizedBox(height:10),
      Wrap(spacing:8,children:[FilledButton.tonal(onPressed:_energy>0?_act:null,child:const Text('🚶 تحرك')),FilledButton.tonal(onPressed:_energy>0?()=>setState((){_coins+=50;_energy--;}):null,child:const Text('💼 مهمة')),FilledButton.tonal(onPressed:()=>setState(()=>_coins+=20),child:const Text('💰 دخل'))]),
    ]);
  }
}
