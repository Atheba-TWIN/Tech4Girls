// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertSettingsAdapter extends TypeAdapter<AlertSettings> {
  @override
  final int typeId = 1;

  @override
  AlertSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertSettings(
      temperatureThreshold: fields[0] as double,
      enableTemperatureAlert: fields[1] as bool,
      enableEmergencyAlert: fields[2] as bool,
      enableNotifications: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AlertSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.temperatureThreshold)
      ..writeByte(1)
      ..write(obj.enableTemperatureAlert)
      ..writeByte(2)
      ..write(obj.enableEmergencyAlert)
      ..writeByte(3)
      ..write(obj.enableNotifications);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
