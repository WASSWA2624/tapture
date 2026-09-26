import 'dart:convert';
import 'dart:io';

/// The planning catalogue this tool turns into shipped assets, relative to
/// `frontend/`, which is where the tools run from.
const String _defaultSource = '../resources/templates.md';

/// Typed archetype packs, kept by hand beside this tool.
const String _defaultPacks = 'tool/template_catalogue/packs.json';

/// Choice lists and per-field corrections, kept by hand beside this tool.
const String _defaultRules = 'tool/template_catalogue/field_rules.json';

/// Where the catalogue assets are written. The loader reads them from here.
const String _defaultAssets = 'assets/templates/catalogue';

/// The groups every shipped template inherits (§13.3).
const String _defaultBaseGroups = 'assets/templates/_groups.json';

/// Where the readable list of every template is written.
const String _defaultList = '../resources/template-library.md';

/// Compares instead of writing, and exits 1 when anything is stale.
const String _checkFlag = '--check';

/// How to call this, printed when the arguments do not add up.
const String _usage =
    'usage: dart run tool/build_template_catalogue.dart [$_checkFlag] '
    '[--source=<md>] [--assets=<dir>] [--list=<md>]';

/// The groups a catalogue template inherits before its own, in order.
const List<String> _baseGroups = <String>[
  'record_admin',
  'location_context',
  'evidence',
  'review',
];

/// Index file inside the assets directory.
const String _indexName = '_catalogue.json';

/// Field groups file inside the assets directory.
const String _groupsName = '_groups.json';

/// Field group a template's own starter fields sit in.
const String _specificGroup = 'specific_details';

/// Field group a category's shared context fields sit in.
const String _contextGroup = 'context';

/// Unit of a measured field whose unit the operator states beside it.
const String _asDeclared = 'as_declared';

/// How many starter templates specification §13.4 ships beside the catalogue.
const int _starterCount = 23;

/// Suggested requiredness of a template's own starter fields (§13.2).
const String _starterRequiredness = 'RECOMMENDED';

/// Suggested requiredness of a category's context fields.
const String _contextRequiredness = 'RECOMMENDED';

/// Words that end a plural-looking key but name one thing.
const Set<String> _singularEndings = <String>{
  'access',
  'address',
  'analysis',
  'basis',
  'business',
  'class',
  'diagnosis',
  'gas',
  'loss',
  'means',
  'news',
  'premises',
  'process',
  'progress',
  'prognosis',
  'series',
  'species',
  'status',
  'stress',
  'success',
  'synopsis',
  'thickness',
  'wellness',
};

/// Singular last words that name prose rather than one short value.
const Set<String> _narrativeWords = <String>{
  'account',
  'action',
  'agenda',
  'agreement',
  'analysis',
  'answer',
  'approach',
  'arrangement',
  'assessment',
  'assistance',
  'brief',
  'caption',
  'cause',
  'change',
  'comment',
  'commitment',
  'complaint',
  'concern',
  'conclusion',
  'condition',
  'containment',
  'content',
  'context',
  'contingency',
  'description',
  'deviation',
  'diagnosis',
  'effect',
  'exception',
  'experience',
  'explanation',
  'feedback',
  'finding',
  'followup',
  'goal',
  'grievance',
  'guidance',
  'history',
  'impact',
  'improvement',
  'information',
  'interpretation',
  'justification',
  'lesson',
  'message',
  'methodology',
  'mitigation',
  'narrative',
  'need',
  'note',
  'objective',
  'obligation',
  'observation',
  'outcome',
  'overview',
  'plan',
  'problem',
  'procedure',
  'prognosis',
  'purpose',
  'question',
  'rationale',
  'reason',
  'recommendation',
  'relationship',
  'remedy',
  'requirement',
  'resolution',
  'response',
  'review',
  'scope',
  'situation',
  'statement',
  'story',
  'strategy',
  'summary',
  'support',
  'symptom',
  'testimony',
  'text',
  'transcript',
};

/// Last words of prose an AI may rewrite, so a refined companion is kept
/// beside the raw value (§32).
const Set<String> _refinedWords = <String>{
  'account',
  'comments',
  'description',
  'details',
  'explanation',
  'feedback',
  'findings',
  'narrative',
  'notes',
  'observations',
  'statement',
  'story',
  'summary',
  'transcript',
};

/// Last words of money fields; each gets a `_currency` companion.
const Set<String> _moneyWords = <String>{
  'balance',
  'budget',
  'cost',
  'deposit',
  'donation',
  'fee',
  'fine',
  'income',
  'penalty',
  'premium',
  'price',
  'revenue',
  'salary',
  'subsidy',
  'total',
  'wage',
};

/// `*_value` keys that hold money rather than a measurement.
const Set<String> _moneyValues = <String>{
  'declared_value',
  'documented_value',
  'insured_value',
  'opportunity_value',
  'stock_value',
};

/// Last words of measured fields with a fixed unit: (type, unit).
const Map<String, (String, String)> _measured = <String, (String, String)>{
  'depth': ('decimal', 'm'),
  'distance': ('decimal', 'km'),
  'duration': ('decimal', 'minutes'),
  'height': ('decimal', 'm'),
  'length': ('decimal', 'm'),
  'score': ('decimal', 'points'),
  'temperature': ('decimal', 'degC'),
  'volume': ('decimal', 'L'),
  'weight': ('decimal', 'kg'),
  'width': ('decimal', 'm'),
};

/// Last words of measured fields whose unit the operator states beside it.
const Set<String> _declaredMeasures = <String>{
  'capacity',
  'quantity',
  'value',
  'yield',
};

