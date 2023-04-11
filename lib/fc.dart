import 'dart:io';

Future<void> createProject(String projectName, List<String> options) async {
  // Create the Flutter project
  final createProjectResult =
      await Process.run('flutter', ['create', ...options, projectName]);
  if (createProjectResult.exitCode != 0) {
    print('Error creating Flutter project: ${createProjectResult.stderr}');
    return;
  }

  // Run 'flutter packages get' to fetch the dependencies
  final addGoRouterDependencyResult = await Process.run(
      'flutter', ['pub', 'add', "go_router"],
      workingDirectory: projectName);
  if (addGoRouterDependencyResult.exitCode != 0) {
    print('Error fetching dependencies: ${addGoRouterDependencyResult.stderr}');
    return;
  }
  // Run 'flutter packages get' to fetch the dependencies
  final addRiverpodDependencyResult = await Process.run(
      'flutter', ['pub', 'add', "flutter_riverpod"],
      workingDirectory: projectName);
  if (addRiverpodDependencyResult.exitCode != 0) {
    print('Error fetching dependencies: ${addRiverpodDependencyResult.stderr}');
    return;
  }

  // Define the directory structure
  final structure = {
    'core': ['models', 'constants'],
    'data': ['datasources', 'repositories'],
    'domain': ['entities', 'repositories', 'usecases'],
    'presentation': ['widgets', 'pages', 'theme', 'providers', 'router'],
  };

  // Create the lib folder
  final libDir = Directory('${projectName}/lib');
  await libDir.delete(recursive: true);
  await libDir.create();

  // Create the directory structure
  structure.forEach((key, value) async {
    final mainDir = Directory('${projectName}/lib/$key');
    await mainDir.create();

    for (final subDirName in value) {
      final subDir = Directory('${projectName}/lib/$key/$subDirName');
      await subDir.create();
    }
  });

  // Create the necessary files and add the code

  // main.dart
  final mainDartContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'presentation/router/app_router.dart';

void main() {
  final goRouter = AppRouter.createGoRouter();
  runApp(ProviderScope(child: MyApp(goRouter: goRouter)));
}

class MyApp extends StatelessWidget {
  final GoRouter goRouter;

  const MyApp({super.key, required this.goRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: goRouter.routerDelegate,
      routeInformationParser: goRouter.routeInformationParser,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
  ''';

  await createFileWithContent('${projectName}/lib/main.dart', mainDartContent);

  // auth_provider.dart
  final authProviderContent = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecase.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepositoryImpl());

final authProvider =
    Provider((ref) => AuthUseCase(ref.read(authRepositoryProvider)));

  ''';

  await createFileWithContent(
      '${projectName}/lib/presentation/providers/auth_provider.dart',
      authProviderContent);

  // app_router.dart
  final appRouterContent = '''
import 'package:go_router/go_router.dart';

import '../pages/login_page.dart';

class AppRouter {
  static GoRouter createGoRouter() {
    final goRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return const LoginPage();
          },
        ),
      ],
    );
    return goRouter;
  }
}
  ''';

  await createFileWithContent(
    '${projectName}/lib/presentation/router/app_router.dart',
    appRouterContent,
  );

  // auth_repository.dart
  final authRepositoryContent = '''
import 'package:kayko/core/models/user_model.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<UserModel> signin(String email, String password) {
    // TODO: implement signin
    throw UnimplementedError();
  }
}
  ''';

  await createFileWithContent(
      '${projectName}/lib/data/repositories/auth_repository.dart',
      authRepositoryContent);

// user_model.dart
  final userModelContent = '''
class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({required this.id, required this.name, required this.email});
}

''';

  await createFileWithContent(
      '${projectName}/lib/core/models/user_model.dart', userModelContent);

// user_data_source.dart
  final userDataSourceContent = '''
import 'package:kayko/core/models/user_model.dart';

abstract class AuthDataSource {
  Future<UserModel> signin(String email, String password);
}

class AuthDataSourceImpl implements AuthDataSource {
  @override
  Future<UserModel> signin(String email, String password) {
    // TODO: implement signin
    throw UnimplementedError();
  }
}
''';

  await createFileWithContent(
      '${projectName}/lib/data/datasources/user_data_source.dart',
      userDataSourceContent);

// user_repository.dart
  final userRepositoryContent = '''
import '../../core/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signin(String email, String password);
}
''';

  await createFileWithContent(
      '${projectName}/lib/domain/repositories/auth_repository.dart',
      userRepositoryContent);

  // auth_usecase.dart
  final authUseCaseContent = '''
import '../repositories/auth_repository.dart';

class AuthUseCase {
  final AuthRepository authRepository;

  AuthUseCase(this.authRepository);

  // Add your authentication use case logic here
}
  ''';

  await createFileWithContent(
      '${projectName}/lib/domain/usecases/auth_usecase.dart',
      authUseCaseContent);

  // login_page.dart
  final loginPageContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add your login page UI here
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Login Page')),
    );
  }
}

  ''';

  await createFileWithContent(
      '${projectName}/lib/presentation/pages/login_page.dart',
      loginPageContent);

  print('Project created successfully!');
}

Future<void> createUseCase(String useCaseName) async {
  // Check if the current directory is a valid project
  final currentDir = Directory.current;
  if (!File('${currentDir.path}/pubspec.yaml').existsSync()) {
    print('Not a valid project directory');
    return;
  }

  // Create the use case file
  final useCaseFile = File('lib/domain/usecases/$useCaseName.dart');
  await useCaseFile.create();

  // Add the use case code to the file

  print('Use case created successfully!');
}

Future<void> createFileWithContent(String path, String content) async {
  final file = File(path);
  await file.create(recursive: true);
  await file.writeAsString(content);
}
