import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Product {
  final String name; //название
  final String type; //тип
  final String makeDate; //дата изготовления
  final String expirationDate; //дата истечения срока годности
  final String weight; // масса/объём
  final String nutritionalInfo; // пищевая ценность
  final String typeMeasure; //тип измерения

  Product({
    required this.name,
    required this.type,
    required this.makeDate,
    required this.expirationDate,
    required this.weight,
    required this.nutritionalInfo,
    required this.typeMeasure,
  });
}