/// `*_area` keys that are a measured surface, with their unit. Every other
/// `*_area` names a place and stays text.
const Map<String, String> _measuredAreas = <String, String>{
  'building_area': 'sqm',
  'cleaning_area': 'sqm',
  'completed_area': 'ha',
  'farm_area': 'ha',
  'land_area': 'ha',
  'pasture_area': 'ha',
  'planted_area': 'ha',
  'plot_area': 'ha',
  'pond_area': 'sqm',
  'sample_area': 'sqm',
};

/// `*_dimensions` keys that are abstract aspects, not sizes.
const Set<String> _abstractDimensions = <String>{
  'assessment_dimensions',
  'consented_dimensions',
  'feasibility_dimensions',
  'quality_dimensions',
};

/// Prefixes of `*_condition` keys that grade a physical thing.
const Set<String> _physicalConditions = <String>{
  'asset',
  'body',
  'building',
  'component',
  'container',
  'current',
  'device',
  'display',
  'equipment',
  'facility',
  'general',
  'item',
  'machine',
  'overall',
  'packaging',
  'physical',
  'road',
  'site',
  'structure',
  'surface',
  'tire',
  'tyre',
  'vehicle',
};

/// Last words that make a field a photo reference.
const Set<String> _photoWords = <String>{
  'clip',
  'clips',
  'footage',
  'image',
  'images',
  'media',
  'photo',
  'photos',
  'picture',
  'pictures',
  'video',
  'videos',
};

/// Last words that make a field an attached file.
const Set<String> _documentWords = <String>{
  'attachment',
  'attachments',
  'audio',
  'certificate',
  'certificates',
  'document',
  'documents',
  'drawings',
  'evidence',
  'file',
  'files',
  'receipts',
  'recording',
  'recordings',
  'scan',
  'scans',
  'vouchers',
};

/// Last words that become a choice, with the option set they use.
const Map<String, String> _choiceWords = <String, String>{
  'confirmation': 'confirmation',
  'consent': 'consent_status',
  'decision': 'decision',
  'priority': 'priority',
  'rating': 'rating',
  'severity': 'severity',
  'urgency': 'priority',
};

/// Choice sets whose value a person must set, never a model (§12.2).
const Set<String> _manualChoices = <String>{'consent_status', 'decision'};

/// The heading a supergroup opens with: `# 01 · Cross-sector foundations`.
final RegExp _supergroupLine = RegExp(r'^# (\d{2}) · (.+)$');

/// The heading a category opens with.
final RegExp _categoryLine = RegExp(
  r'^## ([A-Z]{2,4}) — (.+) \((\d+) templates\)$',
);

/// The shared context line under a category heading.
final RegExp _contextLine = RegExp(r'^Shared category context: (.+)\.$');

/// The heading a template opens with: `### UNI-001 — General observation`.
final RegExp _templateLine = RegExp(r'^### ([A-Z]{2,4})-(\d{3}) — (.+)$');

/// A template's record type and pack. Six entries add a note that a
/// detailed starter schema exists elsewhere; the note carries no fields.
final RegExp _typeLine = RegExp(
  r'^\*\*Type:\*\* (.+) · \*\*Shared pack:\*\* ([A-Z]+)\.'
  r'( \*\*Detailed starter schema included\.\*\*)?$',
);

/// A template's own starter fields.
final RegExp _starterLine = RegExp(
  r'^\*\*Specific starter fields:\*\* (.+)\.$',
);

/// One of a template's guidance lines.
final RegExp _guidanceLine = RegExp(
  r'^\*\*(Capture|AI assistance|Potential outputs|Review):\*\* (.+)$',
);

/// A template's privacy and rollout line.
final RegExp _privacyLine = RegExp(
  r'^\*\*Default privacy:\*\* (\w+) · \*\*Rollout:\*\* (P\d) · (\w+)\.$',
);

/// A pack's heading in the shared packs section.
final RegExp _packLine = RegExp(r'^\*\*([A-Z]+) — (.+)\*\*$');

/// A pack's field list.
final RegExp _packFieldsLine = RegExp(r'^Fields: (.+)\.$');

/// The catalogue's headline counts and version.
final RegExp _headline = RegExp(
  r'^\*\*([\d,]+) distinct templates · (\d+) categories · (\d+) supergroups'
  r' · Version (\d+\.\d+\.\d+)\*\*$',
);

/// snake_case, starting with a letter.
final RegExp _snake = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

/// Builds the catalogue assets and the readable list from the planning
/// catalogue, or checks that the committed copies are current.
Future<int> main(List<String> args) async {
  final Map<String, String> options = <String, String>{};
  bool check = false;
  for (final String argument in args) {
    if (argument == _checkFlag) {
      check = true;
      continue;
    }
    final int equals = argument.indexOf('=');
    final String name = equals < 0 ? argument : argument.substring(0, equals);
    if (equals < 0 ||
        !<String>{'--source', '--assets', '--list'}.contains(name)) {
      stderr.writeln('unrecognised argument: $argument');
      stderr.writeln(_usage);
      exitCode = 1;
      return exitCode;
    }
    options[name] = argument.substring(equals + 1);
  }
  final String sourcePath = options['--source'] ?? _defaultSource;
  final String assetsPath = options['--assets'] ?? _defaultAssets;
  final String listPath = options['--list'] ?? _defaultList;

  final List<String> problems = <String>[];
  final Map<String, String> outputs = _build(
    source: File(sourcePath),
    packs: File(_defaultPacks),
    rules: File(_defaultRules),
    baseGroups: File(_defaultBaseGroups),
    assetsPath: assetsPath,
    listPath: listPath,
    problems: problems,
  );
  if (problems.isNotEmpty) {
    for (final String problem in problems) {
      stderr.writeln(problem);
    }
    stdout.writeln('catalogue: ${problems.length} problem(s), nothing written');
    exitCode = 1;
    return exitCode;
  }
  final List<String> stale = _staleOutputs(outputs, assetsPath);
  if (check) {
    for (final String path in stale) {
      stderr.writeln(
        '$path: out of date; run dart run '
        'tool/build_template_catalogue.dart',
      );
    }
    stdout.writeln(
      stale.isEmpty
          ? 'catalogue: ${outputs.length} file(s) current'
          : 'catalogue: ${stale.length} file(s) out of date',
    );
    exitCode = stale.isEmpty ? 0 : 1;
    return exitCode;
  }
  _write(outputs, assetsPath);
  stdout.writeln(
    'catalogue: wrote ${outputs.length} file(s), ${stale.length} changed',
  );
  exitCode = 0;
  return exitCode;
}

