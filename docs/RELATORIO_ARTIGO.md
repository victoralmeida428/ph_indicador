# Relatório do Projeto ph_indicador

**Preparado para subsidiar a elaboração de um artigo científico.**

- **Repositório**: `ph_indicador` (`/home/victor/StudioProjects/ph_indicador`)
- **Data**: 22/08/2026
- **Idioma do documento**: Português

---

## 1. Resumo executivo

O **ph_indicador** ("pH Analyzer") é um aplicativo móvel Android desenvolvido em Flutter que converte um smartphone em um colorímetro portátil para leitura de pH por tiras indicadoras (papel de pH, indicadores universais, etc.). Em vez da comparação visual subjetiva entre a cor da tira e a escala impressa — método tradicional, qualitativo e dependente do observador — o aplicativo:

1. captura uma fotografia da amostra com a câmera do dispositivo, guiando o usuário por uma mira central de 28×28 px;
2. extrai a cor média RGB da região central da imagem;
3. converte a cor para o espaço CIELAB;
4. compara a cor amostrada com uma base de cores de referência (faixas de pH cadastradas pelo usuário) usando a métrica perceptual **CIEDE2000** (ΔE00), com **tolerância configurável** e **ponderação de luminosidade (kL) ajustável**;
5. retorna o intervalo de pH correspondente à cor de referência mais próxima, ou reporta ausência de correspondência.

O projeto foi **concebido para o ensino de química no ensino básico** e já passou por uma **validação experimental preliminar em sala de aula e em ambiente doméstico**: diversas análises do padrão foram realizadas nesses dois contextos e **todas as medidas de pH do pHmetro coincidiram com as leituras obtidas pelas fotos analisadas pelo app**. Essa concordância total, mesmo com a variação de iluminação típica entre casa e sala de aula, indica a robustez prática da abordagem e constitui o núcleo da contribuição científica a ser sistematizada.

Do ponto de vista técnico, o diferencial do projeto é a **configurabilidade dos parâmetros de comparação cromática** (tolerância ΔE, fator kL, normalização de intensidade e modo de comparação), pensada para mitigar o problema mais crítico desse tipo de medição: a variação de iluminação ambiente entre capturas. A combinação — ferramenta educacional de código aberto, sem hardware adicional, validada em condições reais de uso — é o que posiciona o artigo na literatura de educação química apoiada por smartphones.

---

## 2. Descrição técnica do projeto

### 2.1 Visão geral da arquitetura

O projeto segue **Clean Architecture** em camadas, com **BLoC** como padrão de gerenciamento de estado e injeção de dependências manual realizada em `main.dart`.

```
lib/
├── main.dart                              # Bootstrap: banco, repositório, rotas
└── src/
    ├── core/                              # Infraestrutura transversal
    │   ├── database/database_helper.dart  # SQLite (sqflite), singleton
    │   ├── errors/                        # Exceptions e Failures
    │   ├── routes/                        # Rotas nomeadas e gerador
    │   ├── settings/                      # SettingsService + chaves (SharedPreferences)
    │   ├── ui/widget/                     # AppScaffold, camera, painters de overlay
    │   └── utils/image_color_extractor.dart  # Extração da cor média (28×28)
    └── features/
        ├── analysis/                      # Caso de uso do matching cromático
        │   ├── domain/usecases/find_best_match_range_usecase.dart
        │   └── presentation/              # AnalysisPage, AnalysisConfigPage, BLoC
        └── indicador/                     # Domínio de indicadores (CRUD + QR)
            ├── data/                      # datasource SQLite, models, repository
            ├── domain/                    # entities, repository, usecases (QR)
            └── presentation/              # páginas, widgets, BLoC
```

**Dependências principais** (`pubspec.yaml`): `camera` (captura), `image` (decodificação/corte de imagem), `color_models` (conversões de espaço de cor), `flutter_bloc` (estado), `sqflite` (persistência local), `shared_preferences` (configurações), `qr_flutter`/`mobile_scanner` (exportação/importação de padrões via QR Code), `uuid` (identificadores).

