import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../services/data_service.dart';

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text("Dicas"), actions: [
            PopupMenuButton(
                itemBuilder: (_) => [3, 7, 15]
                    .map((number) => PopupMenuItem(
                          value: number,
                          child: Text("Carregar $number itens por vez"),
                        ))
                    .toList(),
                onSelected: (number) {
                  dataService.numberOfItems = number;
                },
                child: ValueListenableBuilder(
                    valueListenable: dataService.tableStateNotifier,
                    builder: (_, value, __) {
                      return Row(children: [
                        Text("${dataService.numberOfItems} itens por vez"),
                        const Icon(Icons.arrow_drop_down)
                      ]);
                    }))
          ]),
          body: ValueListenableBuilder(
              valueListenable: dataService.tableStateNotifier,
              builder: (_, value, __) {
                switch (value['status']) {
                  case TableStatus.idle:
                    return const Center(child: Text("Toque em algum botão"));

                  case TableStatus.loading:
                    return const Center(child: CircularProgressIndicator());

                  case TableStatus.ready:
                    return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SingleChildScrollView(
                            child: DataTableWidget(
                                jsonObjects: value['dataObjects'],
                                propertyNames: value['propertyNames'],
                                columnNames: value['columnNames']),
                          )
                        ]);

                  case TableStatus.error:
                    return const Text("Lascou");
                }

                return const Text("...");
              }),
          bottomNavigationBar:
              NewNavBar(itemSelectedCallback: dataService.carregar),
        ));
  }
}

class NewNavBar extends HookWidget {
  final _itemSelectedCallback;

  NewNavBar({itemSelectedCallback})
      : _itemSelectedCallback = itemSelectedCallback ?? (int) {}

  @override
  Widget build(BuildContext context) {
    var state = useState(1);

    return BottomNavigationBar(
        onTap: (index) {
          state.value = index;

          _itemSelectedCallback(index);
        },
        currentIndex: state.value,
        items: const [
          BottomNavigationBarItem(
            label: "Cafés",
            icon: Icon(Icons.coffee_outlined, color: Colors.black),
          ),
          BottomNavigationBarItem(
              label: "Cervejas",
              icon: Icon(Icons.local_drink, color: Colors.black)),
          BottomNavigationBarItem(
              label: "Nações",
              icon: Icon(Icons.flag_outlined, color: Colors.black)),
          BottomNavigationBarItem(
              label: "Sobremessas",
              icon: Icon(Icons.cake_outlined, color: Colors.black)),
        ]);
  }
}

class DataTableWidget extends StatefulWidget {
  final List jsonObjects;
  final List<String> columnNames;
  final List<String> propertyNames;

  DataTableWidget({
    this.jsonObjects = const [],
    this.columnNames = const [],
    this.propertyNames = const [],
  });

  @override
  _DataTableWidgetState createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      columns: widget.columnNames
          .asMap()
          .map((index, name) => MapEntry(
                index,
                DataColumn(
                  label: Text(name,
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _sortColumnIndex = columnIndex;
                      _sortAscending = ascending;
                    });
                    dataService.sortCurrentState(
                        widget.propertyNames[columnIndex], ascending);
                  },
                ),
              ))
          .values
          .toList(),
      rows: widget.jsonObjects.map((obj) {
        return DataRow(
          cells: widget.propertyNames
              .map((propName) => DataCell(Text(obj[propName])))
              .toList(),
        );
      }).toList(),
    );
  }
}
