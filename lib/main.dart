import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const projectUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://uhqqxvrkozitbyxqwwxv.supabase.co',
);
const publishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_zdd1aR6L8cFn4Zvt4pQjBw_szy2O8tE',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: projectUrl, anonKey: publishableKey);
  runApp(const OBShopApp());
}

final supabase = Supabase.instance.client;

class OBShopApp extends StatefulWidget {
  const OBShopApp({super.key});
  @override
  State<OBShopApp> createState() => _OBShopAppState();
}

class _OBShopAppState extends State<OBShopApp> {
  ThemeMode themeMode = ThemeMode.dark;
  String language = 'Türkçe';
  final List<ShopProduct> cart = [];

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'O.B Awto Bezegleri',
        themeMode: themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffa83232)),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xffb83232),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xff101318),
          cardColor: const Color(0xff1c222b),
          useMaterial3: true,
        ),
        home: SplashGate(
          child: ShopHome(
            language: language,
            onLanguage: (v) => setState(() => language = v),
            isDark: themeMode == ThemeMode.dark,
            onTheme: (v) => setState(() => themeMode = v ? ThemeMode.dark : ThemeMode.light),
            cart: cart,
            onAdd: (p) => setState(() => cart.add(p)),
          ),
        ),
      );
}

class SplashGate extends StatefulWidget {
  final Widget child;
  const SplashGate({super.key, required this.child});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool show = true;
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => show = false);
    });
  }

  @override
  Widget build(BuildContext context) => !show
      ? widget.child
      : Scaffold(
          backgroundColor: const Color(0xff101318),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Image.asset('assets/logo_dark.png', fit: BoxFit.contain),
            ),
          ),
        );
}

class ShopProduct {
  final int? id;
  final String name;
  final String category;
  final String description;
  final String price;
  final String? imageUrl;
  const ShopProduct({this.id, required this.name, required this.category,
    required this.description, required this.price, this.imageUrl});

  factory ShopProduct.fromMap(Map<String, dynamic> row) => ShopProduct(
    id: row['id'] as int?,
    name: (row['name_tr'] ?? '').toString(),
    category: (row['category_name'] ?? 'Genel').toString(),
    description: (row['description_tr'] ?? '').toString(),
    price: '${row['price'] ?? 0}',
    imageUrl: row['image_url']?.toString(),
  );
}

class ShopHome extends StatefulWidget {
  final String language;
  final ValueChanged<String> onLanguage;
  final bool isDark;
  final ValueChanged<bool> onTheme;
  final List<ShopProduct> cart;
  final ValueChanged<ShopProduct> onAdd;
  const ShopHome({super.key, required this.language, required this.onLanguage,
    required this.isDark, required this.onTheme, required this.cart, required this.onAdd});
  @override
  State<ShopHome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<ShopHome> {
  late Future<List<ShopProduct>> productsFuture;
  @override
  void initState() {
    super.initState();
    productsFuture = loadProducts();
  }

  Future<List<ShopProduct>> loadProducts() async {
    final rows = await supabase.from('products').select('*, categories(name_tr)').eq('active', true).order('created_at');
    return rows.map((raw) {
      final row = Map<String, dynamic>.from(raw);
      final cat = row['categories'];
      row['category_name'] = cat is Map ? cat['name_tr'] : 'Genel';
      return ShopProduct.fromMap(row);
    }).toList();
  }

  String tr(String t, String tk, String ru) => widget.language == 'Türkçe' ? t : widget.language == 'Русский' ? ru : tk;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('O.B AWTO BEZEGleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      actions: [
        PopupMenuButton<String>(icon: const Icon(Icons.language), onSelected: widget.onLanguage,
          itemBuilder: (_) => const [PopupMenuItem(value: 'Türkçe', child: Text('Türkçe')), PopupMenuItem(value: 'Türkmençe', child: Text('Türkmençe')), PopupMenuItem(value: 'Русский', child: Text('Русский'))]),
        IconButton(icon: const Icon(Icons.search), onPressed: () async {
          final rows = await productsFuture;
          if (!context.mounted) return;
          showSearch(context: context, delegate: ProductSearch(rows));
        }),
        IconButton(icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode), onPressed: () => widget.onTheme(!widget.isDark)),
      ],
    ),
    drawer: Drawer(child: ListView(padding: EdgeInsets.zero, children: [
      const DrawerHeader(decoration: BoxDecoration(color: Color(0xff252b35)), child: Align(alignment: Alignment.bottomLeft, child: Text('O.B AWTO BEZEGleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))),
      ListTile(leading: const Icon(Icons.home), title: Text(tr('Ana sayfa','Baş sahypa','Главная')), onTap: () => Navigator.pop(context)),
      ListTile(leading: const Icon(Icons.shopping_bag), title: Text(tr('Sepetim','Sebedim','Корзина')), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage(cart: widget.cart))); }),
      ListTile(leading: const Icon(Icons.person), title: Text(tr('Üyelik / Giriş','Agza bolmak / Giriş','Регистрация / Вход')), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipPage())); }),
      ListTile(leading: const Icon(Icons.admin_panel_settings), title: Text(tr('Yönetici girişi','Administrator girişi','Вход администратора')), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginPage())); }),
    ])),
    body: RefreshIndicator(
      onRefresh: () async => setState(() => productsFuture = loadProducts()),
      child: FutureBuilder<List<ShopProduct>>(
        future: productsFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <ShopProduct>[];
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16,18,16,8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Aracına değer kat.','Awtoulagyňa aýratynlyk goş.','Добавьте стиль вашему автомобилю.'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6), Text(tr('Otomobil aksesuarları ve özel ürünler.','Awtoulag esbaplary we ýörite önümler.','Автоаксессуары и специальные товары.'), style: TextStyle(color: Theme.of(context).hintColor)),
              const SizedBox(height: 16), Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xff5c2024),Color(0xff242a34)])), child: const Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('O.B',style: TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:Colors.white)),Text('AWTO BEZEGleri',style:TextStyle(letterSpacing:1.2,color:Colors.white,fontWeight:FontWeight.bold))])),Icon(Icons.directions_car_filled,size:58,color:Colors.white70)])),
              const SizedBox(height:20), Text(tr('Ürünler','Önümler','Товары'),style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
            ]))),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (snapshot.hasError)
              SliverFillRemaining(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Ürünler yüklenemedi. İnternet bağlantısını kontrol edip ekranı aşağı çekerek yenile.\n${snapshot.error}', textAlign: TextAlign.center))))
            else if (items.isEmpty)
              SliverFillRemaining(child: Center(child: Text(tr('Henüz ürün eklenmedi. Yönetici ürün ekleyebilir.','Entäk önüm goşulmady. Administrator önüm goşup biler.','Товары пока не добавлены. Администратор может добавить товары.'))))
            else
              SliverPadding(padding: const EdgeInsets.fromLTRB(16,8,16,24), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((context,i) {
                final p = items[i];
                return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => Navigator.push(context,MaterialPageRoute(builder: (_) => ProductPage(product:p,onAdd:widget.onAdd))), child: Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Center(child:p.imageUrl == null ? const Icon(Icons.directions_car,size:54,color:Color(0xffc64a4a)) : Image.network(p.imageUrl!,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.image_not_supported,size:48)))),Text(p.name,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(p.category,style:TextStyle(color:Theme.of(context).hintColor,fontSize:12)),const SizedBox(height:6),Text(p.price,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12))]))));
              },childCount:items.length),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:.88))),
          ]);
        },
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (_) => CartPage(cart:widget.cart))),icon:const Icon(Icons.shopping_cart),label:Text('${tr('Sepet','Sebet','Корзина')} (${widget.cart.length})')),
  );
}

