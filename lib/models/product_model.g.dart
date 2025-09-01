// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String,
      image: fields[3] as String,
      price: fields[4] as double,
      categoryId: fields[5] as int,
      ownerProfileImage: fields[6] as String?,
      categoryName: fields[7] as String,
      ownerId: fields[8] as String,
      ownerName: fields[9] as String,
      locationName: fields[10] as String,
      availability: fields[11] as bool,
      createdAt: fields[12] as DateTime,
      status: fields[13] as String,
      views: fields[14] as int,
      isWishlisted: fields[15] as bool,
      latitude: fields[16] as double?,
      longitude: fields[17] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.image)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.ownerProfileImage)
      ..writeByte(7)
      ..write(obj.categoryName)
      ..writeByte(8)
      ..write(obj.ownerId)
      ..writeByte(9)
      ..write(obj.ownerName)
      ..writeByte(10)
      ..write(obj.locationName)
      ..writeByte(11)
      ..write(obj.availability)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.views)
      ..writeByte(15)
      ..write(obj.isWishlisted)
      ..writeByte(16)
      ..write(obj.latitude)
      ..writeByte(17)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