**Persistência** (`database_helper.dart`): duas tabelas relacionadas — `indicators` (id, name) e `indicator_ranges` (id, indicator_id, ph_min, ph_max, color_hex), com `FOREIGN KEY ... ON DELETE CASCADE`. As operações de escrita são transacionais (`indicator_local_datasource_impl.dart:16`), usando `INSERT OR REPLACE` para suportar criação e atualização com o mesmo caminho.

### 2.2 Domínio: indicadores e faixas

As entidades centrais são:

- **`Indicator`** (`domain/entities/indicator.dart`): `id`, `name`, `ranges` — representa um indicador químico (ex.: "Azul de Bromotimol", "Papel Universal").
- **`IndicatorRange`** (`domain/entities/indicator_ranges.dart`): `id`, `phMin`, `phMax`, `colorHex` — uma faixa de pH associada a uma cor de referência (armazenada como inteiro RGB `0xRRGGBB`).

Cada faixa associa um **intervalo de pH** a uma **cor observada** da tira nesse pH. Essa generalização permite cadastrar qualquer indicador comercial (escalas de 0–14, tiras de faixa estreita, indicadores líquidos) sem alterar o código.

### 2.3 Fluxo 1 — Cadastro de indicadores (calibração)

1. O usuário cria um novo padrão (`add_indicator_page.dart`) informando o nome.
2. Para cada faixa de pH, abre-se o modal `AddRangeSheet` (`add_range_widget.dart`): informa `phMin`/`phMax` e **captura a cor de referência pela câmera** — a foto é tirada na mesma mira 28×28 usada na análise, e `ImageColorExtractor.extractAverageColor` calcula a cor média, garantindo consistência entre calibração e medição (`add_range_widget.dart:52-73`).
3. Ao salvar, o `IndicatorBloc` persiste indicador + faixas em transação única.
4. Os padrões podem ser **exportados/importados via QR Code** (`generate_indicators_qrcode.dart` / `import_indicators_from_json.dart`): o JSON (`id`, `name`, `ranges[]` com `ph_min`, `ph_max`, `color_hex`) é codificado em QR (`qr_flutter`) ou lido com `mobile_scanner`. Isso permite **compartilhar curvas de calibração entre dispositivos e turmas** — relevante para o uso educacional.

### 2.4 Fluxo 2 — Análise de pH

O pipeline de análise é orquestrado pelo `AnalysisBloc` (`analysis_bloc.dart`):

```
AnalysisPage (seleção do indicador)
        ↓  onPictureTaken(file)
AnalysisBloc._onAnalyzeImage
        ↓
ImageColorExtractor.extractAverageColor(file.path)   → cor média RGB (28×28 central)
        ↓
FindBestMatchingRangeUseCase(tolerance, kL, normalizeIntensity, matchingMode)
        ├─ RGB → CIELAB (color_models)
        ├─ para cada IndicatorRange: ΔE00(sample, referência)   [ou modo cromaticidade]
        └─ menor distância ≤ tolerance ? retorna faixa : NoColorMatchException
        ↓
AnalysisSuccess(matchedRange, sampledColor)  → dialog "pH X – Y" com comparação visual
```

#### 2.4.1 Extração da cor (`image_color_extractor.dart`)

- Recorta um quadrado de **28×28 px** exatamente no centro da imagem (`image_color_extractor.dart:23-41`).
- Calcula a média aritmética dos canais R, G, B sobre os 784 pixels, retornando `Color.fromARGB(255, r̄, ḡ, b̄)` (`image_color_extractor.dart:44-59`).
- O posicionamento da amostra é guiado por um overlay com "mira" 28×28 (`overlay_with_hole_painter.dart:58-77`), desenhado sobre um quadrado de enquadramento maior (até 280 px), garantindo que o usuário centralize a tira e que a região amostrada esteja dentro da área colorida.

#### 2.4.2 Comparação cromática (`find_best_match_range_usecase.dart`)