class ProductPage extends StatelessWidget {
  final ShopProduct product;
  final ValueChanged<ShopProduct> onAdd;

  const ProductPage({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: product.imageUrl == null
                    ? const Icon(
                        Icons.directions_car,
                        size: 120,
                        color: Color(0xffc64a4a),
                      )
                    : Image.network(
                        product.imageUrl!,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          size: 80,
                        ),
                      ),
              ),
            ),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              product.price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xffd56a6a),
              ),
            ),
            const SizedBox(height: 12),
            Text(product.description),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  onAdd(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ürün sepete eklendi'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Sepete ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class CartPage extends StatelessWidget {
  final List<ShopProduct> cart;
  const CartPage({super.key,required this.cart});
  @override
  Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text('Sepetim')),body:cart.isEmpty?const Center(child:Text('Sepetiniz boş.')):ListView(children:[...cart.map((p)=>ListTile(leading:const Icon(Icons.shopping_bag),title:Text(p.name),subtitle:Text(p.price))),Padding(padding:const EdgeInsets.all(16),child:FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MembershipPage())),child:const Text('Sipariş için giriş yap')))]));
}

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});
  @override
  State<MembershipPage> createState()=>_MembershipPageState();
}
class _MembershipPageState extends State<MembershipPage> {
  final email=TextEditingController(); final password=TextEditingController(); final phone=TextEditingController(); bool busy=false;
  @override
  void dispose(){email.dispose();password.dispose();phone.dispose();super.dispose();}
  Future<void> signUp() async {
    setState(()=>busy=true);
    try { await supabase.auth.signUp(email:email.text.trim(),password:password.text, data:{'phone':phone.text.trim()}); if(mounted) _message('Kayıt isteği gönderildi. E-posta doğrulaması gerekiyorsa gelen kutunu kontrol et. Üyeliğin yönetici onayından sonra etkinleşir.'); }
    on AuthException catch(e){_message(e.message);} catch(e){_message('Kayıt yapılamadı: $e');} finally{if(mounted)setState(()=>busy=false);}
  }
  void _message(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Üyelik başvurusu')),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('Üyelik oluştur',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('Başvurun yönetici tarafından onaylanana kadar hesabın beklemede kalır.'),const SizedBox(height:18),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Telefon numarası',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Şifre (en az 6 karakter)',border:OutlineInputBorder())),const SizedBox(height:18),FilledButton(onPressed:busy?null:signUp,child:busy?const CircularProgressIndicator():const Text('Üyelik başvurusu gönder'))]));
}

class AdminLoginPage extends StatefulWidget { const AdminLoginPage({super.key}); @override State<AdminLoginPage> createState()=>_AdminLoginPageState(); }
class _AdminLoginPageState extends State<AdminLoginPage> {
  final email=TextEditingController(); final password=TextEditingController(); bool busy=false;
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  Future<void> login() async {
    setState(()=>busy=true);
    try {
      final response=await supabase.auth.signInWithPassword(email:email.text.trim(),password:password.text);
      final user=response.user;
      if(user==null) throw Exception('Giriş başarısız.');
      final profile=await supabase.from('profiles').select('role').eq('id',user.id).maybeSingle();
      if(profile?['role']!='admin'){await supabase.auth.signOut();throw Exception('Bu hesap yönetici yetkisine sahip değil.');}
      if(!mounted)return;
      Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const AdminPanelPage()));
    } on AuthException catch(e){_show(e.message);} catch(e){_show(e.toString().replaceFirst('Exception: ',''));} finally{if(mounted)setState(()=>busy=false);}
  }
  void _show(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Admin girişi')),body:ListView(padding:const EdgeInsets.all(20),children:[const Icon(Icons.admin_panel_settings,size:64),const SizedBox(height:16),const Text('Yönetici hesabı',textAlign:TextAlign.center,style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:20),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-posta',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Şifre',border:OutlineInputBorder())),const SizedBox(height:18),FilledButton(onPressed:busy?null:login,child:busy?const CircularProgressIndicator():const Text('Giriş yap'))]));
}

