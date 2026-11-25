import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const BiblioTechApp());

// ======================= CORES =======================
const azulEscuro = Color(0xFF1B2559);
const azul = Color(0xFF2B3A9E);
const ambar = Color(0xFFF2B544);
const fundo = Color(0xFFF3F5FA);
const cinza = Color(0xFF4B5372);
const borda = Color(0xFFE1E5F0);
const mut = TextStyle(color: cinza, fontSize: 13);

// Tela estreita (DartPad pequeno / celular)
bool estreito(BuildContext c) => MediaQuery.sizeOf(c).width < 900;

// ======================= MODELOS =======================
enum Perfil { aluno, professor }

class Livro {
  final String titulo, autor, isbn, categoria;
  final int total;
  int disponiveis;
  Livro(
    this.titulo,
    this.autor,
    this.isbn,
    this.categoria,
    this.total,
    this.disponiveis,
  );
}

class Exemplar {
  final String tombo, estante, estado;
  final Livro livro;
  bool disponivel;
  Exemplar(this.tombo, this.livro, this.estante, this.estado, this.disponivel);
}

class Emprestimo {
  final Livro livro;
  final DateTime retirada;
  DateTime prevista;
  int renovacoes;
  Exemplar? ex;
  Emprestimo(
    this.livro,
    this.retirada,
    this.prevista, {
    this.renovacoes = 0,
    this.ex,
  });
}

class Leitor {
  String nome;
  final String matricula;
  final Perfil perfil;
  final List<Emprestimo> emprestimos = [];
  Leitor(this.nome, this.matricula, this.perfil);

  String get iniciais => iniciaisDe(nome);
  String get perfilTexto => perfil == Perfil.professor ? 'Professor' : 'Aluno';
  double get multa =>
      emprestimos.fold(0.0, (s, e) => s + Regras.multa(e.prevista));
  bool get temAtraso =>
      emprestimos.any((e) => Regras.diasAtraso(e.prevista) > 0);
}

