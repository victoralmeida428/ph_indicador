import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // 1. Padrão Singleton: Garante que só exista uma instância desta classe
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Variável para guardar o banco de dados aberto
  static Database? _database;

  // Construtor privado
  DatabaseHelper._init();

  // 2. Getter do banco de dados (Lazy Initialization)
  // Se o banco já estiver aberto, retorna ele. Se não, inicializa.
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('ph_analyzer.db'); // Nome do arquivo do banco
    return _database!;
  }

  // 3. Inicializa o banco de dados
  Future<Database> _initDB(String filePath) async {
    // Pega o caminho padrão onde o Android/iOS guardam bancos de dados
    final dbPath = await getDatabasesPath();

    // Junta o caminho da pasta com o nome do arquivo (requer package:path)
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1, // Se mudar a estrutura do banco no futuro, aumente este número
      onCreate: _createDB,
      // onUpgrade: _onUpgrade, // Usado para migrações futuras
    );
  }

  // 4. Cria as tabelas (Executado apenas na primeira vez que o app roda)
  Future _createDB(Database db, int version) async {
    // Tabela de Indicadores
    // Tipos SQLite: NULL, INTEGER, REAL, TEXT, BLOB
    await db.execute('''
      CREATE TABLE indicators (
        id TEXT PRIMARY KEY,
        name TEXT
      )
    ''');

    // Tabela 2: As Faixas (Filhos)
    // Linked via indicator_id
    await db.execute('''
      CREATE TABLE indicator_ranges (
        id TEXT PRIMARY KEY,
        indicator_id TEXT,
        ph_min REAL,
        ph_max REAL,
        color_hex INTEGER,
        FOREIGN KEY (indicator_id) REFERENCES indicators (id) ON DELETE CASCADE
      )
    ''');
  }
}