/// One pack of shared fields, as the planning catalogue names it.
final class _Pack {
  _Pack(this.code, this.title, this.catalogueFields);

  final String code;
  final String title;
  final List<String> catalogueFields;
  String kind = '';
  List<String> identity = <String>[];
  List<Map<String, Object?>> fields = <Map<String, Object?>>[];
  String capture = '';
  String aiAssistance = '';
  String outputs = '';
  String review = '';
}

/// A supergroup and the categories under it.
final class _Supergroup {
  _Supergroup(this.code, this.title);

  final String code;
  final String title;
  final List<_Category> categories = <_Category>[];
}

/// A category, its shared context fields and its templates.
final class _Category {
  _Category(this.code, this.title, this.declared, this.supergroup, this.line);

  final String code;
  final String title;
  final int declared;
  final _Supergroup supergroup;
  final int line;
  List<String> context = <String>[];
  final List<_Entry> templates = <_Entry>[];

  String get key => code.toLowerCase();

  String get fileName =>
      '${supergroup.code}_${key}_${_slug(title)}.json'.replaceAll('__', '_');
}

/// One template as the planning catalogue describes it.
final class _Entry {
  _Entry(this.code, this.title, this.line);

  final String code;
  final String title;
  final int line;
  String typeLabel = '';
  String pack = '';
  List<String> starter = <String>[];
  final Map<String, String> guidance = <String, String>{};
  String privacy = '';
  String rollout = '';
  String rolloutLabel = '';
}

/// The parsed planning catalogue.
final class _Catalogue {
  final List<_Supergroup> supergroups = <_Supergroup>[];
  final Map<String, _Pack> packs = <String, _Pack>{};
  String version = '';
  int declaredTemplates = 0;
  int declaredCategories = 0;
  int declaredSupergroups = 0;

  Iterable<_Category> get categories =>
      supergroups.expand((_Supergroup supergroup) => supergroup.categories);

  Iterable<_Entry> get templates =>
      categories.expand((_Category category) => category.templates);
}

