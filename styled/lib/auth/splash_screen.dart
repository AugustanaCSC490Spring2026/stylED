import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:styled/auth/login_page.dart';
import 'package:google_fonts/google_fonts.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin{ //duration

@override
void initState() {
    
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive); //get rid of top and bottom bar
    Future.delayed(Duration(seconds: 4),() {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()
      ));
    }); //Set timer to take us from splash screen to login
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values); //get top and bottom bar back
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, //as big as possible
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blueAccent, Colors.deepPurpleAccent, Colors.lightBlueAccent, Colors.deepPurple],
          begin:Alignment.topRight,
          end: Alignment.bottomLeft,
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, //center logo + name
          children: [

            Image.asset('assets/icons/icons8-wardrobe-100.png', width: 100),
            SizedBox(height: 2), //separator

            Text('StylED', style: GoogleFonts.rockSalt(
              fontStyle: FontStyle.italic,
              color: Colors.white,
              fontSize: 67,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,

            


            )),
            SizedBox(height: 8), //sepator
            Text('Your closet. Reimagined.', style: GoogleFonts.audiowide(
              fontStyle: FontStyle.normal,
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,

            ))
          ],
          )
      ),
    );
  }
}
 