import 'package:flutter/material.dart';
import 'dart:math';
import 'dash_path.dart';

/// 折现统计图
///
/// 2019-09-12  16:35
/// boyko
class LineChart extends StatefulWidget {
  @override
  _LineChartState createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> with TickerProviderStateMixin {
  GlobalKey<State<StatefulWidget>> anchorKey = GlobalKey();

  BaseLineChart baseLineChart;

  double clickIndex = -1;

  Animation<double> movement;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    baseLineChart = BaseLineChart(clickIndex: clickIndex);
    return Container(
      height: 300,
      width: double.infinity,
      margin: EdgeInsets.all(20),
      child: GestureDetector(
        key: anchorKey,
        child: CustomPaint(painter: baseLineChart),
        onTapDown: (TapDownDetails d) {
          RenderBox renderBox = anchorKey.currentContext.findRenderObject();
          Offset localPosition = renderBox.globalToLocal(d.globalPosition);
          int i = baseLineChart.checkClickArea(localPosition);
          if (i != -1) move(baseLineChart.clickIndex, i.toDouble());
        },
      ),
    );
  }

  move(double start, double end) {
    if (start == -1) return;
    var _controller = AnimationController(duration: Duration(milliseconds: 400), vsync: this);
    movement = Tween<double>(
      begin: start,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // 或 ElasticInCurve
      ),
    )
      ..addListener(() {
        setState(() {
          clickIndex = movement.value;
        });
      })
      ..addStatusListener((AnimationStatus s) {
        if (s == AnimationStatus.completed) {
          setState(() {
//            changeData(startClickNum);
//            setItemFalse();
//            isrunning = false;
          });
        }
      });
    _controller.reset();
    _controller.forward();
  }
}

class BaseLineChart extends CustomPainter {
  /// 画笔
  Paint painter = Paint()
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;

