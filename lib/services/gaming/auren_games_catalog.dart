import 'package:flutter/material.dart';

class AurenGameDefinition {
  final String id, title, subtitle;
  final IconData icon;
  const AurenGameDefinition(this.id, this.title, this.subtitle, this.icon);
}

class AurenGamesCatalog {
  static const all = <AurenGameDefinition>[
    AurenGameDefinition('lost_world','AUREN: Lost World','مغامرة جماعية أصلية في عالم متغير',Icons.public),
    AurenGameDefinition('ludo','Ludo','سباق أربعة لاعبين',Icons.casino_outlined),
    AurenGameDefinition('dominoes','Dominoes','دومينو كلاسيكي',Icons.grid_4x4),
    AurenGameDefinition('uno','UNO','بطاقات ومنافسة سريعة',Icons.style),
    AurenGameDefinition('crime_files','Crime Files','حل القضايا والأدلة',Icons.manage_search),
    AurenGameDefinition('football','Football','مباريات وتحديات كرة القدم',Icons.sports_soccer),
    AurenGameDefinition('basketball','Basketball','مباريات وتسديدات',Icons.sports_basketball),
    AurenGameDefinition('boxing','Boxing','نزال وتوقيت وضربات',Icons.sports_mma),
    AurenGameDefinition('racing','Racing','سباقات ومضامير',Icons.directions_car),
    AurenGameDefinition('wars','Battle Wars','معارك استراتيجية',Icons.shield),
    AurenGameDefinition('samurai','Samurai','مبارزات سريعة',Icons.sports_kabaddi),
    AurenGameDefinition('chess','Chess','شطرنج',Icons.grid_3x3),
    AurenGameDefinition('checkers','Checkers','دامة',Icons.blur_on),
    AurenGameDefinition('backgammon','Backgammon','طاولة',Icons.apps),
    AurenGameDefinition('connect4','Connect 4','أربع قطع متصلة',Icons.view_column),
    AurenGameDefinition('tic_tac_toe','Tic Tac Toe','إكس أو',Icons.close),
    AurenGameDefinition('four_in_row','Four in a Row','تنافس سريع',Icons.table_rows),
    AurenGameDefinition('word_arena','Word Arena','تحدي كلمات',Icons.abc),
    AurenGameDefinition('quiz','AUREN Quiz','أسئلة معرفة عامة',Icons.quiz),
    AurenGameDefinition('memory','Memory Match','تطابق الذاكرة',Icons.memory),
    AurenGameDefinition('2048','2048','دمج الأرقام',Icons.numbers),
    AurenGameDefinition('snake','Snake','الثعبان الكلاسيكي',Icons.pest_control),
    AurenGameDefinition('mines','Mines','كشف الخلايا الآمنة',Icons.warning_amber),
    AurenGameDefinition('tower','Tower Builder','ابنِ أعلى برج',Icons.account_balance),
    AurenGameDefinition('space','Space Mission','مهمة فضائية',Icons.rocket_launch),
    AurenGameDefinition('island','Island Survival','البقاء على الجزيرة',Icons.beach_access),
    AurenGameDefinition('jungle','Jungle Quest','مغامرة الأدغال',Icons.forest),
    AurenGameDefinition('desert','Desert Run','عبور الصحراء',Icons.wb_sunny),
    AurenGameDefinition('ocean','Ocean Explorer','استكشاف المحيط',Icons.water),
    AurenGameDefinition('treasure','Treasure Hunt','البحث عن الكنز',Icons.card_giftcard),
    AurenGameDefinition('escape','Escape Room','اهرب من الغرفة',Icons.lock_open),
    AurenGameDefinition('zombies','Night Survival','نجاة ليلية',Icons.nights_stay),
    AurenGameDefinition('monster','Monster Arena','مواجهة الوحوش',Icons.pets),
    AurenGameDefinition('ninja','Ninja Run','جري ومراوغة',Icons.directions_run),
    AurenGameDefinition('drift','Drift Rush','انجراف سريع',Icons.sports_motorsports),
    AurenGameDefinition('bike','Bike Rush','سباق دراجات',Icons.pedal_bike),
    AurenGameDefinition('golf','Mini Golf','غولف مصغر',Icons.sports_golf),
    AurenGameDefinition('tennis','Tennis','تنس',Icons.sports_tennis),
    AurenGameDefinition('volleyball','Volleyball','كرة طائرة',Icons.sports_volleyball),
    AurenGameDefinition('archery','Archery','رماية',Icons.sports),
    AurenGameDefinition('fishing','Fishing','صيد واكتشاف',Icons.phishing),
    AurenGameDefinition('farm','Farm Tycoon','مزرعة وإدارة موارد',Icons.agriculture),
    AurenGameDefinition('city','City Builder','ابنِ مدينتك',Icons.location_city),
    AurenGameDefinition('business','Business Tycoon','تجارة ونمو',Icons.business_center),
    AurenGameDefinition('space_wars','Space Wars','قتال فضائي',Icons.satellite_alt),
    AurenGameDefinition('pirates','Pirate Quest','مغامرة القراصنة',Icons.sailing),
    AurenGameDefinition('heroes','Hero League','أبطال وقدرات',Icons.auto_awesome),
    AurenGameDefinition('cards','Card Clash','مباراة بطاقات',Icons.layers),
    AurenGameDefinition('dice','Dice Masters','تحدي النرد',Icons.casino),
    AurenGameDefinition('strategy','World Strategy','استراتيجية عالمية',Icons.public_outlined),
  ];
}
