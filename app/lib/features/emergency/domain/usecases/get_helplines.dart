import 'package:injectable/injectable.dart';
import 'package:scamshield/features/emergency/domain/entities/helpline.dart';
import 'package:scamshield/features/emergency/domain/repositories/helpline_repository.dart';

@injectable
class GetHelplines {
  const GetHelplines(this._repository);

  final HelplineRepository _repository;

  Future<List<Helpline>> call() => _repository.getHelplines();
}