class AdminPanelPage extends StatefulWidget { const AdminPanelPage({super.key}); @override State<AdminPanelPage> createState()=>_AdminPanelPageState(); }
class _AdminPanelPageState extends State<AdminPanelPage> {
  late Future<List<Map<String,dynamic>>> future;
  @override void initState(){super.initState();future=fetchProducts();}
  Future<List<Map<String,dynamic>>> fetchProducts() async {final rows=await supabase.from('products').select().order('created_at',ascending:false);return rows.map((e)=>Map<String,dynamic>.from(e)).toList();}
  Future<void> addProduct() async {
    final name=TextEditingController(),desc=TextEditingController(),price=TextEditingController(text:'0');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Yeni ürün'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Ürün adı (Türkçe)')),TextField(controller:desc,decoration:const InputDecoration(labelText:'Açıklama (Türkçe)')),TextField(controller:price,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Fiyat'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('İptal')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Kaydet'))]));
    if(ok==true&&name.text.trim().isNotEmpty){try{await supabase.from('products').insert({'name_tr':name.text.trim(),'description_tr':desc.text.trim(),'price':double.tryParse(price.text.replaceAll(',','.'))??0,'active':true});setState(()=>future=fetchProducts());}catch(e){_toast('Ürün kaydedilemedi: $e');}}
    name.dispose();desc.dispose();price.dispose();
  }
  Future<void> toggleProduct(Map<String,dynamic> p) async {try{await supabase.from('products').update({'active':!(p['active'] as bool? ?? true)}).eq('id',p['id']);setState(()=>future=fetchProducts());}catch(e){_toast('Güncellenemedi: $e');}}
  Future<void> setMembership(String id,String status) async {try{await supabase.from('profiles').update({'membership_status':status}).eq('id',id);setState(()=>future=fetchProducts());}catch(e){_toast('İşlem yapılamadı: $e');}}
  void _toast(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Admin paneli'),actions:[IconButton(onPressed:()async{await supabase.auth.signOut();if(mounted)Navigator.pop(context);},icon:const Icon(Icons.logout))]),floatingActionButton:FloatingActionButton.extended(onPressed:addProduct,icon:const Icon(Icons.add),label:const Text('Ürün ekle')),body:FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Hata: ${s.error}'));final rows=s.data??[];if(rows.isEmpty)return const Center(child:Text('Henüz ürün yok. + düğmesiyle ekleyebilirsin.'));return RefreshIndicator(onRefresh:()async=>setState(()=>future=fetchProducts()),child:ListView(children:rows.map((p)=>ListTile(title:Text('${p['name_tr']??''}'),subtitle:Text('Fiyat: ${p['price']??0}'),trailing:Switch(value:p['active'] as bool? ?? true,onChanged:(_)=>toggleProduct(p)))).toList()));}));
}

class ProductSearch extends SearchDelegate<String> {
  final List<ShopProduct> products;
  ProductSearch(this.products);
  @override String get searchFieldLabel=>'Ürün ara';
  @override List<Widget> buildActions(BuildContext context)=>[IconButton(onPressed:()=>query='',icon:const Icon(Icons.clear))];
  @override Widget buildLeading(BuildContext context)=>IconButton(onPressed:()=>close(context,''),icon:const Icon(Icons.arrow_back));
  @override Widget buildResults(BuildContext context)=>_results();
  @override Widget buildSuggestions(BuildContext context)=>_results();
  Widget _results(){final found=products.where((p)=>p.name.toLowerCase().contains(query.toLowerCase())).toList();return ListView(children:found.map((p)=>ListTile(title:Text(p.name),subtitle:Text(p.category))).toList());}
}
