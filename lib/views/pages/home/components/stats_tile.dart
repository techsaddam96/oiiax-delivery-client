import 'package:blockatie/utils/size_config.dart';
import 'package:blockatie/utils/spacing.dart';
import 'package:flutter/material.dart';

class HomeStatsTile extends StatelessWidget {
  const HomeStatsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: SizeConfig.heightMultiplier * 12,
      width: SizeConfig.widthMultiplier * 42,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), color: Colors.white),
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.widthMultiplier * 3),
      child: Row(
        children: [
          Container(
            // height: SizeConfig.heightMultiplier * 5.5,
            // width: SizeConfig.widthMultiplier * 12,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), color: color),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                icon,
                color: Colors.white,
                width: SizeConfig.widthMultiplier * 7,
                height: SizeConfig.heightMultiplier * 3.5,
              ),
            ),
          ),
          Spacing.x(2.5),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: textTheme.bodySmall!
                    .copyWith(fontSize: SizeConfig.textMultiplier * 1.2),
              )
            ],
          )
        ],
      ),
    );
  }
}
