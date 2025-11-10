import 'package:flutter/material.dart';

class EditProfileScreen  extends StatefulWidget{
  const EditProfileScreen({super.key});


  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = "";
  String phone = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Name"),
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Phone"),
                onSaved: (value) => phone = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: Text("Save Changes"),
                onPressed: () {
                  if(_formKey.currentState!.validate()){
                    _formKey.currentState!.save();
                    //save the update data to firebase
                    Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }
}