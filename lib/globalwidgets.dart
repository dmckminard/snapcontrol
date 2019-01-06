import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
            child: RefreshProgressIndicator(
              backgroundColor: Theme.of(context).primaryColor,
            )));
  }
}
