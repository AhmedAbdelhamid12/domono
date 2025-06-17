// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Domino Score';

  @override
  String get resetGame => 'Reset Game';

  @override
  String get editTeamNames => 'Edit Team Names';

  @override
  String get rightTeam => 'Right Team';

  @override
  String get leftTeam => 'Left Team';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get total => 'Total';

  @override
  String get noScores => 'No scores recorded';

  @override
  String get selectedTeam => 'Selected Team';

  @override
  String get matchLimit => 'Winning Limit';

  @override
  String get points => 'points';

  @override
  String get history => 'Match History';

  @override
  String get noHistory => 'No previous matches';

  @override
  String get winMessage => 'won with';

  @override
  String get resetConfirmation => 'Are you sure you want to reset the points?';

  @override
  String get confirm => 'Confirm';

  @override
  String get matchResult => 'Match Result';

  @override
  String get date => 'Date';

  @override
  String get close => 'Close';

  @override
  String get showCurrentGame => 'Show Current Game';

  @override
  String get showHistory => 'Show History';
}
