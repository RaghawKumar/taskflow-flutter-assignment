import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/validators.dart';
import '../../core/app_localizations.dart';
import '../../domain/models/models.dart';
import '../blocs/auth/auth_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/branding/taskflow_app_icon.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            semanticLabel: 'TaskFlow TF logo',
          ),
          const SizedBox(height: 12),
          Text(
            'TaskFlow',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>();
    return Scaffold(
      body: _AuthBackground(
        child: _AuthCardLayout(child: _loginForm(context, auth)),
      ),
    );
  }

  Widget _loginForm(BuildContext context, AuthBloc auth) => Card(
    color: Theme.of(context).colorScheme.surface.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.88 : 0.84,
    ),
    elevation: 8,
    shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to TaskFlow',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to plan, assign, and finish work.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              key: const Key('email'),
              controller: email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.l10n.text('email'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('password'),
              controller: password,
              validator: Validators.password,
              obscureText: hidden,
              decoration: InputDecoration(
                labelText: context.l10n.text('password'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => hidden = !hidden),
                  icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            if (auth.state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  auth.state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('login_button'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: auth.state.phase == LoadPhase.loading
                  ? null
                  : () {
                      if (form.currentState!.validate()) {
                        auth.login(email.text, password.text);
                      }
                    },
              child: auth.state.phase == LoadPhase.loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.text('login')),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    ),
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.l10n.text('register')),
        backgroundColor: Colors.transparent,
      ),
      body: _AuthBackground(
        child: _AuthCardLayout(
          topOffset: 220,
          child: Card(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: dark ? 0.88 : 0.84),
            elevation: 8,
            shadowColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create your TaskFlow account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registration is simulated for this assignment.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: name,
                      validator: (v) => Validators.required(v, 'Name'),
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: email,
                      validator: Validators.email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      validator: Validators.password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () async {
                        if (!form.currentState!.validate()) return;
                        await context.read<AuthBloc>().register(
                          name.text,
                          email.text,
                          password.text,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Account simulated successfully. Please sign in with a test account.',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCardLayout extends StatelessWidget {
  const _AuthCardLayout({required this.child, this.topOffset = 310});

  final Widget child;
  final double topOffset;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 700;
        final horizontal = constraints.maxWidth < 600 ? 20.0 : 40.0;
        final vertical = short ? 16.0 : 32.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, vertical, horizontal, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - vertical - 32,
            ),
            child: Padding(
              padding: EdgeInsets.only(top: short ? 24 : topOffset),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -90,
          left: 0,
          right: 0,
          bottom: 0,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: dark ? 0.22 : 0.46,
              child: Image.asset(
                'assets/branding/taskflow_login_background_v2.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
        ColoredBox(
          color: Theme.of(
            context,
          ).scaffoldBackgroundColor.withValues(alpha: dark ? 0.72 : 0.18),
        ),
        child,
      ],
    );
  }
}
