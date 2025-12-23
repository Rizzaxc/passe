import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

class PuboxIcons {
  static const age = SvgPicture(AssetBytesLoader('./assets/icons/age.svg.vec'));

  static const suitcase =
  SvgPicture(AssetBytesLoader('./assets/icons/suitcase.svg.vec'));

  static const male =
  SvgPicture(AssetBytesLoader('./assets/icons/male.svg.vec'));

  static const female =
  SvgPicture(AssetBytesLoader('./assets/icons/female.svg.vec'));

  static const ageGroup =
  SvgPicture(AssetBytesLoader('./assets/icons/ageGroup.svg.vec'));

  static const badminton =
  SvgPicture(AssetBytesLoader('./assets/icons/badminton.svg.vec'));

  static const basketball =
  SvgPicture(AssetBytesLoader('./assets/icons/basketball.svg.vec'));

  static const basketballDunk =
  SvgPicture(AssetBytesLoader('./assets/icons/basketballDunk.svg.vec'));

  static const coach =
  SvgPicture(AssetBytesLoader('./assets/icons/coach.svg.vec'));

  static const gender =
  SvgPicture(AssetBytesLoader('./assets/icons/gender.svg.vec'));

  static const googleRound =
  AssetBytesLoader('./assets/icons/google_round.svg.vec');

  static const lobby =
  SvgPicture(AssetBytesLoader('./assets/icons/lobby.svg.vec'));

  static const network =
  SvgPicture(AssetBytesLoader('./assets/icons/network.svg.vec'));

  static const pickleball =
  SvgPicture(AssetBytesLoader('./assets/icons/pickleball.svg.vec'));

  static const playtime =
  SvgPicture(AssetBytesLoader('./assets/icons/playtime.svg.vec'));

  static const position =
  SvgPicture(AssetBytesLoader('./assets/icons/position.svg.vec'));

  static const referee =
  SvgPicture(AssetBytesLoader('./assets/icons/referee.svg.vec'));

  static const soccer =
  SvgPicture(AssetBytesLoader('./assets/icons/soccer.svg.vec'));

  static const soccerGK =
  SvgPicture(AssetBytesLoader('./assets/icons/soccerGK.svg.vec'));

  static const soccerOutfield =
  SvgPicture(AssetBytesLoader('./assets/icons/soccerOutfield.svg.vec'));

  static const strength =
  SvgPicture(AssetBytesLoader('./assets/icons/strength.svg.vec'));

  static const tennis =
  SvgPicture(AssetBytesLoader('./assets/icons/tennis.svg.vec'));

  static const profile =
  SvgPicture(AssetBytesLoader('./assets/icons/profile.svg.vec'));
}

class SportIcons {
  static SizedBox soccer({double size = 16}) {
    return SizedBox.fromSize(
        size: Size.fromRadius(size), child: PuboxIcons.soccer);
  }

  static SizedBox basketball({double size = 16}) {
    return SizedBox.fromSize(
        size: Size.fromRadius(size), child: PuboxIcons.basketball);
  }

  static SizedBox tennis({double size = 16}) {
    return SizedBox.fromSize(
        size: Size.fromRadius(size), child: PuboxIcons.tennis);
  }

  static SizedBox badminton({double size = 16}) {
    return SizedBox.fromSize(
        size: Size.fromRadius(size), child: PuboxIcons.badminton);
  }

  static SizedBox pickleball({double size = 16}) {
    return SizedBox.fromSize(
        size: Size.fromRadius(size), child: PuboxIcons.pickleball);
  }
}
