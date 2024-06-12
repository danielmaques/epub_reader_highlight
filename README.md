![logo banner](images/logo_banner.png)

# EPub Reader Highlight

[![GitHub stars](https://img.shields.io/github/stars/danielmaques/epub_reader_highlight.svg?style=social&label=Star)](https://github.com/danielmaques/epub_reader_highlight)

## Sumário

- [Descrição](#descrição)
- [Funcionalidades](#funcionalidades)
- [Capturas de Tela](#capturas-de-tela)
  - [Destaque de Texto](#destaque-de-texto)
  - [Lista de Capítulos](#lista-de-capítulos)
  - [Gerenciamento de Destaques](#gerenciamento-de-destaques)
- [Como Usar](#como-usar)
  - [Instalação](#instalação)
  - [Exemplos de Uso](#exemplos-de-uso)
- [Contribuindo](#contribuindo)
- [Agradecimentos](#agradecimentos)
- [Licença](#licença)

## Descrição

O EPub Reader Highlight é um aplicativo desenvolvido em Flutter que oferece uma solução completa para leitura de livros no formato Epub. Com uma interface intuitiva e recursos avançados, esta ferramenta permite aos desenvolvedores criar experiências de leitura personalizadas e eficientes para seus usuários.

## Funcionalidades

- **Destaque de Texto:** Selecione trechos importantes do livro e aplique diferentes cores de destaque para facilitar a revisão e organização do conteúdo.
- **Lista de Capítulos:** Navegue facilmente entre os capítulos do livro, visualizando o título e o número de cada um.
- **Gerenciamento de Destaques:** Acesse uma lista organizada de todos os destaques adicionados, com a opção de filtrar por cor ou capítulo.
- **Interface Personalizável:** Adapte a aparência do leitor às suas preferências, com opções para ajustar o tamanho da fonte, espaçamento entre linhas e modo de leitura.

## Capturas de Tela

Aqui estão algumas capturas de tela do EPub Reader Highlight em ação:

### Destaque de Texto

<p>
    <img src="images/image1.png" alt="Destaque de Texto" width="250"/>
    <img src="images/image2.png" alt="Destaque de Texto" width="250"/>
</p>

### Lista de Capítulos

<p>
    <img src="images/image3.png" alt="Lista de Capítulos" width="250"/>
    <img src="images/image4.png" alt="Lista de Capítulos" width="250"/>
</p>

### Gerenciamento de Destaques

<img src="images/highlight_management.png" alt="Gerenciamento de Destaques" width="250"/>

## Como Usar

### Instalação

1. Clone o repositório:
   ```sh
   git clone https://github.com/danielmaques/epub_reader_highlight.git
   ```
2. Navegue até o diretório do projeto:
   ```sh
   cd epub_reader_highlight
   ```
3. Instale as dependências:
   ```sh
   flutter pub get
   ```
4. Execute o aplicativo:
   ```sh
   flutter run
   ```

### Exemplos de Uso

```dart
class _MainAppState extends State<MainApp> {
  late EpubController _epubReaderController;

  @override
  void initState() {
    super.initState();

    /// Assets
    /// EpubDocument.openAsset('assets/gentle-green-obooko.epub')
    /// EpubDocument.openFile(path)

    _epubReaderController = EpubController(
      document: EpubDocument.openAsset('assets/gentle-green-obooko.epub'),
    );

    _epubReaderController = EpubController(
      document: EpubDocument.,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: EpubViewActualChapter(
                controller: _epubReaderController,
                builder: (chapterValue) => Text(
                  'Chapter: ${chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ?? ''}',
                  textAlign: TextAlign.start,
                ),
              ),
            ),
            drawer: Drawer(
              child: EpubViewTableOfContents(
                controller: _epubReaderController,
              ),
            ),
            body: EpubView(
              builders: EpubViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(
                  textStyle: TextStyle(),
                ),
                chapterDividerBuilder: (_) => Container(),
              ),
              controller: _epubReaderController,
            ),
          ),
        ),
      ),
    );
  }
}
```

- **Destaque de Texto:** Para destacar um trecho, basta selecionar o texto desejado e escolher uma cor de destaque.
- **Navegação entre Capítulos:** Utilize o menu de capítulos para navegar facilmente pelo livro.

```dart
    EpubViewTableOfContents(
        controller: _epubReaderController,
    ),
```
- **Personalização da Interface:** Acesse as configurações do aplicativo para ajustar a fonte, o espaçamento e o modo de leitura.

## Contribuindo

Contribuições são o que fazem a comunidade de código aberto ser um lugar incrível para aprender, inspirar e criar. Qualquer contribuição que você fizer será **muito apreciada**.

Se você tiver uma sugestão para melhorar o projeto, por favor, faça um fork do repositório e crie um pull request. Você também pode simplesmente abrir uma issue com a tag apropriada. Não se esqueça de dar uma estrela ao projeto! Muito obrigado!

1. Faça um Fork do Projeto
2. Crie uma Branch para sua Feature (`git checkout -b feature/AmazingFeature`)
3. Comite suas Mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Faça o Push para a Branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

Lembre-se de incluir uma tag e seguir as [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) e [Semantic Versioning](https://semver.org/) ao subir seu commit e/ou criar a issue.

## Agradecimentos

Obrigado a todas as pessoas que contribuíram para este projeto. Sem vocês, este projeto não seria possível.

<a href="https://github.com/danielmaques/epub_reader_highlight/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=danielmaques/epub_reader_highlight" />
</a>

## Licença

Este projeto está licenciado sob a licença [MIT](LICENSE).