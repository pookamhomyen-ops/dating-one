import 'package:flutter/material.dart';

class WallComponent extends StatelessWidget {
  final double width;
  final double height;
  
  const WallComponent({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blueGrey[700],
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(4, 0))
        ]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) => Container(
          height: 2,
          color: Colors.black26,
        )),
      ),
    );
  }
}