// ======================= REGRAS DE NEGÓCIO (RN) =======================
class Regras {
  static DateTime get hoje {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static const double multaPorDia = 1.0; // RN04: R$ 1,00 por dia de atraso

  static int prazoDias(Perfil p) => p == Perfil.professor ? 15 : 7; // RN01
  static int limiteEmprestimos(Perfil p) =>
      p == Perfil.professor ? 5 : 3; // RN02

  static int diasAtraso(DateTime prevista) {
    final d = hoje.difference(prevista).inDays;
    return d > 0 ? d : 0;
  }

  static double multa(DateTime prevista) =>
      diasAtraso(prevista) * multaPorDia; // RN04

  // RN05: atraso ou multa pendente bloqueia reservas e renovações
  static String? pendencia(Leitor l) => (l.temAtraso || l.multa > 0)
      ? 'leitor com atraso ou multa pendente.'
      : null;

  static String? bloqueio(Leitor l) {
    if (pendencia(l) != null) return 'Leitor com atraso ou multa pendente.';
    if (l.emprestimos.length >= limiteEmprestimos(l.perfil)) {
      return 'Limite de empréstimos atingido.';
    }
    return null;
  }
}

String iniciaisDe(String nome) {
  final i = nome
      .trim()
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
  return i.isEmpty ? '?' : i;
}

String fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String reais(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

// ======================= ESTADO (dados fictícios em memória) =======================
class AppState extends ChangeNotifier {
  final livros = <Livro>[
    Livro(
      'Engenharia de Software',
      'Ian Sommerville',
      '978-85-00000-01-0',
      'Computação',
      5,
      3,
    ),
    Livro(
      'Engenharia de Software: Uma Abordagem Profissional',
      'Roger Pressman',
      '978-85-00000-02-7',
      'Computação',
      4,
      0,
    ),
    Livro(
      'Código Limpo',
      'Robert C. Martin',
      '978-85-00000-03-4',
      'Programação',
      2,
      1,
    ),
    Livro(
      'Padrões de Projeto',
      'Erich Gamma et al.',
      '978-85-00000-04-1',
      'Programação',
      2,
      0,
    ),
  ];
  final reservas = <String>{};
  final usuario = Leitor('Bruno', '202610001', Perfil.aluno);
  final leitores = <String, Leitor>{};
  final exemplares = <String, Exemplar>{};
  String nomeBib = 'Bibliotecário';
  bool bibliotecario = false;
  int tela = 0;

  String get nomeAtual => bibliotecario ? nomeBib : usuario.nome;

  void renomear(String n) {
    final novo = n.trim();
    if (novo.isEmpty) return;
    if (bibliotecario) {
      nomeBib = novo;
    } else {
      usuario.nome = novo;
    }
    notifyListeners();
  }

  AppState() {
    final h = Regras.hoje;
    DateTime d(int dias) => h.add(Duration(days: dias));
    usuario.emprestimos.addAll([
      Emprestimo(livros[2], d(-10), d(-3)), // atrasado 3 dias
      Emprestimo(livros[0], d(-5), d(2)),
    ]);
    final ana = Leitor('Ana Beatriz Lima', '202610045', Perfil.aluno)
      ..emprestimos.add(Emprestimo(livros[1], d(-3), d(4)));
    final joao = Leitor('João Pedro Alves', '202610046', Perfil.aluno)
      ..emprestimos.add(Emprestimo(livros[3], d(-12), d(-5)));
    for (final l in [usuario, ana, joao]) {
      leitores[l.matricula] = l;
    }
    exemplares.addAll({
      'TB-004217': Exemplar(
        'TB-004217',
        livros[2],
        'Estante B-12',
        'bom',
        true,
      ),
      'TB-004218': Exemplar(
        'TB-004218',
        livros[2],
        'Estante B-12',
        'bom',
        false,
      ),
      'TB-000301': Exemplar(
        'TB-000301',
        livros[0],
        'Estante A-03',
        'bom',
        true,
      ),
      'TB-000302': Exemplar(
        'TB-000302',
        livros[1],
        'Estante A-04',
        'regular',
        false,
      ),
    });
    usuario.emprestimos[0].ex = exemplares['TB-004218'];
    ana.emprestimos[0].ex = exemplares['TB-000302'];
  }

  void trocarPerfil(bool bib) {
    bibliotecario = bib;
    tela = 0;
    notifyListeners();
  }

  void irPara(int i) {
    tela = i;
    notifyListeners();
  }

  // Empréstimo ativo de um exemplar (null se estiver na estante)
  Emprestimo? emprestimoDe(Exemplar x) {
    for (final l in leitores.values) {
      for (final e in l.emprestimos) {
        if (e.ex == x) return e;
      }
    }
    return null;
  }

  // Quem está com o exemplar agora
  Leitor? leitorDe(Exemplar x) {
    for (final l in leitores.values) {
      if (l.emprestimos.any((e) => e.ex == x)) return l;
    }
    return null;
  }

  String reservar(Livro l) {
    final p = Regras.pendencia(usuario);
    if (p != null) return 'Reserva bloqueada: $p';
    if (reservas.length >= 2) return 'Limite de 2 reservas atingido.';
    if (l.disponiveis > 0)
      return 'Há exemplares disponíveis: retire no balcão.';
    reservas.add(l.titulo);
    notifyListeners();
    return 'Reserva realizada para "${l.titulo}".';
  }

  String renovar(Emprestimo e) {
    final p = Regras.pendencia(usuario);
    if (p != null) return 'Renovação bloqueada: $p';
    if (e.renovacoes >= 2) return 'Limite de 2 renovações atingido.';
    e.prevista = e.prevista.add(
      Duration(days: Regras.prazoDias(usuario.perfil)),
    );
    e.renovacoes++;
    notifyListeners();
    return 'Renovado até ${fmt(e.prevista)}.';
  }

  // Aluga um livro escolhido no acervo (leitor logado)
  String alugar(Livro l) {
    final b = Regras.bloqueio(usuario);
    if (b != null)
      return 'Não foi possível alugar. $b (veja "Meus empréstimos").';
    if (usuario.emprestimos.any((e) => e.livro == l))
      return 'Você já está com este livro.';
    if (l.disponiveis <= 0)
      return 'Sem exemplares disponíveis. Faça uma reserva.';
    Exemplar? ex;
    for (final x in exemplares.values) {
      if (x.livro == l && x.disponivel) {
        ex = x;
        break;
      }
    }
    ex?.disponivel = false;
    final h = Regras.hoje;
    final prev = h.add(Duration(days: Regras.prazoDias(usuario.perfil)));
    usuario.emprestimos.add(Emprestimo(l, h, prev, ex: ex));
    l.disponiveis--;
    notifyListeners();
    return 'Livro alugado: "${l.titulo}". Devolução até ${fmt(prev)}.';
  }

  // Remove um empréstimo (devolução). Se estava atrasado, a multa é quitada.
  String devolver(Emprestimo e) {
    final multa = Regras.multa(e.prevista);
    usuario.emprestimos.remove(e);
    e.livro.disponiveis++;
    e.ex?.disponivel = true;
    notifyListeners();
    return multa > 0
        ? 'Livro devolvido. Multa de ${reais(multa)} quitada.'
        : 'Livro removido: "${e.livro.titulo}".';
  }

  // Simula devolução + pagamento da multa de todos os atrasados
  void regularizar() {
    final atrasados = usuario.emprestimos
        .where((e) => Regras.diasAtraso(e.prevista) > 0)
        .toList();
    for (final e in atrasados) {
      devolver(e);
    }
  }

  String confirmarEmprestimo(Leitor l, Exemplar ex) {
    final b = Regras.bloqueio(l);
    if (b != null) return b;
    if (!ex.disponivel) return 'Exemplar já está emprestado.';
    final h = Regras.hoje;
    l.emprestimos.add(
      Emprestimo(
        ex.livro,
        h,
        h.add(Duration(days: Regras.prazoDias(l.perfil))),
        ex: ex,
      ),
    );
    ex.disponivel = false;
    ex.livro.disponiveis--;
    notifyListeners();
    return 'Empréstimo registrado para ${l.nome}.';
  }
}

// ======================= WIDGETS BASE =======================
Widget caixa({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(20),
  Color cor = Colors.white,
  Color? bordaCor,
}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: cor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: bordaCor ?? borda),
  ),
  child: child,
);

