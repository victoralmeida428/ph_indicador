import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// -----------------------------------------------------------------------------
// FALHAS DE INFRAESTRUTURA
// -----------------------------------------------------------------------------

class DatabaseFailure extends Failure {
  const DatabaseFailure({String message = "Erro ao acessar o banco de dados."})
      : super(message);
}

class CameraFailure extends Failure {
  const CameraFailure({String message = "Não foi possível utilizar a câmera."})
      : super(message);
}

// -----------------------------------------------------------------------------
// FALHAS DE LÓGICA / PROCESSAMENTO
// -----------------------------------------------------------------------------

class ImageProcessingFailure extends Failure {
  // Essa falha é específica para quando o 'ImageColorExtractor' não conseguir
  // ler os pixels ou fazer o crop 28x28
  const ImageProcessingFailure({String message = "Falha ao analisar a cor da amostra."})
      : super(message);
}

class InvalidInputFailure extends Failure {
  // Usado quando o usuário tenta salvar um pH inválido (ex: pH Min > pH Max)
  // embora a validação de UI pegue isso, é bom ter no Domain.
  const InvalidInputFailure(String message) : super(message);
}

class NoColorMatchFailure extends Failure {
  const NoColorMatchFailure({String message = "Nenhuma cor correspondente"}):super(message);
}

class QrCodeInvalidFailure extends Failure {
  const QrCodeInvalidFailure({String message = "QrCode inválido"}):super(message);
}