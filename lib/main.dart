import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

const String kBaseUrl = 'http://localhost/api-test/public';

void main() => runApp(const CvFabienApp());

class Membre {
  final int? id;
  final String nom;
  final String postnom;
  final String prenom;
  final String lieuNaissance;
  final String dateNaissance;
  final String parente;
  final String? imageUrl;

  Membre({
    this.id,
    required this.nom,
    required this.postnom,
    required this.prenom,
    required this.lieuNaissance,
    required this.dateNaissance,
    required this.parente,
    this.imageUrl,
  });

  factory Membre.fromJson(Map<String, dynamic> json) {
    return Membre(
      id: json['id'],
      nom: json['nom'] ?? '',
      postnom: json['postnom'] ?? '',
      prenom: json['prenom'] ?? '',
      lieuNaissance: json['lieu_naissance'] ?? '',
      dateNaissance: json['date_naissance'] ?? '',
      parente: json['parente'] ?? '',
      imageUrl: json['image_url'],
    );
  }

  Map<String, String> toJson() {
    return {
      'nom': nom,
      'postnom': postnom,
      'prenom': prenom,
      'lieu_naissance': lieuNaissance,
      'date_naissance': dateNaissance,
      'parente': parente,
    };
  }
}

class ApiService {
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/accounts/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['message'] ?? 'Erreur de connexion');
  }

  static Future<List<Membre>> getMembres() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/famille-membres'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data['data'] as List;
      return list.map((e) => Membre.fromJson(e)).toList();
    }
    throw Exception('Erreur lors du chargement');
  }

  static String _parseError(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (data['errors'] != null) {
        return (data['errors'] as Map).values.first.toString();
      }
      return data['message'] ?? 'Erreur inconnue';
    } catch (_) {
      return 'Erreur serveur (${res.statusCode})';
    }
  }

  static Future<void> addMembre(Membre m, {File? image}) async {
    try {
      if (image != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$kBaseUrl/famille-membres'),
        );
        request.headers.addAll({'Accept': 'application/json'});
        request.fields.addAll(m.toJson());
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );

        final response = await request.send();
        final res = await http.Response.fromStream(response);
        if (res.statusCode != 201) throw Exception(_parseError(res));
      } else {
        final res = await http.post(
          Uri.parse('$kBaseUrl/famille-membres'),
          headers: _headers,
          body: jsonEncode(m.toJson()),
        );
        if (res.statusCode != 201) throw Exception(_parseError(res));
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<void> updateMembre(Membre m, {File? image}) async {
    try {
      if (image != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$kBaseUrl/famille-membres/${m.id}'),
        );
        request.headers.addAll({'Accept': 'application/json'});
        request.fields.addAll(m.toJson());
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );

        final response = await request.send();
        final res = await http.Response.fromStream(response);
        if (res.statusCode != 200) throw Exception(_parseError(res));
      } else {
        final res = await http.put(
          Uri.parse('$kBaseUrl/famille-membres/${m.id}'),
          headers: _headers,
          body: jsonEncode(m.toJson()),
        );
        if (res.statusCode != 200) throw Exception(_parseError(res));
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<void> deleteMembre(int id) async {
    final res = await http.delete(
      Uri.parse('$kBaseUrl/famille-membres/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Erreur lors de la suppression');
  }
}

class Cv {
  static const prenom = 'Fabien';
  static const nom = 'Kapilinga';
  static const nomComplet = 'Fabien Kapilinga';
  static const statut = 'Étudiant à l\'ISIG Goma';
  static const photo = 'assets/images/kika.jpeg';
  static const portrait = 'assets/images/kika_portrait.jpg';

  static const dateNaissance = '27 juillet 2004';
  static const lieuNaissance = 'Goma';
  static const ville = 'Goma, RD Congo';

  static const parcours = [
    (
      'Aujourd\'hui',
      'ISIG Goma',
      'Institut Supérieur d\'Informatique et de Gestion — étudiant',
    ),
    ('Secondaire', 'École secondaire Maendeleo', 'Études secondaires — Goma'),
  ];
}

const kFond = Color(0xFFF3F3EF);
const kNoir = Color(0xFF111111);
const kCitron = Color(0xFFC8F026);
const kBlanc = Colors.white;
const kGris = Color(0xFF6E6E6A);
const kBord = Color(0xFFE2E2DC);

TextStyle sg(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = kNoir,
  double? h,
  double? ls,
}) => GoogleFonts.spaceGrotesk(
  fontSize: size,
  fontWeight: w,
  color: c,
  height: h,
  letterSpacing: ls,
);

class CvFabienApp extends StatelessWidget {
  const CvFabienApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CV Fabien Kapilinga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kFond,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kCitron,
          primary: kNoir,
          surface: kBlanc,
        ),
      ),
      home: const PageConnexion(),
    );
  }
}

