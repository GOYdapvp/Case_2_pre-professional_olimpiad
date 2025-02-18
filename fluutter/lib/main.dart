import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Дополнительный код для выхода пользователя
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = '${await getDatabasesPath()}/products_database.db';
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _onCreate(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _onCreate(db, newVersion);
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        typ TEXT,
        makeday TEXT,
        expirationday TEXT,
        weight REAL,
        nutritionalinfo REAL,
        typemeasure TEXT,
        quantity REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS operation_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        product_name TEXT,
        timestamp TEXT,
        location TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_list(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        is_checked INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        message TEXT,
        timestamp TEXT,
        isRead INTEGER
      )
    ''');

    await _createTriggers(db);
  }

  Future<void> _createTriggers(Database db) async {
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS after_insert_products
      AFTER INSERT ON products
      BEGIN
        INSERT INTO operation_history (action, product_name, timestamp, location)
        VALUES ('add', NEW.name, DATETIME('now'), 'Основной список');
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS after_delete_products
      AFTER DELETE ON products
      BEGIN
        INSERT INTO operation_history (action, product_name, timestamp, location)
        VALUES ('remove', OLD.name, DATETIME('now'), 'Основной список');
      END
    ''');
  }

  Future<int> insertProduct(Product product) async {
    Database db = await database;
    return await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateProduct(Product product) async {
    Database db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<List<Product>> getProducts() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<int> deleteProduct(int id) async {
    Database db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllProducts() async {
    Database db = await database;
    return await db.delete('products');
  }

  Future<bool> productExists(String name) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'name = ?',
      whereArgs: [name],
    );
    return maps.isNotEmpty;
  }

  Future<int> insertHistoryItem(HistoryItem item) async {
    Database db = await database;
    return await db.insert('operation_history', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HistoryItem>> getHistoryItems() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('operation_history');
    return List.generate(maps.length, (i) => HistoryItem.fromMap(maps[i]));
  }

  Future<int> deleteHistoryItem(int id) async {
    Database db = await database;
    return await db.delete('operation_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearHistory() async {
    Database db = await database;
    return await db.delete('operation_history');
  }

  Future<int> insertShoppingItem(ShoppingItem item) async {
    Database db = await database;
    return await db.insert('shopping_list', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ShoppingItem>> getShoppingList() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('shopping_list');
    return List.generate(maps.length, (i) => ShoppingItem.fromMap(maps[i]));
  }

  Future<int> updateShoppingItem(ShoppingItem item) async {
    Database db = await database;
    return await db.update(
      'shopping_list',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> clearShoppingList() async {
    Database db = await database;
    return await db.delete('shopping_list');
  }

  Future<int> deleteShoppingItem(int id) async {
    Database db = await database;
    return await db.delete('shopping_list', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isTableExists(String tableName) async {
    Database db = await database;
    var result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
    );
    return result.isNotEmpty;
  }

  Future<int> insertNotification(Notification notification) async {
    Database db = await database;
    return await db.insert('notifications', notification.toMap());
  }

  Future<List<Notification>> getNotifications() async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query('notifications');
      return List.generate(maps.length, (i) => Notification.fromMap(maps[i]));
    } catch (e) {
      print('Ошибка при получении уведомлений: $e');
      if (e.toString().contains('no such table')) {
        return getNotifications(); // Повторная попытка после создания таблицы
      }
      return [];
    }
  }
  Future<int> deleteNotification(int id) async {
    Database db = await database;
    return await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getExpiringProducts() async {
    final db = await database;
    final now = DateTime.now();
    final threeDaysLater = now.add(Duration(days: 3));

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'expirationday BETWEEN ? AND ?',
      whereArgs: [now.toIso8601String(), threeDaysLater.toIso8601String()],
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }
  Future<List<Product>> getExpiredProducts() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'expirationday < ?',
      whereArgs: [now],
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<List<Map<String, dynamic>>> getAllTables() async {
    Database db = await database;
    return await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  }

  Future<List<Map<String, dynamic>>> getTableContent(String tableName) async {
    Database db = await database;
    try {
      return await db.query(tableName);
    } catch (e) {
      print('Ошибка при получении данных из таблицы $tableName: $e');
      return [];
    }
  }
  Future<List<Product>> getExpiringSoonProducts() async {
    final db = await database;
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 3));

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'expirationday BETWEEN ? AND ?',
      whereArgs: [now.toIso8601String(), threshold.toIso8601String()],
    );

    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }
}

class Product {
  int? id;
  String name;
  String typ;
  String makeday;
  String expirationday;
  double weight;
  double nutritionalinfo;
  String typemeasure;
  int quantity;

  Product({
    this.id,
    required this.name,
    required this.typ,
    required this.makeday,
    required this.expirationday,
    required this.weight,
    required this.nutritionalinfo,
    required this.typemeasure,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'typ': typ,
      'makeday': makeday,
      'expirationday': expirationday,
      'weight': weight,
      'nutritionalinfo': nutritionalinfo,
      'typemeasure': typemeasure,
      'quantity': quantity,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      typ: map['typ'],
      makeday: map['makeday'],
      expirationday: map['expirationday'],
      weight: map['weight'],
      nutritionalinfo: map['nutritionalinfo'],
      typemeasure: map['typemeasure'],
      quantity: map['quantity'] ?? 1,
    );
  }
}

class Department {
  final String name;
  final List<Product> products;

  Department({required this.name, required this.products});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'products': products.map((product) => product.toMap()).toList(),
    };
  }

  static Department fromMap(Map<String, dynamic> map) {
    return Department(
      name: map['name'],
      products: (map['products'] as List)
          .map((productMap) => Product.fromMap(productMap))
          .toList(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Холодильник',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Холодильник'),
          centerTitle: true,
        ),
        body: QRScannerPage(),
      ),
    );
  }
}