/// Everything the generator writes, keyed by path.
Map<String, String> _build({
  required File source,
  required File packs,
  required File rules,
  required File baseGroups,
  required String assetsPath,
  required String listPath,
  required List<String> problems,
}) {
  for (final File file in <File>[source, packs, rules, baseGroups]) {
    if (!file.existsSync()) {
      problems.add('${file.path}:0: missing; the catalogue is built from it');
    }
  }
  if (problems.isNotEmpty) {
    return <String, String>{};
  }
  final _Catalogue catalogue = _parse(
    source.path,
    source.readAsLinesSync(),
    problems,
  );
  final Map<String, Object?> rulesJson = _object(
    jsonDecode(rules.readAsStringSync()),
  );
  final Map<String, List<String>> optionSets = <String, List<String>>{
    for (final MapEntry<String, Object?> entry in _object(
      rulesJson['option_sets'],
    ).entries)
      entry.key: _strings(entry.value),
  };
  final Map<String, List<Map<String, Object?>>> overrides =
      <String, List<Map<String, Object?>>>{
        for (final MapEntry<String, Object?> entry in _object(
          rulesJson['overrides'],
        ).entries)
          entry.key: _objects(entry.value),
      };
  _readPacks(packs, catalogue, optionSets, problems);
  final Set<String> baseKeys = <String>{
    for (final Object? group in _object(
      jsonDecode(baseGroups.readAsStringSync()),
    ).values)
      for (final Map<String, Object?> field in _objects(
        _object(group)['fields'],
      ))
        field['field_key']! as String,
  };
  if (problems.isNotEmpty) {
    return <String, String>{};
  }
  final _Typer typer = _Typer(optionSets, overrides, problems);
  final Map<String, String> outputs = <String, String>{};
  final Map<String, Object?> groups = <String, Object?>{};
  for (final _Category category in catalogue.categories) {
    groups['context_${category.key}'] = <String, Object?>{
      'input_mode': 'any',
      'fields': <Map<String, Object?>>[
        for (final String key in category.context)
          for (final Map<String, Object?> field in typer.type(
            key,
            where: '${source.path}:${category.line}',
          ))
            _emitField(
              field,
              optionSets,
              group: _contextGroup,
              required: _contextRequiredness,
              stickable: true,
            ),
      ],
    };
  }
  for (final _Pack pack in catalogue.packs.values) {
    groups['pack_${pack.code.toLowerCase()}'] = <String, Object?>{
      'input_mode': 'any',
      'fields': <Map<String, Object?>>[
        for (final Map<String, Object?> field in pack.fields)
          _emitField(field, optionSets, group: pack.kind),
      ],
    };
  }
  final Map<String, Set<String>> groupKeys = <String, Set<String>>{
    for (final MapEntry<String, Object?> entry in groups.entries)
      entry.key: <String>{
        for (final Map<String, Object?> field in _objects(
          _object(entry.value)['fields'],
        ))
          field['field_key']! as String,
      },
  };
  final Set<String> templateKeys = <String>{};
  final Map<String, List<Map<String, Object?>>> byCategory =
      <String, List<Map<String, Object?>>>{};
  for (final _Category category in catalogue.categories) {
    final List<Map<String, Object?>> assets = <Map<String, Object?>>[];
    for (final _Entry entry in category.templates) {
      final _Pack pack = catalogue.packs[entry.pack]!;
      final String templateKey = '${category.key}_${_slug(entry.title)}';
      if (!_snake.hasMatch(templateKey) || !templateKeys.add(templateKey)) {
        problems.add(
          '${source.path}:${entry.line}: ${entry.code} gives the template key '
          '"$templateKey", which is not unique snake_case',
        );
        continue;
      }
      final Set<String> inherited = <String>{
        ...baseKeys,
        ...groupKeys['context_${category.key}']!,
        ...groupKeys['pack_${pack.code.toLowerCase()}']!,
      };
      final List<Map<String, Object?>> own = <Map<String, Object?>>[];
      final Set<String> ownKeys = <String>{};
      for (final String key in entry.starter) {
        for (final Map<String, Object?> field in typer.type(
          key,
          where: '${source.path}:${entry.line}',
        )) {
          final String fieldKey = field['key']! as String;
          if (inherited.contains(fieldKey) || !ownKeys.add(fieldKey)) {
            continue;
          }
          own.add(
            _emitField(
              field,
              optionSets,
              group: _specificGroup,
              required: _starterRequiredness,
            ),
          );
        }
      }
      assets.add(<String, Object?>{
        'schema_version': 1,
        'template_key': templateKey,
        'name': 'templates.$templateKey.name',
        'title': entry.title,
        'code': entry.code,
        'kind': pack.kind,
        'pack': pack.code,
        'privacy': entry.privacy,
        'rollout': entry.rollout,
        'identity_fields': pack.identity,
        'inherits_groups': <String>[
          ..._baseGroups,
          'context_${category.key}',
          'pack_${pack.code.toLowerCase()}',
        ],
        'fields': own,
        'child_rows': <Object?>[],
      });
    }
    byCategory[category.code] = assets;
  }
  if (problems.isNotEmpty) {
    return <String, String>{};
  }
  outputs['$assetsPath/$_groupsName'] = _json(groups);
  outputs['$assetsPath/$_indexName'] = _json(
    _index(catalogue, assetsPath, byCategory),
  );
  for (final _Category category in catalogue.categories) {
    outputs['$assetsPath/${category.fileName}'] = _json(<String, Object?>{
      'category': category.code,
      'templates': byCategory[category.code],
    });
  }
  outputs[listPath] = _list(catalogue, groups, byCategory, optionSets);
  return outputs;
}

/// Reads the planning catalogue line by line, recording every shape break.
_Catalogue _parse(String path, List<String> lines, List<String> problems) {
  final _Catalogue catalogue = _Catalogue();
  _Supergroup? supergroup;
  _Category? category;
  _Entry? entry;
  _Pack? pack;
  for (int index = 0; index < lines.length; index++) {
    final String line = lines[index].trimRight();
    final int number = index + 1;
    RegExpMatch? match;
    if ((match = _headline.firstMatch(line)) != null) {
      catalogue.declaredTemplates = int.parse(
        match!.group(1)!.replaceAll(',', ''),
      );
      catalogue.declaredCategories = int.parse(match.group(2)!);
      catalogue.declaredSupergroups = int.parse(match.group(3)!);
      catalogue.version = match.group(4)!;
    } else if ((match = _packLine.firstMatch(line)) != null) {
      pack = _Pack(match!.group(1)!, match.group(2)!, <String>[]);
      catalogue.packs[pack.code] = pack;
    } else if (pack != null &&
        (match = _packFieldsLine.firstMatch(line)) != null) {
      pack.catalogueFields.addAll(_splitKeys(match!.group(1)!));
      pack = null;
    } else if ((match = _supergroupLine.firstMatch(line)) != null) {
      supergroup = _Supergroup(match!.group(1)!, match.group(2)!.trim());
      catalogue.supergroups.add(supergroup);
      category = null;
      entry = null;
    } else if ((match = _categoryLine.firstMatch(line)) != null) {
      if (supergroup == null) {
        problems.add('$path:$number: a category before any supergroup');
        continue;
      }
      category = _Category(
        match!.group(1)!,
        match.group(2)!.trim(),
        int.parse(match.group(3)!),
        supergroup,
        number,
      );
      supergroup.categories.add(category);
      entry = null;
    } else if (category != null &&
        (match = _contextLine.firstMatch(line)) != null) {
      category.context = _splitKeys(match!.group(1)!);
    } else if ((match = _templateLine.firstMatch(line)) != null) {
      if (category == null || match!.group(1) != category.code) {
        problems.add('$path:$number: a template outside its category');
        continue;
      }
      entry = _Entry(
        '${match.group(1)}-${match.group(2)}',
        match.group(3)!,
        number,
      );
      category.templates.add(entry);
    } else if (entry != null && (match = _typeLine.firstMatch(line)) != null) {
      entry.typeLabel = match!.group(1)!;
      entry.pack = match.group(2)!;
    } else if (entry != null &&
        (match = _starterLine.firstMatch(line)) != null) {
      entry.starter = _splitKeys(match!.group(1)!);
    } else if (entry != null &&
        (match = _guidanceLine.firstMatch(line)) != null) {
      entry.guidance[match!.group(1)!] = _sentence(match.group(2)!);
    } else if (entry != null &&
        (match = _privacyLine.firstMatch(line)) != null) {
      entry.privacy = match!.group(1)!.toLowerCase();
      entry.rollout = match.group(2)!.toLowerCase();
      entry.rolloutLabel = match.group(3)!;
    }
  }
  for (final _Category category in catalogue.categories) {
    if (category.templates.length != category.declared) {
      problems.add(
        '$path:${category.line}: ${category.code} declares '
        '${category.declared} templates and lists '
        '${category.templates.length}',
      );
    }
    if (category.context.isEmpty) {
      problems.add('$path:${category.line}: ${category.code} has no context');
    }
    for (final _Entry entry in category.templates) {
      final List<String> missing = <String>[
        if (entry.pack.isEmpty) 'type and pack',
        if (entry.starter.isEmpty) 'starter fields',
        if (entry.privacy.isEmpty) 'privacy and rollout',
        if (entry.guidance.length != 4) 'guidance',
      ];
      if (missing.isNotEmpty) {
        problems.add(
          '$path:${entry.line}: ${entry.code} has no ${missing.join(', ')}',
        );
      }
      if (entry.pack.isNotEmpty && !catalogue.packs.containsKey(entry.pack)) {
        problems.add(
          '$path:${entry.line}: ${entry.code} names the unknown pack '
          '${entry.pack}',
        );
      }
      for (final String key in entry.starter) {
        if (!_snake.hasMatch(key)) {
          problems.add(
            '$path:${entry.line}: ${entry.code} field "$key" is not '
            'snake_case',
          );
        }
      }
    }
  }
  final int templates = catalogue.templates.length;
  final int categories = catalogue.categories.length;
  if (templates != catalogue.declaredTemplates ||
      categories != catalogue.declaredCategories ||
      catalogue.supergroups.length != catalogue.declaredSupergroups) {
    problems.add(
      '$path:1: the headline declares ${catalogue.declaredTemplates} '
      'templates, ${catalogue.declaredCategories} categories and '
      '${catalogue.declaredSupergroups} supergroups; the body lists '
      '$templates, $categories and ${catalogue.supergroups.length}',
    );
  }
  return catalogue;
}