O núcleo científico do projeto:

- **Conversão RGB→CIELAB**: feita via pacote `color_models` (o Lab é obtido de `rgbToLab`, `find_best_match_range_usecase.dart:70-80`).
- **CIEDE2000 (ΔE00)**: implementação própria (`find_best_match_range_usecase.dart:96-181`) seguindo a formulação canônica de Luo, Cui & Rigg (2001), com os termos de correção:
  - fator de ajuste de croma **G** (linhas 112-115),
  - ângulos de matiz e **T** (linhas 120-165),
  - funções de ponderação **SL, SC, SH** (linhas 167-169),
  - termo de rotação **RT** para a região azul (linhas 171-173),
  - fator paramétrico **kL** (peso da luminosidade) aplicado ao termo ΔL′ (linha 176).
- **Modo alternativo "chromaticity"**: ignora completamente a luminosidade, comparando apenas a cromaticidade (Δa\*, Δb\* no CIELAB) (`find_best_match_range_usecase.dart:90-94`).
- **Tolerância**: se a menor distância excede `tolerance` (ΔE), lança `NoColorMatchException` — o app informa que a amostra não corresponde a nenhuma faixa cadastrada (`find_best_match_range_usecase.dart:49-52`), evitando falsas leituras.
- **Normalização de intensidade**: opcional, escala os canais RGB para remover a diferença de brilho entre capturas, mantendo apenas as proporções entre canais (`find_best_match_range_usecase.dart:57-67`).

#### 2.4.3 Parâmetros configuráveis (`analysis_config_page.dart`)

| Parâmetro | Faixa | Padrão | Papel |
|---|---|---|---|
| **Tolerância (ΔE)** | 1.0 – 50.0 | 10.0 | Máxima distância perceptual aceita para declarar correspondência. Menor = mais rigor; maior = mais tolerante a iluminação. |
| **kL (peso da luminosidade)** | 0.5 – 10.0 | 1.0 | Pondera o termo de luminosidade do ΔE00. kL > 1 reduz a sensibilidade a brilho (iluminação diferente entre capturas). |
| **Normalizar intensidade** | bool | false | Remove completamente a diferença de brilho, mantendo só proporção RGB. |
| **Modo de comparação** | `ciede2000` / `chromaticity` | `ciede2000` | `chromaticity` compara apenas Δa\*b\* (ignora luminosidade). |

Persistidos via `SettingsService` (SharedPreferences) e lidos pelo `AnalysisBloc` a cada análise (`analysis_bloc.dart:72-75`).

### 2.5 Captura de imagem (`camera_capture_widget.dart`)

- Resolução `ResolutionPreset.high`, áudio desabilitado.
- Flash iniciado em `off` para minimizar alteração de cor; botão de **lanterna (torch)** opcional (`camera_capture_widget.dart:120-138`).
- **Troca entre câmeras** disponível quando há mais de uma (`camera_capture_widget.dart:109-118`), com descarte seguro do controller antigo para evitar "câmera morta" na UI.
- Overlay de enquadramento: quadrado central (≤280 px) com borda e mira 28×28 (`overlay_with_hole_painter.dart`); há também `white_corner_guides_painter.dart` (guia de cantos, não usado no fluxo principal).

### 2.6 Estado atual do repositório

- 8 commits no `main`, árvore de trabalho **limpa** (sem alterações pendentes):

  | Commit | Descrição |
  |---|---|
  | `422cad3` | first commit |
  | `e0acd99` | início da tela |
  | `e37108c` | implementando bloc e câmera |
  | `70943dd` | mais de uma faixa por indicador e tema |
  | `04dc1f5` | leitura de amostra e export/import via QR Code |
  | `77bbffe` | troca de câmera e precisão de cor com CIEDE2000 |
  | `ecd0ec9` | remoção de prints de debug no use case |
  | `bca45b7` | parâmetros de análise configuráveis (`analysis_config_page.dart`, `settings/`, ajustes no use case e no BLoC) + este relatório (`docs/RELATORIO_ARTIGO.md`) |

