import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  static final DatabaseManager instance = DatabaseManager._init();
  static Database? _database;

  DatabaseManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cooksmart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Versi database
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future _createDb(Database db, int version) async {
    // Tabel untuk favorit
    await db.execute(''' 
      CREATE TABLE favorite (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        imageUrl TEXT,
        calories INTEGER,
        protein INTEGER,
        carbs INTEGER,
        fat INTEGER,
        ingredients TEXT
      )
    ''');

    // Tabel untuk rencana makan
    await db.execute(''' 
      CREATE TABLE meal_plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT,
        meals TEXT,
        calorie_limit INTEGER
      )
    ''');

    // Tabel untuk daftar belanja dengan nama resep dan status bahan (is_checked)
    await db.execute(''' 
      CREATE TABLE shopping_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_name TEXT NOT NULL,  -- Nama resep
        ingredient TEXT NOT NULL,  -- Nama bahan
        is_checked INTEGER DEFAULT 0,  -- Status bahan (0 = belum dicentang, 1 = sudah dicentang)
        UNIQUE(recipe_name, ingredient)  -- Membuat pasangan nama resep dan bahan unik
      )
    ''');

    // Tabel untuk langkah-langkah memasak
    await db.execute(''' 
      CREATE TABLE cooking_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER,
        step_number INTEGER,
        instruction TEXT,
        recipe_title TEXT,
        FOREIGN KEY (recipe_id) REFERENCES favorite (id)
      )
    ''');
  }

  Future _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      print("Upgrading database from version $oldVersion to $newVersion");
      // Cek apakah kolom 'is_checked' ada di tabel shopping_list
      var result = await db.rawQuery('PRAGMA table_info(shopping_list)');
      bool isCheckedColumnExists = result.any((column) => column['name'] == 'is_checked');

      if (!isCheckedColumnExists) {
        // Menambahkan kolom 'is_checked' jika belum ada
        await db.execute('''
          ALTER TABLE shopping_list ADD COLUMN is_checked INTEGER DEFAULT 0
        ''');
      }
    }
  }

  // Fungsi untuk mengonversi instruksi menjadi string yang terformat
  String instructionsToString(List<Map<String, String>> instructions) {
    return instructions.map((step) {
      return "Step ${step['step']}: ${step['instruction']}";
    }).join('\n');  // Memisahkan setiap langkah dengan newline
  }

  Future<void> insertCookingStep(Map<String, dynamic> stepData) async {
    final db = await instance.database;
    await db.insert(
      'cooking_steps',
      stepData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fungsi untuk mendapatkan langkah-langkah memasak berdasarkan id resep
  Future<List<Map<String, dynamic>>> getCookingSteps(int recipeId) async {
    final db = await database;
    return await db.query(
      'cooking_steps',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'step_number ASC',
    );
  }

  // Fungsi untuk memasukkan data resep favorit ke dalam database
  Future<int> insertFavorite(Map<String, dynamic> row) async {
    final db = await instance.database;
    final id = await db.insert('favorite', row);
    print("Inserted favorite with ID: $id"); // Debug log
    return id;
  }

  // Fungsi untuk memasukkan resep favorit beserta instruksi
  Future<void> insertFavoriteWithInstructions(Map<String, dynamic> row, List<Map<String, String>> instructions) async {
    final db = await instance.database;
    // Cek apakah resep sudah ada di favorit
    bool isFavorite = await isRecipeFavorite(row['title']);
    if (!isFavorite) {
      // Jika resep belum ada, simpan data resep ke tabel 'favorite'
      await db.insert('favorite', row);
      // Mendapatkan ID dari resep favorit yang baru dimasukkan
      final id = row['id'];
      // Simpan langkah-langkah memasak ke dalam tabel 'cooking_steps'
      for (var i = 0; i < instructions.length; i++) {
        await insertCookingStep({
          'recipe_id': id,
          'step_number': i + 1,
          'instruction': instructions[i]['instruction'],
        });
      }
    } else {
      // Jika resep sudah ada, ambil langkah-langkah dari database
      print("Recipe already exists in favorites. Fetching cooking steps from database.");
      final id = row['id']; // You would typically fetch this from the database after checking the title
      // Mengambil langkah-langkah dari tabel cooking_steps
      List<Map<String, dynamic>> existingSteps = await getCookingSteps(id);
      print("Fetched ${existingSteps.length} cooking steps.");
    }
  }

  // Fungsi untuk mengambil langkah memasak berdasarkan recipe_id dan step_number
  Future<Map<String, dynamic>?> getCookingStepByRecipeIdAndStepNumber(int recipeId, int stepNumber) async {
    final db = await database;
    final result = await db.query(
      'cooking_steps',
      where: 'recipe_id = ? AND step_number = ?',
      whereArgs: [recipeId, stepNumber],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // Fungsi untuk mendapatkan semua resep favorit
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await instance.database;
    return await db.query('favorite');
  }

  // Fungsi untuk menghapus resep favorit berdasarkan ID
  Future<int> deleteFavorite(int id) async {
    final db = await instance.database;
    return await db.delete('favorite', where: 'id = ?', whereArgs: [id]);
  }

  // Fungsi untuk menghapus langkah-langkah memasak berdasarkan recipe_id
  Future<int> deleteCookingSteps(int recipeId) async {
    final db = await database;
    return await db.delete(
      'cooking_steps', 
      where: 'recipe_id = ?', 
      whereArgs: [recipeId],
    );
  }

  // Fungsi untuk menghapus semua item belanja berdasarkan nama resep
  Future<int> deleteShoppingItems(String recipeName) async {
    final db = await database;
    return await db.delete(
      'shopping_list', 
      where: 'recipe_name = ?', 
      whereArgs: [recipeName],
    );
  }

  // Fungsi untuk memasukkan rencana makan
  Future<int> insertMealPlan(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('meal_plan', row);
  }

  // Fungsi untuk mendapatkan semua rencana makan
  Future<List<Map<String, dynamic>>> getMealPlans() async {
    final db = await instance.database;
    return await db.query('meal_plan');
  }

  // Fungsi untuk mengupdate rencana makan
  Future<int> updateMealPlan(Map<String, dynamic> mealPlan) async {
    final db = await instance.database;
    return await db.update(
      'meal_plan',
      mealPlan,
      where: 'id = ?',
      whereArgs: [mealPlan['id']],
    );
  }

  // Fungsi untuk menghapus rencana makan berdasarkan ID
  Future<int> deleteMealPlan(int id) async {
    final db = await instance.database;
    return await db.delete('meal_plan', where: 'id = ?', whereArgs: [id]);
  }

  // Fungsi untuk memasukkan item belanja
  Future<void> insertShoppingItem(Map<String, dynamic> shoppingItem) async {
    final db = await database;
    await db.insert(
      'shopping_list',
      shoppingItem,
      conflictAlgorithm: ConflictAlgorithm.ignore, // Menghindari duplikasi
    );
  }

  // Fungsi untuk mendapatkan semua item belanja
  Future<List<Map<String, dynamic>>> getShoppingItems() async {
    final db = await database;
    return await db.query('shopping_list');
  }

  // Fungsi untuk menandai bahan belanja sudah dibeli
  Future<int> markAsBought(int id, int isChecked) async {
    final db = await database;
    int result = await db.update(
      'shopping_list',
      {'is_checked': isChecked},
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  // Fungsi untuk menghapus item belanja berdasarkan ID
  Future<int> deleteShoppingItem(int id) async {
    final db = await database;
    return await db.delete('shopping_list', where: 'id = ?', whereArgs: [id]);
  }

  // Fungsi untuk mengecek apakah resep sudah ada dalam daftar favorit
  Future<bool> isRecipeFavorite(String title) async {
    final db = await instance.database;
    final result = await db.query(
      'favorite',
      where: 'title = ?',
      whereArgs: [title],
    );
    return result.isNotEmpty;
  }

  // Fungsi untuk mendapatkan path file database untuk debugging
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cooksmart.db');
    return path;
  }

  // Fungsi untuk mendapatkan resep favorit berdasarkan Title
  Future<Map<String, dynamic>?> getFavoriteByTitle(String title) async {
    final db = await instance.database;
    final result = await db.query(
      'favorite',
      where: 'title = ?',  // Mengubah kondisi query untuk mencari berdasarkan title
      whereArgs: [title],   // Menggunakan title sebagai parameter pencarian
    );
    if (result.isNotEmpty) {
      return result.first;  // Jika ada data, kembalikan data pertama
    }
    return null;  // Jika tidak ada data yang ditemukan, kembalikan null
  }

  Future<int?> getCaloriesByTitle(String title) async {
    final db = await database;
    final result = await db.query(
      'favorite',
      columns: ['calories'],
      where: 'title = ?',
      whereArgs: [title],
    );
    if (result.isNotEmpty) {
      return result.first['calories'] as int?;
    }
    return null;
  }

  // Misalnya fungsi untuk menghapus meal berdasarkan title dan day
  Future<void> deleteMealPlanByTitleAndDay(String meal, String day) async {
    final db = await database; // Pastikan Anda memiliki akses ke database
    await db.delete(
      'meal_plan', // Nama tabel tempat menyimpan meal plans
      where: 'meals = ? AND day = ?',
      whereArgs: [meal, day],
    );
  }

  // Fungsi untuk mendapatkan URL gambar berdasarkan judul meal
  Future<String?> getImageUrlByTitle(String title) async {
    final db = await instance.database;
    final result = await db.query(
      'favorite',
      columns: ['imageUrl'],
      where: 'title = ?',
      whereArgs: [title],
    );
    if (result.isNotEmpty) {
      return result.first['imageUrl'] as String?;
    }
    return null;
  }
}
