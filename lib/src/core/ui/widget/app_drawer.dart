import 'package:flutter/material.dart';
import 'package:ph_indicador/src/core/routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Fundo do Drawer seguindo o tema escuro
      backgroundColor: const Color(0xFF0D1B2A),
      child: Column(
        children: [
          // CABEÇALHO (Logo ou Info do Usuário)
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1B263B), // Azul um pouco mais claro
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.science, color: Colors.white, size: 30),
            ),
            accountName: const Text(
              "pH Analyzer",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text(
              "Versão 1.0.0",
              style: TextStyle(color: Colors.white70),
            ),
          ),

          // ITEM 1: LEITURA DE AMOSTRA
          _buildDrawerItem(
            context,
            icon: Icons.camera_alt_outlined,
            title: "Ler Amostra",
            route: AppRoutes.analysis,
          ),

          // DIVISOR
          const Divider(color: Colors.white24, height: 1),

          // ITEM 2: CADASTRO DE PADRÃO
          _buildDrawerItem(
            context,
            icon: Icons.list_alt,
            title: "Meus Padrões",
            route: AppRoutes.indicators,
          ),

          // Espaço para jogar o botão de sair/config para o final
          const Spacer(),

          const Divider(color: Colors.white24, height: 1),

          _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: "Configurações",
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                // TODO: Navegar para config
              }
          ),
          const SizedBox(height: 20), // Margem inferior
        ],
      ),
    );
  }

  // Método auxiliar para criar os itens do menu sem repetir código (DRY)
  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap ?? () {
        // 1. Fecha o drawer antes de navegar
        Navigator.pop(context);

        // 2. Navega para a rota se ela existir
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}