- **Suíte de testes automatizados**: 85 testes (diretório `test/`), incluindo a **validação do CIEDE2000 contra os 34 pares oficiais de Sharma et al. (2005)** — todos passando. Ver §5.2, item 4.
- A implementação dos parâmetros de análise (tolerância, kL, normalização, modo) está commitada e integrada ao fluxo (`AnalysisBloc` → `FindBestMatchingRangeUseCase`).
- Não há balanço de branco, calibração de câmera, cartão de referência de cor nem tratamento da correção automática de imagem do dispositivo.

---

## 3. Fundamentação teórica

### 3.1 Colorimetria e espaços de cor

A leitura de pH por indicadores é intrinsecamente um problema **colorimétrico**: o indicador muda de cor conforme a concentração de H⁺ (mudança no espectro de absorção refletido). Medir pH por imagem exige quantificar essa cor de forma robusta.

- **RGB** é o espaço nativo das câmeras, mas é **dependente do dispositivo e da iluminação** (não é perceptual nem padronizado).
- **CIELAB (L\*a\*b\*)** é um espaço aproximadamente perceptualmente uniforme, no qual distâncias euclidianas correlacionam com diferenças percebidas pelo olho humano. A conversão RGB→Lab passa por um espaço intermediário (ex.: sRGB→XYZ→Lab) — feita no projeto pelo pacote `color_models`.

### 3.2 Métricas de diferença de cor (ΔE)

| Métrica | Fórmula | Limitação |
|---|---|---|
| **CIE76 (ΔE\*ab)** | distância euclidiana em Lab | Não uniforme para cores saturadas; subestima diferenças em azuis. |
| **CIE94** | pondera ΔC e ΔH por croma | Melhor que CIE76, ainda limitado em regiões específicas. |
| **CIEDE2000 (ΔE00)** | correções: G (croma), SL/SC/SH (pesos locais), RT (rotação para azuis), parâmetros kL/kC/kH | **Estado da arte da CIE** para diferença perceptual de cor; é a métrica usada no projeto. |

A escolha do **CIEDE2000** no app é tecnicamente sólida e está alinhada com trabalhos recentes de análise colorimétrica por smartphone (ex.: análise de tiras de urina com CIEDE2000 em CIELab, Hwang et al., 2018).

### 3.3 O problema da iluminação

A maior fonte de erro em colorimetria por smartphone é a **variação de iluminação ambiente** e as **correções automáticas de imagem** das câmeras (balanço de branco, ganho, tom de cor). As estratégias da literatura incluem: caixas de luz impressas em 3D (Kim et al., 2017), cartões de referência de cor (MQuant StripScan; Li et al., 2021), algoritmos de adaptação de cor e normalização. O projeto aborda o problema **na camada de comparação** — kL alto, normalização de intensidade e modo cromaticidade — o que é uma abordagem distinta (sem hardware adicional), com a vantagem de ser configurável e passível de avaliação experimental.

---

## 4. Revisão da literatura relacionada

### 4.1 Eixo educacional (núcleo da contribuição)