class Selo extends StatelessWidget {
  final String texto;
  final Color bg, fg;
  const Selo.ok(this.texto, {super.key})
    : bg = const Color(0xFFDCFCE7),
      fg = const Color(0xFF14532D);
  const Selo.no(this.texto, {super.key})
    : bg = const Color(0xFFFEE2E2),
      fg = const Color(0xFF7F1D1D);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      texto,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}

Widget titulo(String t, String sub) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(sub, style: const TextStyle(color: cinza)),
  ],
);

Widget linha(List<Widget> cols, List<int> flex, {bool cab = false}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cab ? const Color(0xFFF7F8FC) : null,
        border: cab
            ? null
            : const Border(top: BorderSide(color: Color(0xFFE8EBF4))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cols.length; i++)
            Expanded(
              flex: flex[i],
              child: Align(alignment: Alignment.centerLeft, child: cols[i]),
            ),
        ],
      ),
    );

Widget cab(String t) => Text(
  t.toUpperCase(),
  style: const TextStyle(
    fontSize: 12,
    color: cinza,
    fontWeight: FontWeight.w600,
  ),
);

// Tabela em telas largas; cartões empilhados em telas estreitas.
// A última célula de cada linha é a "ação" (sem rótulo no modo cartão).
Widget tabelaResp(
  BuildContext c,
  List<String> cabs,
  List<List<Widget>> rows,
  List<int> flex,
) {
  if (!estreito(c)) {
    return caixa(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            linha([for (final h in cabs) cab(h)], flex, cab: true),
            for (final r in rows) linha(r, flex),
          ],
        ),
      ),
    );
  }
  return Column(
    children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: caixa(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  r[0],
                  for (var i = 1; i < r.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: i == r.length - 1
                          ? r[i]
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cabs[i], style: mut),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: r[i],
                                  ),
                                ),
                              ],
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

Widget navItem(String t, bool on, VoidCallback f) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: InkWell(
    onTap: f,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: on ? Colors.white : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        t,
        style: TextStyle(
          color: on ? azulEscuro : const Color(0xFFD5DAF0),
          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  ),
);

Widget pill(String t, bool on, VoidCallback f) => InkWell(
  onTap: f,
  borderRadius: BorderRadius.circular(20),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: on ? Colors.white : const Color(0x33FFFFFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: on ? azulEscuro : Colors.white,
      ),
    ),
  ),
);

void aviso(BuildContext c, String msg) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));

final btn = FilledButton.styleFrom(
  minimumSize: const Size(0, 44),
  backgroundColor: azul,
);
final btnG = OutlinedButton.styleFrom(
  minimumSize: const Size(0, 44),
  foregroundColor: azul,
);

