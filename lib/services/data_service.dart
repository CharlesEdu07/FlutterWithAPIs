import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum TableStatus { idle, loading, ready, error }

enum ItemType {
  beer,
  coffee,
  nation,
  dessert,
  none;

  String get asString => name;

  List<String> get columns => this == coffee
      ? ["Nome", "Origem", "Tipo"]
      : this == beer
          ? ["Nome", "Estilo", "IBU"]
          : this == nation
              ? ["Nome", "Capital", "Idioma", "Esporte"]
              : this == dessert
                  ? ["Nome", "Cobertura", "Aroma"]
                  : [];

  List<String> get properties => this == coffee
      ? ["blend_name", "origin", "variety"]
      : this == beer
          ? ["name", "style", "ibu"]
          : this == nation
              ? ["nationality", "capital", "language", "national_sport"]
              : this == dessert
                  ? ["variety", "topping", "flavor"]
                  : [];
}

class DataService {
  static const maxNItems = 15;
  static const minNItems = 3;
  static const defaultNItems = 7;

  int _numberOfItems = defaultNItems;

  int get numberOfItems => _numberOfItems;

  set numberOfItems(int value) {
    _numberOfItems = value < 0
        ? minNItems
        : value > maxNItems
            ? maxNItems
            : value;
    carregar(tableStateNotifier.value['itemType'].index);
  }

  final ValueNotifier<Map<String, dynamic>> tableStateNotifier = ValueNotifier({
    'status': TableStatus.idle,
    'dataObjects': [],
    'itemType': ItemType.none
  });

  void carregar(index) {
    final params = [
      ItemType.coffee,
      ItemType.beer,
      ItemType.nation,
      ItemType.dessert
    ];

    loadByType(params[index]);
  }

  void sortCurrentState(String property, bool ascending) {
    List objects = tableStateNotifier.value['dataObjects'] ?? [];

    if (objects == []) return;

    var sortedObjects = List.from(objects);

    sortedObjects.sort((a, b) {
      var aValue = a[property];
      var bValue = b[property];

      if (aValue is String) {
        return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (aValue is int) {
        return ascending ? aValue - bValue : bValue - aValue;
      } else {
        return 0;
      }
    });

    sendSortedState(sortedObjects, property);
  }

  Uri buildUri(ItemType type) {
    return Uri(
      scheme: 'https',
      host: 'random-data-api.com',
      path: 'api/${type.asString}/random_${type.asString}',
      queryParameters: {'size': '$_numberOfItems'},
    );
  }

  Future<List<dynamic>> apiAccess(Uri uri) async {
    var jsonString = await http.read(uri);
    var json = jsonDecode(jsonString);

    json = [...tableStateNotifier.value['dataObjects'], ...json];

    return json;
  }

  void sendSortedState(List sortedObjects, String property) {
    var state = Map<String, dynamic>.from(tableStateNotifier.value);

    state['dataObjects'] = sortedObjects;
    state['sortCriteria'] = property;
    state['ascending'] = true;

    tableStateNotifier.value = state;
  }

  void sendLoadingState(ItemType type) {
    tableStateNotifier.value = {
      'status': TableStatus.loading,
      'dataObjects': [],
      'itemType': type
    };
  }

  void sendReadyState(ItemType type, var json) {
    tableStateNotifier.value = {
      'status': TableStatus.ready,
      'dataObjects': json,
      'itemType': type,
      'propertyNames': type.properties,
      'columnNames': type.columns,
    };
  }

  bool onGoingRequest() =>
      tableStateNotifier.value['status'] == TableStatus.loading;

  bool changeRequiredItemType(ItemType type) =>
      tableStateNotifier.value['itemType'] != type;

  void loadByType(ItemType type) async {
    if (onGoingRequest()) return;

    if (changeRequiredItemType(type)) {
      sendLoadingState(type);
    }

    var uri = buildUri(type);
    var json = await apiAccess(uri);

    sendReadyState(type, json);
  }
}

final dataService = DataService();
