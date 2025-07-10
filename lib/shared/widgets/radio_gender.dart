import 'package:flutter/material.dart';

class RadioGender extends StatefulWidget {
  final int? initGender;
  final Function genderFunction;
  const RadioGender({super.key, required this.genderFunction, this.initGender});

  @override
  State<RadioGender> createState() => _RadioGenderState();
}

class _RadioGenderState extends State<RadioGender> {
  int? gender;

  @override
  Widget build(BuildContext context) {
    gender ??= widget.initGender;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Giới tính",
            style: TextStyle(
                color: Color(0xFF1F2329),
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(
            height: 2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: <Widget>[
                  Text(
                    "Nam",
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.7), fontSize: 14),
                  ),
                  Radio(
                    value: 1,
                    onChanged: (value) {
                      setState(() {
                        gender = value;
                        widget.genderFunction(gender);
                      });
                    },
                    groupValue: gender,
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Text(
                    "Nữ",
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.7), fontSize: 14),
                  ),
                  Radio(
                    value: 0,
                    onChanged: (value) {
                      setState(() {
                        gender = value;
                        widget.genderFunction(gender);
                      });
                    },
                    groupValue: gender,
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Text(
                    "Khác",
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.7), fontSize: 14),
                  ),
                  Radio(
                    value: 2,
                    onChanged: (value) {
                      setState(() {
                        gender = value;
                        widget.genderFunction(gender);
                      });
                    },
                    groupValue: gender,
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
