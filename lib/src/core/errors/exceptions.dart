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

// Erro de Regra de Negócio: O Indicador existe, mas não tem faixas cadastradas
class EmptyRangesException implements Exception {
  final String message;
  EmptyRangesException([this.message = "Este indicador não possui faixas de cor cadastradas."]);
}

// Erro Técnico: Falha ao ler os pixels da imagem
class ImageExtractionException implements Exception {
  final String message;
  ImageExtractionException([this.message = "Não foi possível extrair a cor da imagem."]);
}

// Adicione em exceptions.dart
class NoColorMatchException implements Exception {
  final String message;
  NoColorMatchException([this.message = "A cor da amostra não corresponde a nenhuma faixa do padrão."]);
}

class QRCodeInvalid implements Exception {
  final String message;
  QRCodeInvalid([this.message = "Qr code inválido"]);
}