Widget campo(
  TextEditingController c,
  String rotulo,
  VoidCallback ok, {
  String? erro,
}) => TextField(
  controller: c,
  onSubmitted: (_) => ok(),
  decoration: InputDecoration(
    labelText: rotulo,
    errorText: erro,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

Widget logo({Color texto = Colors.white}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ambar,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'B',
        style: TextStyle(fontWeight: FontWeight.w800, color: azulEscuro),
      ),
    ),
    const SizedBox(width: 10),
    Text(
      'BiblioTech',
      style: TextStyle(color: texto, fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ],
);

// Seletor "Leitor | Bibliotecário" (botão segmentado)
Widget seletorPerfil(bool bib, void Function(bool) f) {
  Widget op(String t, bool on, bool valor) => Expanded(
    child: InkWell(
      onTap: () => f(valor),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? Colors.white : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: on ? azulEscuro : Colors.white,
          ),
        ),
      ),
    ),
  );
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0x33FFFFFF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        op('Leitor', !bib, false),
        const SizedBox(width: 4),
        op('Bibliotecário', bib, true),
      ],
    ),
  );
}

// ======================= APP / SHELL =======================
class BiblioTechApp extends StatelessWidget {
  const BiblioTechApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'BiblioTech',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: azul),
      scaffoldBackgroundColor: fundo,
    ),
    home: const Shell(),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final s = AppState();

  List<String> get _itens => s.bibliotecario
      ? ['Registrar empréstimo']
      : ['Acervo', 'Meus empréstimos'];

  // Sidebar (telas largas)
  Widget _sidebar() => Container(
    width: 232,
    color: azulEscuro,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 24), child: logo()),
        for (var i = 0; i < _itens.length; i++)
          navItem(_itens[i], s.tela == i, () => s.irPara(i)),
        const SizedBox(height: 12),
        const Divider(color: Color(0x33FFFFFF), height: 1),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Entrar como',
            style: TextStyle(color: Color(0xFFD5DAF0), fontSize: 12),
          ),
        ),
        seletorPerfil(s.bibliotecario, _trocar),
      ],
    ),
  );

  // Barra de navegação (telas estreitas)
  Widget _pills() => Container(
    width: double.infinity,
    color: azulEscuro,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _itens.length; i++)
              pill(_itens[i], s.tela == i, () => s.irPara(i)),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Entrar como',
          style: TextStyle(color: Color(0xFFD5DAF0), fontSize: 12),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: seletorPerfil(s.bibliotecario, _trocar),
        ),
      ],
    ),
  );

  // Leitor entra direto; Bibliotecário exige senha
  void _trocar(bool bib) {
    if (!bib) {
      s.trocarPerfil(false);
      return;
    }
    if (s.bibliotecario) return;
    _pedirSenha();
  }

  Future<void> _pedirSenha() async {
    final c = TextEditingController();
    String? erro;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          void tentar() {
            if (c.text.length == 6) {
              Navigator.pop(ctx, true);
            } else {
              setD(() => erro = 'Digite os 6 dígitos da senha.');
            }
          }

          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acesso restrito aos responsáveis.\nDemonstração: digite qualquer senha de 6 dígitos.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Senha: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: c,
                            autofocus: true,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            cursorColor: Colors.white,
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (_) => tentar(),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: '6 dígitos',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF2B2B2B),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (erro != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          erro!,
                          style: const TextStyle(
                            color: Color(0xFFFF8A80),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: tentar,
                          child: const Text('Entrar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (ok == true) s.trocarPerfil(true);
  }

  Future<void> _editarNome() async {
    final c = TextEditingController(text: s.nomeAtual);
    final novo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar nome do usuário'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (novo != null) s.renomear(novo);
  }

  Widget _topbar(bool narrow) {
    final bib = s.bibliotecario;
    final nome = s.nomeAtual;
    return Container(
      height: narrow ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borda)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          narrow
              ? logo(texto: azulEscuro)
              : Text(
                  bib ? 'Balcão · Bibliotecário' : 'Leitor · Aluno',
                  style: const TextStyle(color: cinza),
                ),
          Flexible(
            child: InkWell(
              onTap: _editarNome,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        nome,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_outlined, size: 16, color: cinza),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: azul,
                      child: Text(
                        iniciaisDe(nome),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tela() {
    if (s.bibliotecario) return BalcaoTela(s: s);
    return s.tela == 0 ? BuscaTela(s: s) : EmprestimosTela(s: s);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: s,
    builder: (context, _) {
      final narrow = estreito(context);
      final conteudo = Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(narrow ? 16 : 28),
          child: _tela(),
        ),
      );
      return Scaffold(
        body: narrow
            ? Column(children: [_topbar(true), _pills(), conteudo])
            : Row(
                children: [
                  _sidebar(),
                  Expanded(child: Column(children: [_topbar(false), conteudo])),
                ],
              ),
      );
    },
  );
}

// ======================= TELA 1: PESQUISAR ACERVO =======================
class BuscaTela extends StatefulWidget {
  final AppState s;
  const BuscaTela({super.key, required this.s});
  @override
  State<BuscaTela> createState() => _BuscaTelaState();
}

class _BuscaTelaState extends State<BuscaTela> {
  static const todas = 'Todas as categorias';
  final ctrl = TextEditingController();
  String termo = '';
  String categoria = todas;

  void pesquisar() => setState(() => termo = ctrl.text.trim());

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final n = estreito(context);
    final t = termo.toLowerCase();
    final res = s.livros.where((l) {
      final okCat = categoria == todas || l.categoria == categoria;
      final okTxt =
          t.isEmpty ||
          '${l.titulo} ${l.autor} ${l.isbn}'.toLowerCase().contains(t);
      return okCat && okTxt;
    }).toList();

    final campoBusca = campo(ctrl, 'Buscar', pesquisar);
    final cat = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC3CADF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: n,
          value: categoria,
          items: const [
            todas,
            'Computação',
            'Programação',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => categoria = v!),
        ),
      ),
    );
    final bt = FilledButton(
      style: btn,
      onPressed: pesquisar,
      child: const Text('Pesquisar'),
    );

    final rows = <List<Widget>>[
      for (final l in res)
        [
          Text(l.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(l.autor),
          Text(l.isbn, style: mut),
          Text(l.categoria),
          l.disponiveis > 0
              ? Selo.ok('${l.disponiveis} de ${l.total} disponíveis')
              : Selo.no('0 de ${l.total} disponíveis'),
          s.usuario.emprestimos.any((e) => e.livro == l)
              ? const Text('Já alugado por você', style: mut)
              : l.disponiveis > 0
              ? FilledButton(
                  style: btn,
                  onPressed: () => aviso(context, s.alugar(l)),
                  child: const Text('Alugar'),
                )
              : s.reservas.contains(l.titulo)
              ? const Text('Reservado', style: mut)
              : OutlinedButton(
                  style: btnG,
                  onPressed: () => aviso(context, s.reservar(l)),
                  child: const Text('Reservar'),
                ),
        ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titulo(
          'Pesquisar acervo',
          'Encontre livros por título, autor, ISBN ou categoria.',
        ),
        const SizedBox(height: 20),
        caixa(
          child: n
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    campoBusca,
                    const SizedBox(height: 12),
                    cat,
                    const SizedBox(height: 12),
                    bt,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: campoBusca),
                    const SizedBox(width: 12),
                    cat,
                    const SizedBox(width: 12),
                    bt,
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Text(
          '${res.length} resultado${res.length == 1 ? '' : 's'} · seus empréstimos: ${s.usuario.emprestimos.length} de ${Regras.limiteEmprestimos(s.usuario.perfil)} · prazo de ${Regras.prazoDias(s.usuario.perfil)} dias · multa por atraso: ${reais(Regras.multaPorDia)}/dia',
          style: mut,
        ),
        const SizedBox(height: 8),
        tabelaResp(
          context,
          ['Título', 'Autor', 'ISBN', 'Categoria', 'Exemplares', ''],
          rows,
          const [4, 3, 3, 2, 3, 2],
        ),
      ],
    );
  }
}

