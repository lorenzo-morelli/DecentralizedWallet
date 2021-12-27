import 'package:flutter/material.dart';

class ListItem extends StatefulWidget {
  final bool buy;
  final int quantity;

  const ListItem({Key? key, required this.buy, required this.quantity}) : super(key: key);

  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  @override
  Widget build(BuildContext context) {
    String number = widget.quantity.toString();

    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, bottom: 15),
      height: 60,
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 3,
            blurRadius: 8,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Center(
        child: widget.buy
            ? Text('+\$${widget.quantity.toString()}', style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.w500))
            : Text('-\$${(widget.quantity * (-1)).toString()}',
                style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
