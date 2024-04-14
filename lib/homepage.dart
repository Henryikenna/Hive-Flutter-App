import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();

    _refreshItems(); //load data when app starts
  }

  void _refreshItems() {
    final data = _shoppingBox.keys.map((key) {
      final item = _shoppingBox.get(key);
      return {"key": key, "name": item["name"], "quantity": item["quantity"]};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
      print(_items.length);
      // we use "reversed" to sort items in order from the latest to the oldest
    });
  }

  final _shoppingBox = Hive.box('shopping_box');

  //Create new item
  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _shoppingBox.add(newItem);
    // print("amount data is ${_shoppingBox.length}");
    _refreshItems();
  }

  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _shoppingBox.put(itemKey, item);
    _refreshItems(); // Update the UI
  }

  Future<void> _deleteItem(int itemKey) async {
    await _shoppingBox.delete(itemKey);
    _refreshItems(); // Update the UI

    if (mounted) {
      // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Item no. $itemKey has been deleted"),
        ),
      );
    }
  }

  void _showForm(BuildContext ctx, int? itemKey) async {
    if (itemKey != null) {
      final existingItem =
          _items.firstWhere((element) => element['key'] == itemKey);
      _nameController.text = existingItem['name'];
      _quantityController.text = existingItem['quantity'];
    } else {
      // Clear the text fields
      _nameController.text = '';
      _quantityController.text = '';
    }

    showModalBottomSheet(
      context: ctx,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 15,
          left: 15,
          right: 15,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Name',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                hintText: 'Quantity',
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                //If itemKey is null (when we're creatng a new item we pass null to the itemKey variable, check our implementation of it in the FloatingActionButton)
                // So if itemKey is null, the createItem function will be called
                if (itemKey == null) {
                  _createItem({
                    "name": _nameController.text,
                    "quantity": _quantityController.text,
                  });
                }
                // If itemKey is not null, the updateItem function will be called becuase we pass an itemKey when we're editing
                if (itemKey != null) {
                  _updateItem(itemKey, {
                    "name": _nameController.text.trim(),
                    "quantity": _quantityController.text.trim(),
                  });
                }

                // Clear the text fields
                _nameController.text = '';
                _quantityController.text = '';

                Navigator.pop(context);
              },
              child: Text(itemKey == null ? "Create New" : "Edit"),
            ),
            const SizedBox(
              height: 15,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive'),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, index) {
          final currentItem = _items[index];
          return Card(
            color: Colors.purple.shade100,
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: Text(currentItem['name']),
              subtitle: Text(currentItem['quantity'].toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      _showForm(context, currentItem['key']);
                    },
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () {
                      _deleteItem(currentItem['key']);
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showForm(context, null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
