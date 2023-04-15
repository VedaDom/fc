import 'dart:io';

Future<void> createProject(
  String projectName,
  List<String> options, {
  String? workingDirectory,
  bool featureBased = false,
}) async {
  // Create the Flutter project
  print("Creating Flutter project...");
  final createProjectResult = await Process.run(
    'flutter',
    ['create', ...options, projectName],
    workingDirectory: workingDirectory,
  );
  if (createProjectResult.exitCode != 0) {
    print('Error creating Flutter project: ${createProjectResult.stderr}');
    return;
  }

  if (workingDirectory != null) {
    workingDirectory = '$workingDirectory/$projectName';
  } else {
    workingDirectory = projectName;
  }

  print('Project created successfully!');

  print("Fetching dependencies...");
  // Run 'flutter packages get' to fetch the dependencies
  final addGoRouterDependencyResult = await Process.run(
    'flutter',
    ['pub', 'add', "go_router"],
    workingDirectory: workingDirectory,
  );
  if (addGoRouterDependencyResult.exitCode != 0) {
    print('Error fetching dependencies: ${addGoRouterDependencyResult.stderr}');
    return;
  }
  // Run 'flutter packages get' to fetch the dependencies
  final addRiverpodDependencyResult = await Process.run(
    'flutter',
    ['pub', 'add', "flutter_riverpod"],
    workingDirectory: workingDirectory,
  );
  if (addRiverpodDependencyResult.exitCode != 0) {
    print('Error fetching dependencies: ${addRiverpodDependencyResult.stderr}');
    return;
  }

  print("Creating project structure...");

  // Define the directory structure
  if (featureBased) {
    await createFeature(workingDirectory, 'login');
  } else {
    await defaultStracture(workingDirectory, {
      'core': ['models', 'constants'],
      'data': ['datasources', 'repositories'],
      'domain': ['entities', 'repositories', 'usecases'],
      'presentation': ['widgets', 'pages', 'theme', 'providers', 'router'],
    });
  }

  print('Project settup completed successfully!');
}

Future<void> createFeature(String projectName, String featureName) async {
  // Create the feature directory
  final featureDir = Directory('$projectName/lib/features/$featureName');
  await featureDir.create(recursive: true);

  await createDataLayer(
    projectName,
    'login',
    'auth_data_source',
    generateAuthDataSourceContent(projectName, featureName),
    'auth_repository',
    generateAuthRepositoryContent(projectName, featureName),
  );

  await createDomainLayer(
    projectName,
    featureName,
    'user',
    generateAuthEntityContent(projectName, featureName),
    'auth_repository',
    generateAuthDomainRepositoryContent(projectName, featureName),
    'auth_usecase',
    generateAuthUseCaseContent(projectName, featureName),
  );

  await createPresentationLayer(
    projectName,
    'login',
    'login_page',
    generateLoginPageContent(projectName),
  );

  // Update the shared routes
  await updateRoutes(projectName, featureName);
}

Future<void> createDataLayer(
  String projectName,
  String featureName,
  String dataSourceFileName,
  String dataSourceContent,
  String repositoryFileName,
  String repositoryContent,
) async {
  final featureDataPath = '$projectName/lib/features/$featureName/data';
  final datasourcesPath = '$featureDataPath/datasources';
  final repositoriesPath = '$featureDataPath/repositories';

  // Create datasources folder
  final datasourcesDir = Directory(datasourcesPath);
  await datasourcesDir.create(recursive: true);

  // Create repositories folder
  final repositoriesDir = Directory(repositoriesPath);
  await repositoriesDir.create(recursive: true);

  // Create data source file
  await createFileWithContent(
      '$datasourcesPath/$dataSourceFileName.dart', dataSourceContent);

  // Create repository file
  await createFileWithContent(
      '$repositoriesPath/$repositoryFileName.dart', repositoryContent);
}

Future<void> createDomainLayer(
  String projectName,
  String featureName,
  String entityFileName,
  String entityContent,
  String repositoryFileName,
  String repositoryContent,
  String useCaseFileName,
  String useCaseContent,
) async {
  final featureDir = Directory('$projectName/lib/domain/$featureName');
  await featureDir.create(recursive: true);

  final entitiesDir =
      Directory('$projectName/lib/domain/$featureName/entities');
  await entitiesDir.create(recursive: true);
  await createFileWithContent(
    '$projectName/lib/domain/$featureName/entities/$entityFileName.dart',
    entityContent,
  );

  final repositoriesDir =
      Directory('$projectName/lib/domain/$featureName/repositories');
  await repositoriesDir.create(recursive: true);
  await createFileWithContent(
    '$projectName/lib/domain/$featureName/repositories/$repositoryFileName.dart',
    repositoryContent,
  );

  final useCasesDir =
      Directory('$projectName/lib/domain/$featureName/usecases');
  await useCasesDir.create(recursive: true);
  await createFileWithContent(
    '$projectName/lib/domain/$featureName/usecases/$useCaseFileName.dart',
    useCaseContent,
  );
}

