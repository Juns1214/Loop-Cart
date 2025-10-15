import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/swiper.dart';
import 'package:lottie/lottie.dart';
import '../../utils/router.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/onboarding",
      onGenerateRoute: onGenerateRoute,
      home: const OnboardingPage(),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  List<Widget> pages = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pages = [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/online shopping delivery.json', 
            width: 350, 
            height: 450,
            fit: BoxFit.fill,
            repeat: true,
            animate: true),
        
            SizedBox(height: 20),
        
            Text( 
                "Speed & Reliability Guaranteed",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
        
            SizedBox(height: 20,),
        
            Text("Over 25 million customers enjoying same-day delivery from 500,000+ trusted merchants with 99.5% on-time",
            textAlign: TextAlign.center,
            style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),),
          ],
        ),
      ),

      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/ecommerce online banner.json', 
            width: 350, 
            height: 450,
            fit: BoxFit.fill,
            repeat: true,
            animate: true),
        
            SizedBox(height: 20),
        
            Text( 
                "Buy, Sell & Discover More",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
        
            SizedBox(height: 20,),
        
            Text("Millions of new and secondhand items from 300,000+ trusted sellers - turn your unused items into cash today",
            textAlign: TextAlign.center,
            style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),),
          ],
        ),
      ),

      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/Eco Friendly Animetion.json', 
            width: 350, 
            height: 450,
            fit: BoxFit.fill,
            repeat: true,
            animate: true),
        
            SizedBox(height: 20),
        
            Text( 
                "Green Shopping Experience",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
        
            SizedBox(height: 20,),
        
            Text("Supporting circular economy principles to reduce waste and promote sustainability through responsible shopping choices",
            textAlign: TextAlign.center,
            style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),),
          ],
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: 
    Container(
      height: double.infinity,
      width: double.infinity,
      color: Color(0xFFE4FEDB),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 80),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton(onPressed: (){}, 
              child: Text("Skip",
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),)),
            ],
          ),

          Expanded(child: Swiper(pages: pages),),

          SizedBox(height: 40),

          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Color(0xFF87C159)),
              padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 100, vertical: 15)),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              )),
            ),
            onPressed: (){
              Navigator.pushReplacementNamed(context, "/login");
            },
            child: Text("Next",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            )),

            SizedBox(height: 30,)

        ],
      ),
    ));
  }
}
