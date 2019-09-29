在flutter中图表框架目前相对较少,且不太符合项目需求,本篇文章将介绍如何运用自定义view完成曲线统计图的绘制,最终效果如图.
    
![](https://user-gold-cdn.xitu.io/2019/9/19/16d483b2ffab8220?w=680&h=626&f=png&s=60220)

### 绘制背景线条
```
 /// 画背景线
  void darwBackgroundLine(Canvas canvas) {
    painter.strokeWidth = 1.2; // 线条宽度
    painter.color = Color(0xffEBECF0);
    for (int i = 0; i < LINE_NUM - 1; i++) {
      // 绘制横线
      canvas.drawLine(Offset(yTextwidth, i * LINE_SPACE + Y_TEXT_HEIGHT), Offset(width, i * LINE_SPACE + Y_TEXT_HEIGHT), painter);
    }
    painter.strokeWidth = 1.4; // 最后一条线条较粗
    painter.color = Color(0xffC4C6CF);
    // 绘制横线
    canvas.drawLine(Offset(yTextwidth, (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT),
        Offset(width, (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT), painter);
  }
```

### 绘制文本,X,Y值及标题
```
 /// 坐标抽文字
  void xyText(Canvas canvas) {
    // y轴标题
    textPainter.text = TextSpan(
      text: lineChartBean.yRemindText,
      style: new TextStyle(
        color: Color(0xff303133),
        fontSize: S(20),
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
          fontSize: S(24),
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
```

### 绘制曲线

  在flutter中可以通过Path绘制线条,把已知的四个点连起来,就是基本的折线统计图,但要绘制出点与点之前平滑过渡的曲线,就需要另外一个方法得到曲线的坐标,这个方法就是cos函数.
 
做之前先回忆一下cos长啥样.

![](https://user-gold-cdn.xitu.io/2019/9/19/16d486a1b3f5990b?w=466&h=225&f=png&s=69132)


绘制所需要的就是0 ~ 2π 间的曲线.


```
  /// 获取曲线路径
  /// [v1] 第一个Y轴值 [v2] 第二个Y轴值
  /// [index] X轴坐标位置
  Path getCurvePath(double v1, double v2, int index, Path path) {
    int clipNum = 30; // 一段曲线被分割绘制的数量,越大曲线越平滑.
    double temp = 1 / clipNum; // 遍历运算用到的临时数值
    bool isNegativeNumber; // 是否为负数
    double diff = (v1 - v2).abs(); // 两点之间的差值
    isNegativeNumber = (v1 - v2) < 0; // 判断正负
    for (int i = 0; i < clipNum; i++) {
      path.lineTo(
        // x点坐标值,x轴不参与cos运算
        getX(temp * i + index.toDouble()),
        // y点坐标值
        // 公式 y = cos(v) + 1 , isNegativeNumber 为true时,用到的是π~2π之间的曲线,为false时,用到的是0~π间的曲线.
        // 通过公式运算之后再与实际大小做比相乘得出实际结果,添加到Path
        getY((cos((isNegativeNumber ? pi : 0) + pi * temp * i) + 1) * diff / 2 + (isNegativeNumber ? v1 : v2)));
    }
    // 返回Path
    return path;
  }

  /// 获取Y轴坐标
  double getY(double value) => (MAX_VALUE - value) / MAX_VALUE * (LINE_NUM - 1) * LINE_SPACE + Y_TEXT_HEIGHT;

  /// 获取X轴坐标
  double getX(double index) => yTextwidth + unitWidth / 2 + index * unitWidth;

```

```
// 最后用drawPath完成整段绘制.
canvas.drawPath(path, painter);
```
### 最后
以上为全部内容,如有错误请指正.

