import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'math_util.dart';

class NavPage extends StatefulWidget {
  NavPage({Key key, this.data})
      : super(key: key);
  final List data;

  @override
  State<StatefulWidget> createState() {
    return _NavPageState();
  }
}

class _NavPageState extends State<NavPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavWidget(data: widget.data),
    );
  }
}

class NavWidget extends StatefulWidget {
  NavWidget({Key key, this.data, this.callback})
      : super(key: key);
  final List data;
  Function callback;

  @override
  State<StatefulWidget> createState() {
    return _NavWidgetState();
  }
}

class _NavWidgetState extends State<NavWidget> {
  int index = 0; //一级分类下标
  int subIndex = -1;
  double menuOffset = 0;
  ScrollController _optionsController = new ScrollController();
  ScrollController _menuController = new ScrollController();
  static double selectItemHeight = 32.0;
  static double topTipHeight = 35.0;
  List optionsOffsets = [];
  List menuOffsets = [];
  double menuItemHeight = 48.0;
  int menuCenterIndex;
  bool isScrollDown = true;
  double optionsOffset = 0;
  double widgetHeight = 0;
  double halfWidgetHeight = 0;
  double maxMenuScrollableDistance = 0;
  double maxOpScrollableDistance = 0;
  double lastItemBottomPadding = 20;
  double itemTopPadding = 10;
  var _datas;
  String owbProfessionWhite;

