<div align="center">

<img src="assets/icon/orbis.svg" width="96" alt="Orbis" />

# Orbis

**Todo o seu planejamento em um só lugar**

Aplicativo pessoal de produtividade e finanças que reúne rotina, hábitos e dinheiro em uma única interface.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?style=flat-square&logo=firebase&logoColor=black)

</div>

---

## Sobre

O Orbis nasceu de três planilhas de Excel que eu mantinha separadas: a agenda semanal, o tracker de hábitos e o controle financeiro. O nome vem do latim *orbis*, círculo e órbita, porque rotina, hábitos e dinheiro giram em torno de um mesmo centro.

O projeto é uma evolução do FinFamily, um app de gestão financeira familiar que construí anteriormente na mesma stack. O Orbis reaproveita o design system e os padrões de código validados lá, e amplia o escopo para produtividade.

## Funcionalidades

### Finanças

- **Gastos variáveis** com lançamento diário, faixa de dias do mês e três contas (Geral, Nubank, Bradesco)
- **Resumo do mês** com receitas, despesas, média diária, ranking de categorias, evolução do patrimônio e gráficos de entradas e saídas por dia
- **Resumo do ano** com a mesma estrutura, agregada por mês
- **Gastos fixos** com vigência por período e itens compostos, onde uma fatura agrupa assinaturas e passa a valer a soma delas

### Rotina

Grade semanal no formato da planilha original: linhas de horário, colunas de dia. Três tabelas independentes (dias úteis, sábado e domingo), já que os horários não se alinham entre elas. Um bloco pode valer em todos os dias úteis ou apenas em dias específicos, o que resolve casos como Inglês às segundas, quartas e sextas e Tecnologias às terças e quintas. O bloco do horário corrente é destacado em tempo real.

### Habit Tracker

Grade mensal com hábitos nas linhas e dias nas colunas, com três estados por célula: cumprido, não cumprido e dispensado. O terceiro estado é o que torna o percentual honesto, já que dias dispensados saem do denominador. Métricas por hábito incluem contagem, percentual e sequência atual.

## Decisões técnicas

**Denormalização proposital no Firestore.** Cada transação guarda o nome e a cor da categoria, não só o id. Renomear uma categoria não reescreve o histórico, e a listagem não precisa cruzar coleções para renderizar.

**Uma leitura por mês.** As telas carregam o mês inteiro de uma vez e filtram o dia em memória. Trocar de dia não gera nova consulta, o que mantém o app confortavelmente dentro do plano gratuito do Firebase.

**Gravação incremental.** Marcações de hábitos e conclusões de rotina vivem em um único documento por mês, atualizado com `SetOptions(merge: true)`. Clicar numa célula grava apenas aquele campo.

**Sem Cloud Functions.** Toda a lógica roda no cliente. As regras de segurança do Firestore escopam tudo sob `users/{uid}`, o que simplifica o modelo de permissões para um app de uso individual.

**Marca desenhada em código.** O símbolo animado do Orbis é um `CustomPainter` com um `Ticker` de tempo contínuo, não um arquivo de imagem. Escala sem perda em qualquer tamanho, acompanha o tema e não reinicia a animação entre ciclos.

**Atalhos de teclado com `HardwareKeyboard`.** O lançamento diário é feito inteiro sem mouse. Os handlers são registrados globalmente e guardados contra dois casos: foco dentro de um campo de texto e diálogos abertos sobre a tela.

## Atalhos de teclado

### Gastos variáveis

| Tecla | Ação |
|---|---|
| `G` `N` `B` | Alterna entre Geral, Nubank e Bradesco |
| `1` a `31` | Seleciona o dia do mês |
| `↑` `↓` | Nova entrada, nova saída |
| `←` `→` | Mês anterior, próximo mês |

Os dígitos usam um buffer com temporizador: teclas de 1 a 3 aguardam meio segundo por um segundo dígito, porque podem virar 12, 25 ou 31. De 4 a 9 aplicam na hora, já que não existe dia 41.

### Diálogo de lançamento

| Tecla | Ação |
|---|---|
| `←` `→` | Navega um item na etapa atual |
| `↑` `↓` | Navega três itens, acompanhando as colunas do grid |
| `Enter` | Confirma a etapa e avança, salva na última |
| `Tab` | Volta uma etapa |
| `Esc` | Fecha |

### Habit Tracker

| Tecla | Ação |
|---|---|
| `S` `N` `A` | Cumprido, não cumprido, dispensado |
| `Espaço` | Limpa a marcação |
| Setas | Navega pela grade |
| `+` | Novo hábito |
| `Esc` | Sai do modo de marcação |

## Stack

| Camada | Tecnologia |
|---|---|
| Interface | Flutter Web, layout desktop-first |
| Autenticação | Firebase Authentication (e-mail e senha) |
| Banco de dados | Cloud Firestore |
| Gráficos | fl_chart |
| Formatação | intl, locale pt_BR |
| Tipografia | google_fonts |

## Arquitetura

```
lib/
├── data/        Catálogos estáticos: contas, categorias, navegação, rotina padrão
├── models/      Entidades, serialização do Firestore e estatísticas derivadas
├── services/    Autenticação e acesso a dados por domínio
├── screens/     Telas principais
├── widgets/     Componentes reutilizáveis e diálogos
├── theme/       Design system
└── utils/       Formatação de moeda, datas e máscaras de entrada
```

### Modelagem no Firestore

```
users/{uid}
├── transactions/{id}      Lançamentos com categoria denormalizada
├── budgets/{YYYY-MM}      Saldos de abertura e fechamento por conta
├── fixedCosts/{id}        Itens fixos, com parentId para compostos
├── habits/{id}            Hábitos acompanhados
├── habitLogs/{YYYY-MM}    Mapa "habitId:dia" com o estado da marcação
├── routineBlocks/{id}     Blocos do template semanal
└── routineLogs/{YYYY-MM-DD}
```

## Design system

Tema dark construído sobre grafite, nunca preto puro. A elevação é comunicada por cor de superfície, não por sombra.

| Token | Valor | Uso |
|---|---|---|
| `bg` | `#0F1113` | Fundo base |
| `surface` | `#16191C` | Cards |
| `surfaceRaised` | `#1C2024` | Cards em destaque e estados de hover |
| `accent` | `#4DA3FF` | Azul de marca |
| `income` | `#5FD4A0` | Entradas |
| `expense` | `#E0785F` | Saídas |

Outras convenções: `Instrument Serif` em números grandes e títulos, `Inter` na interface, algarismos tabulares em todo valor monetário, bordas de 0,5px em estado normal e 1px quando selecionado.

## Como rodar

Pré-requisitos: Flutter 3.x e um projeto Firebase com Authentication e Firestore habilitados.

```bash
git clone https://github.com/MatheusPoliChiarelli/orbis.git
cd orbis
flutter pub get
flutterfire configure
flutter run -d chrome
```

Regras do Firestore:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Status

Em uso pessoal. Os três módulos estão funcionais e o app roda localmente.

## Autor

**Matheus Poli Chiarelli**

Engenheiro Físico pela UFSCar, desenvolvedor com foco em Python, .NET e Flutter.

[Portfólio](https://matheuspolichiarelli.com) · [LinkedIn](https://linkedin.com/in/matheuspolichiarelli) · [GitHub](https://github.com/MatheusPoliChiarelli)