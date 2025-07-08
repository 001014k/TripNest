import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../widgets/custom_drawer_menu.dart';

class ZoomDrawerContainer extends StatefulWidget {
  final Widget Function(BuildContext context) mainScreenBuilder;
  final int selectedIndex;
  final Function(int index) onItemSelected;

  const ZoomDrawerContainer({
    Key? key,
    required this.mainScreenBuilder,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  State<ZoomDrawerContainer> createState() => _ZoomDrawerContainerState();
}

class _ZoomDrawerContainerState extends State<ZoomDrawerContainer> {
  final ZoomDrawerController _zoomDrawerController = ZoomDrawerController();

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: _zoomDrawerController,
      menuBackgroundColor: const Color(0xFF242629),
      shadowLayer1Color: const Color(0xFF47454E),
      shadowLayer2Color: const Color(0xFFE6E6E6).withOpacity(0.3),
      borderRadius: 32.0,
      showShadow: true,
      style: DrawerStyle.defaultStyle,
      angle: -12.0,
      drawerShadowsBackgroundColor: Colors.black38,
      slideWidth: MediaQuery.of(context).size.width * 0.7,
      menuScreen: CustomDrawerMenu(
        selectedIndex: widget.selectedIndex,
        onItemSelected: widget.onItemSelected,
      ),
      mainScreen: widget.mainScreenBuilder(context),
    );
  }
}


