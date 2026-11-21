import 'package:scamshield/features/emergency/domain/entities/helpline.dart';

abstract interface class HelplineRepository {
  Future<List<Helpline>> getHelplines();
}