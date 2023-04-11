import 'package:args/args.dart';
import 'package:fc/fc.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('create')
    ..addOption('org', abbr: 'o', defaultsTo: '')
    ..addOption('empty', abbr: 'e', defaultsTo: '');

  final argsResult = parser.parse(arguments);
  final command = argsResult.command;

  if (command?.name == 'create') {
    final args = command?.arguments;
    if (args != null && args.isNotEmpty) {
      final targetType = args[0];
      if (targetType == 'project') {
        final projectName = args[1];
        final org = command?['org'] as String?;
        final empty = command?['empty'] as String?;

        List<String> options = [];
        if (org != null && org.isNotEmpty) {
          options.add('--org');
          options.add(org);
        }
        if (empty != null && empty.isNotEmpty) {
          options.add('--empty');
        }

        await createProject(projectName, options);
      } else if (targetType == 'page') {
        final pageName = args[1];
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