/// Merges the typed packs into the parsed ones and checks they cover every
/// field the planning catalogue names.
void _readPacks(
  File file,
  _Catalogue catalogue,
  Map<String, List<String>> optionSets,
  List<String> problems,
) {
  final Map<String, Object?> root = _object(
    jsonDecode(file.readAsStringSync()),
  );
  for (final _Pack pack in catalogue.packs.values) {
    final Map<String, Object?>? typed = root[pack.code] == null
        ? null
        : _object(root[pack.code]);
    if (typed == null) {
      problems.add('${file.path}:0: pack ${pack.code} has no typed fields');
      continue;
    }
    pack.kind = typed['kind']! as String;
    pack.identity = _strings(typed['identity']);
    pack.fields = _objects(typed['fields']);
    final Set<String> covered = <String>{};
    final Set<String> keys = <String>{};
    for (final Map<String, Object?> field in pack.fields) {
      final String key = field['key']! as String;
      keys.add(key);
      covered.add(key);
      final Object? from = field['from'];
      if (from is String) {
        covered.add(from);
      }
      final Object? options = field['options'];
      if (options is String && !optionSets.containsKey(options)) {
        problems.add(
          '${file.path}:0: pack ${pack.code} field "$key" names the unknown '
          'option set "$options"',
        );
      }
    }
    for (final String key in pack.catalogueFields) {
      if (!covered.contains(key)) {
        problems.add(
          '${file.path}:0: pack ${pack.code} does not cover the catalogue '
          'field "$key"',
        );
      }
    }
    for (final String key in pack.identity) {
      if (!keys.contains(key)) {
        problems.add(
          '${file.path}:0: pack ${pack.code} identity names "$key", which it '
          'does not define',
        );
      }
    }
  }
  for (final _Entry entry in catalogue.templates) {
    final _Pack? pack = catalogue.packs[entry.pack];
    if (pack == null) {
      continue;
    }
    final Map<String, String> guidance = <String, String>{
      'Capture': pack.capture,
      'AI assistance': pack.aiAssistance,
      'Potential outputs': pack.outputs,
      'Review': pack.review,
    };
    for (final MapEntry<String, String> line in entry.guidance.entries) {
      final String known = guidance[line.key]!;
      if (known.isEmpty) {
        switch (line.key) {
          case 'Capture':
            pack.capture = line.value;
          case 'AI assistance':
            pack.aiAssistance = line.value;
          case 'Potential outputs':
            pack.outputs = line.value;
          case 'Review':
            pack.review = line.value;
        }
      } else if (known != line.value) {
        problems.add(
          '${file.path}:0: ${entry.code} gives pack ${pack.code} a second '
          '${line.key} line; guidance is shared by the pack',
        );
      }
    }
  }
}

/// Turns one catalogue field key into typed, atomic fields.
final class _Typer {
  _Typer(this._optionSets, this._overrides, this._problems);

  final Map<String, List<String>> _optionSets;
  final Map<String, List<Map<String, Object?>>> _overrides;
  final List<String> _problems;

  /// The fields [key] becomes. Most keys become one field; money, stated
  /// measures and sizes add their companions, and overrides may split.
  List<Map<String, Object?>> type(String key, {required String where}) {
    final List<Map<String, Object?>>? override = _overrides[key];
    if (override != null) {
      return <Map<String, Object?>>[
        for (final Map<String, Object?> field in override)
          <String, Object?>{...field, 'from': key},
      ];
    }
    final List<Map<String, Object?>> fields = _infer(key);
    for (final Map<String, Object?> field in fields) {
      final Object? options = field['options'];
      if (options is String && !_optionSets.containsKey(options)) {
        _problems.add('$where: "$key" names the unknown option set $options');
      }
    }
    return fields;
  }