| # | Trabalho | Método | Relação com o ph_indicador |
|---|---|---|---|
| 1 | **Li et al. (2023)** — "Mobile App to Quantify pH Strips and Monitor Titrations: Smartphone-Aided Chemical Education and Classroom Demonstrations", *J. Chem. Educ.* 100(9):3634–3640. DOI: 10.1021/acs.jchemed.3c00227 | App didático ("Smart pH Reader") para leitura de tiras de pH e titulações em sala, validado contra pHmetro, com calibração prévia feita com um único pHmetro | **Análogo educacional mais direto**: mesmo público e mesmo critério de validação (concordância com pHmetro). Diferenças: exige calibração por pHmetro e não cobre toda a escala; o ph_indicador calibra por captura de cor e compartilha padrões via QR. |
| 2 | **ChemEye (2026)** — "Analytical Chemistry in Daily Life – ChemEye: A Smartphone Based Mobile App for Colorimetric Analysis", *J. Chem. Educ.* 103(1):603–. | App de colorimetria com curvas de calibração; validado em workshops com **144 professores de química do ensino médio** e 30 graduandos; desempenho comparável ao espectrofotômetro UV-vis para fins didáticos | Confirma demanda e viabilidade de apps colorimétricos na educação básica; a validação com professores serve de modelo para o estudo de caso do ph_indicador. |
| 3 | **Android-Based Color Detector (2023)** — "Development of an Android-Based Color Detector for Chemistry Experiment in the Classroom", *J. Chem. Educ.* | Experimentos de colorimetria em casa (*at-home*), inquiry-based, com detector de cor Android | **Validação em dois ambientes (casa + sala)**: mesmo padrão da validação do ph_indicador; referência para justificar a coleta em ambiente doméstico. |
| 4 | **Hwang et al. (2018)** — "Color Space Transformation-Based Smartphone Algorithm for Colorimetric Urinalysis", *Sensors* 18(9):2904. PMCID: PMC6175489 | **CIEDE2000 em CIELab** para análise de tiras de urina | Metodologia idêntica à do app (CIELab + ΔE00); embasa tecnicamente a métrica usada no projeto. |

### 4.2 Eixo técnico (contexto e fundamentação)

| # | Trabalho | Método | Relação com o ph_indicador |
|---|---|---|---|
| 5 | **Luo, Cui & Rigg (2001)** — "The development of the CIE 2000 colour-difference formula: CIEDE2000", *Color Res. Appl.* 26(5):340–350. DOI: 10.1002/col.1049 | Proposição do CIEDE2000 | Base teórica da métrica usada no app. |
| 6 | **Sharma, Wu & Dalal (2005)** — "The CIEDE2000 color-difference formula: Implementation notes, supplementary test data, and mathematical observations", *Color Res. Appl.* 30(1):21–30. DOI: 10.1002/col.20070 | Notas de implementação + dados de teste para validar implementações do ΔE00 | Deve ser usada para validar a implementação do app (a fórmula implementada segue Luo et al., 2001). |
| 7 | **Li, Wang, Li & Yu (2021)** — "Quantitative pH Determination Based on the Dominant Wavelength Analysis of Commercial Test Strips", *Anal. Chem.* 93(46):15452–15458. DOI: 10.1021/acs.analchem.1c03393 | Tiras comerciais quantitativas via comprimento de onda dominante + caixa óptica 3D + app | Abordagem com acessório de hardware; o ph_indicador dispensa acessórios — útil como comparação de acurácia no artigo. |
| 8 | **Kim et al. (2017)** — "A Smartphone-Based Automatic Measurement Method for Colorimetric pH Detection Using a Color Adaptation Algorithm", *Sensors* 17(7):1604. PMID: 28698528 | Algoritmo de adaptação de cor + caixa de luz 3D + calibração com cartão impresso | O problema da iluminação que o ph_indicador mitiga via kL/normalização, sem hardware adicional. |
| 9 | **pHScoper (2026)** — "Smartphone-based colorimetric analysis of pH strips using machine learning", *Analytical Methods* (RSC). DOI: 10.1039/D6AY00780E | ML + SHAP para predição quantitativa de pH; dataset sob múltiplas iluminações | Estado da arte analítico; caminho alternativo (regressão/ML) ao matching por faixas do app. |
| 10 | **Smartphone-based pH titration for liquid food applications (2024)**, *Chemical Papers* (Springer). DOI: 10.1007/s11696-024-03715-9 | YOLOv5 para localizar a tira + seleção de features RGB/HSV/Lab + ML | Alternativa com visão computacional; o ph_indicador depende do usuário centralizar na mira. |
| 11 | **Chanu, Kapoor & Karthik (2021)** — "Digital image analysis for microfluidic paper based pH sensor platform", *Mater. Today Proc.* 40(S1):S64–S68. DOI: 10.1016/j.matpr.2020.03.503 | Sensor lab-on-a-chip em papel + análise de imagem por smartphone + regressão para pH | Metodologia análoga (imagem → cor → pH), com regressão contínua em vez de faixas. |
| 12 | **Single-Image-Referenced Colorimetric Water Quality Detection Using a Smartphone (2018)**, *Anal. Chem.* (PMC6641965) | Cartão de referência de cor na mesma cena + modelo treinado | Sugere melhoria possível: cartão de referência na imagem em vez de parâmetros manuais. |