class PageConnexion extends StatefulWidget {
  const PageConnexion({super.key});
  @override
  State<PageConnexion> createState() => _PageConnexionState();
}

class _PageConnexionState extends State<PageConnexion> {
  final _id = TextEditingController();
  final _mdp = TextEditingController();
  bool _masque = true;
  bool _loading = false;
  String? _erreur;

  Future<void> _valider() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _erreur = null;
      _loading = true;
    });

    try {
      await ApiService.login(_id.text.trim(), _mdp.text);
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const Coquille()));
      }
    } catch (e) {
      setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _id.dispose();
    _mdp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: kNoir,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kCitron,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'CV · 2026',
                        style: sg(12, w: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      Cv.prenom,
                      style: sg(48, w: FontWeight.w700, c: kBlanc, h: 1),
                    ),
                    Text(
                      Cv.nom,
                      style: sg(48, w: FontWeight.w700, c: kCitron, h: 1),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      Cv.statut,
                      style: sg(15, c: kBlanc.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Connexion', style: sg(24, w: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Entrez vos identifiants pour continuer.',
                style: sg(14, c: kGris),
              ),
              const SizedBox(height: 22),
              _champ(_id, 'Identifiant (Email)', Icons.person_rounded),
              const SizedBox(height: 12),
              _champ(
                _mdp,
                'Mot de passe',
                Icons.lock_rounded,
                masque: _masque,
                suffixe: IconButton(
                  onPressed: () => setState(() => _masque = !_masque),
                  icon: Icon(
                    _masque
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: kGris,
                  ),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erreur!,
                  style: sg(13, w: FontWeight.w600, c: Colors.red.shade700),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _loading ? null : _valider,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCitron,
                    foregroundColor: kNoir,
                    disabledBackgroundColor: kCitron.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: kNoir, width: 2),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: kNoir)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Se connecter',
                              style: sg(17, w: FontWeight.w700),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_outward_rounded),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _champ(
    TextEditingController c,
    String label,
    IconData icone, {
    bool masque = false,
    Widget? suffixe,
  }) {
    OutlineInputBorder bord(Color col, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: col, width: w),
    );
    return TextField(
      controller: c,
      obscureText: masque,
      style: sg(16, w: FontWeight.w500),
      cursorColor: kNoir,
      onSubmitted: (_) => _valider(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: sg(15, c: kGris),
        floatingLabelStyle: sg(15, w: FontWeight.w600),
        prefixIcon: Icon(icone, color: kNoir, size: 20),
        suffixIcon: suffixe,
        filled: true,
        fillColor: kBlanc,
        enabledBorder: bord(kBord, 1.5),
        focusedBorder: bord(kNoir, 2),
      ),
    );
  }
}

class Coquille extends StatefulWidget {
  const Coquille({super.key});
  @override
  State<Coquille> createState() => _CoquilleState();
}

class _CoquilleState extends State<Coquille> {
  int _i = 0;

  static const _onglets = [
    (Icons.badge_rounded, 'CV'),
    (Icons.favorite_rounded, 'Famille'),
    (Icons.near_me_rounded, 'Contact'),
  ];

  void _deconnexion() => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => const PageConnexion()));

  @override
  Widget build(BuildContext context) {
    final pages = [
      PageCv(onDeconnexion: _deconnexion),
      const PageFamille(),
      const PageContact(),
    ];
    return Scaffold(
      extendBody: true,
      body: SafeArea(bottom: false, child: pages[_i]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
          child: Container(
            height: 66,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kNoir,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int k = 0; k < _onglets.length; k++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _i = k),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: _i == k ? kCitron : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _onglets[k].$1,
                              size: 20,
                              color: _i == k
                                  ? kNoir
                                  : kBlanc.withValues(alpha: 0.6),
                            ),
                            if (_i == k) ...[
                              const SizedBox(width: 6),
                              Text(
                                _onglets[k].$2,
                                style: sg(13.5, w: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Etiquette extends StatelessWidget {
  final String texte;
  const Etiquette(this.texte, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: kCitron,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(BorderSide(color: kNoir, width: 1.5)),
          ),
        ),
        const SizedBox(width: 10),
        Text(texte.toUpperCase(), style: sg(13, w: FontWeight.w700, ls: 1.5)),
      ],
    ),
  );
}

class Bloc extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color couleur;
  const Bloc({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.couleur = kBlanc,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: couleur,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kNoir, width: 1.5),
    ),
    child: child,
  );
}

