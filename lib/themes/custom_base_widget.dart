import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/dark_theme_provider.dart';
import '../widget/ui_spacer.dart';
import 'appbar_cust.dart';

class CustomBaseWidget extends StatefulWidget {
  final bool useSafeArea;
  final bool showAppBar;
  final bool showLeadingAction;
  final bool showCart;
  final Function? onBackPressed;
  final String? appBarTitle;
  final Widget body;
  final Widget? appBar;
  final Widget? bottomSheet;
  final Widget? fab;
  final bool isLoading;
  final bool extendBodyBehindAppBar;
  final double? elevation;
  final Color? appBarItemColor;
  final Color? backgroundColor;
  final Color? appBarColor;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final bool resizeToAvoidBottomInset;

  const CustomBaseWidget({
    this.useSafeArea = false,
    this.showAppBar = false,
    this.showLeadingAction = false,
    this.leading,
    this.showCart = false,
    this.onBackPressed,
    this.appBarTitle = "",
    required this.body,
    this.appBar,
    this.bottomSheet,
    this.fab,
    this.isLoading = false,
    this.appBarColor,
    this.elevation,
    this.extendBodyBehindAppBar = false,
    this.appBarItemColor,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.actions,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  @override
  _CustomBaseWidgetState createState() => _CustomBaseWidgetState();
}

class _CustomBaseWidgetState extends State<CustomBaseWidget> {


  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    Color textColor =widget.appBarColor ?? Theme.of(context).primaryColor;

    Widget scaffold = Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      // backgroundColor:
      // widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      // appBar: widget.showAppBar
      //     ? (widget.appBar != null
      //     ? PreferredSize(
      //   preferredSize: const Size.fromHeight(kToolbarHeight),
      //   child: widget.appBar!,
      // )
      //     : AppBar(
      //   backgroundColor:
      //   widget.appBarColor ?? Colors.transparent,
      //   elevation: widget.elevation,
      //   automaticallyImplyLeading:
      //   widget.showLeadingAction || Navigator.canPop(context),
      //   leading: widget.showLeadingAction || Navigator.canPop(context)
      //       ? widget.leading ??
      //       IconButton(
      //         icon: Icon(
      //           Icons.arrow_back,
      //           color: widget.appBarItemColor ??
      //               Theme.of(context).colorScheme.onPrimary,
      //         ),
      //         onPressed: widget.onBackPressed != null
      //             ? () => widget.onBackPressed!()
      //             : () => Navigator.pop(context),
      //       )
      //       : null,
      //   title: Text(
      //     widget.appBarTitle ?? "",
      //     style: Theme.of(context).textTheme.titleLarge?.copyWith(
      //       color: widget.appBarItemColor ??
      //           Theme.of(context).colorScheme.onPrimary,
      //     ),
      //   ),
      //   actions: widget.actions,
      // ))
      //     : null,
      appBar: widget.showAppBar
          ? (widget.appBar != null
          ? PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: widget.appBar!,
      )
          : CustomAppbar(
        title: widget.appBarTitle ?? "",
        bgColor: widget.appBarColor,
        textColor: widget.appBarItemColor,
        elevation: widget.elevation,
        leading: widget.leading,
        isLeadingIcon: widget.showLeadingAction || Navigator.canPop(context),
        onClick: widget.onBackPressed != null
            ? () => widget.onBackPressed!()
            : null,

        actions: widget.actions,
      ))
          : null,



      body: Column(
        children: [
          widget.isLoading
              ? const LinearProgressIndicator()
              : UiSpacer.emptySpace(),
          Expanded(child: widget.body),
        ],
      ),
      bottomSheet: widget.bottomSheet,
      floatingActionButton: widget.fab,
      bottomNavigationBar: widget.bottomNavigationBar,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: widget.useSafeArea ? SafeArea(child: scaffold) : scaffold,
    );
  }
}