// ======================= TELA 2: MEUS EMPRÉSTIMOS =======================
class EmprestimosTela extends StatelessWidget {
  final AppState s;
  const EmprestimosTela({super.key, required this.s});

  Widget stat(bool n, String t, String v, {Color? cor}) {
    final c = caixa(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: mut),
          const SizedBox(height: 6),
          Text(
            v,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
    return n ? SizedBox(width: double.infinity, child: c) : Expanded(child: c);
  }

  Widget situacao(Emprestimo e) {
    final atraso = Regras.diasAtraso(e.prevista);
    if (atraso > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Selo.no('Atrasado · $atraso dia${atraso > 1 ? 's' : ''}'),
          const SizedBox(height: 4),
          Text(
            'Multa: $atraso × ${reais(Regras.multaPorDia)} = ${reais(Regras.multa(e.prevista))}',
            style: mut,
          ),
        ],
      );
    }
    final r = e.prevista.difference(Regras.hoje).inDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Selo.ok(r == 0 ? 'Vence hoje' : 'No prazo · $r dia${r > 1 ? 's' : ''}'),
        const SizedBox(height: 4),
        Text('Se atrasar: ${reais(Regras.multaPorDia)} por dia', style: mut),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = estreito(context);
    final l = s.usuario;
    final pend = Regras.pendencia(l) != null;
    final atrasados = l.emprestimos
        .where((e) => Regras.diasAtraso(e.prevista) > 0)
        .length;

