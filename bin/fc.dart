import 'package:args/args.dart';
import 'package:fc/fc.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('create')
    ..addOption('org', abbr: 'o', defaultsTo: '')
    ..addOption('features', abbr: 'f', defaultsTo: 'false')
    ..addOption('path', abbr: 'p', defaultsTo: '');

  final argsResult = parser.parse(arguments);
  final command = argsResult.command!;

  if (command.name == 'create') {
    final args = command.arguments;

    if (args.isNotEmpty) {
      final targetType = args[0];
      if (targetType == 'project') {
        final projectName = args[1];
        final result = <String, String>{};
        for (int i = 0; i < args.length; i += 2) {
          result[args[i].replaceAll("--", "")] = args[i + 1];
        }
        final org = result['org'] ?? '';
        final path = result['path'];
        dynamic featureBased = result['features'];

        List<String> options = [];
        if (org.isNotEmpty) {
          options.add('--org');
          options.add(org);
        }

        if (featureBased == 'true') {
          featureBased = true;
        } else {
          featureBased = false;
        }

        options.add('--empty');

        await createProject(
          projectName,
          options,
          workingDirectory: path,
          featureBased: featureBased,
        );
      } else if (targetType == 'page') {
        // Call your function to create a page here
      } else {
        print('Invalid target type. Use "project" or "page"');
      }
    } else {
      print('Please provide a target type (project or page) and name.');
    }
  } else {
    print(
        'Invalid command. Use "project-generator create project my_project" or "project-generator create page login"');
  }
}