Future<void> createPresentationLayer(String projectName, String featureName,
    String pageFileName, String pageContent) async {
  final presentationDir =
      Directory('$projectName/lib/features/$featureName/presentation');
  await presentationDir.create(recursive: true);

  final widgetsDir =
      Directory('$projectName/lib/features/$featureName/presentation/widgets');
  await widgetsDir.create(recursive: true);

  final pagesDir =
      Directory('$projectName/lib/features/$featureName/presentation/pages');
  await pagesDir.create(recursive: true);

  final providersDir = Directory(
      '$projectName/lib/features/$featureName/presentation/providers');
  await providersDir.create(recursive: true);

  await createFileWithContent(
    '$projectName/lib/features/$featureName/presentation/pages/$pageFileName.dart',
    pageContent,
  );
}

Future<void> updateRoutes(String projectName, String featureName) async {
  // Update the routes file with the new feature's route
  final routesFilePath = '$projectName/lib/presentation/router/routes.dart';
  final routesFile = File(routesFilePath);

  // If routes file does not exist, create one with the basic content
  if (!routesFile.existsSync()) {
    final initialRoutesContent = '''
import 'package:go_router/go_router.dart';

final routes = [
];
    ''';

    final routerDir = Directory('$projectName/lib/presentation/router');
    await routerDir.create(recursive: true);

    await createFileWithContent(
      '$projectName/lib/presentation/router/routes.dart',
      initialRoutesContent,
    );
  }

  String routesContent = await routesFile.readAsString();

  // Add the new route for the created feature
  final newRoute = '''
        GoRoute(
          path: '/$featureName',
          builder: (context, state) {
            return const ${toPascalCase(featureName)}Page();
          },
        ),
  ''';

  // Insert the new route before the closing square bracket
  final closingBracketIndex = routesContent.lastIndexOf(']');
  routesContent = routesContent.replaceRange(
      closingBracketIndex, closingBracketIndex, newRoute);

  // Write the updated content to the shared routes file
  await routesFile.writeAsString(routesContent);
}

String toPascalCase(String text) {
  return text
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join();
}

Future<void> defaultStracture(
    String workingDirectory, Map<String, List<String>> structure) async {
  // Create the lib folder
  final libDir = Directory('$workingDirectory/lib');
  await libDir.delete(recursive: true);
  await libDir.create(recursive: true);

  // Create the directory structure
  structure.forEach((key, value) async {
    final mainDir = Directory('$workingDirectory/lib/$key');
    await mainDir.create(recursive: true);

    for (final subDirName in value) {
      final subDir = Directory('$workingDirectory/lib/$key/$subDirName');
      await subDir.create(recursive: true);
    }
  });

  print("Creating files...");
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

  await createFileWithContent(
      '$workingDirectory/lib/main.dart', mainDartContent);

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
      '$workingDirectory/lib/presentation/providers/auth_provider.dart',
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
    '$workingDirectory/lib/presentation/router/app_router.dart',
    appRouterContent,
  );

  // auth_repository.dart
  final authRepositoryContent = '''
  import '../../core/models/user_model.dart';
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
      '$workingDirectory/lib/data/repositories/auth_repository.dart',
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
      '$workingDirectory/lib/core/models/user_model.dart', userModelContent);

  // user_data_source.dart
  final userDataSourceContent = '''
  import '../../core/models/user_model.dart';
  
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
      '$workingDirectory/lib/data/datasources/user_data_source.dart',
      userDataSourceContent);

  // user_repository.dart
  final userRepositoryContent = '''
  import '../../core/models/user_model.dart';
  
  abstract class AuthRepository {
  Future<UserModel> signin(String email, String password);
  }
  ''';

  await createFileWithContent(
      '$workingDirectory/lib/domain/repositories/auth_repository.dart',
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
      '$workingDirectory/lib/domain/usecases/auth_usecase.dart',
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
      '$workingDirectory/lib/presentation/pages/login_page.dart',
      loginPageContent);
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

String generateAuthDataSourceContent(String projectName, String featureName) {
  return '''
import '../../../core/models/user_model.dart';

abstract class AuthDataSource {
  Future<UserModel> signIn(String email, String password);
}

class AuthDataSourceImpl implements AuthDataSource {
  @override
  Future<UserModel> signIn(String email, String password) {
    // TODO: implement signIn
    throw UnimplementedError();
  }
}
  ''';
}

String generateAuthRepositoryContent(String projectName, String featureName) {
  return '''
import '../../../$projectName/core/models/user_model.dart';
import '../../../$projectName/data/$featureName/datasources/auth_data_source.dart';
import '../../../$projectName/domain/$featureName/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource authDataSource;

  AuthRepositoryImpl(this.authDataSource);

  @override
  Future<UserModel> signIn(String email, String password) {
    return authDataSource.signIn(email, password);
  }
}
  ''';
}

String generateAuthEntityContent(String projectName, String featureName) {
  return '''
class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}
  ''';
}

String generateAuthDomainRepositoryContent(
  String projectName,
  String featureName,
) {
  return '''
import '../../$projectName/domain/$featureName/entities/user.dart';

abstract class AuthRepository {
  Future<User> signIn(String email, String password);
}
  ''';
}

String generateAuthUseCaseContent(String projectName, String featureName) {
  return '''
import '../../$projectName/domain/$featureName/repositories/auth_repository.dart';
import '../../$projectName/domain/$featureName/entities/user.dart';

class AuthUseCase {
  final AuthRepository authRepository;

  AuthUseCase(this.authRepository);

  Future<User> signIn(String email, String password) {
    return authRepository.signIn(email, password);
  }
}
  ''';
}

String generateLoginPageContent(String projectName) {
  return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:$projectName/features/login/presentation/providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({Key? key}) : super(key: key);

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
}