  @override
  void initState() {
    super.initState();
    _datas = widget.data ?? [];
    optionsOffsets.clear();
    double distance = 0;
    optionsOffsets.add(distance);
    for (int i = 1; i < _datas.length; i++) {
      distance += getOffset(getItemLines(i - 1));
      optionsOffsets.add(distance);
    }
    double menuDistance = 0;
    menuOffsets.add(menuDistance);
    for (int i = 1; i < _datas.length; i++) {
      menuOffsets.add(menuItemHeight * i);
    }
    _optionsController.addListener(() {
      if (_optionsController.offset < 0 ||
          _optionsController.offset >= maxOpScrollableDistance) {
        return;
      }
      isScrollDown = _optionsController.offset > optionsOffset;
      optionsOffset = _optionsController.offset;
      if (optionsScrollState == NORMAL_SCROLLING) {
        int scrollIndex = getScrollingItemIndex(_optionsController.offset);
        if (index != scrollIndex) {
          setState(() {
            index = scrollIndex;
            subIndex = -1;
          });
          int pos = (menuOffset / menuItemHeight).floor();
          double offset = 0;
          if (isScrollDown &&
              (menuOffset + menuOffsets[scrollIndex]) > halfWidgetHeight) {
            offset =
                menuOffsets[checkRangeIn(pos + 1, 0, menuOffsets.length - 1)];
            _menuController.jumpTo(offset > maxMenuScrollableDistance
                ? maxMenuScrollableDistance
                : offset < 0
                    ? 0
                    : offset);
          } else if (!isScrollDown &&
              (menuOffsets[scrollIndex] - menuOffset) < halfWidgetHeight) {
            offset =
                menuOffsets[checkRangeIn(pos - 1, 0, menuOffsets.length - 1)];
            _menuController.jumpTo(offset > maxMenuScrollableDistance
                ? maxMenuScrollableDistance
                : offset < 0
                    ? 0
                    : offset);
          }
        }
      }
    });
    _menuController.addListener(() {
      menuOffset = _menuController.offset;
    });
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      widgetHeight = context.size.height;
      halfWidgetHeight = widgetHeight / 2;
      maxMenuScrollableDistance =
          menuItemHeight * optionsOffsets.length - widgetHeight > 0
              ? menuItemHeight * optionsOffsets.length - widgetHeight
              : 0;
      maxOpScrollableDistance = optionsOffsets[optionsOffsets.length - 1] +
          getOffset(getItemLines(_datas.length - 1)) +
          lastItemBottomPadding -
          widgetHeight;
      maxOpScrollableDistance =
          maxOpScrollableDistance > 0 ? maxOpScrollableDistance : 0;
    });
  }

  checkRangeIn(int pos, int start, int end) {
    if (pos < start) {
      return start;
    }
    if (pos > end) {
      return end;
    }
    return pos;
  }

  autoScrollToSelectIndex(
      controller, count, index, maxScrollableDistance, offsets) {
    if (maxScrollableDistance <= 0) {
      return;
    }
    controller.jumpTo(offsets[index] > maxScrollableDistance
        ? maxScrollableDistance
        : offsets[index]);
  }

  getMenuIndex(double offset) {
    if (offset <= 0 && menuOffsets == null || menuOffsets.length == 1) {
      return 0;
    }
    for (int i = 0; i < menuOffsets.length; i++) {
      if (offset >= menuOffsets[0] &&
          i + 1 < menuOffsets.length &&
          offset < menuOffsets[i + 1]) {
        return i;
      }
    }
    return optionsOffsets.length - 1;
  }

  getScrollingItemIndex(double offset) {
    if (offset <= 0 && optionsOffsets == null || optionsOffsets.length == 1) {
      return 0;
    }
    for (int i = 0; i < optionsOffsets.length; i++) {
      if (offset >= optionsOffsets[0] &&
          i + 1 < optionsOffsets.length &&
          offset < optionsOffsets[i + 1]) {
        return i;
      }
    }
    return optionsOffsets.length - 1;
  }

  @override
  void dispose() {
    //为了避免内存泄露，需要调用_controller.dispose
    _optionsController.dispose();
    super.dispose();
  }

  Widget getMenuItem(int i) {
    return GestureDetector(
      child: Container(
        alignment: Alignment.center,
        height: menuItemHeight,
        decoration: BoxDecoration(
          color: index == i ? Color(0xFFF5F6FF) : Colors.white,
          border: Border(
            left: BorderSide(
                width: 3, color: index == i ? Color(0xFF464EB5) : Colors.white),
          ),
        ),
        child: Text(
          _datas[i]['label'],
          style: TextStyle(
            fontWeight: i == index ? FontWeight.w500 : FontWeight.w400,
            color: Color(i == index ? 0xFF464EB5 : 0xFF677092),
            fontSize: 12,
          ),
        ),
      ),
      onTap: () {
        if (optionsScrollState != KEEP_STATIC) {
          return;
        }
        setState(() {
          index = i; //记录选中的下标
          subIndex = -1;
          menuClickToScroll = true;
          double offset = optionsOffsets[i] > maxOpScrollableDistance
              ? maxOpScrollableDistance
              : optionsOffsets[i];
          _optionsController.animateTo(offset,
              duration: Duration(milliseconds: 200), curve: Curves.ease);
          // if (Math.abs(offset - _optionsController.offset) < 6) {
          //   optionsScrollState = KEEP_STATIC;
          //   menuClickToScroll = false;
          // }
        });
      },
    );
  }

  getOffset(int i) {
    return (selectItemHeight + itemTopPadding) * i + topTipHeight;
  }

  getItemLines(int pos) {
    var items = _datas[pos]['children'];
    return (items.length % 3 == 0)
        ? (items.length / 3).floor()
        : (items.length / 3).floor() + 1;
  }

  Widget getChip(int i) {
    //更新对应下标数据
    var data = _datas[i];
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: topTipHeight,
            alignment: Alignment.bottomLeft,
            child: Text(
              data['label'],
              style: TextStyle(
                  color: Color(0xFF222328),
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
          getItemsContainer(i)
        ],
      ),
    );
  }

  getItem(var item, bool isFake, int rowIndex, int columnIndex) {
    return Expanded(
        child: GestureDetector(
            onTap: () {
              if (optionsScrollState != KEEP_STATIC || isFake) {
                return;
              }
              if (widget.callback != null) {
                widget.callback(_datas[rowIndex]['label'], item['label']);
                return;
              }
              Navigator.of(context)
                  .pop({"index": rowIndex, "childIndex": columnIndex});
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: (rowIndex == index && subIndex == columnIndex)
                      ? BoxDecoration(
                          border:
                              Border.all(color: Color(0xFF464EB5), width: 1),
                          color: Colors.white)
                      : !isFake
                          ? BoxDecoration(color: Colors.white)
                          : null,
                  margin: EdgeInsets.only(left: columnIndex % 3 == 0 ? 0 : 10),
                  height: selectItemHeight,
                  alignment: Alignment.center,
                  child: Text(
                    isFake ? "" : handleLabelText(item['label']),
                    style: TextStyle(
                        color: Color(
                            rowIndex == index && subIndex == columnIndex
                                ? 0xFF464EB5
                                : 0xFF677092),
                        fontSize: 14),
                  ),
                ),
              ],
            )));
  }

  handleLabelText(String value) {
    if (value.length >= 6 && value.endsWith('店')) {
      return value.substring(0, value.length - 1);
    } else {
      return value;
    }
  }

  Widget getItemsContainer(int pos) {
    if (_datas[pos]['val'] == 'ADD') {
      var item = _datas[pos]['children'][0];
      return Container(
        width: double.infinity,
        child: GestureDetector(
          onTap: () async {

          },
          child: Container(
            decoration: BoxDecoration(color: Colors.white),
            height: selectItemHeight,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  child: Image(
                      width: 9,
                      height: 9,
                      image: AssetImage("static/images/add_icon.png")),
                  padding: EdgeInsets.only(right: 5, top: 2),
                ),
                Text(
                  item['label'],
                  style:
                  TextStyle(color: Color(0xFF464EB5), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        margin: EdgeInsets.only(
            top: itemTopPadding, right: 15, bottom: lastItemBottomPadding),
      );
    }
    List items = _datas[pos]['children'];
    List<Widget> columnLists = new List();
    int lines = getItemLines(pos);
    for (int i = 0; i < lines; i++) {
      List<Widget> rowItems = new List();
      for (int j = 0; j < 3; j++) {
        if (i * 3 + j < items.length) {
          bool isFake = items[i * 3 + j]['label'] == '其他';
          rowItems.add(getItem(items[i * 3 + j], isFake, pos, i * 3 + j));
        } else {
          rowItems.add(getItem(null, true, pos, i * 3 + j));
        }
      }
      bool isLastItem = pos == _datas.length - 1 && i == lines - 1;
      Widget columnItem = Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowItems,
        ),
        margin: EdgeInsets.only(
            top: itemTopPadding,
            right: 15,
            bottom: isLastItem ? lastItemBottomPadding : 0),
      );
      columnLists.add(columnItem);
    }
    Widget colunmWidget = Column(
      children: columnLists,
    );
    return colunmWidget;
  }

  int optionsScrollState = KEEP_STATIC;
  bool menuClickToScroll = false;
  static int KEEP_STATIC = -1;
  static int NORMAL_SCROLLING = 0;
  static int SCROLLING_CLICED_BY_MENU = 1;

  @override
  Widget build(BuildContext context) {
    return _renderContent();
  }

  Widget _renderContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 0),
              controller: _menuController,
              itemCount: _datas.length,
              //列表项构造器
              itemBuilder: (BuildContext context, int index) {
                return getMenuItem(index);
              },
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Container(
            color: Color(0xFFF5F6FF),
            child: NotificationListener(
              onNotification: (notification) {
                switch (notification.runtimeType) {
                  case ScrollStartNotification:
                    optionsScrollState = menuClickToScroll
                        ? SCROLLING_CLICED_BY_MENU
                        : NORMAL_SCROLLING;
                    break;
                  case ScrollUpdateNotification:
                    break;
                  case ScrollEndNotification:
                    menuClickToScroll = false;
                    optionsScrollState = KEEP_STATIC;
                    break;
                  case OverscrollNotification:
                    break;
                }
              },
              child: ListView.builder(
                padding: EdgeInsets.only(top: 0),
                controller: _optionsController,
                itemCount: _datas.length,
                //列表项构造器
                itemBuilder: (BuildContext context, int index) {
                  return getChip(index);
                },
              ),
            ),
          ),
        )
      ],
    );
  }
}