    final aviso1 = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text:
                'Você tem $atrasados empréstimo em atraso e ${reais(l.multa)} em multa pendente. ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(
            text:
                'Renovações e novas reservas ficam bloqueadas até a regularização. '
                'A multa é de R\$ 1,00 por dia de atraso. Procure o balcão da biblioteca.',
          ),
        ],
      ),
      style: const TextStyle(color: Color(0xFF78350F)),
    );
    final regBtn = OutlinedButton(
      style: btnG,
      onPressed: s.regularizar,
      child: const Text('Regularizar (simulação)'),
    );

    final cards = [
      stat(
        n,
        'Empréstimos ativos',
        '${l.emprestimos.length} de ${Regras.limiteEmprestimos(l.perfil)}',
      ),
      stat(n, 'Reservas ativas', '${s.reservas.length} de 2'),
      stat(
        n,
        'Multa pendente',
        reais(l.multa),
        cor: l.multa > 0 ? const Color(0xFF7F1D1D) : null,
      ),
    ];

    final rows = <List<Widget>>[
      if (l.emprestimos.isEmpty)
        [const Text('Nenhum empréstimo ativo.', style: mut)],
      for (final e in l.emprestimos)
        [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.livro.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(e.livro.autor, style: mut),
            ],
          ),
          Text(fmt(e.retirada)),
          Text(fmt(e.prevista)),
          situacao(e),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (Regras.diasAtraso(e.prevista) == 0)
                    FilledButton(
                      style: btn,
                      onPressed: (pend || e.renovacoes >= 2)
                          ? null
                          : () => aviso(context, s.renovar(e)),
                      child: Text('Renovar (${e.renovacoes} de 2)'),
                    ),
                  OutlinedButton.icon(
                    style: btnG,
                    onPressed: () => aviso(context, s.devolver(e)),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(
                      Regras.diasAtraso(e.prevista) > 0
                          ? 'Remover e quitar multa'
                          : 'Remover',
                    ),
                  ),
                ],
              ),
              if (pend && Regras.diasAtraso(e.prevista) == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Renovação bloqueada por pendência', style: mut),
                ),
            ],
          ),
        ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titulo(
          'Meus empréstimos',
          'Acompanhe prazos, renovações e multas. Multa por atraso: ${reais(Regras.multaPorDia)} por dia.',
        ),
        const SizedBox(height: 20),
        if (pend) ...[
          caixa(
            cor: const Color(0xFFFEF3C7),
            bordaCor: ambar,
            child: n
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [aviso1, const SizedBox(height: 12), regBtn],
                  )
                : Row(
                    children: [
                      Expanded(child: aviso1),
                      const SizedBox(width: 16),
                      regBtn,
                    ],
                  ),
          ),
          const SizedBox(height: 20),
        ],
        if (n)
          Column(
            children: [
              for (final c in cards)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cards[0],
              const SizedBox(width: 16),
              cards[1],
              const SizedBox(width: 16),
              cards[2],
            ],
          ),
        const SizedBox(height: 8),
        const Text(
          'Empréstimos atuais',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        tabelaResp(
          context,
          ['Livro', 'Retirado em', 'Devolução prevista', 'Situação', 'Ação'],
          rows,
          const [4, 2, 2, 3, 3],
        ),
      ],
    );
  }
}

// ======================= TELA 3: REGISTRAR EMPRÉSTIMO (BALCÃO) =======================
class BalcaoTela extends StatefulWidget {
  final AppState s;
  const BalcaoTela({super.key, required this.s});
  @override
  State<BalcaoTela> createState() => _BalcaoTelaState();
}

class _BalcaoTelaState extends State<BalcaoTela> {
  static const vermelho = Color(0xFF7F1D1D);
  static const verde = Color(0xFF14532D);
  final mat = TextEditingController();
  final tomb = TextEditingController();
  Leitor? leitor;
  Exemplar? ex;
  String? erroL, erroE, sucesso;

