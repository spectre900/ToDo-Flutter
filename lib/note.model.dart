import 'package:hive/hive.dart';

part 'note.model.g.dart';

@HiveType(typeId: 0)
class Note{
  @HiveField(0)
  String title;
  @HiveField(1)
  bool finished = false;
  Note(this.title,this.finished);
}