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
    load(tableStateNotifier.value['itemType'].index);
  }

  final ValueNotifier<Map<String, dynamic>> tableStateNotifier = ValueNotifier({
    'status': TableStatus.idle,
    'dataObjects': [],
    'itemType': ItemType.none
  });

  final List<Map<String, dynamic>> previousStates = [];
  final List<Map<String, dynamic>> nextStates = [];

  void load(index) {
    previousStates.add(Map<String, dynamic>.from(tableStateNotifier.value));

    final params = [
      ItemType.coffee,
      ItemType.beer,
      ItemType.nation,
      ItemType.dessert
    ];

    loadByType(params[index]);
  }

  void sortCurrentState(String property) {
    previousStates.add(Map<String, dynamic>.from(tableStateNotifier.value));

    List objects = tableStateNotifier.value['dataObjects'] ?? [];

    if (objects.isEmpty) return;

    bool ascending = true;
    var sortCriteria = tableStateNotifier.value['sortCriteria'];

    if (sortCriteria == property) {
      ascending = !tableStateNotifier.value[
          'ascending']; // Alternar entre crescente e decrescente se a mesma coluna for clicada novamente
    }

    objects.sort((a, b) {
      final valueA = a[property];
      final valueB = b[property];
      return ascending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
    });

    sendSortedState(objects, property, ascending);
  }

  void undo() {
    if (previousStates.isEmpty) return;

    nextStates.add(Map<String, dynamic>.from(tableStateNotifier.value));

    tableStateNotifier.value = previousStates.removeLast();
  }

  void redo() {
    if (nextStates.isEmpty) return;

    previousStates.add(Map<String, dynamic>.from(tableStateNotifier.value));

    tableStateNotifier.value = nextStates.removeLast();
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

  void sendSortedState(List sortedObjects, String property, bool ascending) {
    var state = Map<String, dynamic>.from(tableStateNotifier.value);

    state['dataObjects'] = sortedObjects;
    state['sortCriteria'] = property;
    state['ascending'] = ascending;

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