  @override
  void initState() {
    super.initState();
    final s = widget.s;
    for (final l in s.leitores.values) {
      if (Regras.bloqueio(l) == null) {
        leitor = l;
        break;
      }
    }
    for (final x in s.exemplares.values) {
      if (x.disponivel) {
        ex = x;
        break;
      }
    }
    if (leitor != null) mat.text = leitor!.matricula;
    if (ex != null) tomb.text = ex!.tombo;
  }

  void escolherLeitor(Leitor? l, {String? erro}) => setState(() {
    leitor = l;
    erroL = erro;
    sucesso = null;
    if (l != null) mat.text = l.matricula;
  });

  void escolherEx(Exemplar? x, {String? erro}) => setState(() {
    ex = x;
    erroE = erro;
    sucesso = null;
    if (x != null) tomb.text = x.tombo;
  });

  void buscarLeitor() {
    final l = widget.s.leitores[mat.text.trim()];
    escolherLeitor(l, erro: l == null ? 'Leitor não encontrado.' : null);
  }

  void buscarEx() {
    final x = widget.s.exemplares[tomb.text.trim().toUpperCase()];
    escolherEx(x, erro: x == null ? 'Exemplar não encontrado.' : null);
  }

  String? get impedimento {
    if (leitor == null || ex == null) return null;
    final b = Regras.bloqueio(leitor!);
    if (b != null) return b;
    if (!ex!.disponivel) return 'Exemplar já está emprestado.';
    return null;
  }

  void confirmar() {
    final msg = widget.s.confirmarEmprestimo(leitor!, ex!);
    setState(() => sucesso = msg);
    aviso(context, msg);
  }

