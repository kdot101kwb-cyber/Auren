import 'dart:math';
import 'package:flutter/material.dart';

class AurenFlagshipGamesPanel extends StatefulWidget {
  final int gameIndex;
  const AurenFlagshipGamesPanel({super.key, required this.gameIndex});
  @override State<AurenFlagshipGamesPanel> createState() => _AurenFlagshipGamesPanelState();
}

class _AurenFlagshipGamesPanelState extends State<AurenFlagshipGamesPanel> {
  final _rng = Random();
  int _score = 0, _round = 0, _hp = 100, _streak = 0;
  final List<int> _ludo = [0, 0, 0, 0];
  final List<int> _domino = [6, 4, 2, 1];
  final List<String> _uno = ['🔴5', '🔵+2', '🟢7', '🟡↩'];
  int _selectedCard = 0;
  int _playerGoals = 0, _cpuGoals = 0, _playerPoints = 0, _cpuPoints = 0;
  String _message = 'ابدأ الجولة';

  static const _names = [
    '🎲 Ludo','🁫 Dominoes','🃏 UNO','🕵️ Crime Files',
    '⚽ AUREN Football Pro','🏀 Basketball Pro','🥊 Boxing Champion',
    '⚔️ Ancient & Modern Wars','🥷 Samurai Legacy','🏎️ AUREN Street Racing',
  ];