class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}
class _QRScannerPageState extends State<QRScannerPage> with WidgetsBindingObserver {
  List<Department> _departments = [];
  List<Product> _expiredProducts = []; // Список для хранения просроченных продуктов
  List<HistoryItem> _historyItems = [];
  String _searchQuery = ''; // Новое состояние для поискового запроса
  bool _isSearching = false; // Флаг для отслеживания состояния
  Future<void> resetAppData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _departments.clear();
      _expiredProducts.clear();
      _historyItems.clear();
    });
    _saveProducts();

    // Очистка базы данных
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.deleteAllProducts();
    await dbHelper.clearHistory();
    await dbHelper.clearShoppingList();

    // Показать сообщение пользователю
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Все данные приложения очищены')),
    );
  }
  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadHistory();
    _removeExpiredProducts();
    WidgetsBinding.instance.addObserver(this);
  }

  List<Product> _getFilteredProducts() {
    List<Product> allProducts = [];
    for (var department in _departments) {
      allProducts.addAll(department.products);
    }
    return allProducts.where((product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _scanQR() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666',
      'Отмена',
      true,
      ScanMode.QR,
    );

    if (barcodeScanRes != '-1') {
      Map<String, dynamic> productData = json.decode(barcodeScanRes);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            scanResult: productData,
            onConfirm: () => _addProduct(productData),
          ),
        ),
      );
    }
  }

  void _saveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> historyJson = _historyItems.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList('history', historyJson);
  }
  void _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? historyJson = prefs.getStringList('history');
    if (historyJson != null) {
      setState(() {
        _historyItems = historyJson.map((item) => HistoryItem.fromMap(jsonDecode(item))).toList();
      });
    }
  }

  DatabaseHelper dbHelper = DatabaseHelper();

  void _addProduct(Map<String, dynamic> productData) {
    setState(() {
      // Найти отдел (Department) по типу продукта
      Department? department = _departments.firstWhere(
            (dept) => dept.name == productData['typ'],
        orElse: () {
          // Если отдела нет, создаем новый
          var newDept = Department(name: productData['typ'], products: []);
          _departments.add(newDept);
          return newDept;
        },
      );
      int existingIndex = department.products.indexWhere((p) =>
      p.name == productData['name'] &&
          p.typ == productData['typ'] &&
          p.makeday == productData['makeday'] &&
          p.expirationday == productData['expirationday'] &&
          p.weight == productData['weight'] &&
          p.nutritionalinfo == productData['nutritionalinfo'] &&
          p.typemeasure == productData['typemeasure']);
      if (existingIndex != -1) {
        // Если продукт уже существует, увеличиваем его количество
        department.products[existingIndex].quantity =
            (department.products[existingIndex].quantity ?? 0) + 1;
      } else {
        // Если продукта нет, создаем новый
        Product newProduct = Product(
          name: productData['name'],
          typ: productData['typ'],
          expirationday: productData['expirationday'],
          makeday: productData['makeday'],
          weight: productData['weight'],
          nutritionalinfo: productData['nutritionalinfo'],
          typemeasure: productData['typemeasure'],
          quantity: 1,
        );
        department.products.add(newProduct);
        dbHelper.insertProduct(newProduct);

        _addHistoryItem(HistoryItem(
          action: 'add',
          productName: newProduct.name,
          timestamp: DateTime.now(),
          location: 'Основной список',
        ));
        if (_getRemainingDays(newProduct.expirationday) == 'Просрочен') {
          _expiredProducts.add(newProduct);
        }
      }
    });
    // Удаляем просроченные продукты
    //_removeExpiredProducts();

    // Сохраняем изменения в базе данных и SharedPreferences
    _saveProducts();
  }
  void _deleteProduct(Product product, int departmentIndex) {
    setState(() {
      if (product.quantity > 1) {
        product.quantity--;
      } else {
        _departments[departmentIndex].products.remove(product);
        if (_departments[departmentIndex].products.isEmpty) {
          _departments.removeAt(departmentIndex);
        }
      }
    });
    _saveProducts();
    _addHistoryItem(HistoryItem(
      action: 'remove',
      productName: product.name,
      timestamp: DateTime.now(),
      location: 'Основной список',
    ));
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProducts = prefs.getString('products');
    if (savedProducts != null) {
      final decodedProducts = jsonDecode(savedProducts) as List;
      setState(() {
        _departments = decodedProducts.map((deptMap) => Department.fromMap(deptMap)).toList();
      });
    }
  }
  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedProducts = jsonEncode(_departments.map((dept) =>
        dept.toMap()
    ).toList());
    await prefs.setString('products', encodedProducts);
  }

  void _removeExpiredProducts() {
    for (var department in _departments) {
      department.products.removeWhere((product) {
        if (_getRemainingDays(product.expirationday) == 'Просрочен') {
          _expiredProducts.add(product);
          _addHistoryItem(HistoryItem(
            action: 'remove',
            productName: product.name,
            timestamp: DateTime.now(),
            location: 'Основной список',
          ));
          return true;
        }
        return false;
      });
    }
    _departments.removeWhere((department) => department.products.isEmpty);
  }

  String _getRemainingDays(String expirationDateStr) {
    DateTime expirationDate = DateTime.parse(expirationDateStr);
    DateTime now = DateTime.now();
    // Приводим текущую дату к началу дня
    DateTime today = DateTime(now.year, now.month, now.day);
    int remainingDays = expirationDate.difference(today).inDays;
    if (remainingDays < 0) {
      return 'Просрочен';
    } else if (remainingDays == 0) {
      return 'Истекает сегодня';
    } else if (remainingDays == 1) {
      return 'Истекает завтра';
    } else {
      return '${remainingDays} дн.';
    }
  }


  void _addHistoryItem(HistoryItem item) {
    setState(() {
      _historyItems.add(item);
    });
    _saveHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Поиск продукта...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : Text('Поиск продуктов'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: _searchQuery.isEmpty
          ? ListView.builder(
        itemCount: _departments.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(_departments[index].name),
            children: _departments[index].products.map((product) {
              return Dismissible(
                key: UniqueKey(),
                background: Container(
                  color: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteProduct(product, index);
                },
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(product.name)),
                      Text(
                        '${product.quantity} шт. - ${_getRemainingDays(product.expirationday)}',
                        style: TextStyle(
                          color: _getRemainingDays(product.expirationday) == 'Просрочен'
                              ? Colors.red
                              : _getRemainingDays(product.expirationday) == 'Истекает сегодня'
                              ? Colors.deepOrange
                              : _getRemainingDays(product.expirationday) == 'Истекает завтра'
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    ],
                  ),
                  subtitle: Text('${product.weight}${product.typemeasure}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(product: product),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Удалить продукт'),
                            content: Text('Вы уверены, что хотите удалить ${product.name}?'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Отмена'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('Удалить'),
                                onPressed: () {
                                  _deleteProduct(product, index);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      )
          : ListView.builder(
        itemCount: _getFilteredProducts().length,
        itemBuilder: (context, index) {
          final product = _getFilteredProducts()[index];
          String remainingDays = _getRemainingDays(product.expirationday);
          return ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(product.name)),
                Text(
                  remainingDays,
                  style: TextStyle(
                    color: remainingDays == 'Просрочен' ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            subtitle: Text('${product.weight}${product.typemeasure}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(product: product),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.qr_code_scanner),
              onPressed: _scanQR,
              tooltip: 'Сканировать QR-код',
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShoppingListPage(
                onHistoryItemAdded: (historyItem) {
                  setState(() {
                    _historyItems.add(historyItem);
                  });
                },
              )),
              );
              },
              tooltip: 'Список покупок',
            ),
            IconButton(
              icon: Icon(Icons.history),
              onPressed: () {
                Navigator.push(

                  context,
                  MaterialPageRoute(builder: (context) => HistoryPage(historyItems: _historyItems)),
                );
              },
              tooltip: 'Аналитика',
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    _saveProducts();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveProducts();
    }
  }
}


class ResultPage extends StatelessWidget {
  final Map<String, dynamic> scanResult;
  final Function onConfirm;

  ResultPage({required this.scanResult, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Результат сканирования'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Детали продукта:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Table(
                border: TableBorder.all(),
                children: scanResult.entries.map((entry) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(entry.value.toString()),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    onConfirm();
                    Navigator.pop(context);
                  },
                  child: Text('Добавить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ProductDetailsPage extends StatelessWidget {
  final Product product;
  ProductDetailsPage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            border: TableBorder.all(),
            children: [
              _buildTableRow('Название', product.name),
              _buildTableRow('Тип', product.typ),
              _buildTableRow('Дата изготовления', DateFormat('dd.MM.yyyy').format(DateTime.parse(product.makeday))),
              _buildTableRow('Годен до', DateFormat('dd.MM.yyyy').format(DateTime.parse(product.expirationday))),
              _buildTableRow('Вес', '${product.weight} ${product.typemeasure}'),
              _buildTableRow('Пищевая ценность', '${product.nutritionalinfo} ${'ккал'}'),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)))),
        TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(value))),
      ],
    );
  }
}