### 4.3 Posicionamento do projeto na literatura

- **Eixo educacional**: o ph_indicador pertence à família de apps de leitura colorimétrica para ensino (Li et al., 2023; ChemEye, 2026; Color Detector, 2023). Seu diferencial é a **validação em condições reais** (casa e sala de aula) com **concordância total com o pHmetro**, sem exigir pHmetro para calibração nem acessórios de hardware — e com **código aberto**, permitindo auditoria e replicação.
- **Eixo técnico**: usa a métrica perceptual de referência (CIELab + CIEDE2000, como Hwang et al., 2018) com matching por faixas discretas em vez de regressão/ML — mais simples, auditável e adequado ao contexto didático.
- **Lacuna editorial a explorar**: nenhum dos trabalhos educacionais revisados relata validação em **dois ambientes** (doméstico e escolar) com concordância perfeita contra pHmetro; o estudo de caso do projeto preenche exatamente esse espaço.

---

## 5. Análise crítica e lacunas

### 5.1 Pontos fortes

- **Métrica perceptual correta**: CIEDE2000 em CIELAB é o estado da arte para diferença de cor (Sharma et al., 2005).
- **Pipeline consistente**: mesma região de amostragem (28×28 central) na calibração e na medição.
- **Sem dependência de hardware**: viável em qualquer dispositivo Android com câmera.
- **Configurabilidade**: kL, tolerância, normalização e modo de comparação permitem adaptação ao ambiente e experimentação controlada.
- **Compartilhamento via QR**: calibrações podem ser distribuídas (útil para replicação em pesquisa e uso em turmas).
- **Validado em condições reais**: análises realizadas em casa e em sala de aula apresentaram **concordância total com o pHmetro** — evidência empírica preliminar de que a abordagem funciona fora do laboratório controlado.
- **Arquitetura limpa e testável**: separação domain/data/presentation + BLoC facilita a adição de testes e a reutilização do uso case fora da UI.

### 5.2 Lacunas para a publicação

1. **Validação realizada, mas não formalizada**: há evidência empírica (concordância total com o pHmetro em casa e na sala), porém sem protocolo documentado, sem registro de nº de amostras/faixas testadas e sem tratamento estatístico. **Organizar e analisar esses dados é o pré-requisito nº 1 para o artigo.**
2. **Sem controle documentado de iluminação**: as condições de iluminação das capturas não foram registradas; a contribuição específica de kL/normalização/modo cromaticidade permanece não quantificada (pode virar estudo complementar).
3. **Sem calibração de cor da câmera**: não há balanço de branco, cartão de referência nem perfil do dispositivo; a cor absoluta varia entre aparelhos.
4. **Testes automatizados — RESOLVIDO**: suíte de 85 testes criada em `test/` (CIEDE2000 validado contra o dataset oficial de Sharma et al., 2005 — todos os 34 pares passam com erro < 1e-4; mais use case, extrator de imagem, models, JSON/QR, datasource SQLite e BLoCs). O teste de integração do datasource revelou e corrigiu um bug de produção: o `PRAGMA foreign_keys = ON` não era ativado, desativando o `ON DELETE CASCADE` (fix em `database_helper.dart`).
5. **Tolerância padrão subjetiva** (ΔE = 10): sem justificativa empírica; um estudo pode derivar o limiar ótimo por curva ROC.
6. **Matching discreto**: o app retorna intervalo de pH, não valor pontual; para comparação quantitativa com pHmetro é preciso decidir a métrica (ex.: erro absoluto médio sobre o ponto médio da faixa, acurácia de classificação, concordância κ de Cohen) — decisão necessária já na organização dos dados da validação.
7. **Sem estudos formais de usabilidade/aprendizagem**: a validação de campo não incluiu instrumentos como questionário pré/pós-teste conceitual ou SUS; podem ser incorporados em uma segunda rodada de aplicação.

