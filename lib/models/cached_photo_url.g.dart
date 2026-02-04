// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_photo_url.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedPhotoUrlAdapter extends TypeAdapter<CachedPhotoUrl> {
  @override
  final typeId = 3;

  @override
  CachedPhotoUrl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedPhotoUrl();
  }

  @override
  void write(BinaryWriter writer, CachedPhotoUrl obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedPhotoUrlAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