Widget ligneInfo(IconData icone, String libelle, String valeur) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kFond,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icone, size: 20, color: kNoir),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(libelle, style: sg(14, c: kGris)),
      ),
      Text(valeur, style: sg(15, w: FontWeight.w700)),
    ],
  ),
);

class PageCv extends StatelessWidget {
  final VoidCallback onDeconnexion;
  const PageCv({super.key, required this.onDeconnexion});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mon CV',
              style: sg(15, w: FontWeight.w600, c: kGris),
            ),
            OutlinedButton.icon(
              onPressed: onDeconnexion,
              icon: const Icon(Icons.logout_rounded, size: 18, color: kNoir),
              label: Text('Quitter', style: sg(13, w: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kNoir, width: 1.5),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 400,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  Cv.photo,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.55),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDD111111)],
                      stops: [0.5, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Cv.nomComplet,
                        style: sg(30, w: FontWeight.w700, c: kBlanc, h: 1.1),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kCitron,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          Cv.statut,
                          style: sg(13, w: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const Etiquette('Informations'),
        Bloc(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            children: [
              ligneInfo(
                Icons.cake_rounded,
                'Date de naissance',
                Cv.dateNaissance,
              ),
              const Divider(height: 1, color: kBord),
              ligneInfo(
                Icons.place_rounded,
                'Lieu de naissance',
                Cv.lieuNaissance,
              ),
            ],
          ),
        ),

        const Etiquette('Parcours scolaire'),
        for (int i = 0; i < Cv.parcours.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Bloc(
              couleur: i == 0 ? kCitron : kBlanc,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kNoir,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      i == 0 ? Icons.school_rounded : Icons.menu_book_rounded,
                      color: i == 0 ? kCitron : kBlanc,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Cv.parcours[i].$1.toUpperCase(),
                          style: sg(
                            11.5,
                            w: FontWeight.w700,
                            ls: 1.2,
                            c: i == 0 ? kNoir : kGris,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Cv.parcours[i].$2,
                          style: sg(18, w: FontWeight.w700, h: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Cv.parcours[i].$3,
                          style: sg(13.5, c: i == 0 ? kNoir : kGris, h: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class PageFamille extends StatefulWidget {
  const PageFamille({super.key});
  @override
  State<PageFamille> createState() => _PageFamilleState();
}

class _PageFamilleState extends State<PageFamille> {
  List<Membre> _membres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _membres = await ApiService.getMembres();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: sg(13, c: kBlanc)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showForm({Membre? membre}) {
    final nomCtrl = TextEditingController(text: membre?.nom ?? '');
    final postnomCtrl = TextEditingController(text: membre?.postnom ?? '');
    final prenomCtrl = TextEditingController(text: membre?.prenom ?? '');
    final lieuCtrl = TextEditingController(text: membre?.lieuNaissance ?? '');
    final dateCtrl = TextEditingController(text: membre?.dateNaissance ?? '');
    final parenteCtrl = TextEditingController(text: membre?.parente ?? '');
    File? image;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kFond,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: kNoir.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        membre == null
                            ? 'Ajouter un membre'
                            : 'Modifier le membre',
                        style: sg(22, w: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildField('Nom', nomCtrl)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField('Postnom', postnomCtrl)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField('Prénom', prenomCtrl),
                      const SizedBox(height: 12),
                      _buildField('Lieu de naissance', lieuCtrl),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateCtrl,
                        readOnly: true,
                        style: sg(15, w: FontWeight.w500),
                        decoration: _inputDeco(
                          'Date de naissance',
                          suffix: const Icon(
                            Icons.calendar_today,
                            color: kNoir,
                          ),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() {
                              dateCtrl.text = DateFormat('yyyy-MM-dd')
                                  .format(picked);
                            });
                          }
                        },
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'Lien de parenté (ex: Père, Sœur)',
                        parenteCtrl,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null)
                            setSheetState(() => image = File(picked.path));
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kNoir, width: 1.5),
                          foregroundColor: kNoir,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.image_rounded),
                        label: Text(
                          image == null
                              ? 'Choisir une photo (Optionnel)'
                              : 'Photo sélectionnée',
                          style: sg(14, w: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final m = Membre(
                              id: membre?.id,
                              nom: nomCtrl.text,
                              postnom: postnomCtrl.text,
                              prenom: prenomCtrl.text,
                              lieuNaissance: lieuCtrl.text,
                              dateNaissance: dateCtrl.text,
                              parente: parenteCtrl.text,
                            );

                            try {
                              if (membre == null) {
                                await ApiService.addMembre(m, image: image);
                              } else {
                                await ApiService.updateMembre(m, image: image);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _load();
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$e',
                                      style: sg(13, c: kBlanc),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kCitron,
                            foregroundColor: kNoir,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: kNoir, width: 2),
                            ),
                          ),
                          child: Text(
                            'Enregistrer',
                            style: sg(16, w: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      style: sg(15, w: FontWeight.w500),
      decoration: _inputDeco(label),
      validator: (v) => v!.isEmpty ? 'Requis' : null,
    );
  }

  InputDecoration _inputDeco(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: sg(14, c: kGris),
      floatingLabelStyle: sg(15, w: FontWeight.w600),
      suffixIcon: suffix,
      filled: true,
      fillColor: kBlanc,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kBord, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kNoir, width: 2),
      ),
    );
  }

  void _delete(Membre m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kFond,
        title: Text('Supprimer', style: sg(20, w: FontWeight.bold)),
        content: Text('Voulez-vous supprimer ${m.nom} ?', style: sg(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: sg(14, c: kGris)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: kBlanc,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.deleteMembre(m.id!);
                _load();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$e', style: sg(13, c: kBlanc)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Supprimer', style: sg(14, w: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFond,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: kCitron,
        foregroundColor: kNoir,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kNoir, width: 2),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kNoir))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: [
                Text('Ma famille', style: sg(34, w: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Mes proches, mes premiers soutiens.',
                  style: sg(15, c: kGris),
                ),
                const Etiquette('Membres'),
                if (_membres.isEmpty)
                  Bloc(
                    child: Center(
                      child: Text(
                        'Aucun membre pour le moment.',
                        style: sg(15, c: kGris),
                      ),
                    ),
                  )
                else
                  for (final m in _membres)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: kBlanc,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: kNoir, width: 1.5),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: m.parente == 'Père' ? kNoir : kCitron,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: m.imageUrl != null
                                  ? Image.network(
                                      m.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          m.nom[0],
                                          style: sg(
                                            26,
                                            w: FontWeight.w700,
                                            c: m.parente == 'Père'
                                                ? kCitron
                                                : kNoir,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        m.nom[0],
                                        style: sg(
                                          26,
                                          w: FontWeight.w700,
                                          c: m.parente == 'Père'
                                              ? kCitron
                                              : kNoir,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: kNoir,
                                            width: 1.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          m.parente,
                                          style: sg(12, w: FontWeight.w700),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.more_vert,
                                          color: kGris,
                                        ),
                                        onSelected: (v) {
                                          if (v == 'edit') _showForm(membre: m);
                                          if (v == 'delete') _delete(m);
                                        },
                                        itemBuilder: (c) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Modifier'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              'Supprimer',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${m.nom} ${m.prenom}',
                                    style: sg(18, w: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

class PageContact extends StatelessWidget {
  const PageContact({super.key});

  Future<void> _carte(BuildContext context, String lieu) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(lieu)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d\'ouvrir la carte.',
            style: sg(13, c: kBlanc),
          ),
          backgroundColor: kNoir,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        Text('Contact', style: sg(34, w: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Où me trouver. Touchez une carte pour l\'ouvrir dans Maps.',
          style: sg(15, c: kGris, h: 1.4),
        ),
        const SizedBox(height: 20),
        Bloc(
          couleur: kNoir,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: kCitron,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    Cv.portrait,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Cv.nomComplet,
                      style: sg(19, w: FontWeight.w700, c: kBlanc),
                    ),
                    Text(Cv.statut, style: sg(13.5, c: kCitron)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Etiquette('Coordonnées'),
        _tuile(
          context,
          Icons.location_city_rounded,
          'Ville',
          Cv.ville,
          Cv.ville,
        ),
        const SizedBox(height: 12),
        _tuile(
          context,
          Icons.school_rounded,
          'Université',
          'ISIG Goma',
          'ISIG Goma',
        ),
      ],
    );
  }

  Widget _tuile(
    BuildContext context,
    IconData icone,
    String libelle,
    String valeur,
    String lieu,
  ) => Material(
    color: kBlanc,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: kNoir, width: 1.5),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _carte(context, lieu),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: kCitron,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icone, color: kNoir),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(libelle, style: sg(13, c: kGris)),
                  Text(valeur, style: sg(17, w: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.arrow_outward_rounded, color: kNoir),
          ],
        ),
      ),
    ),
  );
}