class ShoppingListPage extends StatefulWidget {
  final Function(HistoryItem) onHistoryItemAdded;

  ShoppingListPage({required this.onHistoryItemAdded});

  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}
class _ShoppingListPageState extends State<ShoppingListPage> {
  List<ShoppingItem> shoppingList = [];
  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  void _loadShoppingList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedList = prefs.getStringList('shopping_list');
    if (savedList != null) {
      shoppingList = savedList.map((item) => ShoppingItem.fromMap(jsonDecode(item))).toList();
      setState(() {});
    }
  }

  void _saveShoppingList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> saveList = shoppingList.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList('shopping_list', saveList);
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Добавить в список покупок'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textFieldController,
                decoration: InputDecoration(hintText: "Введите название продукта"),
                autofocus: true,
              ),
              SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(hintText: "Введите количество"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Добавить'),
              onPressed: () {
                setState(() {
                  if (_textFieldController.text.isNotEmpty) {
                    int quantity = int.tryParse(_quantityController.text) ?? 1;
                    shoppingList.add(ShoppingItem(
                      name: _textFieldController.text,
                      quantity: quantity,
                    ));
                    _textFieldController.clear();
                    _quantityController.clear();
                  }
                });
                Navigator.of(context).pop();
                _saveShoppingList();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список покупок'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addItem,
            tooltip: 'Добавить продукт',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: shoppingList.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(shoppingList[index].name),
            background: Container(
              color: Colors.red,
              child: Icon(Icons.delete, color: Colors.white),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                shoppingList.removeAt(index);
                _saveShoppingList();
              });
            },
            child: ListTile(
              title: Text(
                '${shoppingList[index].name} (${shoppingList[index].quantity})',
                style: TextStyle(
                  decoration: shoppingList[index].isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              leading: GestureDetector(
                onTap: () {
                  setState(() {
                    shoppingList[index].isChecked = !shoppingList[index].isChecked;
                    _saveShoppingList();
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: shoppingList[index].isChecked ? Colors.green : Colors.transparent,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: shoppingList[index].isChecked
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (shoppingList[index].quantity > 1) {
                          shoppingList[index].quantity--;
                          _saveShoppingList();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        shoppingList[index].quantity++;
                        _saveShoppingList();
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _saveShoppingList();
    super.dispose();
  }
}
class ShoppingItem {
  int? id;
  String name;
  bool isChecked;
  int quantity;

  ShoppingItem({
    this.id,
    required this.name,
    this.isChecked = false,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isChecked': isChecked ? 1 : 0,
      'quantity': quantity,
    };
  }

  static ShoppingItem fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'],
      isChecked: map['isChecked'] == 1,
      quantity: map['quantity'] ?? 1,
    );
  }
}


class HistoryPage extends StatefulWidget {
  final List<HistoryItem> historyItems;

  HistoryPage({required this.historyItems});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}
class _HistoryPageState extends State<HistoryPage> {
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<HistoryItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filterItems();
  }

  void _filterItems() {
    setState(() {
      _filteredItems = widget.historyItems.where((item) =>
      item.timestamp.isAfter(_startDate.subtract(Duration(days: 1))) &&
          item.timestamp.isBefore(_endDate.add(Duration(days: 1)))
      ).toList();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _filterItems();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Аналитика потребления'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Период: ${DateFormat('dd.MM.yyyy').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  leading: Icon(
                    item.action == 'add' ? Icons.add_circle : Icons.remove_circle,
                    color: item.action == 'add' ? Colors.green : Colors.red,
                  ),
                  title: Text(item.productName),
                  subtitle: Text('${item.action == 'add' ? 'Добавлено' : 'Удалено'} ${DateFormat('dd.MM.yyyy HH:mm').format(item.timestamp)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class HistoryItem {
  final String action;
  final String productName;
  final DateTime timestamp;
  final String location;

  HistoryItem({
    required this.action,
    required this.productName,
    required this.timestamp,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'productName': productName,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
    };
  }

  static HistoryItem fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      action: map['action'],
      productName: map['productName'],
      timestamp: DateTime.parse(map['timestamp']),
      location: map['location'],
    );
  }
}
