class Hotline {
  const Hotline({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.number,
    this.hours,
    this.verified = false,
  });

  factory Hotline.fromJson(Map<String, dynamic> j) => Hotline(
        id: j['id'] as String,
        nameEn: j['name_en'] as String,
        nameBn: j['name_bn'] as String,
        number: j['number'] as String,
        hours: j['hours'] as String?,
        verified: j['verified'] as bool? ?? false,
      );

  final String id;
  final String nameEn;
  final String nameBn;
  final String number;
  final String? hours;
  final bool verified;

  String name(bool bn) => bn ? nameBn : nameEn;
}

class TreeOption {
  const TreeOption({required this.key, required this.en, required this.bn, required this.next});

  factory TreeOption.fromJson(Map<String, dynamic> j) => TreeOption(
        key: j['key'] as String,
        en: j['en'] as String,
        bn: j['bn'] as String,
        next: j['next'] as String,
      );

  final String key;
  final String en;
  final String bn;
  final String next;

  String label(bool bn) => bn ? this.bn : en;
}

class TreeNode {
  const TreeNode({
    required this.id,
    this.qEn,
    this.qBn,
    this.options = const [],
    this.end = false,
    this.stepsEn = const [],
    this.stepsBn = const [],
    this.hotlineIds = const [],
  });

  factory TreeNode.fromJson(String id, Map<String, dynamic> j) {
    List<String> strings(String k) => (j[k] as List?)?.cast<String>() ?? const [];
    return TreeNode(
      id: id,
      qEn: j['q_en'] as String?,
      qBn: j['q_bn'] as String?,
      options: ((j['options'] as List?) ?? const [])
          .map((o) => TreeOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      end: j['end'] as bool? ?? false,
      stepsEn: strings('steps_en'),
      stepsBn: strings('steps_bn'),
      hotlineIds: strings('hotlines'),
    );
  }

  final String id;
  final String? qEn;
  final String? qBn;
  final List<TreeOption> options;
  final bool end;
  final List<String> stepsEn;
  final List<String> stepsBn;
  final List<String> hotlineIds;

  String question(bool bn) => (bn ? qBn : qEn) ?? '';
  List<String> steps(bool bn) => bn ? stepsBn : stepsEn;
}

class EmergencyTree {
  const EmergencyTree({required this.root, required this.nodes, required this.hotlines});

  factory EmergencyTree.fromJson(Map<String, dynamic> j) {
    final nodes = (j['nodes'] as Map<String, dynamic>).map(
      (id, v) => MapEntry(id, TreeNode.fromJson(id, v as Map<String, dynamic>)),
    );
    final hotlines = {
      for (final h in (j['hotlines'] as List))
        (h as Map<String, dynamic>)['id'] as String: Hotline.fromJson(h),
    };
    return EmergencyTree(root: j['root'] as String, nodes: nodes, hotlines: hotlines);
  }

  final String root;
  final Map<String, TreeNode> nodes;
  final Map<String, Hotline> hotlines;

  TreeNode node(String id) => nodes[id] ?? nodes[root]!;

  List<Hotline> hotlinesFor(TreeNode n) =>
      n.hotlineIds.map((id) => hotlines[id]).whereType<Hotline>().toList();
}