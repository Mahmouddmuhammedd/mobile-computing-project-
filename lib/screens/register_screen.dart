import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen:false);
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
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
                  await auth.signUp(_email.text.trim(), _pass.text.trim());
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Register failed: \$e')));
                }
                setState(()=>loading=false);
              },
              child: loading ? CircularProgressIndicator(color: Colors.white) : Text('Create')
            ),
          ]
        )
      )
    );
  }
}