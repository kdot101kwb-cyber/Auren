import 'dart:math' as math;
import 'package:flutter/material.dart';

enum Auren3DWorldPreset { city, arena, desert, sports }

/// Reusable lightweight 3D perspective layer for AUREN games.
/// It uses Flutter Canvas, so it works without adding a native 3D dependency.
class Auren3DWorldScreen extends StatefulWidget {
  final String title;
  final Auren3DWorldPreset preset;
  const Auren3DWorldScreen({super.key, this.title = 'AUREN 3D', this.preset = Auren3DWorldPreset.city});

  @override
  State<Auren3DWorldScreen> createState() => _Auren3DWorldScreenState();
}

class _Auren3DWorldScreenState extends State<Auren3DWorldScreen> {
  double yaw = 0, pitch = .22, zoom = 1;
  int selected = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [IconButton(onPressed: () => setState(() { yaw = 0; pitch = .22; zoom = 1; }), tooltip: 'إعادة ضبط المنظور', icon: const Icon(Icons.center_focus_strong))],
    ),
    body: Column(children: [
      Expanded(
        child: GestureDetector(
          onScaleUpdate: (d) => setState(() {
            if (d.pointerCount > 1) {
              zoom = (zoom * d.scale).clamp(.65, 1.8);
            } else {
              yaw += d.focalPointDelta.dx * .012;
              pitch = (pitch - d.focalPointDelta.dy * .008).clamp(-.2, .75);
            }
          }),
          child: CustomPaint(
            painter: _Auren3DPainter(yaw: yaw, pitch: pitch, zoom: zoom, preset: widget.preset, selected: selected),
            child: const SizedBox.expand(),
          ),
        ),
      ),
      SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: Text(_label, style: const TextStyle(fontWeight: FontWeight.w800))),
          IconButton.filledTonal(onPressed: () => setState(() => selected = (selected + 1) % 6), icon: const Icon(Icons.explore)),
        ]),
      )),
    ]),
  );

  String get _label {
    switch (widget.preset) {
      case Auren3DWorldPreset.city: return 'مدينة 3D • منطقة ' + (selected + 1).toString();
      case Auren3DWorldPreset.arena: return 'Arena 3D • مقاتل ' + (selected + 1).toString();
      case Auren3DWorldPreset.desert: return 'Desert Quest 3D • قطاع ' + (selected + 1).toString();
      case Auren3DWorldPreset.sports: return 'Sports 3D • ملعب ' + (selected + 1).toString();
    }
  }
}

class _Auren3DPainter extends CustomPainter {
  final double yaw, pitch, zoom;
  final Auren3DWorldPreset preset;
  final int selected;
  const _Auren3DPainter({required this.yaw, required this.pitch, required this.zoom, required this.preset, required this.selected});

  Offset p(Offset v, Size s, [double h = 0]) {
    final cy = math.cos(yaw), sy = math.sin(yaw), cp = math.cos(pitch), sp = math.sin(pitch);
    final x = v.dx * cy - v.dy * sy;
    final z = v.dx * sy + v.dy * cy;
    final yy = h * cp - z * sp;
    final depth = (8 + z * cp + h * sp).clamp(2.0, 20.0);
    final scale = s.shortestSide * .09 * zoom / depth;
    return Offset(s.width / 2 + x * scale, s.height * .56 - yy * scale);
  }

  void box(Canvas c, Size s, Paint paint, double x, double y, double w, double d, double h) {
    final a=p(Offset(x,y),s), b=p(Offset(x+w,y),s), cc=p(Offset(x+w,y+d),s), d0=p(Offset(x,y+d),s);
    final t0=p(Offset(x,y),s,h), t1=p(Offset(x+w,y),s,h), t2=p(Offset(x+w,y+d),s,h), t3=p(Offset(x,y+d),s,h);
    c.drawPath(Path()..addPolygon([a,b,t1,t0],true),paint);
    c.drawPath(Path()..addPolygon([b,cc,t2,t1],true),paint);
    c.drawPath(Path()..addPolygon([cc,d0,t3,t2],true),paint);
    c.drawPath(Path()..addPolygon([d0,a,t0,t3],true),paint);
    c.drawPath(Path()..addPolygon([t0,t1,t2,t3],true),paint);
  }

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color=const Color(0xFF080A12));
    final ground=Paint()..color=const Color(0xFF171B2B);
    c.drawPath(Path()..addPolygon([p(const Offset(-40,-40),s),p(const Offset(40,-40),s),p(const Offset(40,40),s),p(const Offset(-40,40),s)],true),ground);
    final grid=Paint()..color=const Color(0xFF343A55)..strokeWidth=1;
    for(var i=-8;i<=8;i++){
      c.drawLine(p(Offset(i*4,-32),s),p(Offset(i*4,32),s),grid);
      c.drawLine(p(Offset(-32,i*4),s),p(Offset(32,i*4),s),grid);
    }

    if(preset==Auren3DWorldPreset.city){
      final a=Paint()..color=const Color(0xFF4C5278), b=Paint()..color=const Color(0xFF7078AA);
      for(var i=0;i<8;i++) box(c,s,i==3?b:a,(i%4)*11-17,(i~/4)*13-13,7,6,7+(i%3)*4);
    } else if(preset==Auren3DWorldPreset.arena){
      final wall=Paint()..color=const Color(0xFF454A68);
      for(var i=0;i<8;i++){final a=i*math.pi/4; box(c,s,wall,math.cos(a)*15-1.5,math.sin(a)*15-1.5,3,3,2.5);}
    } else if(preset==Auren3DWorldPreset.desert){
      final dune=Paint()..color=const Color(0xFF6B604B);
      for(var i=0;i<7;i++) box(c,s,dune,-24+i*8,8-(i%2)*12,6,5,1+(i%3));
      box(c,s,Paint()..color=const Color(0xFF3E6470),3,-8,9,7,.4);
    } else {
      final field=Paint()..color=const Color(0xFF344D3F);
      box(c,s,field,-20,-13,40,26,.25);
      final mark=Paint()..color=const Color(0xFFE4E6EF)..style=PaintingStyle.stroke..strokeWidth=2;
      c.drawLine(p(const Offset(-20,0),s),p(const Offset(20,0),s),mark);
      c.drawLine(p(const Offset(0,-13),s),p(const Offset(0,13),s),mark);
    }

    final player=p(Offset(selected*2-5,2),s);
    c.drawCircle(player.translate(0,-13),7,Paint()..color=const Color(0xFFE9ECFF));
    c.drawCircle(player.translate(0,-2),11,Paint()..color=const Color(0xFFE9ECFF));
  }

  @override bool shouldRepaint(covariant _Auren3DPainter old) =>
      old.yaw!=yaw || old.pitch!=pitch || old.zoom!=zoom || old.preset!=preset || old.selected!=selected;
}
