part of console;

abstract class VariableStyle {
  static const _SingleBracketVariableStyle SINGLE_BRACKET = const _SingleBracketVariableStyle();
  static const _DoubleBracketVariableStyle DOUBLE_BRACKET = const _DoubleBracketVariableStyle();
  static const _BashBracketVariableStyle BASH_BRACKET = const _BashBracketVariableStyle();
  
  static VariableStyle DEFAULT = SINGLE_BRACKET;

  const VariableStyle();

  List<String> findVariables(String input);
  String replace(String input, String variable, String value);
}

class _DoubleBracketVariableStyle extends VariableStyle {
  static final RegExp _REGEX = new RegExp(r"\{\{(.+?)\}\}");

  const _DoubleBracketVariableStyle();

  @override
  List<String> findVariables(String input) {
    var matches = _REGEX.allMatches(input);
    var allKeys = new Set<String>();

    for (var match in matches) {

      var key = match.group(1);
      if (!allKeys.contains(key)) {
        allKeys.add(key);
      }
    }

    return allKeys;
  }

  @override
  String replace(String input, String variable, String value) {
    return input.replaceAll("{{${variable}}}", value);
  }
}

class _BashBracketVariableStyle extends VariableStyle {
  static final RegExp _REGEX = new RegExp(r"\$\{(.+?)\}");

  const _BashBracketVariableStyle();

  @override
  List<String> findVariables(String input) {
    var matches = _REGEX.allMatches(input);
    var allKeys = new Set<String>();

    for (var match in matches) {

      var key = match.group(1);
      if (!allKeys.contains(key)) {
        allKeys.add(key);
      }
    }

    return allKeys;
  }

  @override
  String replace(String input, String variable, String value) {
    return input.replaceAll("\${${variable}}", value);
  }
}

class _SingleBracketVariableStyle extends VariableStyle {
  static final RegExp _REGEX = new RegExp(r"\{(.+?)\}");

  const _SingleBracketVariableStyle();

  @override
  List<String> findVariables(String input) {
    var matches = _REGEX.allMatches(input);
    var allKeys = new Set<String>();

    for (var match in matches) {
      var key = match.group(1);
      if (!allKeys.contains(key)) {
        allKeys.add(key);
      }
    }

    return allKeys;
  }

  @override
  String replace(String input, String variable, String value) {
    return input.replaceAll("{${variable}}", value);
  }
}

String format(String input, {List<String> args, Map<String, String> replace, VariableStyle style}) {
  if (style == null) {
    style = VariableStyle.DEFAULT;
  }
  
  var out = input;
  var allKeys = style.findVariables(input);

  for (var id in allKeys) {
    if (args != null) {
      try {
        var index = int.parse(id);
        if (index < 0 || index > args.length - 1) {
          throw new RangeError.range(index, 0, args.length - 1);
        }
        out = style.replace(out, "${index}", args[index]);
        continue;
      } on FormatException catch (e) {}
    }

    if (replace != null && replace.containsKey(id)) {
      out = style.replace(out, id, replace[id]);
      continue;
    }

    if (id.startsWith("@") || id.startsWith("color.")) {
      var color = id.startsWith("@") ? id.substring(1) : id.substring(6);
      if (color.length == 0) {
        throw new Exception("color directive requires an argument");
      }

      if (_COLORS.containsKey(color)) {
        out = style.replace(out, "${id}", _COLORS[color].toString());
        continue;
      }

      if (color == "normal" || color == "end") {
        out = style.replace(out, id, "${Console.ANSI_ESCAPE}0m");
        continue;
      }
    }
    
    if (id.startsWith("env.")) {
      var envVariable = id.substring(4);
      if (envVariable.isEmpty) {
        throw new Exception("Unknown Key: ${id}");

      }
      var value = Platform.environment[envVariable];
      if (value == null) value = "";
      out = style.replace(out, id, value);
      continue;
    }
    
    if (id.startsWith("platform.")) {
      var variable = id.substring(9);
      
      if (variable.isEmpty) {
        throw new Exception("Unknown Key: ${id}");
      }
      
      var value = _resolvePlatformVariable(variable);
      
      out = style.replace(out, id, value);
      continue;
    }

    throw new Exception("Unknown Key: ${id}");
  }

  return out;
}

String _resolvePlatformVariable(String name) {
  switch (name) {
    case "hostname":
      return Platform.localHostname;
    case "executable":
      return Platform.executable;
    case "os":
      return Platform.operatingSystem;
    case "version":
      return Platform.version;
    case "script":
      return Platform.script.toString();
    default:
      throw new Exception("Unsupported Platform Variable: ${name}");
  }
}