  List<Map<String, Object?>> _infer(String key) {
    final List<String> words = key.split('_');
    final String last = words.last;
    final String stem = words.length == 1
        ? ''
        : key.substring(0, key.length - last.length - 1);
    Map<String, Object?> field(String type, {String? rename}) =>
        <String, Object?>{'key': rename ?? key, 'type': type};

    if (key.startsWith('is_') || key.startsWith('has_')) {
      return <Map<String, Object?>>[field('boolean')];
    }
    if (key.contains('barcode')) {
      return <Map<String, Object?>>[field('barcode')];
    }
    switch (last) {
      case 'date':
        return <Map<String, Object?>>[field('date')];
      case 'at':
        return <Map<String, Object?>>[field('date_time')];
      case 'timestamp' || 'datetime':
        return <Map<String, Object?>>[
          field('date_time', rename: _join(stem, 'at')),
        ];
      case 'deadline' || 'due' || 'expiry' || 'start' || 'end':
        return <Map<String, Object?>>[field('date', rename: '${key}_date')];
      case 'time':
        return <Map<String, Object?>>[field('time')];
      case 'count':
        return <Map<String, Object?>>[
          <String, Object?>{...field('number'), 'unit': 'count'},
        ];
      case 'hours':
        return <Map<String, Object?>>[
          <String, Object?>{...field('decimal'), 'unit': last},
        ];
      case 'minutes' || 'days' || 'months' || 'years':
        return <Map<String, Object?>>[
          <String, Object?>{...field('number'), 'unit': last},
        ];
      case 'percent' || 'percentage':
        return <Map<String, Object?>>[
          <String, Object?>{...field('percentage'), 'unit': 'percent'},
        ];
      case 'amount':
        return _money(key, _join(stem, 'currency'));
      case 'coordinates':
        return <Map<String, Object?>>[field('gps_location')];
      case 'geometry':
        return <Map<String, Object?>>[
          <String, Object?>{
            ...field('long_text'),
            'help': 'Coordinates as WKT or GeoJSON.',
          },
        ];
      case 'signature' || 'signatures' || 'signoff':
        return <Map<String, Object?>>[field('signature')];
      case 'dimensions':
        if (_abstractDimensions.contains(key)) {
          return <Map<String, Object?>>[field('long_text')];
        }
        return <Map<String, Object?>>[
          for (final String side in <String>['length', 'width', 'height'])
            field('decimal', rename: _join(stem, '${side}_mm')),
        ];
      case 'area':
        final String? unit = _measuredAreas[key];
        return <Map<String, Object?>>[
          if (unit == null)
            field('text')
          else
            <String, Object?>{...field('decimal'), 'unit': unit},
        ];
    }
    if (words.length > 2 && words[0] == 'number' && words[1] == 'of') {
      return <Map<String, Object?>>[
        <String, Object?>{...field('number'), 'unit': 'count'},
      ];
    }
    if (_moneyWords.contains(last) || _moneyValues.contains(key)) {
      return _money(key, '${key}_currency');
    }
    final (String, String)? measured = _measured[last];
    if (measured != null) {
      return <Map<String, Object?>>[
        <String, Object?>{...field(measured.$1), 'unit': measured.$2},
      ];
    }
    if (_declaredMeasures.contains(last)) {
      return <Map<String, Object?>>[
        <String, Object?>{...field('decimal'), 'unit': _asDeclared},
        field('text', rename: '${key}_unit'),
      ];
    }
    if (_photoWords.contains(last)) {
      return <Map<String, Object?>>[field('photo_reference')];
    }
    if (_documentWords.contains(last)) {
      return <Map<String, Object?>>[field('document_reference')];
    }
    final String? choice = key == 'verification_status'
        ? 'verification_status'
        : last == 'risk'
        ? 'risk_rating'
        : last == 'condition' &&
              (stem.isEmpty || _physicalConditions.contains(words.first))
        ? 'condition'
        : _choiceWords[last];
    if (choice != null) {
      return <Map<String, Object?>>[
        <String, Object?>{
          ...field('choice'),
          'options': choice,
          if (_manualChoices.contains(choice)) 'input_mode': 'manual_only',
        },
      ];
    }
    if (_isPlural(last) || _narrativeWords.contains(last)) {
      return <Map<String, Object?>>[
        <String, Object?>{
          ...field('long_text'),
          if (_refinedWords.contains(last)) 'refine': true,
        },
      ];
    }
    return <Map<String, Object?>>[field('text')];
  }

  List<Map<String, Object?>> _money(String key, String currency) {
    return <Map<String, Object?>>[
      <String, Object?>{
        'key': key,
        'type': 'currency',
        'input_mode': 'manual_only',
      },
      <String, Object?>{'key': currency, 'type': 'text'},
    ];
  }
}

/// Whether [word] reads as a plural noun, which a field holds as a list.
bool _isPlural(String word) {
  if (_singularEndings.contains(word)) {
    return false;
  }
  return word.length > 3 &&
      word.endsWith('s') &&
      !word.endsWith('ss') &&
      !word.endsWith('us') &&
      !word.endsWith('is');
}

