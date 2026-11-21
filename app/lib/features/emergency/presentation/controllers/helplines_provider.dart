import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scamshield/core/di/injection.dart';
import 'package:scamshield/features/emergency/domain/entities/helpline.dart';
import 'package:scamshield/features/emergency/domain/usecases/get_helplines.dart';

part 'helplines_provider.g.dart';

@riverpod
Future<List<Helpline>> helplines(Ref ref) => getIt<GetHelplines>()();