  /// 文字
  TextPainter textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );

  /// 横向线段间隔
  double LINE_SPACE = 45;

  /// 线段数量
  int LINE_NUM = 6;

  /// 最大值
  double MAX_VALUE = 5000;

  /// Y轴标题高度
  double Y_TEXT_HEIGHT = 40;

  /// 整体宽度
  double width;

  /// Y轴坐标文字宽度
  double yTextwidth;

  /// x轴坐标单元间距
  double unitWidth;

  /// 点击的坐标位置
  double clickIndex;

  BaseLineChart({this.clickIndex = -1});

  @override
  void paint(Canvas canvas, Size size) {
    /*
     * 基本区域剪切
     */
    Rect rect = Offset.zero & size;
    canvas.clipRect(rect);
    painter.color = Colors.white;
    painter.style = PaintingStyle.fill;
    canvas.drawRect(rect, painter);

    width = size.width;
    yTextwidth = width / 7;
    unitWidth = (width - yTextwidth) / 4;

    painter.style = PaintingStyle.stroke;
    drawDashesLine(canvas);

    xyText(canvas);

    painter.color = Color(0xff26DAD0);
    painter.strokeWidth = 2;
    drawValueLine(canvas);
    painter.color = Color(0xffC95FF2);
//    drawValueLine(canvas);
//    painter.color = Color(0xff7C6AF2);
//    drawValueLine(canvas);
//    painter.color = Color(0xffFF9F40);
//    drawValueLine(canvas);
//    painter.color = Color(0xffFF6383);
//    drawValueLine(canvas);
  }

  /// 画线
  void drawValueLine(Canvas canvas) {
    List<double> values = List();
    for (int i = 0; i < 4; i++) {
      values.add(700.0 * i + 1000);
    }
    Path path = Path();
    for (int i = 0; i < values.length - 1; i++) {
      double v1 = values[i];
      double v2 = values[i + 1];
      if (i == 0) {
        path.moveTo(getX(i.toDouble()), getY(v1));
      }
      path = getCurvePath(v1, v2, i, path);
    }

    canvas.drawPath(path, painter);
    path.close();
  }

  /// 获取曲线路径
  /// [v1] 第一个Y轴值 [v2] 第二个Y轴值
  /// [index] X轴坐标位置
  Path getCurvePath(double v1, double v2, int index, Path path) {
    int clipNum = 30;
    double temp = 1 / clipNum;
    bool isNegativeNumber;
    double diff = (v1 - v2).abs();
    isNegativeNumber = (v1 - v2) < 0;
    for (int i = 0; i < clipNum; i++) {
      path.lineTo(getX(temp * i + index.toDouble()),
          getY((cos((isNegativeNumber ? pi : 0) + pi * temp * i) + 1) * diff / 2 + (isNegativeNumber ? v1 : v2)));
    }
    return path;
  }

  /// 获取Y轴坐标
  double getY(double value) => (MAX_VALUE - value) / MAX_VALUE * (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT;

  /// 获取X轴坐标
  double getX(double index) => yTextwidth + unitWidth / 2 + index * unitWidth;

  /// 画虚线
  void drawDashesLine(Canvas canvas) {
    // 默认选择的标记位
    var defaultSelect = 2;

    // 灰色背景
    painter.color = Color(0xfffafafa);
    painter.style = PaintingStyle.fill;
    Rect background = Rect.fromLTWH(yTextwidth + defaultSelect * unitWidth + 10, Y_TEXT_HEIGHT / 2, unitWidth - 20,
        (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT / 2);
    canvas.drawRect(background, painter);

    // 选中的灰色背景
    if (clickIndex != -1 && clickIndex != defaultSelect) {
      Rect background = Rect.fromLTWH(yTextwidth + clickIndex * unitWidth + 10, Y_TEXT_HEIGHT / 2, unitWidth - 20,
          (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT / 2);
      canvas.drawRect(background, painter);
    }

    darwBackgroundLine(canvas);

    // 画虚线
    Path path = Path();
    path.moveTo(yTextwidth + unitWidth / 2 + defaultSelect * unitWidth, Y_TEXT_HEIGHT / 2);
    path.lineTo(yTextwidth + unitWidth / 2 + defaultSelect * unitWidth, (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT);
    painter.style = PaintingStyle.stroke;
    painter.color = Color(0xff5D75F1);
    painter.strokeWidth = 1;
    canvas.drawPath(
        dashPath(
          path,
          dashArray: CircularIntervalList<double>(
            <double>[6, 3],
          ),
        ),
        painter);

    // 选中虚线
    if (clickIndex != -1 && clickIndex != defaultSelect) {
      Path path = Path();
      path.moveTo(yTextwidth + unitWidth / 2 + clickIndex * unitWidth, Y_TEXT_HEIGHT / 2);
      path.lineTo(yTextwidth + unitWidth / 2 + clickIndex * unitWidth, (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT);
      painter.color = Color(0xffFFCC00);
      canvas.drawPath(
          dashPath(
            path,
            dashArray: CircularIntervalList<double>(
              <double>[6, 3],
            ),
          ),
          painter);
    }
  }

  /// 坐标抽文字
  void xyText(Canvas canvas) {
    // y轴标题
    textPainter.text = TextSpan(
      text: '工作量（人/次）',
      style: new TextStyle(
        color: Colors.black,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, 0));

    // y 轴文字
    for (int i = 0; i < LINE_NUM; i++) {
      textPainter.text = TextSpan(
        text: '${(LINE_NUM - i - 1) * 1000}',
        style: new TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset((yTextwidth - textPainter.width) / 2, i * LINE_SPACE - textPainter.height / 2 + Y_TEXT_HEIGHT));
    }

    double xTextWidth = width - yTextwidth;
    var temp = xTextWidth / 4;
    // x 文字
    for (int i = 1; i < 5; i++) {
      textPainter.text = TextSpan(
        text: '$i 月',
        style: new TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(yTextwidth + temp * i - temp / 2 - textPainter.width / 2,
              (LINE_NUM - 1) * LINE_SPACE + 6 + Y_TEXT_HEIGHT));
    }
  }

  /// 画背景线
  void darwBackgroundLine(Canvas canvas) {
    painter.strokeWidth = 1.2;
    painter.color = Color(0xffEBECF0);
    for (int i = 0; i < LINE_NUM - 1; i++) {
      canvas.drawLine(
          Offset(yTextwidth, i * LINE_SPACE + Y_TEXT_HEIGHT), Offset(width, i * LINE_SPACE + Y_TEXT_HEIGHT), painter);
    }
    painter.strokeWidth = 1.6;
    painter.color = Color(0xffC4C6CF);
    canvas.drawLine(Offset(yTextwidth, (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT),
        Offset(width, (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT), painter);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  /// 检测点击区域
  int checkClickArea(Offset globalOffset) {
    if (globalOffset.dx < yTextwidth) return -1;
    if (globalOffset.dy > Y_TEXT_HEIGHT && globalOffset.dy < (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT) {
      int selectIndex = (globalOffset.dx - yTextwidth) ~/ unitWidth;
      return selectIndex;
    }
    return -1;
  }
}