/// The shipped JSON shape of one typed field.
Map<String, Object?> _emitField(
  Map<String, Object?> field,
  Map<String, List<String>> optionSets, {
  required String group,
  String? required,
  bool stickable = false,
}) {
  final String key = field['key']! as String;
  final Object? options = field['options'];
  return <String, Object?>{
    'field_key': key,
    'label': 'templates.catalogue.$key',
    'type': field['type'],
    'required': required ?? field['required'] ?? 'OPTIONAL',
    if (field['unit'] != null) 'unit': field['unit'],
    if (options is String)
      'options': <Map<String, String>>[
        for (final String code in optionSets[options] ?? const <String>[])
          <String, String>{
            'code': code,
            'label': 'templates.choices.$options.$code',
          },
      ],
    'group': group,
    if (field['help'] != null) 'help': field['help'],
    if (field['input_mode'] != null) 'input_mode': field['input_mode'],
    if (field['auto_fill'] != null) 'auto_fill': field['auto_fill'],
    if (field['refine'] == true) 'refine': true,
    if (stickable) 'stickable': true,
  };
}

/// The index the loader lists the catalogue from.
Map<String, Object?> _index(
  _Catalogue catalogue,
  String assetsPath,
  Map<String, List<Map<String, Object?>>> byCategory,
) {
  return <String, Object?>{
    'catalogue_version': catalogue.version,
    'source': 'resources/templates.md',
    'template_count': catalogue.templates.length,
    'supergroups': <Map<String, Object?>>[
      for (final _Supergroup supergroup in catalogue.supergroups)
        <String, Object?>{
          'code': supergroup.code,
          'title': supergroup.title,
          'categories': <String>[
            for (final _Category category in supergroup.categories)
              category.code,
          ],
        },
    ],
    'categories': <Map<String, Object?>>[
      for (final _Category category in catalogue.categories)
        <String, Object?>{
          'code': category.code,
          'title': category.title,
          'supergroup': category.supergroup.code,
          'asset': '$assetsPath/${category.fileName}',
          'context_group': 'context_${category.key}',
          'template_count': byCategory[category.code]!.length,
        },
    ],
    'packs': <Map<String, Object?>>[
      for (final _Pack pack in catalogue.packs.values)
        <String, Object?>{
          'code': pack.code,
          'title': pack.title,
          'kind': pack.kind,
          'group': 'pack_${pack.code.toLowerCase()}',
          'capture': pack.capture,
          'ai_assistance': pack.aiAssistance,
          'outputs': pack.outputs,
          'review': pack.review,
        },
    ],
  };
}

/// The readable list: every template, its code, key, record type and fields.
String _list(
  _Catalogue catalogue,
  Map<String, Object?> groups,
  Map<String, List<Map<String, Object?>>> byCategory,
  Map<String, List<String>> optionSets,
) {
  final StringBuffer out = StringBuffer()
    ..writeln('# Template library — every shipped template')
    ..writeln()
    ..writeln(
      '<!-- Generated by frontend/tool/build_template_catalogue.dart from '
      'resources/templates.md. Do not edit by hand. -->',
    )
    ..writeln()
    ..writeln(
      '**${_thousands(catalogue.templates.length + _starterCount)} '
      'templates** in the app: the $_starterCount starter templates of '
      'specification §13.4, and ${_thousands(catalogue.templates.length)} '
      'catalogue templates in '
      '${catalogue.categories.length} categories and '
      '${catalogue.supergroups.length} supergroups (catalogue version '
      '${catalogue.version}).',
    )
    ..writeln()
    ..writeln(
      'Every catalogue template is ordinary template data (§11.3). It '
      'inherits the four groups every shipped template carries (§13.3), its '
      "category's context fields, and its record type's pack, then adds its "
      'own starter fields. Pick one from **Templates → Library**, search it '
      'by name, code, category, record type or field, and add it to a '
      'project as an editable copy: rename, retype, reorder, hide or change '
      'the requiredness of any field (§13.2).',
    )
    ..writeln()
    ..writeln(
      'Requiredness marks: `*` suggested REQUIRED, `+` suggested '
      'RECOMMENDED, unmarked OPTIONAL. A unit follows the type in brackets.',
    )
    ..writeln()
    ..writeln('## Contents')
    ..writeln()
    ..writeln('- [Record types and their packs](#record-types-and-their-packs)')
    ..writeln('- [Category context fields](#category-context-fields)');
  for (final _Supergroup supergroup in catalogue.supergroups) {
    out.writeln(
      '- [${supergroup.code} · ${supergroup.title}]'
      '(#${_anchor('${supergroup.code} · ${supergroup.title}')})',
    );
    for (final _Category category in supergroup.categories) {
      final String heading = '${category.code} — ${category.title}';
      out.writeln(
        '  - [$heading](#${_anchor(heading)}) · '
        '${category.templates.length}',
      );
    }
  }
  out
    ..writeln()
    ..writeln('## Record types and their packs')
    ..writeln()
    ..writeln(
      'Each template has one record type. The pack is the set of fields '
      'every template of that type shares; the guidance lines say how it is '
      'captured, what AI may do, what it produces and how it is reviewed.',
    )
    ..writeln();
  for (final _Pack pack in catalogue.packs.values) {
    final int count = catalogue.templates
        .where((_Entry entry) => entry.pack == pack.code)
        .length;
    out
      ..writeln('### ${pack.code} — ${pack.title}')
      ..writeln()
      ..writeln(
        'Kind `${pack.kind}` · $count templates · identity: '
        '${pack.identity.map((String key) => '`$key`').join(', ')}',
      )
      ..writeln()
      ..writeln(
        _fieldLine(
          _objects(
            _object(groups['pack_${pack.code.toLowerCase()}'])['fields'],
          ),
        ),
      )
      ..writeln()
      ..writeln('- **Capture:** ${pack.capture}')
      ..writeln('- **AI assistance:** ${pack.aiAssistance}')
      ..writeln('- **Outputs:** ${pack.outputs}')
      ..writeln('- **Review:** ${pack.review}')
      ..writeln();
  }
  out
    ..writeln('## Category context fields')
    ..writeln()
    ..writeln(
      'Every template in a category shares these; they are stickable, so a '
      'value set once carries to the next record (§20).',
    )
    ..writeln()
    ..writeln('| Category | Context fields |')
    ..writeln('| --- | --- |');
  for (final _Category category in catalogue.categories) {
    out.writeln(
      '| ${category.code} — ${category.title} | '
      '${_fieldLine(_objects(_object(groups['context_${category.key}'])['fields']))} |',
    );
  }
  out.writeln();
  for (final _Supergroup supergroup in catalogue.supergroups) {
    out
      ..writeln('## ${supergroup.code} · ${supergroup.title}')
      ..writeln();
    for (final _Category category in supergroup.categories) {
      out
        ..writeln('### ${category.code} — ${category.title}')
        ..writeln()
        ..writeln(
          '${category.templates.length} templates · asset '
          '`frontend/assets/templates/catalogue/${category.fileName}`',
        )
        ..writeln()
        ..writeln(
          '| Code | Template | Key | Record type | Privacy | Rollout | '
          'Own fields |',
        )
        ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
      final List<Map<String, Object?>> assets = byCategory[category.code]!;
      for (int index = 0; index < assets.length; index++) {
        final Map<String, Object?> asset = assets[index];
        final _Entry entry = category.templates[index];
        out.writeln(
          '| ${asset['code']} | ${asset['title']} | `${asset['template_key']}` '
          '| ${entry.typeLabel} | ${_capitalised(entry.privacy)} | '
          '${entry.rollout.toUpperCase()} ${entry.rolloutLabel} | '
          '${_fieldLine(_objects(asset['fields']))} |',
        );
      }
      out.writeln();
    }
  }
  return out.toString();
}