  @override
  void didUpdateWidget(covariant AurenFlagshipGamesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameIndex != widget.gameIndex) _reset();
  }

  void _reset() {
    setState(() {
      _score = 0; _round = 0; _hp = 100; _streak = 0;
      _playerGoals = 0; _cpuGoals = 0; _playerPoints = 0; _cpuPoints = 0;
      _message = 'ابدأ الجولة'; _selectedCard = 0;
      for (var i = 0; i < _ludo.length; i++) _ludo[i] = 0;
      _domino.setAll(0, [6, 4, 2, 1]);
      _uno
        ..clear()
        ..addAll(['🔴5','🔵+2','🟢7','🟡↩']);
    });
  }

  void _act() {
    switch (widget.gameIndex) {
      case 0: _ludoTurn(); break; case 1: _dominoTurn(); break; case 2: _unoTurn(); break;
      case 3: _crimeTurn(); break; case 4: _footballTurn(); break; case 5: _basketballTurn(); break;
      case 6: _boxingTurn(); break; case 7: _warTurn(); break; case 8: _samuraiTurn(); break;
      case 9: _racingTurn(); break;
    }
  }

  void _ludoTurn() {
    final dice = 1 + _rng.nextInt(6), i = _round % 4;
    _ludo[i] = min(56, _ludo[i] + dice); _score += dice * 5; _round++;
    _message = '🎲 النرد: ' + dice.toString() + ' • القطعة ' + (i + 1).toString() + ' تقدمت إلى ' + _ludo[i].toString() + '/56';
    if (_ludo[i] == 56) { _streak++; _message += ' • 🏁 وصلت للبيت!'; }
  }

  void _dominoTurn() {
    final left = _rng.nextInt(7), right = _rng.nextInt(7), i = _round % 4;
    final match = _domino[i] == left || _domino[i] == right;
    if (match) _domino[i] = right;
    _score += match ? 25 : 5; _round++;
    _message = match ? '🁫 تطابق ' + left.toString() + '|' + right.toString() + ' • لعبت القطعة' : '🁫 ' + left.toString() + '|' + right.toString() + ' • ابحث عن تطابق أفضل';
    _streak = match ? _streak + 1 : 0;
  }

  void _unoTurn() {
    final card = _uno[_selectedCard], playable = _round == 0 || card.contains('5') || card.contains('+2');
    final draw = ['🔴2','🔵9','🟢5','🟡7','🟣W'][_rng.nextInt(5)];
    if (playable) { _score += 20; _round++; _streak++; _message = '🃏 لعبت ' + card + ' • الخصم يسحب بطاقة'; }
    else { _uno.add(draw); _streak = 0; _message = '🚫 البطاقة غير صالحة • اسحب ' + draw; }
    if (_uno.length > 8) _uno.removeAt(0);
    _selectedCard = min(_selectedCard, max(0, _uno.length - 1));
  }

  void _crimeTurn() {
    const clues = ['بصمة على المقبض','كاميرا توقفت 03:12','إيصال من المتجر','رسالة مشفرة','شاهد رأى سيارة'];
    _round++; _score += 18; _streak++; _message = '🕵️ دليل #' + _round.toString() + ': ' + clues[(_round - 1) % clues.length];
    if (_round >= 5) _message += ' • 🔓 الملف أصبح قابلاً للتحليل';
  }

  void _footballTurn() {
    final goal = _rng.nextInt(3) != _rng.nextInt(3);
    if (goal) { _playerGoals++; _score += 30; _message = '⚽ GOAL! ' + _playerGoals.toString() + '-' + _cpuGoals.toString(); }
    else { _cpuGoals++; _score += 5; _message = '🧤 تصدّي! ' + _playerGoals.toString() + '-' + _cpuGoals.toString(); }
    _round++;
  }

  void _basketballTurn() {
    final shot = _rng.nextDouble(), points = shot > .82 ? 3 : shot > .42 ? 2 : 0;
    if (points > 0) { _playerPoints += points; _score += points * 10; _message = '🏀 ' + points.toString() + ' نقاط!'; }
    else { _cpuPoints += 2; _message = '❌ ضاعت الرمية • الخصم سجل 2'; }
    _round++;
  }

  void _boxingTurn() {
    if (_rng.nextInt(100) > _rng.nextInt(100)) { final damage = 8 + _rng.nextInt(13); _score += damage * 2; _streak++; _message = '🥊 لكمة ناجحة • ضرر ' + damage.toString(); }
    else { final damage = 5 + _rng.nextInt(11); _hp = max(0, _hp - damage); _streak = 0; _message = '🥊 الخصم ردّ • -' + damage.toString() + ' HP'; }
    _round++;
  }

  void _warTurn() {
    const missions = ['أمّن نقطة الإمداد','احمِ القافلة','استعد الموقع','أنقذ الفريق','أكمل الانسحاب الآمن'];
    _round++; _score += 22; _streak++; _message = '⚔️ المهمة ' + _round.toString() + ': ' + missions[(_round - 1) % missions.length];
  }

  void _samuraiTurn() {
    const moves = ['سحب السيف','صدّ الضربة','خطوة جانبية','ضربة دقيقة'];
    final success = _rng.nextDouble() > .25; _round++;
    if (success) { _score += 25; _streak++; _message = '🥷 ' + moves[_rng.nextInt(moves.length)] + ' • ناجحة'; }
    else { _hp = max(0, _hp - 8); _streak = 0; _message = '🥷 تم صدّ الهجمة • -8 HP'; }
  }

  void _racingTurn() {
    final speed = 60 + _rng.nextInt(41), drift = _rng.nextDouble() > .35;
    _round++; _score += drift ? 25 : 10; _streak = drift ? _streak + 1 : 0;
    _message = '🏎️ سرعة ' + speed.toString() + ' km/h • ' + (drift ? 'انجراف مضبوط' : 'حافظ على المسار') + ' • قطاع ' + _round.toString();
  }

  String get _button => ['ارمِ النرد وحرّك','اسحب والعب قطعة','العب البطاقة','اكشف دليلاً','سدّد','ارمِ الكرة','هاجم','نفّذ المهمة','نفّذ حركة الساموراي','سباق!'][widget.gameIndex];

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(_names[widget.gameIndex], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('جولة ' + _round.toString() + ' • ⭐ ' + _score.toString() + ' • 🔥 Combo ' + _streak.toString()),
      const SizedBox(height: 12),
      if (widget.gameIndex == 0) _ludoBoard(),
      if (widget.gameIndex == 1) _dominoBoard(),
      if (widget.gameIndex == 2) _unoBoard(),
      if (widget.gameIndex == 3) _crimeBoard(),
      if (widget.gameIndex >= 4) _actionBoard(),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(_message, style: const TextStyle(fontWeight: FontWeight.w800)))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _hp > 0 ? _act : _reset, icon: Icon(_hp > 0 ? Icons.play_arrow : Icons.refresh), label: Text(_hp > 0 ? _button : 'إعادة المباراة')),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('لعبة جديدة')),
    ]);
  }

  Widget _ludoBoard() => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
    const Text('مسار 56 خانة • 4 قطع اللاعب', style: TextStyle(fontWeight: FontWeight.w800)),
    const SizedBox(height: 10),
    Wrap(spacing: 6, runSpacing: 6, children: List.generate(56, (i) => Container(width: 34, height: 34, alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).colorScheme.surfaceContainerHighest),
      child: Text(_ludo.contains(i + 1) ? '🔵' : (i + 1).toString(), style: const TextStyle(fontSize: 11)))),
  ])));

  Widget _dominoBoard() => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    const Text('سلسلة الدومينو', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12),
    Wrap(spacing: 8, children: _domino.map((n) => Chip(label: Text('🁫 ' + n.toString() + '|' + ((n + 2) % 7).toString()))).toList()),
    const SizedBox(height: 8), const Text('طابق رقم الطرف مع القطعة المسحوبة.'),
  ])));

  Widget _unoBoard() => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
    const Text('يدك', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
    Wrap(spacing: 6, children: List.generate(_uno.length, (i) => ChoiceChip(selected: _selectedCard == i, label: Text(_uno[i]), onSelected: (_) => setState(() => _selectedCard = i)))),
    const SizedBox(height: 8), Text('الهدف: تخلّص من البطاقات أولاً • ' + _uno.length.toString() + ' بطاقة'),
  ])));

  Widget _crimeBoard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('ملف القضية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8), Text('الأدلة المكتشفة: ' + min(5, _round).toString() + '/5'),
    const SizedBox(height: 8), LinearProgressIndicator(value: min(1, _round / 5)),
    const SizedBox(height: 10), Text(_round >= 5 ? '🔓 الملف مفتوح للتحليل النهائي.' : 'اجمع 5 أدلة مترابطة قبل إصدار الاتهام.'),
  ])));

  Widget _actionBoard() {
    final icon = ['⚽','🏀','🥊','⚔️','🥷','🏎️'][widget.gameIndex - 4];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Text(icon + ' ساحة اللعب', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12), LinearProgressIndicator(value: _hp / 100), const SizedBox(height: 8),
      Text('HP ' + _hp.toString() + ' • الجولة ' + _round.toString() + ' • النقاط ' + _score.toString()),
      if (widget.gameIndex == 4) Text('الأهداف: ' + _playerGoals.toString() + ' - ' + _cpuGoals.toString()),
      if (widget.gameIndex == 5) Text('النقاط: ' + _playerPoints.toString() + ' - ' + _cpuPoints.toString()),
    ])));
  }
}
