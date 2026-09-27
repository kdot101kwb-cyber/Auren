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
        ]) : _TenMoreGamesPanel(initialIndex: _selected - 7)),
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
    return ListView(padding:const EdgeInsets.all(16),children:[Text('10 ألعاب جديدة',style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:8),Wrap(spacing:6,runSpacing:6,children:[for(var i=0;i<names.length;i++)ChoiceChip(label:Text(names[i]),selected:_game==i,onSelected:(_){setState(()=>_game=i);})]),const SizedBox(height:16),Card(child:Padding(padding:const EdgeInsets.all(16),child:body)),const SizedBox(height:12),FilledButton.icon(onPressed:_reset,icon:const Icon(Icons.refresh),label:const Text('إعادة'))]);
  }
}
