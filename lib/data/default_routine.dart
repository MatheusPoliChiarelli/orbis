import '../models/routine_block.dart';

class _Seed {
  const _Seed(this.start, this.end, this.label, [this.weekdays = const []]);

  final int start;
  final int end;
  final String label;
  final List<int> weekdays;
}



const _weekday = <_Seed>[
  _Seed(240, 255, 'Bíblia'),
  _Seed(255, 360, 'Concurso'),
  _Seed(360, 435, 'Inglês', [1, 3, 5]),
  _Seed(360, 435, 'Tecnologias', [2, 4]),
  _Seed(435, 455, 'Café da manhã'),
  _Seed(480, 720, 'Trabalho'),
  _Seed(720, 740, 'Almoço'),
  _Seed(740, 760, 'Anki'),
  _Seed(760, 780, 'Exercícios'),
  _Seed(780, 1068, 'Trabalho'),
  _Seed(1110, 1160, 'Academia'),
  _Seed(1170, 1190, 'Jantar'),
  _Seed(1190, 1200, 'Banho'),
  _Seed(1200, 1220, 'Bíblia com família'),
  _Seed(1220, 1260, 'Descanso'),
  _Seed(1260, 1440, 'Dormir'),
];

const _saturday = <_Seed>[
  _Seed(450, 480, 'Bíblia e café da manhã'),
  _Seed(480, 720, 'Concurso (simulado)'),
  _Seed(720, 780, 'Academia'),
  _Seed(780, 900, 'Almoço e descanso'),
  _Seed(900, 960, 'Tecnologias'),
  _Seed(960, 1080, 'Empresas e projetos pessoais'),
  _Seed(1080, 1500, 'Descanso'),
];

const _sundayCommon = <_Seed>[
  _Seed(450, 480, 'Bíblia'),
  _Seed(480, 540, 'Concurso (simulado)'),
  _Seed(540, 600, 'Concurso (revisão semanal)'),
  _Seed(600, 630, 'Café da manhã com a família'),
];

const _sundayAfter = <_Seed>[
  _Seed(720, 780, 'Academia'),
  _Seed(780, 840, 'Almoço na vó'),
  _Seed(840, 900, 'Empresas e projetos pessoais'),
  _Seed(900, 960, 'Inglês'),
  _Seed(960, 1080, 'Descanso'),
  _Seed(1080, 1140, 'Tecnologia'),
  _Seed(1140, 1170, 'Jantar'),
  _Seed(1170, 1200, 'Bíblia'),
  _Seed(1200, 1260, 'Descanso'),
  _Seed(1260, 1440, 'Dormir'),
];

List<RoutineBlock> buildDefaultRoutine() {
  final blocks = <RoutineBlock>[];

  void add(DayType type, List<_Seed> seeds) {
    for (final seed in seeds) {
      blocks.add(
        RoutineBlock(
          id: '',
          dayType: type,
          startMinutes: seed.start,
          endMinutes: seed.end,
          label: seed.label,
          weekdays: seed.weekdays,
          order: blocks.length,
        ),
      );
    }
  }

  add(DayType.weekday, _weekday);
  add(DayType.saturday, _saturday);

  add(DayType.sunday, [
    ..._sundayCommon,
    const _Seed(630, 720, 'Finclass ou revisão mensal'),
    ..._sundayAfter,
  ]);

  return blocks;
}