import 'dart:convert';

import '../../data/hardware/data_source.dart';
import '../../data/processing/session_pipeline.dart';
import '../../data/simulator/simulator_config.dart';
import 'column_map.dart';

/// A recorded data acquisition session.
///
/// A session captures all metadata needed to reproduce or re-process the data:
///   - For simulator sessions: the [SimulatorConfig] is stored so the exact
///     same frames can be re-generated on demand (no raw data storage needed).
///   - For CSV sessions: the file path is stored (user must keep the file).
///   - For future USB OTG / BLE: raw frame storage will be added.
class Session {
  const Session({
    required this.id,
    required this.name,
    required this.bikeSlug,
    required this.dataSourceType,
    this.csvPath,
    this.simulatorConfig,
    this.columnMap = const ColumnMap(),
    this.velocityQuantity = VelocityQuantity.shaft,
    required this.createdAt,
    this.analyzed = false,
  });

  final String id;
  final String name;
  final String bikeSlug;

  /// Identifies which [DataSource] produced this session's data.
  final DataSourceType dataSourceType;

  /// Absolute path to the CSV file (only set when [dataSourceType] == csv).
  final String? csvPath;

  /// Simulator parameters used to generate the data (only set when simulator).
  final SimulatorConfig? simulatorConfig;

  final ColumnMap columnMap;
  final VelocityQuantity velocityQuantity;
  final DateTime createdAt;
  final bool analyzed;

  Session copyWith({
    String? id,
    String? name,
    String? bikeSlug,
    DataSourceType? dataSourceType,
    String? csvPath,
    SimulatorConfig? simulatorConfig,
    ColumnMap? columnMap,
    VelocityQuantity? velocityQuantity,
    DateTime? createdAt,
    bool? analyzed,
  }) =>
      Session(
        id: id ?? this.id,
        name: name ?? this.name,
        bikeSlug: bikeSlug ?? this.bikeSlug,
        dataSourceType: dataSourceType ?? this.dataSourceType,
        csvPath: csvPath ?? this.csvPath,
        simulatorConfig: simulatorConfig ?? this.simulatorConfig,
        columnMap: columnMap ?? this.columnMap,
        velocityQuantity: velocityQuantity ?? this.velocityQuantity,
        createdAt: createdAt ?? this.createdAt,
        analyzed: analyzed ?? this.analyzed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bike_slug': bikeSlug,
        'data_source_type': dataSourceType.name,
        'csv_path': csvPath,
        'simulator_config': simulatorConfig?.toJson(),
        'column_map': columnMap.toJson(),
        'velocity_quantity': velocityQuantity.name,
        'created_at': createdAt.toIso8601String(),
        'analyzed': analyzed,
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        name: json['name'] as String,
        bikeSlug: json['bike_slug'] as String,
        dataSourceType: DataSourceType.values.firstWhere(
          (e) => e.name == json['data_source_type'],
          orElse: () => DataSourceType.simulator,
        ),
        csvPath: json['csv_path'] as String?,
        simulatorConfig: json['simulator_config'] != null
            ? SimulatorConfig.fromJson(
                json['simulator_config'] as Map<String, dynamic>)
            : null,
        columnMap: json['column_map'] != null
            ? ColumnMap.fromJson(json['column_map'] as Map<String, dynamic>)
            : const ColumnMap(),
        velocityQuantity: VelocityQuantity.values.firstWhere(
          (e) => e.name == json['velocity_quantity'],
          orElse: () => VelocityQuantity.shaft,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
        analyzed: json['analyzed'] as bool? ?? false,
      );

  String toJsonString() => jsonEncode(toJson());
  factory Session.fromJsonString(String s) =>
      Session.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Session($name [$id], analyzed=$analyzed)';
}