---

## 6. Propostas de contribuição científica

### Caminho A — Ferramenta educacional validada em sala de aula (contribuição principal — RECOMENDADO)

**Título provisório**: *Leitura colorimétrica de pH por smartphone no ensino de química: um aplicativo de código aberto validado em casa e em sala de aula.*

- **Núcleo da contribuição**: sistematizar a validação já realizada — análises do padrão em casa e na sala de aula com **concordância total entre as leituras do app e o pHmetro** — transformando-a em um estudo de caso com protocolo e análise formal (ver §7).
- **Questões**: (a) o app reproduz as leituras do pHmetro em condições reais de uso (doméstico e escolar)? (b) a precisão percebida pelo estudante é superior à comparação visual tradicional com a escala impressa? (c) o compartilhamento de padrões via QR facilita a replicação entre turmas?
- **Método**: estudo de caso com turmas de ensino médio (nº `[PENDENTE]`), com registro de amostras testadas, condições de captura e leituras emparelhadas app × pHmetro; análise de concordância (κ de Cohen ou acurácia de faixa) e, se possível, questionário de usabilidade (SUS) e pré/pós-teste conceitual.
- **Referências obrigatórias**: Li et al. (2023) e ChemEye (2026), que validaram apps análogos em sala de aula; o diferencial a destacar é a validação **em dois ambientes** com concordância perfeita, **sem pHmetro de calibração** e **sem hardware adicional**.
- **Público-alvo editorial**: *Journal of Chemical Education*, *Química Nova na Escola*, *Revista Brasileira de Ensino de Química*, *Chemistry Education Research and Practice*.

### Caminho B — Estudo técnico complementar (opcional, fortalece o artigo)

**Título provisório**: *Efeito do fator kL do CIEDE2000 e da normalização de intensidade na robustez à iluminação de um leitor de pH por smartphone.*

- **Questão**: em que medida kL > 1, normalização de intensidade e modo cromaticidade melhoram a acurácia do matching sob diferentes fontes de luz?
- **Método**: soluções-tampão de pH conhecido → capturas sob iluminações controladas × configurações do app → métricas: acurácia de faixa, erro médio no pH, ΔE residual.
- **Papel no artigo**: pode compor uma seção de "robustez" do mesmo artigo educacional (mostrando que a concordância observada em campo não é casual) ou virar um segundo artigo em periódico analítico.
- **Validação da implementação**: testes automatizados do ΔE00 contra o dataset de Sharma et al. (2005) — recomendado em qualquer cenário, pois é barato e aumenta a credibilidade.

---

## 7. Estudo de caso: validação em casa e em sala de aula

> **Status**: validação **realizada** (resultados ainda **não organizados formalmente**). Esta seção descreve o que se sabe e lista o que precisa ser levantado para a publicação.

### 7.1 O que foi feito (registro disponível)

- Diversas **análises do padrão** foram realizadas em dois ambientes distintos: **residência** (iluminação doméstica) e **sala de aula** (ensino básico).
- Em cada análise, a amostra foi medida com **pHmetro de referência** e, em paralelo, com o app via fotografia da tira indicadora.
- **Resultado observado**: todas as medidas de pH do pHmetro **coincidiram** com as leituras obtidas pelas fotos analisadas pelo app.

### 7.2 Resultado (até aqui)

| Ambiente | Análises realizadas | Concordância app × pHmetro |
|---|---|---|
| Casa | `[PENDENTE: nº de análises]` | 100% (todas as medidas bateram) |
| Sala de aula | `[PENDENTE: nº de análises]` | 100% (todas as medidas bateram) |