/// One line listing [fields] with their type, unit and requiredness mark.
String _fieldLine(List<Map<String, Object?>> fields) {
  if (fields.isEmpty) {
    return '—';
  }
  return fields
      .map((Map<String, Object?> field) {
        final String mark = switch (field['required']) {
          'REQUIRED' => '*',
          'RECOMMENDED' => '+',
          _ => '',
        };
        final Object? unit = field['unit'];
        final String type = unit == null
            ? '${field['type']}'
            : '${field['type']} [$unit]';
        return '`${field['field_key']}`$mark $type';
      })
      .join(' · ');
}

/// Files whose committed content differs from [outputs], plus catalogue
/// assets nothing generates any more.
List<String> _staleOutputs(Map<String, String> outputs, String assetsPath) {
  final List<String> stale = <String>[
    for (final MapEntry<String, String> entry in outputs.entries)
      if (!File(entry.key).existsSync() ||
          File(entry.key).readAsStringSync() != entry.value)
        entry.key,
  ];
  final Directory assets = Directory(assetsPath);
  if (assets.existsSync()) {
    for (final FileSystemEntity entity in assets.listSync()) {
      final String path = '$assetsPath/${entity.uri.pathSegments.last}';
      if (entity is File && !outputs.containsKey(path)) {
        stale.add(path);
      }
    }
  }
  stale.sort();
  return stale;
}

/// Writes [outputs] and removes catalogue assets nothing generates any more.
void _write(Map<String, String> outputs, String assetsPath) {
  final Directory assets = Directory(assetsPath);
  if (assets.existsSync()) {
    for (final FileSystemEntity entity in assets.listSync()) {
      final String path = '$assetsPath/${entity.uri.pathSegments.last}';
      if (entity is File && !outputs.containsKey(path)) {
        entity.deleteSync();
      }
    }
  }
  for (final MapEntry<String, String> entry in outputs.entries) {
    final File file = File(entry.key);
    file.parent.createSync(recursive: true);
    if (!file.existsSync() || file.readAsStringSync() != entry.value) {
      file.writeAsStringSync(entry.value);
    }
  }
}

/// Stable, readable JSON with a trailing newline.
String _json(Object? value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';

/// Comma-separated keys, trimmed.
List<String> _splitKeys(String text) => <String>[
  for (final String part in text.split(','))
    if (part.trim().isNotEmpty) part.trim(),
];

/// [text] without its closing full stop.
String _sentence(String text) {
  final String trimmed = text.trim();
  return trimmed.endsWith('.')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}

/// [count] with a comma between each group of three digits.
String _thousands(int count) {
  final String digits = '$count';
  final StringBuffer out = StringBuffer();
  for (int index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      out.write(',');
    }
    out.write(digits[index]);
  }
  return out.toString();
}

/// [word] with its first letter in capitals.
String _capitalised(String word) =>
    word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}';

/// [stem] and [word] joined by an underscore, or [word] alone.
String _join(String stem, String word) => stem.isEmpty ? word : '${stem}_$word';

/// A title as a snake_case key.
String _slug(String title) {
  return title
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('^_+|_+\$'), '');
}

/// The anchor GitHub gives a Markdown heading.
String _anchor(String heading) {
  return heading
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\- ]'), '')
      .replaceAll(' ', '-');
}

Map<String, Object?> _object(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return <String, Object?>{
      for (final MapEntry<Object?, Object?> entry in value.entries)
        entry.key.toString(): entry.value,
    };
  }
  return <String, Object?>{};
}

List<Map<String, Object?>> _objects(Object? value) {
  if (value is! List) {
    return <Map<String, Object?>>[];
  }
  return <Map<String, Object?>>[
    for (final Object? item in value) _object(item),
  ];
}

List<String> _strings(Object? value) {
  if (value is! List) {
    return <String>[];
  }
  return <String>[
    for (final Object? item in value)
      if (item is String) item,
  ];
}
