import 'package:flutter/material.dart';
import 'package:ph_indicador/src/core/ui/widget/app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool usePadding;
  final Widget? drawer;

  // Definição das cores do Tema Azul Escuro (Hardcoded aqui ou vindas do Theme)
  static const Color backgroundColor = Color(0xFF0D1B2A); // Azul quase preto
  static const Color appBarColor = Color(0xFF1B263B);     // Azul marinho escuro
  static const Color textColor = Color(0xFFE0E1DD);       // Branco gelo (suave)

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.floatingActionButton,
    this.actions,
    this.drawer,
    this.showAppBar = true,
    this.usePadding = true,

  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,


      appBar: showAppBar
          ? AppBar(
        title: title != null
            ? Text(
          title!,
          style: const TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        )
            : null,
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        actions: actions,
        iconTheme: const IconThemeData(color: textColor), // Ícones brancos
      )
          : null,

      drawer: drawer,

      floatingActionButton: floatingActionButton,

      body: SafeArea(
        child: Padding(
          padding: usePadding
              ? const EdgeInsets.all(16.0)
              : EdgeInsets.zero,
          child: DefaultTextStyle(
            // Garante que todo texto dentro do body seja claro por padrão
            style: const TextStyle(color: textColor, fontSize: 16),
            child: body,
          ),
        ),
      ),
    );
  }
}