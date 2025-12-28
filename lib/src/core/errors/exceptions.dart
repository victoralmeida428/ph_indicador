// Exceção lançada quando o SQLite der erro
class LocalDatabaseException implements Exception {
  final String message;
  LocalDatabaseException(this.message);
}

// Exceção lançada quando não encontrar dados
class CacheException implements Exception {}

// Exceção lançada quando a câmera falhar
class CameraException implements Exception {
  final String message;
  CameraException(this.message);
}
// Exceção para processamento de imagem (Imagem nula, bytes corrompidos, erro no crop 28x28)
class ImageProcessingException implements Exception {
  final String message;
  ImageProcessingException([this.message = "Erro ao processar a imagem."]);
}

// Exceção para dados inválidos (Caso algum dado venha corrompido de uma fonte externa)
class DataParsingException implements Exception {
  final String message;
  DataParsingException(this.message);
}