  Widget kv(String k, String v, {Color? cor, bool topo = true}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: topo
          ? const Border(top: BorderSide(color: Color(0xFFE8EBF4)))
          : null,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(k, style: mut)),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold, color: cor),
          ),
        ),
      ],
    ),
  );

  Widget ficha(List<Widget> linhas) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FC),
      border: Border.all(color: borda),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(children: linhas),
  );

  Widget escolha(bool sel, Widget esq, Widget dir, VoidCallback f) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: InkWell(
      onTap: f,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFEEF0FB) : Colors.white,
          border: Border.all(color: sel ? azul : borda, width: sel ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(child: esq),
            const SizedBox(width: 8),
            dir,
          ],
        ),
      ),
    ),
  );

  Widget buscaLinha(
    TextEditingController c,
    String rotulo,
    VoidCallback f,
    String? erro,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: campo(c, rotulo, f, erro: erro)),
      const SizedBox(width: 12),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: OutlinedButton(
          style: btnG,
          onPressed: f,
          child: const Text('Buscar'),
        ),
      ),
    ],
  );

  Widget fichaLeitor(Leitor l) => ficha([
    kv('Nome', l.nome, topo: false),
    kv('Matrícula', l.matricula),
    kv('Perfil', l.perfilTexto),
    kv(
      'Empréstimos ativos',
      '${l.emprestimos.length} de ${Regras.limiteEmprestimos(l.perfil)}',
    ),
    kv('Prazo por empréstimo', '${Regras.prazoDias(l.perfil)} dias'),
    kv('Multa pendente', reais(l.multa), cor: l.multa > 0 ? vermelho : null),
  ]);

  Widget fichaExemplar(Exemplar x) {
    final emp = widget.s.emprestimoDe(x);
    final dono = widget.s.leitorDe(x);
    final atraso = emp == null ? 0 : Regras.diasAtraso(emp.prevista);
    final falta = emp == null ? 0 : emp.prevista.difference(Regras.hoje).inDays;
    return ficha([
      kv('Título', x.livro.titulo, topo: false),
      kv('Autor', x.livro.autor),
      kv('ISBN', x.livro.isbn),
      kv('Categoria', x.livro.categoria),
      kv('Código de tombo', x.tombo),
      kv('Localização', x.estante),
      kv('Estado de conservação', x.estado),
      kv(
        'Situação',
        x.disponivel ? 'Disponível' : 'Emprestado',
        cor: x.disponivel ? verde : vermelho,
      ),
      if (!x.disponivel && emp != null && dono != null) ...[
        kv('Emprestado para', dono.nome),
        kv('Retirado em', fmt(emp.retirada)),
        kv('Devolução prevista', fmt(emp.prevista)),
        kv(
          'Prazo',
          atraso > 0
              ? '$atraso dia${atraso > 1 ? 's' : ''} de atraso · multa ${reais(Regras.multa(emp.prevista))}'
              : (falta == 0
                    ? 'Vence hoje'
                    : 'No prazo (faltam $falta dia${falta > 1 ? 's' : ''})'),
          cor: atraso > 0 ? vermelho : verde,
        ),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final n = estreito(context);
    final l = leitor, e = ex;
    final imp = impedimento;
    final pronto = l != null && e != null && imp == null && sucesso == null;
    final prevista = l == null
        ? null
        : Regras.hoje.add(Duration(days: Regras.prazoDias(l.perfil)));

    final esquerda = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        caixa(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Leitor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              buscaLinha(mat, 'Matrícula', buscarLeitor, erroL),
              const SizedBox(height: 14),
              const Text('Ou clique em um leitor da lista:', style: mut),
              for (final item in s.leitores.values)
                escolha(
                  l == item,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${item.matricula} · ${item.perfilTexto}',
                        style: mut,
                      ),
                    ],
                  ),
                  Regras.pendencia(item) == null
                      ? const Selo.ok('Sem pendências')
                      : const Selo.no('Com pendência'),
                  () => escolherLeitor(item),
                ),
              if (l != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Dados do leitor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                fichaLeitor(l),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        caixa(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '2. Exemplar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              buscaLinha(tomb, 'Código de tombo', buscarEx, erroE),
              const SizedBox(height: 14),
              const Text('Ou clique em um exemplar da lista:', style: mut),
              for (final item in s.exemplares.values)
                escolha(
                  e == item,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.livro.titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${item.tombo} · ${item.estante}', style: mut),
                    ],
                  ),
                  item.disponivel
                      ? const Selo.ok('Disponível')
                      : const Selo.no('Emprestado'),
                  () => escolherEx(item),
                ),
              if (e != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Ficha do exemplar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                fichaExemplar(e),
              ],
            ],
          ),
        ),
      ],
    );

    final String aviso2;
    final Color corAviso;
    if (sucesso != null) {
      aviso2 = sucesso!;
      corAviso = verde;
    } else if (imp != null) {
      aviso2 = imp;
      corAviso = vermelho;
    } else if (l == null || e == null) {
      aviso2 = 'Escolha um leitor e um exemplar para liberar a confirmação.';
      corAviso = cinza;
    } else {
      aviso2 = 'Tudo certo! Clique em confirmar para registrar o empréstimo.';
      corAviso = verde;
    }

    final resumo = caixa(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '3. Resumo do empréstimo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Confira os dados antes de confirmar.', style: mut),
          const SizedBox(height: 8),
          kv(
            'Leitor',
            l == null ? 'Escolha um leitor' : '${l.nome} (${l.matricula})',
          ),
          kv(
            'Exemplar',
            e == null
                ? 'Escolha um exemplar'
                : '${e.livro.titulo} · ${e.tombo}',
          ),
          kv('Data do empréstimo', fmt(Regras.hoje)),
          kv(
            'Prazo',
            l == null
                ? '7 dias (aluno) ou 15 dias (professor)'
                : '${Regras.prazoDias(l.perfil)} dias corridos (${l.perfilTexto.toLowerCase()})',
          ),
          kv(
            'Devolução prevista',
            prevista == null ? 'Calculada ao escolher o leitor' : fmt(prevista),
            cor: azul,
          ),
          kv('Multa por atraso', '${reais(Regras.multaPorDia)} por dia'),
          if (prevista != null)
            kv(
              'Exemplo de multa',
              'devolvendo 3 dias depois de ${fmt(prevista)}: ${reais(3 * Regras.multaPorDia)}',
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              aviso2,
              style: TextStyle(color: corAviso, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: btn,
            onPressed: pronto ? confirmar : null,
            child: const Text('Confirmar empréstimo'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: btnG,
            onPressed: () => setState(() {
              leitor = null;
              ex = null;
              sucesso = null;
              mat.clear();
              tomb.clear();
              erroL = erroE = null;
            }),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titulo(
          'Registrar empréstimo',
          'Atendimento no balcão: o bibliotecário registra a saída de um livro.',
        ),
        const SizedBox(height: 6),
        const Text(
          'Passo a passo: 1) escolha o leitor, 2) escolha o exemplar, 3) confira o resumo e confirme. '
          'Clique em um item das listas para ver todos os dados dele.',
          style: mut,
        ),
        const SizedBox(height: 20),
        if (n)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [esquerda, const SizedBox(height: 20), resumo],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: esquerda),
              const SizedBox(width: 20),
              SizedBox(width: 380, child: resumo),
            ],
          ),
      ],
    );
  }
}
