import 'dart:convert';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class PestResult {
  final int? id;
  final String isPestDetected;
  final String pestName;
  final String scientificName;
  final String severityLevel;
  final double confidence;
  final String affectedAreaEstimate;
  final String symptomsDetected;
  final String description;
  final String lifeCycle;
  final String damageDetails;
  final String favorableConditions;
  final String economicImpact;
  final String longTermPrevention;
  final List<String> hostPlants;
  final List<String> identificationTips;
  final List<Treatment> organicTreatments;
  final List<ChemicalTreatment> chemicalTreatments;
  final List<String> preventionTips;
  final String plantName;
  final String origin;
  final String useCase;
  final String expectedPrice;
  final String benefits;
  final String careGuide;
  final String? imagePath;
  final DateTime? dateScanned;
  final bool isFavorite;
  final bool isHistory;
  final String scanType; // 'identify', 'diagnose', or 'pest'
  final String healthStatus;
  final int healthScore;
  final List<String> careRecommendations;
  final Map<String, dynamic> completeData; // Stores the full JSON response

  PestResult({
    this.id,
    required this.isPestDetected,
    this.pestName = '',
    this.scientificName = '',
    this.severityLevel = 'Low',
    this.confidence = 0.0,
    this.affectedAreaEstimate = '',
    this.symptomsDetected = '',
    this.description = '',
    this.lifeCycle = '',
    this.damageDetails = '',
    this.favorableConditions = '',
    this.economicImpact = '',
    this.longTermPrevention = '',
    this.hostPlants = const [],
    this.identificationTips = const [],
    this.organicTreatments = const [],
    this.chemicalTreatments = const [],
    this.preventionTips = const [],
    this.plantName = '',
    this.origin = '',
    this.useCase = '',
    this.expectedPrice = '',
    this.benefits = '',
    this.careGuide = '',
    this.imagePath,
    this.dateScanned,
    this.isFavorite = false,
    this.isHistory = false,
    this.scanType = 'pest',
    this.healthStatus = 'Good',
    this.healthScore = 100,
    this.careRecommendations = const [],
    this.completeData = const {},
  });

  String get displayName {
    final String pName = plantName.trim();
    final String pestN = pestName.trim();
    final String diseaseN = (completeData['disease']?['name'])?.toString().trim() ?? '';

    bool isValid(String str) =>
        str.isNotEmpty &&
            str.toLowerCase() != 'unknown' &&
            str.toLowerCase() != 'n/a' &&
            str.toLowerCase() != 'null';

    if (scanType == 'identify') {
      if (isValid(pName)) return pName;
      if (isValid(pestN)) return pestN;
      return 'Plant Identified';
    } else if (scanType == 'diagnose') {
      if (isValid(diseaseN)) {
        if (isValid(pName) && !diseaseN.toLowerCase().contains(pName.toLowerCase())) {
          return '$diseaseN ($pName)';
        }
        return diseaseN;
      }
      if (isValid(pestN)) return pestN;
      if (isValid(pName)) return pName;
      return 'Health Diagnosis';
    } else {
      // scanType == 'pest' or default
      if (isValid(pestN)) return pestN;
      if (isValid(pName)) return pName;
      if (isValid(diseaseN)) return diseaseN;
      return 'Pest Scan';
    }
  }

  String get displaySubtitle {
    final String pName = plantName.trim();
    final String sciN = scientificName.trim();

    bool isValid(String str) =>
        str.isNotEmpty &&
            str.toLowerCase() != 'unknown' &&
            str.toLowerCase() != 'n/a' &&
            str.toLowerCase() != 'null';

    if (scanType == 'identify') {
      if (isValid(sciN)) return sciN;
      return 'Plant Identification';
    } else if (scanType == 'diagnose') {
      if (isValid(sciN)) return sciN;
      if (isValid(pName) && !displayName.contains(pName)) return pName;
      return 'Health Diagnosis';
    } else {
      // scanType == 'pest'
      if (isValid(pName) && !displayName.toLowerCase().contains(pName.toLowerCase())) {
        return pName;
      }
      if (isValid(sciN)) return sciN;
      return 'Pest Scan';
    }
  }

  String _translatePestOrPlantName(AppLocalizations? l10n, String name) {
    if (l10n == null) return name;
    final lower = name.toLowerCase();

    // Aphids
    if (lower.contains('aphid') ||
        lower.contains('plant lice') ||
        lower.contains('من') ||
        lower.contains('قمل النبات') ||
        lower.contains('pulgón') ||
        lower.contains('pulgon') ||
        lower.contains('puceron') ||
        lower.contains('blattlaus') ||
        lower.contains('माहू') ||
        lower.contains('एफिड') ||
        lower.contains('kutu daun') ||
        lower.contains('yaprak biti')) {
      return l10n.pestAphidName;
    }

    // Spider Mites
    if (lower.contains('spider mite') ||
        lower.contains('red spider') ||
        lower.contains('العنكبوت') ||
        lower.contains('عث') ||
        lower.contains('araña roja') ||
        lower.contains('ácaro') ||
        lower.contains('acaro') ||
        lower.contains('tétranyque') ||
        lower.contains('spinnmilbe') ||
        lower.contains('स्पाइडर माइट') ||
        lower.contains('tungau') ||
        lower.contains('örümcek')) {
      return l10n.pestSpiderMiteName;
    }

    // Whiteflies
    if (lower.contains('whitefly') ||
        lower.contains('whiteflies') ||
        lower.contains('white fly') ||
        lower.contains('البيضاء') ||
        lower.contains('ذباب أبيض') ||
        lower.contains('mosca blanca') ||
        lower.contains('mouche blanche') ||
        lower.contains('aleyrode') ||
        lower.contains('weiße fliege') ||
        lower.contains('सफेद मक्खी') ||
        lower.contains('kutu kebul') ||
        lower.contains('beyaz sinek')) {
      return l10n.pestWhiteflyName;
    }

    // Caterpillars
    if (lower.contains('caterpillar') ||
        lower.contains('worm') ||
        lower.contains('grub') ||
        lower.contains('يسروع') ||
        lower.contains('دودة') ||
        lower.contains('oruga') ||
        lower.contains('gusano') ||
        lower.contains('chenille') ||
        lower.contains('raupe') ||
        lower.contains('इल्ली') ||
        lower.contains('कैटरपिलर') ||
        lower.contains('ulat') ||
        lower.contains('lagarta') ||
        lower.contains('tırtıl')) {
      return l10n.pestCaterpillarName;
    }

    // Mealybugs
    if (lower.contains('mealybug') ||
        lower.contains('scale') ||
        lower.contains('الدقيقي') ||
        lower.contains('cochinilla') ||
        lower.contains('cochenille') ||
        lower.contains('schmierlaus') ||
        lower.contains('wollaus') ||
        lower.contains('मीलीबग') ||
        lower.contains('kutu putih') ||
        lower.contains('cochonilha') ||
        lower.contains('unlu bit')) {
      return l10n.pestMealybugName;
    }

    // Thrips
    if (lower.contains('thrip') ||
        lower.contains('تربس') ||
        lower.contains('thrips') ||
        lower.contains('fransenflügler') ||
        lower.contains('थ्रिप्स') ||
        lower.contains('gurem') ||
        lower.contains('triptes')) {
      return l10n.pestThripsName;
    }

    // Beetles
    if (lower.contains('beetle') ||
        lower.contains('خنفساء') ||
        lower.contains('escarabajo') ||
        lower.contains('chrysomèle') ||
        lower.contains('käfer') ||
        lower.contains('kafer') ||
        lower.contains('भृंग') ||
        lower.contains('kumbang') ||
        lower.contains('besouro') ||
        lower.contains('böcek')) {
      return l10n.pestLeafBeetleName;
    }

    // Slugs and Snails
    if (lower.contains('slug') ||
        lower.contains('snail') ||
        lower.contains('بزاقة') ||
        lower.contains('حلزون') ||
        lower.contains('babosa') ||
        lower.contains('caracol') ||
        lower.contains('limace') ||
        lower.contains('escargot') ||
        lower.contains('schnecke') ||
        lower.contains('स्लग') ||
        lower.contains('घोंघा') ||
        lower.contains('siput') ||
        lower.contains('bekicot') ||
        lower.contains('lesma') ||
        lower.contains('sümüklüböcek')) {
      return l10n.pestSlugName;
    }

    // Healthy
    if (lower.contains('healthy') ||
        lower.contains('no pest') ||
        lower.contains('سليم') ||
        lower.contains('صحية') ||
        lower.contains('لا توجد') ||
        lower.contains('sano') ||
        lower.contains('saludable') ||
        lower.contains('sain') ||
        lower.contains('gesund') ||
        lower.contains('स्वस्थ') ||
        lower.contains('sehat') ||
        lower.contains('saudável') ||
        lower.contains('saudavel') ||
        lower.contains('sağlıklı')) {
      return l10n.noPestDetected;
    }

    final lang = l10n.localeName;

    // Common Diseases Translation
    if (lower.contains('powdery mildew') || lower.contains('ففूंदी') || lower.contains('oídio') || lower.contains('oïdium') || lower.contains('mehltau') || lower.contains('البياض الدقيقي') || lower.contains('külleme')) {
      switch (lang) {
        case 'hi': return 'पाउडर फफूंदी';
        case 'es': return 'Oídio';
        case 'fr': return 'Oïdium';
        case 'de': return 'Echter Mehltau';
        case 'ar': return 'البياض الدقيقي';
        case 'id': return 'Embun Tepung';
        case 'pt': return 'Oídio';
        case 'tr': return 'Külleme';
        default: return 'Powdery Mildew';
      }
    }
    if (lower.contains('leaf spot') || lower.contains('धब्बा') || lower.contains('mancha foliar') || lower.contains('tache foliaire') || lower.contains('blattflecken') || lower.contains('تبقع الأوراق') || lower.contains('yaprak lekesi')) {
      switch (lang) {
        case 'hi': return 'पत्ती का धब्बा';
        case 'es': return 'Mancha Foliar';
        case 'fr': return 'Tache Foliaire';
        case 'de': return 'Blattflecken';
        case 'ar': return 'تبقع الأوراق';
        case 'id': return 'Bintik Daun';
        case 'pt': return 'Mancha Foliar';
        case 'tr': return 'Yaprak Lekesi';
        default: return 'Leaf Spot';
      }
    }
    if (lower.contains('root rot') || lower.contains('सड़न') || lower.contains('podredumbre') || lower.contains('pourriture') || lower.contains('wurzelfäule') || lower.contains('تعفن الجذور') || lower.contains('kök çürüklüğü')) {
      switch (lang) {
        case 'hi': return 'जड़ सड़न';
        case 'es': return 'Podredumbre de la Raíz';
        case 'fr': return 'Pourriture des Racines';
        case 'de': return 'Wurzelfäule';
        case 'ar': return 'تعفن الجذور';
        case 'id': return 'Busuk Akar';
        case 'pt': return 'Podridão das Raízes';
        case 'tr': return 'Kök Çürüklüğü';
        default: return 'Root Rot';
      }
    }
    if (lower.contains('black spot') || lower.contains('mancha negra') || lower.contains('tache noire') || lower.contains('البقعة السوداء') || lower.contains('siyah leke')) {
      switch (lang) {
        case 'hi': return 'काला धब्बा';
        case 'es': return 'Mancha Negra';
        case 'fr': return 'Tache Noire';
        case 'de': return 'Sternrußtau';
        case 'ar': return 'البقعة السوداء';
        case 'id': return 'Bintik Hitam';
        case 'pt': return 'Mancha Negra';
        case 'tr': return 'Siyah Leke';
        default: return 'Black Spot';
      }
    }

    // Common Plant Names Translation
    if (lower.contains('rose') || lower.contains('गुलाब') || lower.contains('rosa') || lower.contains('ورد') || lower.contains('mawar') || lower.contains('gül')) {
      switch (lang) {
        case 'hi': return 'गुलाब';
        case 'es': return 'Rosa';
        case 'fr': return 'Rose';
        case 'de': return 'Rose';
        case 'ar': return 'ورد';
        case 'id': return 'Mawar';
        case 'pt': return 'Rosa';
        case 'tr': return 'Gül';
        default: return 'Rose';
      }
    }
    if (lower.contains('tomato') || lower.contains('टमाटर') || lower.contains('tomate') || lower.contains('طماطم') || lower.contains('tomat') || lower.contains('domates')) {
      switch (lang) {
        case 'hi': return 'टमाटर';
        case 'es': return 'Tomate';
        case 'fr': return 'Tomate';
        case 'de': return 'Tomate';
        case 'ar': return 'طماطم';
        case 'id': return 'Tomat';
        case 'pt': return 'Tomate';
        case 'tr': return 'Domates';
        default: return 'Tomato';
      }
    }
    if (lower.contains('money plant') || lower.contains('pothos') || lower.contains('मनी प्लांट') || lower.contains('sirih gading') || lower.contains('jiboia')) {
      switch (lang) {
        case 'hi': return 'मनी प्लांट';
        case 'es': return 'Pothos';
        case 'fr': return 'Pothos';
        case 'de': return 'Efeutute';
        case 'ar': return 'بوتين';
        case 'id': return 'Sirih Gading';
        case 'pt': return 'Jiboia';
        case 'tr': return 'Sarmaşık';
        default: return 'Money Plant';
      }
    }
    if (lower.contains('aloe') || lower.contains('एलोवेरा') || lower.contains('घृतकुमारी') || lower.contains('sábila') || lower.contains('aloès') || lower.contains('الصبار') || lower.contains('lidah buaya') || lower.contains('babosa')) {
      switch (lang) {
        case 'hi': return 'एलोवेरा';
        case 'es': return 'Sábila';
        case 'fr': return 'Aloès';
        case 'de': return 'Aloe Vera';
        case 'ar': return 'الصبار';
        case 'id': return 'Lidah Buaya';
        case 'pt': return 'Babosa';
        case 'tr': return 'Aleo Vera';
        default: return 'Aloe Vera';
      }
    }
    if (lower.contains('snake plant') || lower.contains('sansevieria') || lower.contains('स्नेक प्लांट') || lower.contains('lengua de suegra') || lower.contains('bogenhanf') || lower.contains('جلد الثعبان') || lower.contains('lidah mertua')) {
      switch (lang) {
        case 'hi': return 'स्नेक प्लांट';
        case 'es': return 'Lengua de suegra';
        case 'fr': return 'Langue de belle-mère';
        case 'de': return 'Bogenhanf';
        case 'ar': return 'جلد الثعبان';
        case 'id': return 'Lidah Mertua';
        case 'pt': return 'Espada-de-são-jorge';
        case 'tr': return 'Paşa Kılıcı';
        default: return 'Snake Plant';
      }
    }
    if (lower.contains('tulsi') || lower.contains('basil') || lower.contains('तुलसी') || lower.contains('albahaca') || lower.contains('basilic') || lower.contains('basilikum') || lower.contains('ريحان') || lower.contains('kemangi') || lower.contains('manjericão') || lower.contains('fesleğen')) {
      switch (lang) {
        case 'hi': return 'तुलसी';
        case 'es': return 'Albahaca';
        case 'fr': return 'Basilic';
        case 'de': return 'Basilikum';
        case 'ar': return 'ريحان';
        case 'id': return 'Kemangi';
        case 'pt': return 'Manjericão';
        case 'tr': return 'Fesleğen';
        default: return 'Tulsi';
      }
    }
    if (lower.contains('mango') || lower.contains('आम') || lower.contains('mangue') || lower.contains('مانجو') || lower.contains('mangga') || lower.contains('manga')) {
      switch (lang) {
        case 'hi': return 'आम';
        case 'es': return 'Mango';
        case 'fr': return 'Mangue';
        case 'de': return 'Mango';
        case 'ar': return 'مانجو';
        case 'id': return 'Mangga';
        case 'pt': return 'Manga';
        case 'tr': return 'Mango';
        default: return 'Mango';
      }
    }
    if (lower.contains('neem') || lower.contains('नीम') || lower.contains('nim') || lower.contains('النيـم') || lower.contains('mimba')) {
      switch (lang) {
        case 'hi': return 'नीम';
        case 'es': return 'Neem';
        case 'fr': return 'Margousier';
        case 'de': return 'Neem';
        case 'ar': return 'النيـم';
        case 'id': return 'Mimba';
        case 'pt': return 'Nim';
        case 'tr': return 'Neem';
        default: return 'Neem';
      }
    }
    if (lower.contains('hibiscus') || lower.contains('गुड़हल') || lower.contains('hibisco') || lower.contains('eibisch') || lower.contains('كركديه') || lower.contains('kembang sepatu')) {
      switch (lang) {
        case 'hi': return 'गुड़हल';
        case 'es': return 'Hibisco';
        case 'fr': return 'Hibiscus';
        case 'de': return 'Eibisch';
        case 'ar': return 'كركديه';
        case 'id': return 'Kembang Sepatu';
        case 'pt': return 'Hibisco';
        case 'tr': return 'Japon Gülü';
        default: return 'Hibiscus';
      }
    }
    if (lower.contains('jasmine') || lower.contains('चमेली') || lower.contains('jazmín') || lower.contains('jasmin') || lower.contains('ياسمين') || lower.contains('melati') || lower.contains('jasmim') || lower.contains('yasemin')) {
      switch (lang) {
        case 'hi': return 'चमेली';
        case 'es': return 'Jazmín';
        case 'fr': return 'Jasmin';
        case 'de': return 'Jasmin';
        case 'ar': return 'ياسمين';
        case 'id': return 'Melati';
        case 'pt': return 'Jasmim';
        case 'tr': return 'Yasemin';
        default: return 'Jasmine';
      }
    }
    if (lower.contains('mint') || lower.contains('peppermint') || lower.contains('पुदीना') || lower.contains('menta') || lower.contains('menthe') || lower.contains('minze') || lower.contains('نعناع') || lower.contains('hortelã') || lower.contains('nane')) {
      switch (lang) {
        case 'hi': return 'पुदीना';
        case 'es': return 'Menta';
        case 'fr': return 'Menthe';
        case 'de': return 'Minze';
        case 'ar': return 'نعناع';
        case 'id': return 'Mint';
        case 'pt': return 'Hortelã';
        case 'tr': return 'Nane';
        default: return 'Mint';
      }
    }
    if (lower.contains('cactus') || lower.contains('कैक्टस') || lower.contains('kaktus') || lower.contains('صبار') || lower.contains('cacto')) {
      switch (lang) {
        case 'hi': return 'कैक्टस';
        case 'es': return 'Cactus';
        case 'fr': return 'Cactus';
        case 'de': return 'Kaktus';
        case 'ar': return 'صبار';
        case 'id': return 'Kaktus';
        case 'pt': return 'Cacto';
        case 'tr': return 'Kaktüs';
        default: return 'Cactus';
      }
    }
    if (lower.contains('sunflower') || lower.contains('सूरजमुखी') || lower.contains('girasol') || lower.contains('tournesol') || lower.contains('sonnenblume') || lower.contains('دوار الشمس') || lower.contains('bunga matahari') || lower.contains('ayçiçeği')) {
      switch (lang) {
        case 'hi': return 'सूरजमुखी';
        case 'es': return 'Girasol';
        case 'fr': return 'Tournesol';
        case 'de': return 'Sonnenblume';
        case 'ar': return 'دوار الشمس';
        case 'id': return 'Bunga Matahari';
        case 'pt': return 'Girassol';
        case 'tr': return 'Ayçiçeği';
        default: return 'Sunflower';
      }
    }
    if (lower.contains('lemon') || lower.contains('lime') || lower.contains('नींबू') || lower.contains('limón') || lower.contains('citron') || lower.contains('zitrone') || lower.contains('ليمون') || lower.contains('jeruk nipis') || lower.contains('limão') || lower.contains('limon')) {
      switch (lang) {
        case 'hi': return 'नींबू';
        case 'es': return 'Limón';
        case 'fr': return 'Citron';
        case 'de': return 'Zitrone';
        case 'ar': return 'ليمون';
        case 'id': return 'Jeruk Nipis';
        case 'pt': return 'Limão';
        case 'tr': return 'Limon';
        default: return 'Lemon';
      }
    }

    return name;
  }

  String getLocalizedDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String pName = plantName.trim();
    final String pestN = pestName.trim();
    final String diseaseN = (completeData['disease']?['name'])?.toString().trim() ?? '';

    bool isValid(String str) {
      final s = str.trim().toLowerCase();
      return s.isNotEmpty &&
          s != 'unknown' &&
          s != 'n/a' &&
          s != 'null' &&
          s != 'plant identified' &&
          s != 'health diagnosis' &&
          s != 'pest scan' &&
          s != 'plant identification';
    }

    if (scanType == 'identify') {
      if (isValid(pName)) return _translatePestOrPlantName(l10n, pName);
      if (isValid(pestN)) return _translatePestOrPlantName(l10n, pestN);
      return l10n?.identify ?? 'Identify';
    } else if (scanType == 'diagnose') {
      if (isValid(diseaseN)) {
        final translatedDisease = _translatePestOrPlantName(l10n, diseaseN);
        if (isValid(pName) && !diseaseN.toLowerCase().contains(pName.toLowerCase())) {
          return '$translatedDisease (${_translatePestOrPlantName(l10n, pName)})';
        }
        return translatedDisease;
      }
      if (isValid(pestN)) return _translatePestOrPlantName(l10n, pestN);
      if (isValid(pName)) return _translatePestOrPlantName(l10n, pName);
      return l10n?.diagnose ?? 'Diagnose';
    } else {
      // scanType == 'pest' or default
      if (isValid(pestN)) return _translatePestOrPlantName(l10n, pestN);
      if (isValid(pName)) return _translatePestOrPlantName(l10n, pName);
      if (isValid(diseaseN)) return _translatePestOrPlantName(l10n, diseaseN);
      return l10n?.aiScanner ?? 'AI Pest Scanner';
    }
  }

  String getLocalizedSubtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String pName = plantName.trim();
    final String sciN = scientificName.trim();
    final String dispName = getLocalizedDisplayName(context);

    bool isValid(String str) {
      final s = str.trim().toLowerCase();
      return s.isNotEmpty &&
          s != 'unknown' &&
          s != 'n/a' &&
          s != 'null' &&
          s != 'plant identified' &&
          s != 'health diagnosis' &&
          s != 'pest scan' &&
          s != 'plant identification';
    }

    if (scanType == 'identify') {
      if (isValid(sciN)) return sciN;
      return l10n?.plantInfoTitle ?? 'Plant Identification';
    } else if (scanType == 'diagnose') {
      if (isValid(sciN)) return sciN;
      if (isValid(pName) && !dispName.contains(pName)) return _translatePestOrPlantName(l10n, pName);
      return l10n?.diagnose ?? 'Health Diagnosis';
    } else {
      // scanType == 'pest'
      if (isValid(pName) && !dispName.toLowerCase().contains(pName.toLowerCase())) {
        return _translatePestOrPlantName(l10n, pName);
      }
      if (isValid(sciN)) return sciN;
      return l10n?.aiScanner ?? 'AI Pest Scanner';
    }
  }

  String getLocalizedHealthStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = healthStatus.toLowerCase().trim();
    if (l10n == null) return healthStatus;
    if (status == 'good' || status == 'healthy' || status == 'excellent' || status == 'स्वस्थ' || status == 'سليم') {
      return l10n.noPestDetected;
    }
    if (status == 'moderate' || status == 'fair' || status == 'medium') {
      return l10n.medium;
    }
    if (status == 'poor' || status == 'critical' || status == 'bad' || status == 'severe' || status == 'high') {
      return l10n.high;
    }
    return healthStatus;
  }

  String getLocalizedDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return description;
    final lowerPest = pestName.toLowerCase();

    if (lowerPest.contains('aphid') || lowerPest.contains('من') || lowerPest.contains('pulgón') || lowerPest.contains('माहू')) {
      return l10n.pestAphidDesc;
    }
    if (lowerPest.contains('spider mite') || lowerPest.contains('العنكبوت') || lowerPest.contains('araña roja') || lowerPest.contains('स्पाइडर माइट')) {
      return l10n.pestSpiderMiteDesc;
    }
    if (lowerPest.contains('whitefly') || lowerPest.contains('البيضاء') || lowerPest.contains('mosca blanca') || lowerPest.contains('सफेद मक्खी')) {
      return l10n.pestWhiteflyDesc;
    }
    if (lowerPest.contains('caterpillar') || lowerPest.contains('يسروع') || lowerPest.contains('oruga') || lowerPest.contains('इल्ली')) {
      return l10n.pestCaterpillarDesc;
    }
    if (lowerPest.contains('mealybug') || lowerPest.contains('scale') || lowerPest.contains('الدقيقي') || lowerPest.contains('cochinilla') || lowerPest.contains('मीलीबग')) {
      return l10n.pestMealybugDesc;
    }
    if (lowerPest.contains('thrip') || lowerPest.contains('تربس') || lowerPest.contains('थ्रिप्स')) {
      return l10n.pestThripsDesc;
    }
    if (lowerPest.contains('beetle') || lowerPest.contains('خنفساء') || lowerPest.contains('escarabajo') || lowerPest.contains('भृंग')) {
      return l10n.pestLeafBeetleDesc;
    }
    if (lowerPest.contains('slug') || lowerPest.contains('snail') || lowerPest.contains('بزاقة') || lowerPest.contains('حلزون') || lowerPest.contains('babosa') || lowerPest.contains('स्लग')) {
      return l10n.pestSlugDesc;
    }
    if (lowerPest.contains('healthy') || lowerPest.contains('no pest') || lowerPest.contains('سليم') || lowerPest.contains('صحية') || lowerPest.contains('स्वस्थ')) {
      return l10n.keepHealthy;
    }

    return description.isNotEmpty ? description : l10n.noDescription;
  }

  String getLocalizedSymptoms(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return symptomsDetected;
    final lowerPest = pestName.toLowerCase();

    if (lowerPest.contains('aphid') || lowerPest.contains('من') || lowerPest.contains('pulgón') || lowerPest.contains('माहू')) {
      return l10n.pestAphidSymptoms;
    }
    if (lowerPest.contains('spider mite') || lowerPest.contains('العنكبوت') || lowerPest.contains('araña roja') || lowerPest.contains('स्पाइडर माइट')) {
      return l10n.pestSpiderMiteSymptoms;
    }
    if (lowerPest.contains('whitefly') || lowerPest.contains('البيضاء') || lowerPest.contains('mosca blanca') || lowerPest.contains('सफेद मक्खी')) {
      return l10n.pestWhiteflySymptoms;
    }
    if (lowerPest.contains('caterpillar') || lowerPest.contains('يسروع') || lowerPest.contains('oruga') || lowerPest.contains('इल्ली')) {
      return l10n.pestCaterpillarSymptoms;
    }
    if (lowerPest.contains('mealybug') || lowerPest.contains('scale') || lowerPest.contains('الدقيقي') || lowerPest.contains('cochinilla') || lowerPest.contains('मीलीबग')) {
      return l10n.pestMealybugSymptoms;
    }
    if (lowerPest.contains('thrip') || lowerPest.contains('تربس') || lowerPest.contains('थ्रिप्स')) {
      return l10n.pestThripsSymptoms;
    }
    if (lowerPest.contains('beetle') || lowerPest.contains('خنفساء') || lowerPest.contains('escarabajo') || lowerPest.contains('भृंग')) {
      return l10n.pestLeafBeetleSymptoms;
    }
    if (lowerPest.contains('slug') || lowerPest.contains('snail') || lowerPest.contains('بزاقة') || lowerPest.contains('حلزون') || lowerPest.contains('babosa') || lowerPest.contains('स्लग')) {
      return l10n.pestSlugSymptoms;
    }

    return symptomsDetected;
  }

  String getLocalizedTreatment(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lowerPest = pestName.toLowerCase();
    if (l10n == null) return organicTreatments.isNotEmpty ? organicTreatments.first.instructions : '';

    if (lowerPest.contains('aphid') || lowerPest.contains('من') || lowerPest.contains('pulgón') || lowerPest.contains('माहू')) {
      return l10n.pestAphidTreatment;
    }
    if (lowerPest.contains('spider mite') || lowerPest.contains('العنكبوت') || lowerPest.contains('araña roja') || lowerPest.contains('स्पाइडर माइट')) {
      return l10n.pestSpiderMiteTreatment;
    }
    if (lowerPest.contains('whitefly') || lowerPest.contains('البيضاء') || lowerPest.contains('mosca blanca') || lowerPest.contains('सफेद मक्खी')) {
      return l10n.pestWhiteflyTreatment;
    }
    if (lowerPest.contains('caterpillar') || lowerPest.contains('يسروع') || lowerPest.contains('oruga') || lowerPest.contains('इल्ली')) {
      return l10n.pestCaterpillarTreatment;
    }
    if (lowerPest.contains('mealybug') || lowerPest.contains('scale') || lowerPest.contains('الدقيقي') || lowerPest.contains('cochinilla') || lowerPest.contains('मीलीबग')) {
      return l10n.pestMealybugTreatment;
    }
    if (lowerPest.contains('thrip') || lowerPest.contains('تربس') || lowerPest.contains('थ्रिप्स')) {
      return l10n.pestThripsTreatment;
    }
    if (lowerPest.contains('beetle') || lowerPest.contains('خنفساء') || lowerPest.contains('escarabajo') || lowerPest.contains('भृंग')) {
      return l10n.pestLeafBeetleTreatment;
    }
    if (lowerPest.contains('slug') || lowerPest.contains('snail') || lowerPest.contains('بزاقة') || lowerPest.contains('حلزون') || lowerPest.contains('babosa') || lowerPest.contains('स्लग')) {
      return l10n.pestSlugTreatment;
    }

    return organicTreatments.isNotEmpty ? organicTreatments.first.instructions : '';
  }

  List<String> getLocalizedPrevention(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lowerPest = pestName.toLowerCase();
    if (l10n == null) return preventionTips;

    if (lowerPest.contains('aphid') || lowerPest.contains('من') || lowerPest.contains('pulgón') || lowerPest.contains('माहू')) {
      return [l10n.pestAphidPrevention];
    }
    if (lowerPest.contains('spider mite') || lowerPest.contains('العنكبوت') || lowerPest.contains('araña roja') || lowerPest.contains('स्पाइडर माइट')) {
      return [l10n.pestSpiderMitePrevention];
    }
    if (lowerPest.contains('whitefly') || lowerPest.contains('البيضاء') || lowerPest.contains('mosca blanca') || lowerPest.contains('सफेद मक्खी')) {
      return [l10n.pestWhiteflyPrevention];
    }
    if (lowerPest.contains('caterpillar') || lowerPest.contains('يسروع') || lowerPest.contains('oruga') || lowerPest.contains('इल्ली')) {
      return [l10n.pestCaterpillarPrevention];
    }
    if (lowerPest.contains('mealybug') || lowerPest.contains('scale') || lowerPest.contains('الدقيقي') || lowerPest.contains('cochinilla') || lowerPest.contains('मीलीबग')) {
      return [l10n.pestMealybugPrevention];
    }
    if (lowerPest.contains('thrip') || lowerPest.contains('تربس') || lowerPest.contains('थ्रिप्स')) {
      return [l10n.pestThripsPrevention];
    }
    if (lowerPest.contains('beetle') || lowerPest.contains('خنفساء') || lowerPest.contains('escarabajo') || lowerPest.contains('भृंग')) {
      return [l10n.pestLeafBeetlePrevention];
    }
    if (lowerPest.contains('slug') || lowerPest.contains('snail') || lowerPest.contains('بزاقة') || lowerPest.contains('حلزون') || lowerPest.contains('babosa') || lowerPest.contains('स्लग')) {
      return [l10n.pestSlugPrevention];
    }

    return preventionTips;
  }

  String getLocalizedLifeCycle(BuildContext context) {
    if (lifeCycle.isNotEmpty && lifeCycle != 'N/A') return lifeCycle;
    return getLocalizedDescription(context);
  }

  String getLocalizedFavorableConditions(BuildContext context) {
    if (favorableConditions.isNotEmpty && favorableConditions != 'N/A') return favorableConditions;
    return getLocalizedSymptoms(context);
  }

  String getLocalizedEconomicImpact(BuildContext context) {
    if (economicImpact.isNotEmpty && economicImpact != 'N/A') return economicImpact;
    return getLocalizedDescription(context);
  }

  String getLocalizedLongTermPrevention(BuildContext context) {
    if (longTermPrevention.isNotEmpty && longTermPrevention != 'N/A') return longTermPrevention;
    final tips = getLocalizedPrevention(context);
    return tips.isNotEmpty ? tips.join('. ') : '';
  }

  String getLocalizedDamageDetails(BuildContext context) {
    if (damageDetails.isNotEmpty && damageDetails != 'N/A') return damageDetails;
    return getLocalizedSymptoms(context);
  }

  String getLocalizedOrigin(BuildContext context) {
    if (origin.isNotEmpty && origin != 'N/A') return origin;
    final l10n = AppLocalizations.of(context);
    return l10n?.origin ?? 'Worldwide';
  }

  String getLocalizedUseCase(BuildContext context) {
    if (useCase.isNotEmpty && useCase != 'N/A') return useCase;
    final l10n = AppLocalizations.of(context);
    return l10n?.useCase ?? 'Ornamental / Agricultural';
  }

  String getLocalizedExpectedPrice(BuildContext context) {
    if (expectedPrice.isNotEmpty && expectedPrice != 'N/A') return expectedPrice;
    final l10n = AppLocalizations.of(context);
    return l10n?.expectedPrice ?? '\$5 - \$25';
  }

  String getLocalizedBenefits(BuildContext context) {
    if (benefits.isNotEmpty && benefits != 'N/A') return benefits;
    final l10n = AppLocalizations.of(context);
    return l10n?.benefits ?? 'Air purification, Aesthetic appeal, Ecological balance';
  }

  String getLocalizedCareGuide(BuildContext context) {
    if (careGuide.isNotEmpty && careGuide != 'N/A') return careGuide;
    final l10n = AppLocalizations.of(context);
    return l10n?.careGuideTitle ?? 'Provide adequate sunlight, water moderately, and ensure well-draining soil.';
  }

  List<String> getLocalizedCareRecommendations(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = l10n?.localeName ?? 'en';

    if (careRecommendations.isNotEmpty) {
      return careRecommendations.map((rec) => _translateCareRecommendation(lang, rec)).toList();
    }
    if (l10n != null) {
      return [
        l10n.keepHealthy,
        l10n.careGuideTitle,
      ];
    }
    return careRecommendations;
  }

  static String _translateCareRecommendation(String lang, String rec) {
    final clean = rec.trim().toLowerCase();
    if (clean.contains('water') || clean.contains('irrigate') || clean.contains('moisture')) {
      switch (lang) {
        case 'hi': return 'नियमित पानी दें और मिट्टी में नमी बनाए रखें';
        case 'es': return 'Riegue regularmente y mantenga la humedad adecuada del suelo';
        case 'fr': return 'Arrosez régulièrement et maintenez une humidité du sol appropriée';
        case 'de': return 'Regelmäßig gießen und angemessene Bodenfeuchtigkeit aufrechterhalten';
        case 'ar': return 'اسقِ بانتظام وحافظ على رطوبة التربة المناسبة';
        case 'id': return 'Siram secara teratur dan jaga kelembapan tanah yang cukup';
        case 'pt': return 'Regue regularmente e mantenha a umidade adequada do solo';
        case 'tr': return 'Düzenli sulayın ve uygun toprak nemini koruyun';
        default: return rec;
      }
    }
    if (clean.contains('sun') || clean.contains('light') || clean.contains('shade')) {
      switch (lang) {
        case 'hi': return 'पौधे को पर्याप्त धूप और रोशनी प्रदान करें';
        case 'es': return 'Proporcione suficiente luz solar y ventilación';
        case 'fr': return 'Fournir un ensoleillement et une ventilation suffisants';
        case 'de': return 'Ausreichend Sonnenlicht und Belüftung bereitstellen';
        case 'ar': return 'وفر ضوء الشمس التهوية الكافيين للنبات';
        case 'id': return 'Berikan sinar matahari dan ventilasi yang cukup';
        case 'pt': return 'Forneça luz solar e ventilação suficientes';
        case 'tr': return 'Yeterli güneş ışığı ve havalandırma sağlayın';
        default: return rec;
      }
    }
    if (clean.contains('fertiliz') || clean.contains('nutrient') || clean.contains('compost')) {
      switch (lang) {
        case 'hi': return 'उचित उर्वरक और जैविक खाद का प्रयोग करें';
        case 'es': return 'Aplique fertilizante orgánico y nutrientes adecuados';
        case 'fr': return 'Appliquer de l\'engrais biologique et des nutriments adaptés';
        case 'de': return 'Organischen Dünger und geeignete Nährstoffe auftragen';
        case 'ar': return 'استخدم السماد العضوي والمغذيات المناسبة';
        case 'id': return 'Gunakan pupuk organik dan nutrisi yang sesuai';
        case 'pt': return 'Aplique fertilizante orgânico e nutrientes adequados';
        case 'tr': return 'Organik gübre ve uygun besin maddeleri uygulayın';
        default: return rec;
      }
    }
    if (clean.contains('prun') || clean.contains('clean') || clean.contains('remove')) {
      switch (lang) {
        case 'hi': return 'सूखी या प्रभावित पत्तियों की नियमित रूप से छंटाई करें';
        case 'es': return 'Pode las hojas secas o afectadas regularmente';
        case 'fr': return 'Tallez régulièrement les feuilles sèches ou infectées';
        case 'de': return 'Regelmäßig trockene oder befallene Blätter zurückschneiden';
        case 'ar': return 'تقليم الأوراق الجافة أو المصابة بانتظام';
        case 'id': return 'Pangkas daun yang kering atau terinfeksi secara teratur';
        case 'pt': return 'Pode as folhas secas ou afetadas regularmente';
        case 'tr': return 'Kurumuş veya etkilenmiş yaprakları düzenli olarak budayın';
        default: return rec;
      }
    }
    return rec;
  }

  factory PestResult.fromJson(Map<String, dynamic> json) {
    final parsedPlantName = (json['plant_details']?['plant_name'] ?? json['plant_name'])?.toString() ?? '';
    final rawPestName = json['pest_name']?.toString() ?? '';
    final rawDiseaseName = json['disease']?['name']?.toString() ?? '';

    String parsedPestName = rawPestName;
    if (parsedPestName.isEmpty ||
        parsedPestName.toLowerCase() == 'n/a' ||
        parsedPestName.toLowerCase() == 'unknown') {
      if (rawDiseaseName.isNotEmpty &&
          rawDiseaseName.toLowerCase() != 'n/a' &&
          rawDiseaseName.toLowerCase() != 'unknown') {
        parsedPestName = rawDiseaseName;
      } else if (parsedPlantName.isNotEmpty &&
          parsedPlantName.toLowerCase() != 'n/a' &&
          parsedPlantName.toLowerCase() != 'unknown') {
        parsedPestName = parsedPlantName;
      } else {
        parsedPestName = 'Unknown';
      }
    }

    return PestResult(
      isPestDetected: json['is_pest_detected']?.toString() ?? 'no',
      pestName: parsedPestName,
      scientificName: json['scientific_name']?.toString() ?? '',
      severityLevel: json['severity_level']?.toString() ?? 'Low',
      confidence: (num.tryParse(json['confidence']?.toString() ?? '0') ?? 0)
          .toDouble(),
      affectedAreaEstimate: json['affected_area_estimate']?.toString() ?? '',
      symptomsDetected: json['symptoms_detected']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      lifeCycle: json['life_cycle']?.toString() ?? '',
      damageDetails: json['damage_details']?.toString() ?? '',
      favorableConditions: json['favorable_conditions']?.toString() ?? '',
      economicImpact: json['economic_impact']?.toString() ?? '',
      longTermPrevention: json['long_term_prevention']?.toString() ?? '',
      hostPlants:
      (json['host_plants'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      identificationTips:
      (json['identification_tips'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      organicTreatments:
      _parseTreatmentsList(json['treatment']?['organic'] ?? json['organic_treatments']),
      chemicalTreatments:
      _parseChemicalTreatmentsList(json['treatment']?['chemical'] ?? json['chemical_treatments']),
      preventionTips:
      (json['prevention']?['daily_care'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['prevention_tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      plantName: parsedPlantName,
      origin: (json['plant_details']?['origin'] ?? json['origin'])?.toString() ?? '',
      useCase: (json['plant_details']?['use_case'] ?? json['use_case'])?.toString() ?? '',
      expectedPrice: (json['plant_details']?['expected_price'] ?? json['expected_price'])?.toString() ?? '',
      benefits: _parseNestedField(json['plant_details']?['benefits'] ?? json['benefits']),
      careGuide: json['care_guide']?.toString() ?? '',
      careRecommendations: (json['health_care']?['care_recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      scanType: json['scanType']?.toString() ?? 'pest',
      completeData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_pest_detected': isPestDetected,
      'pest_name': pestName,
      'scientific_name': scientificName,
      'severity_level': severityLevel,
      'confidence': confidence,
      'affected_area_estimate': affectedAreaEstimate,
      'symptoms_detected': symptomsDetected,
      'description': description,
      'life_cycle': lifeCycle,
      'damage_details': damageDetails,
      'favorable_conditions': favorableConditions,
      'economic_impact': economicImpact,
      'long_term_prevention': longTermPrevention,
      'host_plants': hostPlants,
      'identification_tips': identificationTips,
      'organic_treatments': organicTreatments.map((e) => e.toJson()).toList(),
      'chemical_treatments': chemicalTreatments.map((e) => e.toJson()).toList(),
      'prevention_tips': preventionTips,
      'plant_details': {
        'plant_name': plantName,
        'origin': origin,
        'use_case': useCase,
        'expected_price': expectedPrice,
        'benefits': benefits,
      },
      'care_guide': careGuide,
    };
  }

  // Database helper methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pest_name': pestName,
      'scientific_name': scientificName,
      'severity_level': severityLevel,
      'confidence': confidence.toString(),
      'affected_area': affectedAreaEstimate,
      'symptoms': symptomsDetected,
      'description': description,
      'life_cycle': lifeCycle,
      'damage_details': damageDetails,
      'favorable_conditions': favorableConditions,
      'economic_impact': economicImpact,
      'long_term_prevention': longTermPrevention,
      'host_plants': jsonEncode(hostPlants),
      'identification_tips': jsonEncode(identificationTips),
      'organic_treatments': jsonEncode(
        organicTreatments.map((e) => e.toJson()).toList(),
      ),
      'chemical_treatments': jsonEncode(
        chemicalTreatments.map((e) => e.toJson()).toList(),
      ),
      'prevention_tips': jsonEncode(preventionTips),
      'plant_name': plantName,
      'origin': origin,
      'use_case': useCase,
      'expected_price': expectedPrice,
      'benefits': benefits,
      'care_guide': careGuide,
      'image_path': imagePath,
      'date_scanned': dateScanned?.toIso8601String(),
      'health_status': healthStatus,
      'health_score': healthScore,
      'care_recommendations': jsonEncode(careRecommendations),
      'scan_type': scanType,
      'complete_data': jsonEncode(completeData),
      'is_favorite': isFavorite ? 1 : 0,
      'is_history': isHistory ? 1 : 0,
    };
  }

  factory PestResult.fromMap(Map<String, dynamic> map) {
    String pName = map['plant_name'] ?? '';
    String pestN = map['pest_name'] ?? '';

    if (pestN.isEmpty ||
        pestN.toLowerCase() == 'unknown' ||
        pestN.toLowerCase() == 'n/a') {
      if (pName.isNotEmpty &&
          pName.toLowerCase() != 'unknown' &&
          pName.toLowerCase() != 'n/a') {
        pestN = pName;
      }
    }

    return PestResult(
      id: map['id'],
      isPestDetected: 'yes', // Assumed if saved
      pestName: pestN.isNotEmpty ? pestN : (pName.isNotEmpty ? pName : 'Unknown'),
      scientificName: map['scientific_name'] ?? '',
      severityLevel: map['severity_level'] ?? 'Low',
      confidence: double.tryParse(map['confidence'] ?? '0') ?? 0.0,
      affectedAreaEstimate: map['affected_area'] ?? '',
      symptomsDetected: map['symptoms'] ?? '',
      description: map['description'] ?? '',
      lifeCycle: map['life_cycle'] ?? '',
      damageDetails: map['damage_details'] ?? '',
      favorableConditions: map['favorable_conditions'] ?? '',
      economicImpact: map['economic_impact'] ?? '',
      longTermPrevention: map['long_term_prevention'] ?? '',
      hostPlants: _parseStringList(map['host_plants']),
      identificationTips: _parseStringList(map['identification_tips']),
      organicTreatments: _parseTreatments(map['organic_treatments']),
      chemicalTreatments: _parseChemicalTreatments(map['chemical_treatments']),
      preventionTips: _parseStringList(map['prevention_tips']),
      plantName: pName,
      origin: map['origin'] ?? '',
      useCase: map['use_case'] ?? '',
      expectedPrice: map['expected_price'] ?? '',
      benefits: map['benefits'] ?? '',
      careGuide: map['care_guide'] ?? '',
      imagePath: map['image_path'],
      dateScanned: map['date_scanned'] != null
          ? DateTime.parse(map['date_scanned'])
          : null,
      healthStatus: map['health_status'] ?? 'Good',
      healthScore: map['health_score'] ?? 100,
      careRecommendations: _parseStringList(map['care_recommendations']),
      scanType: map['scan_type'] ?? 'pest',
      completeData: _parseCompleteData(map['complete_data']),
      isFavorite: map['is_favorite'] == 1,
      isHistory: map['is_history'] == 1,
    );
  }

  static Map<String, dynamic> _parseCompleteData(String? jsonStr) {
    if (jsonStr == null) return {};
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  static List<Treatment> _parseTreatments(String? jsonStr) {
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => Treatment.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static List<ChemicalTreatment> _parseChemicalTreatments(String? jsonStr) {
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => ChemicalTreatment.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  PestResult copyWith({
    int? id,
    String? isPestDetected,
    String? pestName,
    String? scientificName,
    String? severityLevel,
    double? confidence,
    String? affectedAreaEstimate,
    String? symptomsDetected,
    String? description,
    String? lifeCycle,
    String? damageDetails,
    String? favorableConditions,
    String? economicImpact,
    String? longTermPrevention,
    List<String>? hostPlants,
    List<String>? identificationTips,
    List<Treatment>? organicTreatments,
    List<ChemicalTreatment>? chemicalTreatments,
    List<String>? preventionTips,
    String? plantName,
    String? origin,
    String? useCase,
    String? expectedPrice,
    String? benefits,
    String? imagePath,
    DateTime? dateScanned,
    bool? isFavorite,
    bool? isHistory,
    String? careGuide,
    String? healthStatus,
    int? healthScore,
    List<String>? careRecommendations,
    String? scanType,
    Map<String, dynamic>? completeData,
  }) {
    return PestResult(
      id: id ?? this.id,
      isPestDetected: isPestDetected ?? this.isPestDetected,
      pestName: pestName ?? this.pestName,
      scientificName: scientificName ?? this.scientificName,
      severityLevel: severityLevel ?? this.severityLevel,
      confidence: confidence ?? this.confidence,
      affectedAreaEstimate: affectedAreaEstimate ?? this.affectedAreaEstimate,
      symptomsDetected: symptomsDetected ?? this.symptomsDetected,
      description: description ?? this.description,
      lifeCycle: lifeCycle ?? this.lifeCycle,
      damageDetails: damageDetails ?? this.damageDetails,
      favorableConditions: favorableConditions ?? this.favorableConditions,
      economicImpact: economicImpact ?? this.economicImpact,
      longTermPrevention: longTermPrevention ?? this.longTermPrevention,
      hostPlants: hostPlants ?? this.hostPlants,
      identificationTips: identificationTips ?? this.identificationTips,
      organicTreatments: organicTreatments ?? this.organicTreatments,
      chemicalTreatments: chemicalTreatments ?? this.chemicalTreatments,
      preventionTips: preventionTips ?? this.preventionTips,
      plantName: plantName ?? this.plantName,
      origin: origin ?? this.origin,
      useCase: useCase ?? this.useCase,
      expectedPrice: expectedPrice ?? this.expectedPrice,
      benefits: benefits ?? this.benefits,
      imagePath: imagePath ?? this.imagePath,
      dateScanned: dateScanned ?? this.dateScanned,
      isFavorite: isFavorite ?? this.isFavorite,
      isHistory: isHistory ?? this.isHistory,
      careGuide: careGuide ?? this.careGuide,
      healthStatus: healthStatus ?? this.healthStatus,
      healthScore: healthScore ?? this.healthScore,
      careRecommendations: careRecommendations ?? this.careRecommendations,
      scanType: scanType ?? this.scanType,
      completeData: completeData ?? this.completeData,
    );
  }

  static String _parseNestedField(dynamic field) {
    if (field == null) return '';
    if (field is String) return field;
    if (field is Map) {
      // If it's a map, try to join its values or pick a main one
      final values = field.values.where((v) => v != null).map((v) => v.toString()).toList();
      return values.join(', ');
    }
    return field.toString();
  }

  static List<Treatment> _parseTreatmentsList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) {
        if (e is String) return Treatment(name: e, instructions: 'N/A', frequency: 'N/A');
        return Treatment.fromJson(e as Map<String, dynamic>);
      }).toList();
    }
    return [];
  }

  static List<ChemicalTreatment> _parseChemicalTreatmentsList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) {
        if (e is String) return ChemicalTreatment(name: e, dosage: 'N/A', safetyPrecautions: 'N/A');
        return ChemicalTreatment.fromJson(e as Map<String, dynamic>);
      }).toList();
    }
    return [];
  }

  static List<String> _parseStringList(String? jsonStr) {
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }
}

class Treatment {
  final String name;
  final String instructions;
  final String frequency;

  Treatment({
    required this.name,
    required this.instructions,
    required this.frequency,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      name: json['name'] ?? '',
      instructions: json['instructions'] ?? '',
      frequency: json['frequency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'instructions': instructions,
    'frequency': frequency,
  };
}

class ChemicalTreatment {
  final String name;
  final String dosage;
  final String safetyPrecautions;

  ChemicalTreatment({
    required this.name,
    required this.dosage,
    required this.safetyPrecautions,
  });

  factory ChemicalTreatment.fromJson(Map<String, dynamic> json) {
    return ChemicalTreatment(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      safetyPrecautions: json['safety_precautions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'dosage': dosage,
    'safety_precautions': safetyPrecautions,
  };
}