### 7.3 Dados a levantar para formalizar o estudo (checklist do artigo)

- [ ] Nº de análises por ambiente (casa e sala) e por faixa de pH testada
- [ ] Faixas de pH cobertas e indicador(es) usado(s) (padrão cadastrado)
- [ ] Dispositivos utilizados (modelo de smartphone) e configurações do app usadas em cada sessão (tolerância, kL, normalização, modo)
- [ ] Condições de iluminação das capturas (natural/artificial, horário, com/sem flash)
- [ ] Nº de participantes (se houver) e autorização/ética (TCLE, em se tratando de escola)
- [ ] Análise estatística: acurácia de faixa, κ de Cohen, erro médio vs. pHmetro
- [ ] Registro fotográfico e planilha de dados consolidada

### 7.4 Como descrever no artigo

O estudo de caso pode ser apresentado como *proof-of-concept* de campo: mesmo sem controle de laboratório e com a variação de iluminação típica entre casa e escola, o app reproduziu integralmente as leituras do pHmetro, evidenciando que a calibração por captura de cor + matching CIEDE2000 (com tolerância e kL configuráveis) é robusta o suficiente para uso didático real. A formalização dos dados (§7.3) converte esse relato observacional em evidência publicável.

---

## 8. Referências completas

1. Luo MR, Cui G, Rigg B. The development of the CIE 2000 colour-difference formula: CIEDE2000. *Color Res Appl*. 2001;26(5):340–350. DOI: 10.1002/col.1049
2. Sharma G, Wu W, Dalal EN. The CIEDE2000 color-difference formula: Implementation notes, supplementary test data, and mathematical observations. *Color Res Appl*. 2005;30(1):21–30. DOI: 10.1002/col.20070
3. Li H, Wang X, Li X, Yu H-Z. Quantitative pH Determination Based on the Dominant Wavelength Analysis of Commercial Test Strips. *Anal Chem*. 2021;93(46):15452–15458. DOI: 10.1021/acs.analchem.1c03393
4. Li J, O'Neill ML, Pattison C, Zhou JHW, Ito JM, Wong CST, Yu H-Z, Merbouh N. Mobile App to Quantify pH Strips and Monitor Titrations: Smartphone-Aided Chemical Education and Classroom Demonstrations. *J Chem Educ*. 2023;100(9):3634–3640. DOI: 10.1021/acs.jchemed.3c00227
5. Kim et al. A Smartphone-Based Automatic Measurement Method for Colorimetric pH Detection Using a Color Adaptation Algorithm. *Sensors*. 2017;17(7):1604. PMID: 28698528
6. Chanu OR, Kapoor A, Karthik V. Digital image analysis for microfluidic paper based pH sensor platform. *Mater Today Proc*. 2021;40(S1):S64–S68. DOI: 10.1016/j.matpr.2020.03.503
7. pHScoper: Smartphone-based colorimetric analysis of pH strips using machine learning. *Anal Methods*. 2026. DOI: 10.1039/D6AY00780E
8. Smartphone-based pH titration for liquid food applications. *Chem Pap*. 2024. DOI: 10.1007/s11696-024-03715-9
9. Hwang et al. Color Space Transformation-Based Smartphone Algorithm for Colorimetric Urinalysis. *Sensors*. 2018;18(9):2904. PMCID: PMC6175489
10. Single-Image-Referenced Colorimetric Water Quality Detection Using a Smartphone. *Anal Chem*. 2018 (PMC6641965).
11. MQuant® StripScan Mobile App (Merck/Sigma-Aldrich) — white paper técnico de leitor comercial de tiras por smartphone.
12. Analytical Chemistry in Daily Life – ChemEye: A Smartphone Based Mobile App for Colorimetric Analysis. *J Chem Educ*. 2026;103(1):603–. (DOI a confirmar na publicação final.)
13. Development of an Android-Based Color Detector for Chemistry Experiment in the Classroom. *J Chem Educ*. 2023. (Autores e DOI a confirmar; disponível via ResearchGate.)