import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen:false);
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children:[
            TextField(controller: _email, decoration: InputDecoration(labelText:'Email')),
            TextField(controller: _pass, decoration: InputDecoration(labelText:'Password'), obscureText:true),
            SizedBox(height:12),
            ElevatedButton(
              onPressed: () async {
                setState(()=>loading=true);
                try {
                  await auth.signIn(_email.text.trim(), _pass.text.trim());
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: \$e')));
                }
                setState(()=>loading=false);
              },
              child: loading ? CircularProgressIndicator(color: Colors.white) : Text('Login')
            ),
            TextButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())), child: Text('Create account'))
          ]
        )
      )
    );
  }
}